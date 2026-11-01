public with sharing class CaseUpdatesDataCloud {

    @InvocableMethod(
        label='Get Queue ID and Assign Case'
        description='Returns the ID of a Queue/Group when given its developer name is given and assigns a Case to that queue'
    )
    public static List<OutputWrapper> getQueueIdAndAssignCase(List<InputWrapper> requests) {
        if (requests == null || requests.isEmpty()) {
            return new List<OutputWrapper>();
        }

        // Queue lookup and Case assignment live in CaseUpdates; this action only adds Priority
        List<CaseUpdates.AssignmentRequest> items = new List<CaseUpdates.AssignmentRequest>();
        for (InputWrapper req : requests) {
            items.add(new CaseUpdates.AssignmentRequest(req.queueDeveloperName, req.caseId, req.priority));
        }

        List<OutputWrapper> results = new List<OutputWrapper>();
        for (CaseUpdates.OutputWrapper shared : CaseUpdates.assign(items)) {
            OutputWrapper output = new OutputWrapper();
            output.queueId = shared.queueId;
            output.success = shared.success;
            output.message = shared.message;
            results.add(output);
        }
        return results;
    }

    /**
     * @description Input wrapper class for the invocable method
     */
    public class InputWrapper {
        @InvocableVariable(label='Queue Developer Name' description='The developer name of the queue' required=true)
        public String queueDeveloperName;

        @InvocableVariable(label='Case ID' description='The ID of the Case to assign to the queue' required=true)
        public String caseId;

        @InvocableVariable(label='Priority' description='The priority of the Case' required=true)
        public String priority;
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