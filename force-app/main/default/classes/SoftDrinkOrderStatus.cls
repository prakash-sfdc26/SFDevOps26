// without sharing so a user can look up the status of an order by number even without record access
public without sharing class SoftDrinkOrderStatus {

    // Invocable batches are far smaller than this; it only guards the 50,000 row governor limit
    private static final Integer MAX_ROWS = 2000;

    @InvocableMethod(label='Order Status'
                     description='Return Status of the Soft Drink Order , when user ask for it, for example user can say what is the status of My Soft Drink order ABC')
    public static List<String> getStatus(List<Integer> orderNumber) {
        if (orderNumber == null || orderNumber.isEmpty()) {
            return new List<String>();
        }

        // Sharing is intentionally bypassed (see header), so USER_MODE is not applied to this lookup
        Map<Decimal, String> statusByOrderNumber = new Map<Decimal, String>();
        for (Soft_Drink_Order__c sdo : [SELECT Order_Number__c, Status__c FROM Soft_Drink_Order__c
                                        WHERE Order_Number__c IN :orderNumber LIMIT :MAX_ROWS]) {
            statusByOrderNumber.put(sdo.Order_Number__c, sdo.Status__c);
        }

        // One result per input, in order; unknown orders no longer throw a QueryException
        List<String> statuses = new List<String>();
        for (Integer num : orderNumber) {
            statuses.add(statusByOrderNumber.containsKey(num) ? statusByOrderNumber.get(num) : 'Order not found');
        }
        return statuses;
    }
}