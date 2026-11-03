@IsTest
private class AccountTriggerTest {

    @IsTest
    static void accountTrigger_insertAndUpdate_savesRecords() {
        Account acc = TestDataFactory.createAccount('Trigger Co');
        System.assertNotEquals(null, acc.Id, 'Insert should fire the trigger without errors');

        acc.Rating = 'Hot';
        update acc;
        System.assertEquals('Hot', [SELECT Rating FROM Account WHERE Id = :acc.Id].Rating);
    }

    @IsTest
    static void accountTrigger_bulkInsertAndUpdate_savesAllRecords() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Bulk Co ' + i));
        }

        Test.startTest();
        insert accounts;
        for (Account acc : accounts) {
            acc.Rating = 'Warm';
        }
        update accounts;
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Account WHERE Rating = 'Warm' AND Name LIKE 'Bulk Co %']);
    }
}
