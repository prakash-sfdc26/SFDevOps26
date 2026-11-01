@IsTest
private class AccountTriggerTest {

    @IsTest
    static void firesOnInsertAndUpdate() {
        Account acc = TestDataFactory.createAccount('Trigger Co');
        acc.Rating = 'Hot';
        update acc;
        System.assertEquals('Hot', [SELECT Rating FROM Account WHERE Id = :acc.Id].Rating);
    }
}