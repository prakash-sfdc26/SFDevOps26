@IsTest
private class CaseUpdatesTest {

    private static CaseUpdates.InputWrapper input(String queue, String caseId) {
        CaseUpdates.InputWrapper w = new CaseUpdates.InputWrapper();
        w.queueDeveloperName = queue;
        w.caseId = caseId;
        return w;
    }

    @IsTest
    static void getQueueIdAndAssignCase_existingQueue_assignsCase() {
        Group queue = TestDataFactory.createCaseQueue('Support_Queue');
        Case c = new Case(Subject = 'Needs owner');
        insert c;

        Test.startTest();
        List<CaseUpdates.OutputWrapper> results = CaseUpdates.getQueueIdAndAssignCase(
            new List<CaseUpdates.InputWrapper>{ input('support_queue', c.Id) } // lookup is case-insensitive
        );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].success, results[0].message);
        System.assertEquals(queue.Id, results[0].queueId);
        System.assertEquals('Success: Case assigned to queue support_queue', results[0].message);
        System.assertEquals(queue.Id, [SELECT OwnerId FROM Case WHERE Id = :c.Id].OwnerId);
    }

    @IsTest
    static void getQueueIdAndAssignCase_noCaseId_returnsQueueOnly() {
        Group queue = TestDataFactory.createCaseQueue('Support_Queue');
        List<CaseUpdates.OutputWrapper> results = CaseUpdates.getQueueIdAndAssignCase(
            new List<CaseUpdates.InputWrapper>{ input('Support_Queue', null) }
        );
        System.assert(results[0].success);
        System.assertEquals(queue.Id, results[0].queueId);
        System.assertEquals('Queue found: Support_Queue', results[0].message);
    }

    @IsTest
    static void getQueueIdAndAssignCase_missingOrBlankQueue_reportsFailure() {
        List<CaseUpdates.OutputWrapper> results = CaseUpdates.getQueueIdAndAssignCase(new List<CaseUpdates.InputWrapper>{
            input('Does_Not_Exist', null), input('', null)
        });
        System.assertEquals(2, results.size());
        System.assert(!results[0].success);
        System.assert(results[0].message.contains('not found'));
        System.assert(!results[1].success);
        System.assertEquals('No queue developer name provided', results[1].message);
    }

    @IsTest
    static void getQueueIdAndAssignCase_invalidOrDeletedCase_doesNotFailBatch() {
        TestDataFactory.createCaseQueue('Support_Queue');
        Case good = new Case(Subject = 'Good');
        Case deleted = new Case(Subject = 'Deleted');
        insert new List<Case>{ good, deleted };
        delete deleted;

        List<CaseUpdates.OutputWrapper> results = CaseUpdates.getQueueIdAndAssignCase(new List<CaseUpdates.InputWrapper>{
            input('Support_Queue', 'not-an-id'),
            input('Support_Queue', deleted.Id),
            input('Support_Queue', good.Id)
        });

        System.assert(!results[0].success);
        System.assert(results[0].message.startsWith('Queue found but error updating Case'));
        System.assert(!results[1].success);
        System.assert(results[1].message.startsWith('Queue found but error updating Case'));
        System.assert(results[2].success, results[2].message);
    }

    @IsTest
    static void getQueueIdAndAssignCase_emptyRequests_returnsEmptyList() {
        System.assertEquals(0, CaseUpdates.getQueueIdAndAssignCase(null).size());
        System.assertEquals(0, CaseUpdates.getQueueIdAndAssignCase(new List<CaseUpdates.InputWrapper>()).size());
    }
}