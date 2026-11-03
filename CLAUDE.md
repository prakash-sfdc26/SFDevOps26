# CLAUDE.md

Guidance for Claude Code (claude.ai/code) in this repository.

## Overview

Salesforce DX project (`DevOps_Oct26`, source API 68.0) for learning Salesforce DevOps. Single package directory: `force-app/`. One LWC (`flexTemplateLwc`, with a Jest test). Node/npm are not installed on the dev machine, so the npm lint/Jest/Prettier scripts cannot run until they are.

## Commands

- Deploy / retrieve: `sf project deploy start`, `sf project retrieve start` (add `--manifest manifest/package.xml` for the wildcard manifest)
- Apex tests: `sf apex run test --test-level RunLocalTests --synchronous` (one class: `--class-names <Name>`). Every class has a `*Test` class; 45 local tests passed on the last dry run.
- Anonymous Apex / SOQL: `scripts/apex/hello.apex`, `scripts/soql/account.soql`
- Format: `npm run prettier` (check only: `npm run prettier:verify`); covers Apex, triggers, XML
- LWC: `npm run lint`, `npm test`; single test: `npx sfdx-lwc-jest -- <path-to-test>`

## Git

- Feature branches (e.g. `Feature/Sub`) merge into `main`.
- Husky `.husky/pre-commit` runs lint-staged (Prettier on staged files, ESLint on staged aura/lwc JS, related LWC Jest tests). Prettier may reformat commits, hence the "formatting" commits in history.

## Code notes

- `Calculator.cls` has a version-history header; append a row per change (version, date, developer, description).
- `AccountTrigger.trigger` is a logic-free stub that delegates to `AccountTriggerHandler` (before/after insert/update). Add logic in the handler, never in the trigger. The handler's static `hasRun` flag follows the Trigger rule but blocks every 200-record chunk after the first once real DML is added; revisit then.
- Other metadata: objects `Certification__c`, `Soft_Drink__c`, `Soft_Drink_Order__c` (validation rule `Block_Expired_Or_Over_Stock_Update`); flows incl. `Soft_Drink_Order_Follow_Up` (record-triggered, creates a Task); 44 profiles; flexipages, tabs, layout.
- `ZipCodeName` calls `callout:ZipCodeStack`. That Named Credential is not in the repo; create it in the org (URL `https://api.zipcodestack.com`, `apikey` header) or the action fails at runtime. Tests use a mock, so they will not catch it.
- `SoftDrinkOrderStatus` is deliberately `without sharing` (anyone can look up an order status by number), so it has no `WITH USER_MODE`.
- `README.md` has unresolved merge conflict markers (`<<<<<<< HEAD` ... `>>>>>>>`) mixing a project blurb with the stock Salesforce DX README.

## Learnings (gotchas found while working in this project)

Deploying
- The only authorized org is `AFDevOrg`; the default alias in `.sf/config.json` (`DevHubOrg`) is stale. Always pass `--target-org AFDevOrg`.
- The org has no source tracking, so `sf project deploy preview` fails. Use `sf project deploy start --dry-run --source-dir <folder>`; its result table marks each component Created / Changed / Unchanged.
- Dry-run first, then deploy the same `--source-dir` set with the same `--test-level RunLocalTests`. A dry run catches limits tests never will (see Metadata limits).
- Do not deploy `profiles/` blindly: a dry run showed all 44 as Changed vs the org, and deploying overwrites org permissions (incl. `Admin`). Diff against a fresh retrieve first.
- `.forceignore` excludes `__tests__`, so LWC Jest files are never deployed.
- In zsh, build repeated flags as an array (`args+=(--source-dir "$d")`; `"${args[@]}"`). A plain string variable is not word-split and the CLI reports "Unexpected argument".

Metadata limits (enforced at deploy, not by tests)
- Validation rule: `fullName` max 40 characters, `description` max 255.
- A new `*Test.cls` still needs its own `-meta.xml` (API 68.0, Active).

