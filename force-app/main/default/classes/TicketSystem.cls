public with sharing class TicketSystem {

    private static final String ENDPOINT = 'callout:freshDesk';
    private static final Integer HTTP_CREATED = 201;

    /**
     * @description Creates a ticket in the external ticketing system.
     * @return The external ticket id, or an empty string when the ticket could not be created.
     */
    public static String createTicket(String sub, String email, String description, Integer priority, Integer status) {
        // Serialize instead of concatenating so quotes/newlines in user input cannot break the JSON
        String requestBody = JSON.serialize(new Map<String, Object>{
            'description' => description,
            'subject' => sub,
            'email' => email,
            'priority' => priority,
            'status' => status
        });

        HttpRequest httpReq = new HttpRequest();
        httpReq.setMethod('POST');
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setEndpoint(ENDPOINT);
        httpReq.setBody(requestBody);

        try {
            HttpResponse response = new Http().send(httpReq);
            if (response.getStatusCode() == HTTP_CREATED) {
                Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                return String.valueOf(result.get('id'));
            }
            System.debug(LoggingLevel.ERROR, 'Unexpected response from ticket API. Status ' + response.getStatus()
                + ', status code ' + response.getStatusCode() + ', body ' + response.getBody());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Ticket API callout failed: ' + e.getMessage());
        }
        return '';
    }
}