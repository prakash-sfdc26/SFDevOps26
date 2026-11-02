public with sharing class CaseCopilot {

    @InvocableMethod(label='Create Case record'
                     description='Create Case record in System when user ask to create a Ticket for example user Might say create a ticket with priority high and subject as test Or Create a Case with Prority Low and Subject as XYZ and Description as XYZ')
    public static List<Output> createCase(List<Input> inputWrapper) {
        if (inputWrapper == null || inputWrapper.isEmpty()) {
            return new List<Output>();
        }

        // One query for the whole batch; all callouts must happen before any DML
        String email = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Email;

        List<Case> cases = new List<Case>();
        for (Input inp : inputWrapper) {
            cases.add(new Case(
                Subject = inp.Subject,
                Priority = inp.Priority,
                Description = inp.Description,
                AccountId = inp.AccountId,
                freshDeskId__c = TicketSystem.createTicket(inp.Subject, email, inp.Description, 1, 2)
            ));
        }
        insert cases;

        List<Output> outputs = new List<Output>();
        for (Case c : cases) {
            Output out = new Output();
            out.caseRec = c;
            outputs.add(out);
        }
        return outputs;
    }

    public class Input {
        @InvocableVariable(required=true description='Subject Given by User')
        public String Subject;
        @InvocableVariable(required=true description='Priority given by user if no Priority is given then the default value is Low')
        public String Priority;
        @InvocableVariable(required=true description='Description given by user if No Description is given use Subject as Description')
        public String Description;
        @InvocableVariable(required=true description='get the Account Id from the Account Name given by user before creating the Case')
        public String AccountId;
    }

    public class Output {
        @InvocableVariable(required=true description='Case Record Created in CRM to be displayed on the UI')
        public Case caseRec;
    }
}