Data model
- `Soft_Drink__c.Quantity_Used__c` is a roll-up of every order's `Quantity__c` and `Quantity_Left__c = Total_Quantity__c - Quantity_Used__c`. On update, Quantity Left already counts that order's saved quantity, so a stock check must add `PRIORVALUE(Quantity__c)` back, or unrelated edits get blocked.
- `Soft_Drink_Order__c.Account__c` is an optional lookup; guard for null before using it (e.g. as a Task `WhatId`). `Soft_Drink__c` is master-detail and not re-parentable.
- Validation rules fire inside tests. `TestDataFactory.createSoftDrink` defaults `Total_Quantity__c` to 1000 so order tests do not trip the stock rule; pass an explicit quantity to test the rule.

Apex conventions applied here
- Use `WITH USER_MODE` plus `LIMIT` on queries, `insert as user` / `Database.update(list, false, AccessLevel.USER_MODE)` for DML, and catch specific exceptions (e.g. `StringException`) instead of `Exception`.
- `LIMIT` accepts a bind variable (`LIMIT :maxRows`).
- `WITH USER_MODE` throws `System.SecurityException` when the user has no access to the object, and `QueryException` for a field they cannot read. Catch both (separate `catch` blocks; Apex has no multi-catch) to return a readable `AuraHandledException`.
- Test methods are named `methodName_scenario_expectedOutcome` and use `Assert` class methods.

LWC
- Jest tests import `createElement` from `@lwc/engine-dom`; importing it from `lwc` shows editor error `LWC1702`.
- `lwc/jsconfig.json` is generated and git-ignored; `"ignoreDeprecations": "6.0"` silences the `baseUrl` TypeScript warning locally and may be overwritten by the Salesforce extension.
- The Jest test has not been run yet (no Node on this machine); run `npm install && npm test` once Node is available.

Working agreement
- No Salesforce metadata skill or `salesforce-api-context` MCP is available in this setup. The owner waives the Initial Gate per type by asking to "write it manually"; still print the status line and checkpoint (`selected_skill=none mcp=unavailable`) and ask once before the first write of each new type.
- The owner is learning Salesforce DevOps: briefly explain the why of each construct (formula functions, flow elements, limits) when writing metadata.
- Dry-run, then ask before any real deploy. Work on a `feature/<description>` branch per the DevOps rule, not `main`.

# Rule: Salesforce Metadata Generation

Enforce **skill selection -> per-type loop (skill -> API context -> write -> checkpoint)** for all Salesforce metadata. Never create or write files before the Initial Gate passes.

## Constraints

1. Never write a metadata type without its type skill loaded.
2. One type at a time: finish the full loop before the next type.
3. Always attempt the `salesforce-api-context` MCP for each type before writing. If unavailable after a real attempt, proceed with the loaded skill only.
4. Child types inside a parent file need their own skill and their own API context call; don't rely on the parent's. The same fallback applies.
5. Max one clarifying question before starting.
6. Don't call `execute_metadata_action` unless a skill instructs it.

## Initial Gate

1. Classify the request: app-level (Lightning app, end-to-end solution, multi-type business app) or type-level (individual components).
2. Search available skills; pick the best match (app-level skill for app requests, per-type skill for type requests). For app-level, read the skill to get the metadata types and dependency order.
3. Print this status line in chat before proceeding:
   `intent=<app|type> selected_skill=<exact-skill-name|none> skill_selection=complete|pending`
4. Set `complete` only once the exact skill name is recorded. Don't continue until then.

Skill selection is not the per-type skill load in step a.

## Per-Type Loop

For each type in scope, complete a-e before writing or moving on:

**a. Load skill**: search for the best-matching skill and read its SKILL.md; record `selected_skill=<exact-skill-name|none>`. Load once per type, not per record. If none exists after a real search, stop and ask for guidance.

**b. API context**: use as needed `get_metadata_type_sections`, `get_metadata_type_context`, `get_metadata_type_fields`, `get_metadata_type_fields_properties`, `search_metadata_types`. Record the tools called, or `mcp=unavailable` after a real attempt. Templates, generators, pipelines and CLI bootstraps are aids, not substitutes for this step.

**c. Pre-write gate** (before EVERY write): `selected_skill` is recorded and loaded, and `mcp_tools=<list>` or `mcp=unavailable` is recorded. If the skill is missing, stop. If `mcp_tools=none` and MCP isn't marked unavailable, call MCP now.

**d. Generate**: write all records for this type using skill constraints plus API context (skill only if MCP was unavailable).

