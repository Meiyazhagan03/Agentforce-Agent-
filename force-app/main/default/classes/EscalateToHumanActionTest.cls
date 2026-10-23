@IsTest
private class EscalateToHumanActionTest {
    @TestSetup
    static void setup() {
        RetentionTestDataFactory.createPlans();
        Subscription__c s = RetentionTestDataFactory.createSubscription('Esc', 'Lumio Enterprise', 1800, new List<Integer>{ 71000, 69500, 72500 });
        update new Subscription__c(Id = s.Id, Is_Strategic__c = true);
        RetentionTestDataFactory.createSubscription('EscLow', 'Lumio Growth', 99, new List<Integer>{ 1100, 1000, 1200 });
    }

    private static EscalateToHumanAction.Response call(Id subId) {
        EscalateToHumanAction.Request req = new EscalateToHumanAction.Request();
        req.subscriptionId = subId;
        req.reason = 'Strategic account';
        req.conversationSummary = 'Customer wants to cancel citing cost. Enterprise plan. No offer made.';
        return EscalateToHumanAction.run(new List<EscalateToHumanAction.Request>{ req })[0];
    }

    @IsTest
    static void createsCaseWithBriefingAndAuditOffer() {
        Id s = [SELECT Id FROM Subscription__c WHERE Plan__r.Name = 'Lumio Enterprise'].Id;
        EscalateToHumanAction.Response r = call(s);
        System.assert(r.success, r.message);
        Case c = [SELECT Subject, Priority, Origin, Description, AccountId, ContactId FROM Case WHERE CaseNumber = :r.caseNumber];
        System.assertEquals('High', c.Priority);
        System.assert(c.Subject.startsWith('Retention escalation: '));
        System.assert(c.Description.contains('Suggested next step'));
        System.assert(c.Description.contains('Strategic account: Yes'));
        Retention_Offer__c o = [SELECT Status__c, Case__c FROM Retention_Offer__c WHERE Subscription__c = :s];
        System.assertEquals('Escalated', o.Status__c);
        System.assertEquals(c.Id, o.Case__c);
        // Calling again reuses the case.
        System.assertEquals(r.caseNumber, call(s).caseNumber);
        System.assertEquals(1, [SELECT COUNT() FROM Case]);
    }

    @IsTest
    static void reusesProposedOffer() {
        Id s = [SELECT Id FROM Subscription__c WHERE Plan__r.Name = 'Lumio Growth'].Id;
        GetRetentionOptionsAction.Request g = new GetRetentionOptionsAction.Request();
        g.subscriptionId = s;
        g.reason = 'Too expensive';
        Id offerId = GetRetentionOptionsAction.run(new List<GetRetentionOptionsAction.Request>{ g })[0].retentionOfferId;
        EscalateToHumanAction.Response r = call(s);
        System.assert(r.success);
        System.assertEquals('Escalated', [SELECT Status__c FROM Retention_Offer__c WHERE Id = :offerId].Status__c);
        System.assert([SELECT Description FROM Case LIMIT 1].Description.contains('Downgrade to Lumio Starter'));
    }

    @IsTest
    static void badSubscription() {
        EscalateToHumanAction.Request req = new EscalateToHumanAction.Request();
        req.subscriptionId = 'bad';
        EscalateToHumanAction.Response r = EscalateToHumanAction.run(new List<EscalateToHumanAction.Request>{ req })[0];
        System.assertEquals(false, r.success);
        System.assertEquals(0, [SELECT COUNT() FROM Case]);
    }
}
