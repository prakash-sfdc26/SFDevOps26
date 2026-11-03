@IsTest
private class AccountListControllerTest {

    private static final Integer ACCOUNT_COUNT = 7;

    @TestSetup
    static void setup() {
        // One list insert (not one DML per record). Six Accounts have revenue 1M-6M, the seventh has none
        List<String> ratings = new List<String>{ 'Hot', 'Warm', 'Cold' };
        List<Account> accounts = new List<Account>();
        for (Integer i = 1; i <= ACCOUNT_COUNT; i++) {
            accounts.add(new Account(
                Name = 'Card Account ' + i,
                Industry = 'Technology',
                Phone = '(415) 555-000' + i,
                Rating = ratings[Math.mod(i, ratings.size())],
                AnnualRevenue = i < ACCOUNT_COUNT ? i * 1000000 : null
            ));
        }
        insert accounts;
    }

    @IsTest
    static void getAccounts_default_returnsFiveWithTotalSeven() {
        AccountListController.AccountListResult result = AccountListController.getAccounts(5);

        Assert.areEqual(5, result.accounts.size(), 'Five cards should be returned');
        Assert.areEqual(ACCOUNT_COUNT, result.totalCount, 'Total counts every Account, not just the ones shown');
    }

    @IsTest
    static void getAccounts_belowMinimum_clampsToTwo() {
        Assert.areEqual(2, AccountListController.getAccounts(0).accounts.size());
        Assert.areEqual(2, AccountListController.getAccounts(-3).accounts.size());
    }

    @IsTest
    static void getAccounts_aboveMaximum_clampsToFive() {
        AccountListController.AccountListResult result = AccountListController.getAccounts(99);

        Assert.areEqual(5, result.accounts.size());
        Assert.areEqual(ACCOUNT_COUNT, result.totalCount);
    }

    @IsTest
    static void getAccounts_nullMaxRows_usesDefaultOfFive() {
        Assert.areEqual(5, AccountListController.getAccounts(null).accounts.size());
    }

    @IsTest
    static void getAccounts_withinRange_returnsRequestedNumber() {
        Assert.areEqual(3, AccountListController.getAccounts(3).accounts.size());
    }

    @IsTest
    static void getAccounts_default_ordersByRevenueDescending() {
        List<Account> accounts = AccountListController.getAccounts(5).accounts;

        Assert.areEqual(6000000, accounts[0].AnnualRevenue.intValue(), 'Highest revenue comes first');
        for (Integer i = 1; i < accounts.size(); i++) {
            Assert.isTrue(accounts[i - 1].AnnualRevenue >= accounts[i].AnnualRevenue, 'Revenue must not increase down the list');
        }
    }

    @IsTest
    static void getAccounts_userWithoutAccountAccess_throwsAuraException() {
        Profile noAccess = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        User restricted = new User(
            Alias = 'nolist',
            Email = 'nolist@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'NoAccess',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = noAccess.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'nolist' + System.currentTimeMillis() + '@example.com'
        );
        insert restricted;

        System.runAs(restricted) {
            try {
                AccountListController.getAccounts(5);
                Assert.fail('Expected AuraHandledException');
            } catch (AuraHandledException e) {
                Assert.isFalse(String.isBlank(e.getMessage()), 'The LWC needs a readable message');
            }
        }
    }
}
