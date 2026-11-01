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
