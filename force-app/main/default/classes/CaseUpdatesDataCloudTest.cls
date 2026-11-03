@IsTest
private class CaseUpdatesDataCloudTest {

    private static CaseUpdatesDataCloud.InputWrapper input(String queue, String caseId, String priority) {
        CaseUpdatesDataCloud.InputWrapper w = new CaseUpdatesDataCloud.InputWrapper();
        w.queueDeveloperName = queue;
        w.caseId = caseId;
        w.priority = priority;
        return w;
    }

    @IsTest
    static void getQueueIdAndAssignCase_existingQueue_assignsCaseAndSetsPriority() {
        Group queue = TestDataFactory.createCaseQueue('Support_Queue');
        Case c = new Case(Subject = 'Needs owner', Priority = 'Low');
        insert c;

        Test.startTest();
        List<CaseUpdatesDataCloud.OutputWrapper> results = CaseUpdatesDataCloud.getQueueIdAndAssignCase(
            new List<CaseUpdatesDataCloud.InputWrapper>{ input('Support_Queue', c.Id, 'High') }
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].success, results[0].message);
        System.assertEquals(queue.Id, results[0].queueId);
        Case updated = [SELECT OwnerId, Priority FROM Case WHERE Id = :c.Id];
        System.assertEquals(queue.Id, updated.OwnerId);
        System.assertEquals('High', updated.Priority);
    }

    @IsTest
    static void getQueueIdAndAssignCase_missingQueue_reportsFailure() {
        List<CaseUpdatesDataCloud.OutputWrapper> results = CaseUpdatesDataCloud.getQueueIdAndAssignCase(
            new List<CaseUpdatesDataCloud.InputWrapper>{ input('Nope', null, 'High') }
        );
        System.assert(!results[0].success);
        System.assert(results[0].message.contains('not found'));
    }

    @IsTest
    static void getQueueIdAndAssignCase_emptyRequests_returnsEmptyList() {
        System.assertEquals(0, CaseUpdatesDataCloud.getQueueIdAndAssignCase(null).size());
        System.assertEquals(0, CaseUpdatesDataCloud.getQueueIdAndAssignCase(new List<CaseUpdatesDataCloud.InputWrapper>()).size());
    }
}