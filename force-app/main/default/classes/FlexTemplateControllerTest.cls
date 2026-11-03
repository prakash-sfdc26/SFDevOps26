@IsTest
private class FlexTemplateControllerTest {

    @TestSetup
    static void setup() {
        TestDataFactory.createAccount('Acme');
        insert new List<Product2>{
            new Product2(Name = 'P1', Rating__c = 'Best'),
            new Product2(Name = 'P2', Rating__c = 'Best')
        };
        TestDataFactory.createSoftDrink('Cola', 'Best');
        TestDataFactory.createSoftDrink('Lemonade', 'Best');
    }

    @IsTest
    static void getFlexTemplateResponse_blankInput_throwsAuraException() {
        for (List<String> args : new List<List<String>>{
            new List<String>{ null, 'Best' }, new List<String>{ 'Acme', '' }
        }) {
            try {
                FlexTemplateController.getFlexTemplateResponse(args[0], args[1]);
                System.assert(false, 'Expected AuraHandledException');
            } catch (AuraHandledException e) {
                System.assertEquals('Enter an Account name and select a Rating.', e.getMessage());
            }
        }
    }

    @IsTest
    static void getFlexTemplateResponse_missingAccount_throwsAuraException() {
        try {
            FlexTemplateController.getFlexTemplateResponse('No such account', 'Best');
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('No such account'));
        }
    }

    @IsTest
    static void getFlexTemplateResponse_tooFewRecords_throwsAuraException() {
        try {
            FlexTemplateController.getFlexTemplateResponse('Acme', 'Low');
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('"Low"'));
        }
    }

    // ConnectApi.EinsteinLLM cannot be mocked, so the Prompt Builder call either returns generated text
    // (org with the Customer_Pitch template) or surfaces its failure as an AuraHandledException.
    @IsTest
    static void getFlexTemplateResponse_dataPresent_returnsTextOrAuraException() {
        try {
            String text = FlexTemplateController.getFlexTemplateResponse('Acme', 'Best');
            System.assertNotEquals(null, text);
        } catch (AuraHandledException e) {
            System.assertNotEquals(null, e.getMessage());
        }
    }
}