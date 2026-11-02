@IsTest
public class TestDataFactory {

    public static Account createAccount(String name) {
        Account acc = new Account(Name = name);
        insert acc;
        return acc;
    }

    public static Soft_Drink__c createSoftDrink(String name, String rating) {
        Soft_Drink__c drink = new Soft_Drink__c(Name = name, Rating__c = rating);
        insert drink;
        return drink;
    }

    public static Soft_Drink_Order__c createSoftDrinkOrder(Id softDrinkId, Id accountId, Integer orderNumber, Integer quantity) {
        Soft_Drink_Order__c sdo = new Soft_Drink_Order__c(
            Soft_Drink__c = softDrinkId,
            Account__c = accountId,
            Order_Number__c = orderNumber,
            Quantity__c = quantity,
            Price__c = 5,
            Status__c = 'Open'
        );
        insert sdo;
        return sdo;
    }

    // Queue + Case support are setup objects; callers must not have non-setup DML pending (MIXED_DML_OPERATION)
    public static Group createCaseQueue(String developerName) {
        Group queue;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            queue = new Group(Name = developerName, DeveloperName = developerName, Type = 'Queue');
            insert queue;
            insert new QueueSobject(QueueId = queue.Id, SobjectType = 'Case');
        }
        return queue;
    }
}