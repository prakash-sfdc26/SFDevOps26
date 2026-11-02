public with sharing class AccountTriggerHandler {

    private static Boolean hasRun = false;

    public void onBeforeInsert(List<Account> newRecords) {
    }

    public void onBeforeUpdate(List<Account> newRecords, Map<Id, Account> oldMap) {
    }

    public void onAfterInsert(List<Account> newRecords) {
        if (hasRun) return;
        hasRun = true;
    }

    public void onAfterUpdate(List<Account> newRecords, Map<Id, Account> oldMap) {
        if (hasRun) return;
        hasRun = true;
    }
}
