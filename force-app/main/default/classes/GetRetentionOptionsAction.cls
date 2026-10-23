public with sharing class GetRetentionOptionsAction {
    public class Request {
        @InvocableVariable(label='Subscription Id' description='The subscriptionId returned by Get Customer Subscription. Required.' required=true)
        public String subscriptionId;
        @InvocableVariable(label='Reason' description='Must be exactly one of: Too expensive, Not using enough, Missing features, Switching to competitor, Business closing, Other. Required.' required=true)
        public String reason;
        @InvocableVariable(label='Customer Message' description='The customer\'s own words about why they want to leave.')
        public String customerMessage;
    }

    public class Response {
        @InvocableVariable(label='Offer Type' description='Downgrade, Discount, Escalation or None. Only offer what this says.')
        public String offerType;
        @InvocableVariable(label='Proposed Plan Id' description='Internal. Never show to the customer.')
        public String proposedPlanId;
        @InvocableVariable(label='Proposed Plan Name' description='Name of the plan being offered, if any.')
        public String proposedPlanName;
        @InvocableVariable(label='New Monthly Price' description='Price per month after the offer, in dollars. Quote exactly.')
        public Decimal newMonthlyPrice;
        @InvocableVariable(label='Monthly Savings' description='Dollars saved per month. Quote exactly.')
        public Decimal monthlySavings;
        @InvocableVariable(label='Discount Percent' description='Discount percent, if the offer is a discount.')
        public Decimal discountPercent;
        @InvocableVariable(label='Discount Months' description='How many months the discount lasts.')
        public Integer discountMonths;
        @InvocableVariable(label='Requires Escalation' description='If true, do NOT make an offer. Call Escalate to Human Agent instead.')
        public Boolean requiresEscalation;
        @InvocableVariable(label='Escalation Reason' description='Internal note for the human team. Do not read it to the customer.')
        public String escalationReason;
        @InvocableVariable(label='Explanation' description='Customer-safe wording for the offer. Base your reply on this.')
        public String explanation;
        @InvocableVariable(label='Retention Offer Id' description='Internal. Pass it to Apply Retention Offer. Never show to the customer.')
        public String retentionOfferId;
    }

    @InvocableMethod(label='Get Retention Options' description='Get the single policy-approved retention option for a verified customer and their reason for leaving. Call once the reason is known. Never offer anything this action did not return.')
    public static List<Response> run(List<Request> requests) {
        List<Response> out = new List<Response>();
        for (Request req : requests) {
            Response r = new Response();
            Subscription__c sub = RetentionPolicyService.getSubscription(RetentionPolicyService.toId(req.subscriptionId));
            if (sub == null) {
                r.offerType = 'None';
                r.requiresEscalation = true;
                r.escalationReason = 'Subscription could not be loaded.';
                r.explanation = 'I could not load that subscription. I will connect you with a specialist.';
                out.add(r);
                continue;
            }
            String reason = RetentionPolicyService.normalizeReason(req.reason);
            RetentionPolicyResult p = RetentionPolicyService.evaluate(sub, RetentionPolicyService.getUtilization(sub), reason);

            Retention_Offer__c offer = new Retention_Offer__c(
                Subscription__c = sub.Id,
                Reason__c = reason,
                Customer_Message__c = req.customerMessage,
                Offer_Type__c = p.offerType,
                Proposed_Plan__c = p.proposedPlanId,
                Discount_Percent__c = p.discountPercent,
                Discount_Months__c = p.discountMonths,
                Monthly_Savings__c = p.monthlySavings,
                Status__c = p.requiresEscalation ? 'Escalated' : 'Proposed',
                Agent_Summary__c = p.explanation
            );
            insert as user offer;

            r.offerType = p.offerType;
            r.proposedPlanId = p.proposedPlanId;
            r.proposedPlanName = p.proposedPlanName;
            r.newMonthlyPrice = p.newMonthlyPrice;
            r.monthlySavings = p.monthlySavings;
            r.discountPercent = p.discountPercent;
            r.discountMonths = p.discountMonths;
            r.requiresEscalation = p.requiresEscalation;
            r.escalationReason = p.escalationReason;
            r.explanation = p.explanation;
            r.retentionOfferId = offer.Id;
            out.add(r);
        }
        return out;
    }
}