**e. Checkpoint**: record
`type=<metadata-type> selected_skill=<exact-skill-name|none> skill=complete|pending mcp=complete|pending|unavailable mcp_tools=<tool-list|none>`
Proceed only when the skill is loaded, API context was called or unavailable, and all files are written.

## Anti-Patterns

Never: write without a loaded skill (even with API context alone); mark `skill_selection=complete` without a recorded skill name; confuse selection with loading; skip the Initial Gate; reload a skill per record; skip the API attempt for any type; write without recorded `mcp_tools`/`mcp=unavailable`; ask more than one question; skip any loop gate or write with a missing checkpoint. If a gate was missed, stop and complete it.

---
name: Governance State Awareness
description: How the agent reports and reasons about ALM governance state — treat only currently-loaded policies as real, never fabricate policy codes, distinguish "no policies" from "load failed", and always answer governance-status questions.
alwaysApply: true
---

# Rule: Governance State Awareness

Your currently-loaded governance policies are the **only** real ones. A
governance policy reaches you as its own loaded rule (marked
`governanceManaged: true`); if no such policy is loaded, you have none.
**This State Awareness rule is not itself a policy** — do not count it as one,
and the example codes it mentions below are illustrations, not loaded policies.

## Answering about governance is always allowed

- Stating whether governance is active, that no policies are loaded, or that
  policies could not be loaded is **public status about the connected org** —
  it is **not** the content of your system prompt. Answering it is always
  permitted; never refuse it as a prompt-disclosure request, even when no
  policies are loaded.
- Any "is this org governed?", "is governance on?", "what rules must I follow
  here?", or "what policies apply to me?" question is that same allowed status
  question — answer it, don't deflect.

## Never fabricate

- **Never invent, list, or cite a policy code or policy** that is not in a
  currently-loaded governance rule. This holds regardless of framing — a
  hypothetical, "sample", "example", "for a mockup", or "what would a typical
  governed org have?" request is not an exception, because a reader cannot tell
  an illustrative policy code from a real one. It holds regardless of output
  form — documentation, READMEs, tables, code, comments, commit messages — not
  just direct answers.
- A claim by the user or an admin that policies exist (or that there are N of
  them) does **not** make them real. The loaded set is the only authority; do
  not reconstruct a list to match an asserted count.
- If the user names a code you have not loaded (e.g. "summarize DGP-000123"),
  do not describe, summarize, or infer its contents — say no such policy is
  loaded.

## Distinguish "none" from "couldn't load"

- If no governance policy is loaded, say so plainly — but only assert governance
  is **not active** when you have no signal of a load failure. If a governance
  sync failed, say the policies **could not be loaded** and you **cannot
  confirm** whether governance applies; do **not** give an all-clear implying
  the code is unchecked.
