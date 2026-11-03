public with sharing class AccountListController {

    // The card list only ever shows 2-5 Accounts, whatever the caller asks for
    private static final Integer MIN_ROWS = 2;
    private static final Integer MAX_ROWS = 5;

    public class AccountListResult {
        @AuraEnabled public List<Account> accounts;
        @AuraEnabled public Integer totalCount;
    }

    // cacheable=true lets the LWC call this through @wire; it is allowed because the method only reads data
    @AuraEnabled(cacheable=true)
    public static AccountListResult getAccounts(Integer maxRows) {
        Integer rowLimit = clampRows(maxRows);
        AccountListResult result = new AccountListResult();

        try {
            // Full-table count is intentional: the UI shows "N of total". COUNT() returns one number, not rows,
            // so it cannot hit the 50,000 row limit the way loading every Account into a list would
            result.totalCount = [SELECT COUNT() FROM Account WITH USER_MODE];
            result.accounts = [SELECT Id, Name, Industry, Phone, AnnualRevenue, Rating
                               FROM Account
                               WITH USER_MODE
                               ORDER BY AnnualRevenue DESC NULLS LAST, Name
                               LIMIT :rowLimit];
        } catch (SecurityException e) {
            // USER_MODE throws SecurityException when the user has no read access to the Account object
            throw auraError(e.getMessage());
        } catch (QueryException e) {
            // ...and QueryException when the user lacks read access to one of the queried fields
            throw auraError(e.getMessage());
        }
        return result;
    }

    private static Integer clampRows(Integer requested) {
        if (requested == null) {
            return MAX_ROWS;
        }
        return Math.min(MAX_ROWS, Math.max(MIN_ROWS, requested));
    }

    // setMessage is required, otherwise the LWC (and getMessage()) only sees "Script-thrown exception"
    private static AuraHandledException auraError(String message) {
        AuraHandledException ahe = new AuraHandledException(message);
        ahe.setMessage(message);
        return ahe;
    }
}
