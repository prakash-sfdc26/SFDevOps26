public with sharing class CaseUpdates {

    @InvocableMethod(
        label='Get Queue ID and Assign Case'
        description='Returns the ID of a Queue/Group when given its developer name is given and assigns a Case to that queue'
    )
    public static List<OutputWrapper> getQueueIdAndAssignCase(List<InputWrapper> requests) {
        if (requests == null || requests.isEmpty()) {
            return new List<OutputWrapper>();
        }

        List<AssignmentRequest> items = new List<AssignmentRequest>();
        for (InputWrapper req : requests) {
            items.add(new AssignmentRequest(req.queueDeveloperName, req.caseId));
        }
        return assign(items);
    }

    /**
     * @description Shared, bulk-safe implementation: one Queue query and one Case DML for the whole batch.
     * Results are returned in the same order as the requests.
     */
    public static List<OutputWrapper> assign(List<AssignmentRequest> items) {
        Set<String> queueNames = new Set<String>();
        for (AssignmentRequest item : items) {
            if (String.isNotBlank(item.queueDeveloperName)) {
                queueNames.add(item.queueDeveloperName.toLowerCase());
            }
        }

        Map<String, Id> queueIdByName = new Map<String, Id>();
        if (!queueNames.isEmpty()) {
            for (Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :queueNames]) {
                queueIdByName.put(g.DeveloperName.toLowerCase(), g.Id);
            }
        }

        List<OutputWrapper> results = new List<OutputWrapper>();
        List<Case> casesToUpdate = new List<Case>();
        List<Integer> resultIndexForCase = new List<Integer>();

        for (AssignmentRequest item : items) {
            OutputWrapper output = new OutputWrapper();
            results.add(output);

            if (String.isBlank(item.queueDeveloperName)) {
                output.message = 'No queue developer name provided';
                continue;
            }
            Id queueId = queueIdByName.get(item.queueDeveloperName.toLowerCase());
            if (queueId == null) {
                output.message = 'Error: Queue with developer name "' + item.queueDeveloperName + '" not found';
                continue;
            }

            output.queueId = queueId;
            output.success = true;
            output.message = 'Queue found: ' + item.queueDeveloperName;

            if (String.isBlank(item.caseId)) {
                continue;
            }
            try {
                Case c = new Case(Id = Id.valueOf(item.caseId), OwnerId = queueId);
                if (item.updatePriority) {
                    c.Priority = item.priority;
                }
                casesToUpdate.add(c);
                resultIndexForCase.add(results.size() - 1);
            } catch (Exception e) {
                output.message = 'Queue found but error updating Case: ' + e.getMessage();
                output.success = false;
            }
        }

        if (!casesToUpdate.isEmpty()) {
            // Partial success so one bad Case does not fail the rest of the batch
            List<Database.SaveResult> saveResults = Database.update(casesToUpdate, false);
            for (Integer i = 0; i < saveResults.size(); i++) {
                OutputWrapper output = results[resultIndexForCase[i]];
                if (saveResults[i].isSuccess()) {
                    output.message = 'Success: Case assigned to queue ' + items[resultIndexForCase[i]].queueDeveloperName;
                } else {
                    output.message = 'Queue found but error updating Case: ' + saveResults[i].getErrors()[0].getMessage();
                    output.success = false;
                }
            }
        }
        return results;
    }

    /**
     * @description Internal request used by the shared implementation
     */
    public class AssignmentRequest {
        public String queueDeveloperName;
        public String caseId;
        public String priority;
        public Boolean updatePriority = false;

        public AssignmentRequest(String queueDeveloperName, String caseId) {
            this.queueDeveloperName = queueDeveloperName;
            this.caseId = caseId;
        }

        public AssignmentRequest(String queueDeveloperName, String caseId, String priority) {
            this(queueDeveloperName, caseId);
            this.priority = priority;
            this.updatePriority = true;
        }
    }

    /**
     * @description Input wrapper class for the invocable method
     */
    public class InputWrapper {
        @InvocableVariable(label='Queue Developer Name' description='The developer name of the queue' required=true)
        public String queueDeveloperName;

        @InvocableVariable(label='Case ID' description='The ID of the Case to assign to the queue' required=true)
        public String caseId;
    }

    /**
     * @description Output wrapper class for the invocable method
     */
    public class OutputWrapper {
        @InvocableVariable(label='Queue ID' description='The ID of the found queue')
        public Id queueId;

        @InvocableVariable(label='Success' description='Whether the operation was successful')
        public Boolean success = false;

        @InvocableVariable(label='Message' description='Success or error message')
        public String message;
    }
}