public with sharing class ApplyRetentionOfferAction {
    public class Request {
        @InvocableVariable(label='Subscription Id' description='The subscriptionId from Get Customer Subscription. Required.' required=true)
        public String subscriptionId;
        @InvocableVariable(label='Retention Offer Id' description='The retentionOfferId from Get Retention Options. Required.' required=true)
        public String retentionOfferId;
        @InvocableVariable(label='Customer Confirmed' description='Set true ONLY if the customer has just clearly said yes to this exact offer. Otherwise false. Required.' required=true)
        public Boolean customerConfirmed;
    }

    public class Response {
        @InvocableVariable(label='Success' description='True if the offer was applied.')
        public Boolean success;
        @InvocableVariable(label='Message' description='What happened. If success is false, explain briefly and do not retry.')
        public String message;
        @InvocableVariable(label='New Plan Name' description='Plan after the change.')
        public String newPlanName;
        @InvocableVariable(label='New Monthly Price' description='Monthly price after the change, in dollars.')
        public Decimal newMonthlyPrice;
        @InvocableVariable(label='Confirmation Text' description='Repeat this to the customer to confirm the change.')
        public String confirmationText;
    }

    @InvocableMethod(label='Apply Retention Offer' description='Apply the retention offer the customer accepted. Only call after the customer clearly said yes, with customerConfirmed=true.')
    public static List<Response> run(List<Request> requests) {
        List<Response> out = new List<Response>();
        for (Request req : requests) {
            out.add(apply(req));
        }
        return out;
    }

    private static Response fail(String msg) {
        Response r = new Response();
        r.success = false;
        r.message = msg;
        return r;
    }

    private static Response apply(Request req) {
        if (req.customerConfirmed != true) {
            return fail('The customer has not confirmed. Nothing was changed.');
        }
        Subscription__c sub = RetentionPolicyService.getSubscription(RetentionPolicyService.toId(req.subscriptionId));
        Id offerId = RetentionPolicyService.toId(req.retentionOfferId);
        if (sub == null || offerId == null) {
            return fail('The subscription or offer could not be found. Nothing was changed.');
        }
        List<Retention_Offer__c> offers = [
            SELECT Id, Subscription__c, Reason__c, Offer_Type__c, Proposed_Plan__c, Discount_Percent__c, Discount_Months__c, Status__c
            FROM Retention_Offer__c
            WHERE Id = :offerId
            WITH USER_MODE
            LIMIT 1
        ];
        if (offers.isEmpty() || offers[0].Subscription__c != sub.Id) {
            return fail('That offer does not belong to this subscription. Nothing was changed.');
        }
        Retention_Offer__c offer = offers[0];
        if (offer.Status__c != 'Proposed' || (offer.Offer_Type__c != 'Downgrade' && offer.Offer_Type__c != 'Discount')) {
            return fail('That offer is not available to apply. Nothing was changed.');
        }

        // Re-run policy server-side; the stored offer must match what policy says now.
        RetentionPolicyResult p = RetentionPolicyService.evaluate(sub, RetentionPolicyService.getUtilization(sub), offer.Reason__c);
        Retention_Policy__mdt policy = RetentionPolicyService.getPolicy();
        Boolean matches = p.offerType == offer.Offer_Type__c && !p.requiresEscalation;
        if (matches && p.offerType == 'Downgrade') {
            matches = p.proposedPlanId == offer.Proposed_Plan__c;
        }
        if (matches && p.offerType == 'Discount') {
            matches = p.discountPercent == offer.Discount_Percent__c && p.discountMonths == offer.Discount_Months__c &&
                p.discountPercent <= policy.Max_Discount_Percent__c && p.discountMonths <= policy.Max_Discount_Months__c;
        }
        if (!matches) {
            return fail('This offer no longer matches company policy. Nothing was changed; a specialist can help.');
        }

        Response r = new Response();
        if (p.offerType == 'Downgrade') {
            sub.Plan__c = p.proposedPlanId;
            sub.Monthly_Price__c = p.newMonthlyPrice;
            sub.Discount_Percent__c = null;
            sub.Discount_End_Date__c = null;
            r.newPlanName = p.proposedPlanName;
            r.confirmationText = 'Done! You are now on ' + p.proposedPlanName + ' at $' + p.newMonthlyPrice + '/month, saving $' + p.monthlySavings + '/month.';
        } else {
            sub.Monthly_Price__c = p.newMonthlyPrice;
            sub.Discount_Percent__c = p.discountPercent;
            sub.Discount_End_Date__c = Date.today().addMonths(p.discountMonths);
            sub.Last_Discount_Date__c = Date.today();
            r.newPlanName = sub.Plan__r?.Name;
            r.confirmationText = 'Done! Your price is now $' + p.newMonthlyPrice + '/month for ' + p.discountMonths + ' months, saving $' + p.monthlySavings + '/month.';
        }
        sub.Status__c = 'Retained';
        Subscription__c toUpdate = new Subscription__c(
            Id = sub.Id, Plan__c = sub.Plan__c, Monthly_Price__c = sub.Monthly_Price__c,
            Discount_Percent__c = sub.Discount_Percent__c, Discount_End_Date__c = sub.Discount_End_Date__c,
            Last_Discount_Date__c = sub.Last_Discount_Date__c, Status__c = 'Retained'
        );
        update as user toUpdate;
        // Best effort: the Einstein Agent license cannot create Tasks, so a failure must not undo the change.
        String offerNote = null;
        try {
            insert new Task(
                Subject = 'Retention offer accepted: send confirmation',
                Description = r.confirmationText,
                WhoId = sub.Contact__c,
                WhatId = sub.Account__c,
                ActivityDate = Date.today().addDays(1),
                Status = 'Not Started',
                Priority = 'Normal'
            );
        } catch (Exception e) {
            offerNote = 'Offer applied. Follow-up task could not be created for the agent user; send the confirmation manually.';
        }
        Retention_Offer__c accepted = new Retention_Offer__c(Id = offer.Id, Status__c = 'Accepted');
        if (offerNote != null) {
            accepted.Agent_Summary__c = offerNote;
        }
        update as user accepted;
        r.success = true;
        r.message = 'Retention offer applied.';
        r.newMonthlyPrice = p.newMonthlyPrice;
        return r;
    }
}
