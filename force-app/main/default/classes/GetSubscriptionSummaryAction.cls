public with sharing class GetSubscriptionSummaryAction {
    public class Request {
        @InvocableVariable(label='Customer Email' description='The account email the customer gave you. Pass it exactly as typed. Required.' required=true)
        public String customerEmail;
    }

    public class Response {
        @InvocableVariable(label='Found' description='True if a subscription was found for this email.')
        public Boolean found;
        @InvocableVariable(label='Subscription Id' description='Internal id. Pass it to the other actions. Never show it to the customer.')
        public String subscriptionId;
        @InvocableVariable(label='Customer Name' description='Customer name. You may use it to greet them.')
        public String customerName;
        @InvocableVariable(label='Account Name' description='Customer company name.')
        public String accountName;
        @InvocableVariable(label='Plan Name' description='Current plan name.')
        public String planName;
        @InvocableVariable(label='Plan Tier' description='Current plan tier.')
        public String planTier;
        @InvocableVariable(label='Monthly Price' description='What the customer pays per month now, in dollars.')
        public Decimal monthlyPrice;
        @InvocableVariable(label='Renewal Date' description='Next renewal date.')
        public Date renewalDate;
        @InvocableVariable(label='Average Utilization Percent' description='Average usage over the last 3 months as a percent of the plan limit. Empty if unknown.')
        public Decimal avgUtilizationPct;
        @InvocableVariable(label='Has Active Discount' description='True if the customer already has a discount running.')
        public Boolean hasActiveDiscount;
        @InvocableVariable(label='Is Strategic' description='Internal flag. Do not mention it to the customer.')
        public Boolean isStrategic;
        @InvocableVariable(label='Status' description='Subscription status: Active, Retained, Cancel Requested or Cancelled.')
        public String status;
        @InvocableVariable(label='Message' description='Plain-language result you may relay to the customer.')
        public String message;
    }

    @InvocableMethod(label='Get Customer Subscription' description='Look up the customer\'s subscription, price, renewal date and 3-month usage by account email. Call this first, once you have the customer\'s email.')
    public static List<Response> run(List<Request> requests) {
        List<Response> out = new List<Response>();
        for (Request req : requests) {
            Response r = new Response();
            r.found = false;
            Subscription__c sub = RetentionPolicyService.findByEmail(req.customerEmail);
            if (sub == null) {
                r.message = 'I could not find a subscription for that email. Could you double-check it?';
            } else {
                r.found = true;
                r.subscriptionId = sub.Id;
                r.customerName = sub.Contact__r.Name;
                r.accountName = sub.Account__r.Name;
                r.planName = sub.Plan__r?.Name;
                r.planTier = sub.Plan__r?.Tier__c;
                r.monthlyPrice = sub.Monthly_Price__c;
                r.renewalDate = sub.Renewal_Date__c;
                r.avgUtilizationPct = RetentionPolicyService.getUtilization(sub);
                r.hasActiveDiscount = sub.Discount_Percent__c != null && sub.Discount_Percent__c > 0 &&
                    (sub.Discount_End_Date__c == null || sub.Discount_End_Date__c >= Date.today());
                r.isStrategic = sub.Is_Strategic__c;
                r.status = sub.Status__c;
                r.message = 'Found subscription for ' + r.customerName + ' (' + r.accountName + ').';
            }
            out.add(r);
        }
        return out;
    }
}
