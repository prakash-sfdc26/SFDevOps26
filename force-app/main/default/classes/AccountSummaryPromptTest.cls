@IsTest
private class AccountSummaryPromptTest {

    private static List<AccountSummaryPrompt.Request> request(Account acc) {
        AccountSummaryPrompt.Request req = new AccountSummaryPrompt.Request();
        req.objectToSummarize = acc;
        return new List<AccountSummaryPrompt.Request>{ req };
    }

    @IsTest
    static void summarisesOrdersAndCases() {
        Account acc = TestDataFactory.createAccount('Acme');
        Soft_Drink__c drink = TestDataFactory.createSoftDrink('Cola', 'Best');
        TestDataFactory.createSoftDrinkOrder(drink.Id, acc.Id, 1, 12);
        insert new Case(AccountId = acc.Id, Subject = 'Leaky can', Reason = 'Other', Description = 'It leaks');

        List<AccountSummaryPrompt.Response> result = AccountSummaryPrompt.getSoftDrinkData(request(acc));

        System.assertEquals(1, result.size());
        List<String> lines = result[0].Prompt.split('\n');
        System.assertEquals(2, lines.size());
        System.assertEquals('Soft Drink Details: Cola, 12.', lines[0]);
        System.assert(lines[1].contains('Leaky can, Other, It leaks'));
    }

    @IsTest
    static void reportsWhenNoOrdersOrCases() {
        Account acc = TestDataFactory.createAccount('Empty');
        String prompt = AccountSummaryPrompt.getSoftDrinkData(request(acc))[0].Prompt;
        System.assertEquals('There are no Soft Drink records.\nThere are no Cases Records.', prompt);
    }

    @IsTest
    static void rejectsAnythingButOneRequest() {
        for (List<AccountSummaryPrompt.Request> bad : new List<List<AccountSummaryPrompt.Request>>{
            null, new List<AccountSummaryPrompt.Request>()
        }) {
            try {
                AccountSummaryPrompt.getSoftDrinkData(bad);
                System.assert(false, 'Expected ListException');
            } catch (ListException e) {
                System.assertEquals('The requests list must contain one entry only', e.getMessage());
            }
        }
    }
}