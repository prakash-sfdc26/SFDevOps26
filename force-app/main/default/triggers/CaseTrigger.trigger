trigger CaseTrigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    CaseTriggerHandler handler = new CaseTriggerHandler();
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.onBeforeInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            handler.onBeforeDelete(Trigger.old, Trigger.oldMap);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.onAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        } else if (Trigger.isDelete) {
            handler.onAfterDelete(Trigger.old, Trigger.oldMap);
        } else if (Trigger.isUndelete) {
            handler.onAfterUndelete(Trigger.new);
        }
    }
}
