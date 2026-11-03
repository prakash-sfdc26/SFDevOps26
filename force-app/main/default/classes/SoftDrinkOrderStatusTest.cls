@IsTest
private class SoftDrinkOrderStatusTest {

    @IsTest
    static void getStatus_multipleOrderNumbers_returnsStatusPerInputInOrder() {
        Soft_Drink__c drink = TestDataFactory.createSoftDrink('Cola', 'Best');
        TestDataFactory.createSoftDrinkOrder(drink.Id, null, 1001, 5);
        Soft_Drink_Order__c second = TestDataFactory.createSoftDrinkOrder(drink.Id, null, 1002, 5);
        // Update only the status; master-detail Soft_Drink__c is not re-parentable
        update new Soft_Drink_Order__c(Id = second.Id, Status__c = 'Dispatched');

        Test.startTest();
        List<String> result = SoftDrinkOrderStatus.getStatus(new List<Integer>{ 1002, 1001, 9999 });
        Test.stopTest();

        System.assertEquals(new List<String>{ 'Dispatched', 'Open', 'Order not found' }, result);
    }

    @IsTest
    static void getStatus_emptyInput_returnsEmptyList() {
        System.assertEquals(0, SoftDrinkOrderStatus.getStatus(null).size());
        System.assertEquals(0, SoftDrinkOrderStatus.getStatus(new List<Integer>()).size());
    }
}