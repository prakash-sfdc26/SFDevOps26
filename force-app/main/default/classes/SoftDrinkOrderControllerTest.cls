@IsTest
private class SoftDrinkOrderControllerTest {

    @IsTest
    static void createSoftDrinkOrder_multipleInputs_insertsAllOrders() {
        Soft_Drink__c drink = TestDataFactory.createSoftDrink('Cola', 'Best');

        List<SoftDrinkOrderController.Input> inputs = new List<SoftDrinkOrderController.Input>();
        for (Integer i = 1; i <= 2; i++) {
            SoftDrinkOrderController.Input inp = new SoftDrinkOrderController.Input();
            inp.softDrinkID = drink.Id;
            inp.Quantity = i * 10;
            inp.price = 3;
            inputs.add(inp);
        }

        Test.startTest();
        List<Soft_Drink_Order__c> result = SoftDrinkOrderController.createSoftDrinkOrder(inputs);
        Test.stopTest();

        System.assertEquals(2, result.size());
        System.assertNotEquals(null, result[0].Id);
        List<Soft_Drink_Order__c> saved = [SELECT Quantity__c, Price__c FROM Soft_Drink_Order__c ORDER BY Quantity__c];
        System.assertEquals(2, saved.size());
        System.assertEquals(10, saved[0].Quantity__c);
        System.assertEquals(3, saved[0].Price__c);
    }

    @IsTest
    static void createSoftDrinkOrder_emptyInput_returnsEmptyList() {
        System.assertEquals(0, SoftDrinkOrderController.createSoftDrinkOrder(null).size());
        System.assertEquals(0, SoftDrinkOrderController.createSoftDrinkOrder(new List<SoftDrinkOrderController.Input>()).size());
    }
}