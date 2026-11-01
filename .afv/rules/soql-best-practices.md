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
