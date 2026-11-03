@IsTest
private class SoftDrinkOrderValidationTest {

    private static final String RULE_MESSAGE =
        'This order cannot be saved: the Soft Drink is Expired, or the Quantity is more than the Soft Drink has left.';

    // Stock of 10, one order of 8 -> Quantity Left is 2
    private static Soft_Drink_Order__c createOrderOfEight() {
        Soft_Drink__c drink = TestDataFactory.createSoftDrink('Cola', 'Best', 10);
        return TestDataFactory.createSoftDrinkOrder(drink.Id, null, 1, 8);
    }

    private static void assertBlocked(Database.SaveResult result) {
        Assert.isFalse(result.isSuccess(), 'Expected the validation rule to block the save');
        Assert.areEqual(RULE_MESSAGE, result.getErrors()[0].getMessage());
    }

    @IsTest
    static void validationRule_insertWithExpiredDrink_isAllowed() {
        Soft_Drink__c drink = TestDataFactory.createSoftDrink('Old Cola', 'Low', 10);
        update new Soft_Drink__c(Id = drink.Id, Status__c = 'Expired');

        Soft_Drink_Order__c order = TestDataFactory.createSoftDrinkOrder(drink.Id, null, 1, 20);

        Assert.isNotNull(order.Id, 'The rule only fires on update, so creating the order must succeed');
    }

    @IsTest
    static void validationRule_updateStatusWithinStock_isAllowed() {
        Soft_Drink_Order__c order = createOrderOfEight();

        // Quantity (8) is more than Quantity Left (2), but the order's own 8 is already counted in Quantity Used
        Database.SaveResult result = Database.update(new Soft_Drink_Order__c(Id = order.Id, Status__c = 'Dispatched'), false);

        Assert.isTrue(result.isSuccess(), 'Unrelated updates must not be blocked by the order\'s own quantity');
    }

    @IsTest
    static void validationRule_updateQuantityUpToTotalStock_isAllowed() {
        Soft_Drink_Order__c order = createOrderOfEight();

        Database.SaveResult result = Database.update(new Soft_Drink_Order__c(Id = order.Id, Quantity__c = 10), false);

        Assert.isTrue(result.isSuccess(), 'Ordering exactly the whole stock is allowed');
    }

    @IsTest
    static void validationRule_updateQuantityAboveStock_isBlocked() {
        Soft_Drink_Order__c order = createOrderOfEight();

        assertBlocked(Database.update(new Soft_Drink_Order__c(Id = order.Id, Quantity__c = 11), false));
        Assert.areEqual(8, [SELECT Quantity__c FROM Soft_Drink_Order__c WHERE Id = :order.Id].Quantity__c);
    }

    @IsTest
    static void validationRule_updateWhenDrinkExpired_isBlocked() {
        Soft_Drink_Order__c order = createOrderOfEight();
        update new Soft_Drink__c(Id = [SELECT Soft_Drink__c FROM Soft_Drink_Order__c WHERE Id = :order.Id].Soft_Drink__c, Status__c = 'Expired');

        assertBlocked(Database.update(new Soft_Drink_Order__c(Id = order.Id, Status__c = 'Dispatched'), false));
    }
}
