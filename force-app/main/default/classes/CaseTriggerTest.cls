@IsTest
private class CaseTriggerTest {

    @IsTest
    static void caseTrigger_insert_savesRecord() {
        Case c = new Case(Subject = 'Insert case', Origin = 'Web');
        insert c;

        Assert.isNotNull(c.Id, 'Insert should fire the before and after insert contexts without errors');
    }

    @IsTest
    static void caseTrigger_update_savesChange() {
        Case c = new Case(Subject = 'Update case', Origin = 'Web');
        insert c;

        c.Priority = 'High';
        update c;

        Assert.areEqual('High', [SELECT Priority FROM Case WHERE Id = :c.Id].Priority);
    }

    @IsTest
    static void caseTrigger_delete_removesRecord() {
        Case c = new Case(Subject = 'Delete case', Origin = 'Web');
        insert c;

        delete c;

        Assert.areEqual(0, [SELECT COUNT() FROM Case WHERE Id = :c.Id]);
    }

    @IsTest
    static void caseTrigger_undelete_restoresRecord() {
        Case c = new Case(Subject = 'Undelete case', Origin = 'Web');
        insert c;
        delete c;

        undelete c;

        Assert.areEqual(1, [SELECT COUNT() FROM Case WHERE Id = :c.Id]);
    }

    @IsTest
    static void caseTrigger_bulkLifecycle_processesAllRecords() {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 200; i++) {
            cases.add(new Case(Subject = 'Bulk case ' + i, Origin = 'Web'));
        }

        Test.startTest();
        insert cases;
        for (Case c : cases) {
            c.Priority = 'Low';
        }
        update cases;
        delete cases;
        undelete cases;
        Test.stopTest();

        Assert.areEqual(200, [SELECT COUNT() FROM Case WHERE Priority = 'Low' AND Subject LIKE 'Bulk case %']);
    }
}
