public with sharing class FlexTemplateController {

    private static final String PROMPT_TEMPLATE = 'Customer_Pitch';

    @AuraEnabled
    public static String getFlexTemplateResponse(String accountName, String rating) {
        if (String.isBlank(accountName) || String.isBlank(rating)) {
            throw auraError('Enter an Account name and select a Rating.');
        }

        List<Account> accounts = [SELECT Id FROM Account WHERE Name LIKE :accountName WITH USER_MODE LIMIT 1];
        List<Product2> products = [SELECT Id FROM Product2 WHERE Rating__c = :rating WITH USER_MODE LIMIT 2];
        List<Soft_Drink__c> softDrinks = [SELECT Id FROM Soft_Drink__c WHERE Rating__c = :rating WITH USER_MODE LIMIT 2];

        // The template needs one Account plus two Products and two Soft Drinks
        if (accounts.isEmpty() || products.size() < 2 || softDrinks.size() < 2) {
            throw auraError(
                'Could not find an Account matching "' + accountName + '" and at least two Products and two Soft Drinks rated "' + rating + '".'
            );
        }

        Map<String, ConnectApi.WrappedValue> valueMap = new Map<String, ConnectApi.WrappedValue>{
            'Input:Account' => wrapRecordId(accounts[0].Id),
            'Input:Product' => wrapRecordId(products[0].Id),
            'Input:Product_2' => wrapRecordId(products[1].Id),
            'Input:Soft_Drink' => wrapRecordId(softDrinks[0].Id),
            'Input:Soft_Drink2' => wrapRecordId(softDrinks[1].Id)
        };

        ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
        executeTemplateInput.isPreview = false;
        executeTemplateInput.inputParams = valueMap;

        try {
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(PROMPT_TEMPLATE, executeTemplateInput);
            return generationsOutput.generations[0].text;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Prompt template call failed: ' + e.getMessage());
            throw auraError(e.getMessage());
        }
    }

    // setMessage is required, otherwise the LWC (and getMessage()) only sees "Script-thrown exception"
    private static AuraHandledException auraError(String message) {
        AuraHandledException ahe = new AuraHandledException(message);
        ahe.setMessage(message);
        return ahe;
    }

    private static ConnectApi.WrappedValue wrapRecordId(Id recordId) {
        ConnectApi.WrappedValue wrapped = new ConnectApi.WrappedValue();
        wrapped.value = new Map<String, String>{ 'id' => recordId };
        return wrapped;
    }
}