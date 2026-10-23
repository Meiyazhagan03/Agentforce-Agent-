public with sharing class RecordCancellationRequestAction {
    public class Request {
        @InvocableVariable(label='Subscription Id' description='The subscriptionId from Get Customer Subscription. Required.' required=true)
        public String subscriptionId;
        @InvocableVariable(label='Reason' description='Why the customer is leaving. Exactly one of: Too expensive, Not using enough, Missing features, Switching to competitor, Business closing, Other.' required=true)
        public String reason;
        @InvocableVariable(label='Customer Message' description='The customer\'s own words.')
        public String customerMessage;
        @InvocableVariable(label='Customer Confirmed' description='Set true ONLY if the customer has just explicitly confirmed they want to proceed with the cancellation request. Otherwise false. Required.' required=true)
        public Boolean customerConfirmed;
    }

    public class Response {
        @InvocableVariable(label='Success' description='True if the request was recorded.')
        public Boolean success;
        @InvocableVariable(label='Message' description='Result. Remember: nothing is cancelled yet; a team member will complete it.')
        public String message;
    }

    @InvocableMethod(label='Record Cancellation Request' description='Record that the customer wants to cancel so a team member can process it. This does NOT cancel anything. Only call after the customer explicitly confirms.')
    public static List<Response> run(List<Request> requests) {
        List<Response> out = new List<Response>();
        for (Request req : requests) {
            out.add(record(req));
        }
        return out;
    }

    private static Response record(Request req) {
        Response r = new Response();
        r.success = false;
        if (req.customerConfirmed != true) {
            r.message = 'The customer has not confirmed. Nothing was recorded.';
            return r;
        }
        Subscription__c sub = RetentionPolicyService.getSubscription(RetentionPolicyService.toId(req.subscriptionId));
        if (sub == null) {
            r.message = 'The subscription could not be found. Nothing was recorded.';
            return r;
        }
        if (sub.Status__c == 'Cancel Requested') {
            r.success = true;
            r.message = 'A cancellation request is already recorded. A team member will follow up.';
            return r;
        }
        if (sub.Status__c == 'Cancelled') {
            r.message = 'This subscription is already cancelled.';
            return r;
        }
        update as user new Subscription__c(Id = sub.Id, Status__c = 'Cancel Requested');

        List<Retention_Offer__c> open = [
            SELECT Id FROM Retention_Offer__c WHERE Subscription__c = :sub.Id AND Status__c = 'Proposed' WITH USER_MODE
        ];
        for (Retention_Offer__c o : open) {
            o.Status__c = 'Declined';
        }
        if (!open.isEmpty()) {
            update as user open;
        }
        insert as user new Task(
            Subject = 'Process cancellation request: ' + sub.Account__r.Name,
            Description = 'Customer ' + sub.Contact__r.Name + ' confirmed they want to cancel. Reason: ' +
                RetentionPolicyService.normalizeReason(req.reason) + '.\nCustomer said: ' + (req.customerMessage ?? '') +
                '\nRenewal date: ' + sub.Renewal_Date__c,
            WhoId = sub.Contact__c,
            WhatId = sub.Account__c,
            ActivityDate = Date.today().addDays(1),
            Status = 'Not Started',
            Priority = 'High'
        );
        r.success = true;
        r.message = 'Cancellation request recorded. Nothing is cancelled yet; a team member will complete it.';
        return r;
    }
}
