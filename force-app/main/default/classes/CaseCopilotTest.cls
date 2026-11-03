@IsTest
private class CaseCopilotTest {

    private class TicketMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(201);
            res.setBody('{"id": 777}');
            return res;
        }
    }

    private static CaseCopilot.Input buildInput(String subject, Id accountId) {
        CaseCopilot.Input inp = new CaseCopilot.Input();
        inp.Subject = subject;
        inp.Priority = 'High';
        inp.Description = 'Desc ' + subject;
        inp.AccountId = accountId;
        return inp;
    }

    @IsTest
    static void createCase_validInput_insertsCasesWithExternalId() {
        Account acc = TestDataFactory.createAccount('Acme');
        Test.setMock(HttpCalloutMock.class, new TicketMock());

        Test.startTest();
        List<CaseCopilot.Output> outputs = CaseCopilot.createCase(new List<CaseCopilot.Input>{
            buildInput('First', acc.Id), buildInput('Second', acc.Id)
        });
        Test.stopTest();

        System.assertEquals(2, outputs.size());
        System.assertEquals('First', outputs[0].caseRec.Subject);
        List<Case> saved = [SELECT Subject, Priority, AccountId, freshDeskId__c FROM Case ORDER BY Subject];
        System.assertEquals(2, saved.size());
        for (Case c : saved) {
            System.assertEquals('777', c.freshDeskId__c);
            System.assertEquals('High', c.Priority);
            System.assertEquals(acc.Id, c.AccountId);
        }
    }

    @IsTest
    static void createCase_emptyInput_returnsEmptyList() {
        System.assertEquals(0, CaseCopilot.createCase(new List<CaseCopilot.Input>()).size());
        System.assertEquals(0, CaseCopilot.createCase(null).size());
    }
}