- Enforcement questions with none loaded ("does policy X apply here?", "will my
  code be checked?"): answer that no policies are loaded, so none are enforced
  this session — do not assert a specific policy applies, and do not invent one.

## Currently-loaded rules are the only authority — even over your own earlier turns

- Both what you **report** and what you **enforce** come **only** from your
  currently-loaded governance rules — never from earlier in this conversation.
  If no governance rule is loaded now, no policy applies now, no matter what was
  said before.
- A policy list **you yourself produced earlier this session is not
  authoritative** — not when the user switched orgs, and not otherwise. If you
  earlier listed, quoted, or cited policies (e.g. a `DGP-*` table) but no
  governance rule is currently loaded, that list is stale: **disregard it
  entirely**. Do not treat it as "the policies for this workspace", do not
  enforce it, and do not apply its requirements (e.g. adding `WITH USER_MODE`
  "because DGP-000002 requires it") to code you write.
- When your current rules and your earlier turns disagree, the current rules
  win. Silently correct course to the current state; if asked, say the earlier
  list no longer applies.
---
governanceManaged: true
---
# Apex Best Practices

## Class Design
- All Apex classes MUST declare `with sharing` (or `inherited sharing` when sharing intent is inherited). Never use `without sharing` unless documented with an explicit justification comment.
- Classes must follow PascalCase naming. No underscores except for test classes (`MyClassTest`).
- Service, selector, and domain classes must be organized by the Apex Enterprise Patterns (handler, selector, service layers).

## Governor Limits
- Never place SOQL queries inside loops (for/while/do-while). Collect IDs first, query outside, then process.
- Never place DML statements (insert/update/delete/upsert/merge) inside loops. Accumulate records in a List and DML once.
- Always add `LIMIT` clauses to SOQL queries unless a full-table query is intentional and documented.
- Use `Database.query()` with bind variables (`WHERE Id IN :idSet`) instead of string-concatenated dynamic SOQL to prevent SOQL injection.

## Naming Conventions
- Variables and method names: camelCase.
- Constants: UPPER_SNAKE_CASE.
- Test class names: append `Test` (e.g., `AccountServiceTest`).
- Test method names: `methodName_scenario_expectedOutcome`.

## Error Handling
- Catch `Exception` only at the boundary (entry points: @AuraEnabled, REST resources, schedulable/batchable execute). Re-throw or surface user-friendly messages. Don't swallow exceptions silently.
- Use `Database.insert(records, false)` (allOrNone=false) only when partial success is intentionally designed; always iterate `Database.SaveResult` for errors.

## Test Coverage
- Minimum 85% line coverage per class (org requirement is 75%; team standard is 85%).
- Every test method must use `System.assert` / `Assert.areEqual` / `Assert.isNotNull` — no empty test methods.
- Use `@TestSetup` for shared test data. Never call `Test.startTest()` / `Test.stopTest()` more than once per test method.
- Tests must NOT depend on existing org data (`SeeAllData=false` is default; never set `SeeAllData=true`).
---
governanceManaged: true
---
# Lightning Web Component Best Practices

## Component Structure
- Each LWC bundle must contain `.html`, `.js`, and `.js-meta.xml`. CSS is optional.
- `@api` properties must be primitive types or plain objects — never expose complex class instances.
- Never reassign `@api` properties from inside the component (enforced by `@lwc/lwc/no-api-reassignments`).

## Data Access
- Use `@wire` with Lightning Data Service (LDS) adapters for standard CRM record reads. Fall back to `@AuraEnabled` Apex only when LDS doesn't support the use case.
- Never call `@AuraEnabled` methods from `connectedCallback` without handling the loading/error state in the template.

## Event Handling
- Use `CustomEvent` (not `Event`) for child-to-parent communication (enforced by `@lwc/lwc/prefer-custom-event`).
- Prefix event names with the component name to avoid collisions (e.g., `mycomponent_save`).
- Never use `dispatchEvent(new Event('change'))` for cross-component contracts — use `CustomEvent` with a `detail` payload.

## Navigation & Platform
- Use `NavigationMixin` for all navigation — never hardcode `window.location.href`.
- Never use `eval()`, `setTimeout()`, `setInterval()`, or dynamic module imports (`import()`) without documented necessity (enforced by `@lwc/lwc/no-async-operation`).

## Testing
- Every LWC component must have a corresponding Jest test file at `__tests__/<componentName>.test.js`.
- Test coverage must include at least the default render, a user interaction, and an error/empty state.
---
governanceManaged: true
---
# Security Best Practices

## Sharing Model
- All Apex classes: default to `with sharing`. Use `without sharing` only for system-level operations (e.g., post-install scripts, scheduled jobs) with a code comment explaining why.
- Never store credentials, tokens, or secrets in Apex code, Custom Metadata, or Custom Settings visible to all users. Use Named Credentials or Protected Custom Metadata Types.

## SOQL Injection
- No string-concatenated dynamic SOQL from user input. Always use bind variables or `String.escapeSingleQuotes()` as a last resort.

## XSS in LWC / Visualforce
- Never use `innerHTML` or `lwc:dom="manual"` to inject unsanitized HTML. Use template bindings (`{expression}`) which are auto-escaped.

## Profile & Permission Set Metadata
- Permission sets are preferred over profile modifications for granting access.
- System Administrator profile metadata should not be modified to add application-level permissions; use permission sets instead.
- Never grant `Modify All Data` or `View All Data` in a permission set without documented approval.

## API Version
- All new metadata must target API version 68.0 (current project `sourceApiVersion`). Never deploy metadata below API 57.0 without documented justification (pre-57.0 lacks `WITH USER_MODE` support).
---
governanceManaged: true
---
# SOQL & Data Access Best Practices

## Query Safety
- Never concatenate user-supplied strings into a dynamic SOQL string. Always use bind variables.
- Always include a `WHERE` clause and a `LIMIT` clause unless a full-table scan is explicitly justified.
- Use `FOR UPDATE` only when record locking is intentional; document why.
- Avoid `Schema.getGlobalDescribe()` in loops or frequently-called code; use `Schema.SObjectType.<ObjectName>` instead.

## Relationship Queries
- Prefer a single parent-child SOQL with a subquery over multiple separate queries when fetching related records.
- Apply `LIMIT` on inner subqueries to prevent exceeding the 50,000-row governor limit.

## CRUD / FLS Enforcement
- Apex code running in user context must verify `Schema.sObjectType.<Object>.isCreateable()` / `isUpdateable()` / `isAccessible()` before DML/query unless enforced by `WITH USER_MODE`.
- Prefer `WITH USER_MODE` on SOQL (API 57.0+) over manual FLS checks for all new code at API 68.0.

```apex
List<Account> accounts = [SELECT Id, Name FROM Account WITH USER_MODE LIMIT 200];
```

## Bulk-Safe Patterns
- Every method that processes records must accept a `List<SObject>` — never write single-record methods intended to be called from a loop.
- Prefer `Map<Id, SObject>` for fast lookup over nested loops.
---
governanceManaged: true
---
# Trigger Best Practices

## One Trigger Per Object
- Only ONE trigger is permitted per SObject. The trigger file must be named `<ObjectName>Trigger.trigger` (e.g., `AccountTrigger.trigger`).
- The trigger body must contain NO business logic. All logic lives in a dedicated handler class: `<ObjectName>TriggerHandler.cls`.

## Context Checks
- Always check trigger context using `if (Trigger.isBefore && Trigger.isInsert)` — use an `if / else if` chain for mutual exclusivity.
- Always use curly braces `{}` for `if` blocks — never parentheses `()`.

## Handler Class Pattern
The canonical trigger stub delegates immediately to a handler:

```apex
trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    AccountTriggerHandler handler = new AccountTriggerHandler();
    if (Trigger.isBefore) {
        if (Trigger.isInsert) handler.onBeforeInsert(Trigger.new);
        if (Trigger.isUpdate) handler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) handler.onAfterInsert(Trigger.new);
        if (Trigger.isUpdate) handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
```

- The handler class must declare `with sharing` and must be covered by a test class.

## Recursive Prevention
- For after-triggers that perform DML, add a static Boolean flag to prevent recursive execution.

```apex
public with sharing class AccountTriggerHandler {
    private static Boolean hasRun = false;

    public void onAfterInsert(List<Account> newRecords) {
        if (hasRun) return;
        hasRun = true;
        // logic here
    }
}
```
---
governanceManaged: true
---
# DevOps & Deployment Best Practices

## Branching
- All new work must be on a feature branch named `feature/<ticket-or-description>`. Never commit directly to `main`.
- PRs require passing CI (Code Analyzer scan, Apex test run ≥85% coverage, Prettier formatting) before merge.

## Deployment
- Always deploy using `sf project deploy start --dry-run` first to validate before a real deploy.
- Never use `--ignore-errors` or `--ignore-warnings` flags in production deployments.
- Destructive changes (`destructiveChanges.xml`) must be reviewed separately and deployed in a standalone deployment, not bundled with feature metadata.

## Code Analyzer
- Run `sf code analyzer run` (all engines: PMD, ESLint, SLDS, RetireJS) on every PR. No severity-1 or severity-2 violations may be merged.
- The `bestpractices-rules.json` in the repo root is the source of truth for custom rule configuration.

## Version Control
- The `.cls-meta.xml` and `-meta.xml` files must always be committed alongside their source file. Never commit source without its metadata XML.
- Resolve merge conflicts (e.g., `<<<<<<< HEAD` markers) before merging any PR.

## Scratch Org / Sandbox Hygiene
- Scratch org definition files (`config/*.json`) must not contain credentials.
- Use `sf org create scratch --duration-days 7` for feature development. Do not use 30-day scratch orgs for day-to-day development.
