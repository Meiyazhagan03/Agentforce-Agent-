@IsTest
private class GetRetentionOptionsActionTest {
    @TestSetup
    static void setup() {
        RetentionTestDataFactory.createPlans();
        RetentionTestDataFactory.createSubscription('Opt', 'Lumio Growth', 99, new List<Integer>{ 1100, 1000, 1200 });
        RetentionTestDataFactory.createSubscription('OptHigh', 'Lumio Pro', 249, new List<Integer>{ 15200, 15900, 16000 });
    }

    private static GetRetentionOptionsAction.Response call(String subId, String reason) {
        GetRetentionOptionsAction.Request req = new GetRetentionOptionsAction.Request();
        req.subscriptionId = subId;
        req.reason = reason;
        req.customerMessage = 'too costly';
        return GetRetentionOptionsAction.run(new List<GetRetentionOptionsAction.Request>{ req })[0];
    }

    private static Id subFor(String planName) {
        return [SELECT Id FROM Subscription__c WHERE Plan__r.Name = :planName LIMIT 1].Id;
    }

    @IsTest
    static void downgradeLogsProposedOffer() {
        GetRetentionOptionsAction.Response r = call(subFor('Lumio Growth'), 'Too expensive');
        System.assertEquals('Downgrade', r.offerType);
        System.assertEquals(60, r.monthlySavings);
        Retention_Offer__c o = [SELECT Status__c, Offer_Type__c, Customer_Message__c FROM Retention_Offer__c WHERE Id = :r.retentionOfferId];
        System.assertEquals('Proposed', o.Status__c);
        System.assertEquals('Downgrade', o.Offer_Type__c);
    }

    @IsTest
    static void discountOffer() {
        GetRetentionOptionsAction.Response r = call(subFor('Lumio Pro'), 'Too expensive');
        System.assertEquals('Discount', r.offerType);
        System.assertEquals(15, r.discountPercent);
    }

    @IsTest
    static void escalationLogsEscalatedOffer() {
        GetRetentionOptionsAction.Response r = call(subFor('Lumio Pro'), 'Missing features');
        System.assert(r.requiresEscalation);
        System.assertEquals('Escalated', [SELECT Status__c FROM Retention_Offer__c WHERE Id = :r.retentionOfferId].Status__c);
    }

    @IsTest
    static void badSubscriptionEscalatesSafely() {
        GetRetentionOptionsAction.Response r = call('not-an-id', 'Too expensive');
        System.assert(r.requiresEscalation);
        System.assertEquals(null, r.retentionOfferId);
    }
}
