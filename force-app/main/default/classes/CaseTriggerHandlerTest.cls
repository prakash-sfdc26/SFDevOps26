@IsTest
private class CaseTriggerHandlerTest {

    private static List<Case> buildCases(Integer count) {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < count; i++) {
            cases.add(new Case(Subject = 'Handler case ' + i, Origin = 'Web', Priority = 'Medium'));
        }
        return cases;
    }

    @IsTest
    static void onBeforeInsert_newRecords_leavesRecordsUnchanged() {
        List<Case> cases = buildCases(3);

        new CaseTriggerHandler().onBeforeInsert(cases);

        Assert.areEqual(3, cases.size());
        Assert.areEqual('Medium', cases[0].Priority, 'Stub handler must not modify records');
    }

    @IsTest
    static void onBeforeUpdate_changedRecords_leavesRecordsUnchanged() {
        List<Case> cases = buildCases(3);
        insert cases;
        Map<Id, Case> oldMap = new Map<Id, Case>(cases.deepClone(true));
        cases[0].Priority = 'High';

        new CaseTriggerHandler().onBeforeUpdate(cases, oldMap);

        Assert.areEqual('High', cases[0].Priority, 'Stub handler must not modify records');
        Assert.areEqual('Medium', oldMap.get(cases[0].Id).Priority);
    }

    @IsTest
    static void onBeforeDelete_existingRecords_leavesRecordsInPlace() {
        List<Case> cases = buildCases(3);
        insert cases;
        Map<Id, Case> oldMap = new Map<Id, Case>(cases);

        new CaseTriggerHandler().onBeforeDelete(cases, oldMap);

        Assert.areEqual(3, [SELECT COUNT() FROM Case WHERE Id IN :oldMap.keySet()]);
    }

    @IsTest
    static void onAfterInsert_savedRecords_leavesRecordsUnchanged() {
        List<Case> cases = buildCases(3);
        insert cases;

        new CaseTriggerHandler().onAfterInsert(cases);

        Assert.areEqual(3, [SELECT COUNT() FROM Case WHERE Id IN :new Map<Id, Case>(cases).keySet() AND Priority = 'Medium']);
    }

    @IsTest
    static void onAfterUpdate_changedRecords_leavesRecordsUnchanged() {
        List<Case> cases = buildCases(3);
        insert cases;
        Map<Id, Case> oldMap = new Map<Id, Case>(cases.deepClone(true));
        for (Case c : cases) {
            c.Priority = 'Low';
        }
        update cases;

        new CaseTriggerHandler().onAfterUpdate(cases, oldMap);

        Assert.areEqual(3, [SELECT COUNT() FROM Case WHERE Id IN :oldMap.keySet() AND Priority = 'Low']);
    }

    @IsTest
    static void onAfterDelete_deletedRecords_leavesRecordsDeleted() {
        List<Case> cases = buildCases(3);
        insert cases;
        Map<Id, Case> oldMap = new Map<Id, Case>(cases);
        delete cases;

        new CaseTriggerHandler().onAfterDelete(cases, oldMap);

        Assert.areEqual(0, [SELECT COUNT() FROM Case WHERE Id IN :oldMap.keySet()]);
    }

    @IsTest
    static void onAfterUndelete_restoredRecords_leavesRecordsRestored() {
        List<Case> cases = buildCases(3);
        insert cases;
        delete cases;
        undelete cases;

        new CaseTriggerHandler().onAfterUndelete(cases);

        Assert.areEqual(3, [SELECT COUNT() FROM Case WHERE Id IN :new Map<Id, Case>(cases).keySet()]);
    }

    @IsTest
    static void allHandlerMethods_emptyLists_doNotThrow() {
        CaseTriggerHandler handler = new CaseTriggerHandler();
        List<Case> none = new List<Case>();
        Map<Id, Case> noneMap = new Map<Id, Case>();

        // An unexpected exception here fails the test, so reaching the asserts means every method tolerated empty input
        handler.onBeforeInsert(none);
        handler.onBeforeUpdate(none, noneMap);
        handler.onBeforeDelete(none, noneMap);
        handler.onAfterInsert(none);
        handler.onAfterUpdate(none, noneMap);
        handler.onAfterDelete(none, noneMap);
        handler.onAfterUndelete(none);

        Assert.isTrue(none.isEmpty(), 'Handler must not add records to the trigger collection');
        Assert.isTrue(noneMap.isEmpty(), 'Handler must not add records to the trigger map');
    }
}
