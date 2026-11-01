public with sharing class SoftDrinkOrderController {

    @InvocableMethod(label='Create Soft Drink Order'
                     description='Create Soft Drink Order when User ask to create Soft Drink Order for example user Might say create a Soft Drink Order for the First Soft Drink Or create a Soft Drink Order for the Soft Drink Xyz')
    public static List<Soft_Drink_Order__c> createSoftDrinkOrder(List<Input> inputWrapper) {
        if (inputWrapper == null || inputWrapper.isEmpty()) {
            return new List<Soft_Drink_Order__c>();
        }

        List<Soft_Drink_Order__c> orders = new List<Soft_Drink_Order__c>();
        for (Input inp : inputWrapper) {
            orders.add(new Soft_Drink_Order__c(
                Soft_Drink__c = inp.softDrinkID,
                Quantity__c = inp.Quantity,
                Price__c = inp.price
            ));
        }
        insert orders;
        return orders;
    }

    public class Input {
        @InvocableVariable(required=true)
        public String softDrinkID;
        @InvocableVariable(required=true)
        public Integer Quantity;
        @InvocableVariable(required=true)
        public Double price;
    }
}