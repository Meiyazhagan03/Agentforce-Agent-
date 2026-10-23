@IsTest
private class ApplyRetentionOfferActionTest {
    @TestSetup
    static void setup() {
        RetentionTestDataFactory.createPlans();
        RetentionTestDataFactory.createSubscription('Apply', 'Lumio Growth', 99, new List<Integer>{ 1100, 1000, 1200 });
        RetentionTestDataFactory.createSubscription('ApplyD', 'Lumio Pro', 249, new List<Integer>{ 15200, 15900, 16000 });
    }

    private static Id subFor(String planName) {
        return [SELECT Id FROM Subscription__c WHERE Plan__r.Name = :planName LIMIT 1].Id;
    }

    private static String offerFor(Id subId, String reason) {
        GetRetentionOptionsAction.Request g = new GetRetentionOptionsAction.Request();
        g.subscriptionId = subId;
        g.reason = reason;
        return GetRetentionOptionsAction.run(new List<GetRetentionOptionsAction.Request>{ g })[0].retentionOfferId;
    }

    private static ApplyRetentionOfferAction.Response apply(Id subId, String offerId, Boolean confirmed) {
        ApplyRetentionOfferAction.Request req = new ApplyRetentionOfferAction.Request();
        req.subscriptionId = subId;
        req.retentionOfferId = offerId;
        req.customerConfirmed = confirmed;
        return ApplyRetentionOfferAction.run(new List<ApplyRetentionOfferAction.Request>{ req })[0];
    }

    @IsTest
    static void notConfirmedChangesNothing() {
        Id s = subFor('Lumio Growth');
        ApplyRetentionOfferAction.Response r = apply(s, offerFor(s, 'Too expensive'), false);
        System.assertEquals(false, r.success);
        System.assertEquals('Active', RetentionTestDataFactory.reload(s).Status__c);
        System.assertEquals(0, [SELECT COUNT() FROM Task]);
    }

    @IsTest
    static void downgradeApplied() {
        Id s = subFor('Lumio Growth');
        String o = offerFor(s, 'Too expensive');
        ApplyRetentionOfferAction.Response r = apply(s, o, true);
        System.assert(r.success, r.message);
        Subscription__c sub = RetentionTestDataFactory.reload(s);
        System.assertEquals('Lumio Starter', sub.Plan__r.Name);
        System.assertEquals(39, sub.Monthly_Price__c);
        System.assertEquals('Retained', sub.Status__c);
        System.assertEquals('Accepted', [SELECT Status__c FROM Retention_Offer__c WHERE Id = :o].Status__c);
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE Subject LIKE 'Retention offer accepted%']);
        // Second apply must fail: offer no longer Proposed.
        System.assertEquals(false, apply(s, o, true).success);
    }

    @IsTest
    static void discountApplied() {
        Id s = subFor('Lumio Pro');
        ApplyRetentionOfferAction.Response r = apply(s, offerFor(s, 'Too expensive'), true);
        System.assert(r.success, r.message);
        Subscription__c sub = RetentionTestDataFactory.reload(s);
        System.assertEquals(211.65, sub.Monthly_Price__c);
        System.assertEquals(15, sub.Discount_Percent__c);
        System.assertEquals(Date.today().addMonths(3), sub.Discount_End_Date__c);
        System.assertEquals(Date.today(), sub.Last_Discount_Date__c);
    }

    @IsTest
    static void tamperedOfferRejected() {
        Id s = subFor('Lumio Pro');
        String o = offerFor(s, 'Too expensive');
        update new Retention_Offer__c(Id = o, Discount_Percent__c = 50);
        ApplyRetentionOfferAction.Response r = apply(s, o, true);
        System.assertEquals(false, r.success);
        System.assertEquals(249, RetentionTestDataFactory.reload(s).Monthly_Price__c);
    }

    @IsTest
    static void escalatedOfferAndBadIdsRejected() {
        Id s = subFor('Lumio Pro');
        System.assertEquals(false, apply(s, offerFor(s, 'Missing features'), true).success);
        System.assertEquals(false, apply(s, 'bad', true).success);
        System.assertEquals(false, apply(null, null, true).success);
        // Offer belonging to a different subscription.
        Id other = subFor('Lumio Growth');
        System.assertEquals(false, apply(other, offerFor(s, 'Too expensive'), true).success);
    }
}
