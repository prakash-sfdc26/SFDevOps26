@IsTest
private class TicketSystemTest {

    private class Mock implements HttpCalloutMock {
        Integer statusCode;
        String body;
        String exceptionMessage;

        Mock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }

        Mock(String exceptionMessage) {
            this.exceptionMessage = exceptionMessage;
        }

        public HttpResponse respond(HttpRequest req) {
            if (exceptionMessage != null) {
                throw new CalloutException(exceptionMessage);
            }
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }

    @IsTest
    static void createTicket_status201_returnsExternalId() {
        Test.setMock(HttpCalloutMock.class, new Mock(201, '{"id": 4242}'));
        Test.startTest();
        // Quotes in the input must not break the request
        String id = TicketSystem.createTicket('Say "hi"', 'a@b.com', 'line1\nline2', 1, 2);
        Test.stopTest();
        System.assertEquals('4242', id);
    }

    @IsTest
    static void createTicket_unexpectedStatus_returnsEmptyString() {
        Test.setMock(HttpCalloutMock.class, new Mock(500, '{"error":"boom"}'));
        Test.startTest();
        String id = TicketSystem.createTicket('s', 'a@b.com', 'd', 1, 2);
        Test.stopTest();
        System.assertEquals('', id);
    }

    @IsTest
    static void createTicket_calloutException_returnsEmptyString() {
        Test.setMock(HttpCalloutMock.class, new Mock('Unauthorized endpoint'));
        Test.startTest();
        String id = TicketSystem.createTicket('s', 'a@b.com', 'd', 1, 2);
        Test.stopTest();
        System.assertEquals('', id);
    }
}