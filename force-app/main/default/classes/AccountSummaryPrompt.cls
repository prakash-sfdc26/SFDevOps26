public with sharing class AccountSummaryPrompt {
    //CapabilityType='PromptTemplateType://einstein_gpt__fieldCompletion'
    @InvocableMethod(label='Soft Drink Orders'
                     description='Find Soft Drink for Account'
                     CapabilityType='PromptTemplateType://einstein_gpt__recordSummary')
    public static List<Response> getSoftDrinkData(List<Request> requests) {
        // Validate the expected number of requests as an input
        if (requests == null || requests.size() != 1) {
            throw new ListException('The requests list must contain one entry only');
        }
        Id accountId = requests[0].objectToSummarize.Id;

        List<String> lines = new List<String>();

        List<Soft_Drink_Order__c> softDrinkOrders = [
            SELECT Soft_Drink__r.Name, Quantity__c FROM Soft_Drink_Order__c WHERE Account__c = :accountId
        ];
        if (softDrinkOrders.isEmpty()) {
            lines.add('There are no Soft Drink records.');
        }
        for (Soft_Drink_Order__c drink : softDrinkOrders) {
            lines.add(String.format('Soft Drink Details: {0}, {1}.',
                                    new List<Object>{ drink.Soft_Drink__r.Name, drink.Quantity__c }));
        }

        List<Case> cases = [SELECT Reason, Subject, Description FROM Case WHERE AccountId = :accountId];
        if (cases.isEmpty()) {
            lines.add('There are no Cases Records.');
        }
        for (Case ca : cases) {
            lines.add(String.format('Case Details:- Subject , Reason , Description of the Case are as below: {0}, {1}, {2}.',
                                    new List<Object>{ ca.Subject, ca.Reason, ca.Description }));
        }

        Response res = new Response();
        res.Prompt = String.join(lines, '\n');
        return new List<Response>{ res };
    }

    public class Request {
        @InvocableVariable(required=true)
        public Account objectToSummarize;
    }

    public class Response {
        @InvocableVariable
        public String Prompt;
    }
}