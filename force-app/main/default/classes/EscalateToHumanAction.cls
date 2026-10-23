public with sharing class EscalateToHumanAction {
    public class Request {
        @InvocableVariable(label='Subscription Id' description='The subscriptionId from Get Customer Subscription. Required.' required=true)
        public String subscriptionId;
        @InvocableVariable(label='Reason' description='Why this is being escalated, in a few words (for example: strategic account, discount already used, customer asked for a person).' required=true)
        public String reason;
        @InvocableVariable(label='Conversation Summary' description='3 to 5 sentences: who the customer is, their plan, why they want to leave, what was offered, and what they said. Required.' required=true)
        public String conversationSummary;
    }

    public class Response {
        @InvocableVariable(label='Success' description='True if a case was created.')
        public Boolean success;
        @InvocableVariable(label='Case Number' description='Share this with the customer.')
        public String caseNumber;
        @InvocableVariable(label='Message' description='Result message.')
        public String message;
    }

    @InvocableMethod(label='Escalate to Human Agent' description='Create a case with a full briefing for a human retention specialist. Use when escalation is required, the customer asks for a person, is angry, or mentions legal action.')
    public static List<Response> run(List<Request> requests) {
        List<Response> out = new List<Response>();
        for (Request req : requests) {
            out.add(escalate(req));
        }
        return out;
    }

    private static Response escalate(Request req) {
        Response r = new Response();
        Subscription__c sub = RetentionPolicyService.getSubscription(RetentionPolicyService.toId(req.subscriptionId));
        if (sub == null) {
            r.success = false;
            r.message = 'The subscription could not be found, so no case was created.';
            return r;
        }
        Decimal util = RetentionPolicyService.getUtilization(sub);

        // Latest offer that is not finished; reuse it, or create an audit row.
        List<Retention_Offer__c> offers = [
            SELECT Id, Offer_Type__c, Status__c, Case__c, Case__r.CaseNumber, Monthly_Savings__c, Discount_Percent__c,
                Discount_Months__c, Proposed_Plan__r.Name, Reason__c
            FROM Retention_Offer__c
            WHERE Subscription__c = :sub.Id AND Status__c IN ('Proposed', 'Escalated')
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        Retention_Offer__c offer = offers.isEmpty() ? null : offers[0];
        if (offer != null && offer.Case__c != null) {
            r.success = true;
            r.caseNumber = offer.Case__r.CaseNumber;
            r.message = 'A specialist case already exists for this request.';
            return r;
        }

        String reason = String.isBlank(req.reason) ? (offer?.Reason__c ?? 'Not specified') : req.reason;
        String proposed = 'None';
        if (offer != null) {
            proposed = offer.Offer_Type__c;
            if (offer.Offer_Type__c == 'Downgrade') {
                proposed += ' to ' + offer.Proposed_Plan__r?.Name;
            } else if (offer.Offer_Type__c == 'Discount') {
                proposed += ' ' + offer.Discount_Percent__c + '% for ' + offer.Discount_Months__c + ' months';
            }
        }
        String summary = String.isBlank(req.conversationSummary) ? '' : req.conversationSummary.left(3000);
        String briefing = 'RETENTION ESCALATION BRIEFING\n' +
            'Customer: ' + sub.Contact__r.Name + ' (' + sub.Contact__r.Email + ')\n' +
            'Account: ' + sub.Account__r.Name + '\n' +
            'Plan: ' + sub.Plan__r?.Name + ' at $' + sub.Monthly_Price__c + '/month\n' +
            'Renewal date: ' + sub.Renewal_Date__c + '\n' +
            'Average usage (last 3 months): ' + (util == null ? 'unknown' : util + '% of plan limit') + '\n' +
            'Strategic account: ' + (sub.Is_Strategic__c == true ? 'Yes' : 'No') + '\n' +
            'Stated reason: ' + reason + '\n' +
            'Offer proposed: ' + proposed + '\n\n' +
            'Agent summary:\n' + summary + '\n\n' +
            'Suggested next step: ' + suggestNext(sub, util, reason);

        Case c = new Case(
            Subject = 'Retention escalation: ' + sub.Account__r.Name,
            Priority = 'High',
            Origin = 'Web',
            AccountId = sub.Account__c,
            ContactId = sub.Contact__c,
            Description = briefing.left(32000)
        );
        insert as user c;

        if (offer == null) {
            offer = new Retention_Offer__c(
                Subscription__c = sub.Id, Offer_Type__c = 'Escalation', Status__c = 'Escalated',
                Reason__c = RetentionPolicyService.normalizeReason(req.reason)
            );
        }
        offer.Status__c = 'Escalated';
        offer.Case__c = c.Id;
        offer.Agent_Summary__c = summary;
        if (offer.Id == null) {
            insert as user offer;
        } else {
            update as user offer;
        }

        r.success = true;
        r.caseNumber = [SELECT CaseNumber FROM Case WHERE Id = :c.Id WITH USER_MODE].CaseNumber;
        r.message = 'Case created for a human specialist.';
        return r;
    }

    private static String suggestNext(Subscription__c sub, Decimal util, String reason) {
        if (sub.Is_Strategic__c == true) {
            return 'Assign the account owner to call within one business day before renewal on ' + sub.Renewal_Date__c + '.';
        }
        if (util != null && util >= 50) {
            return 'Usage is healthy, so the price concern is likely value-driven. Review any prior discount and consider an approved custom offer.';
        }
        return 'Contact the customer to discuss "' + reason + '" and confirm whether a plan change or other option fits.';
    }
}
