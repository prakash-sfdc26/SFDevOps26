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
