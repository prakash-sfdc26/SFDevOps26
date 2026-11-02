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
