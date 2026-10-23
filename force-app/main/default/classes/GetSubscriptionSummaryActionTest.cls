@IsTest
private class GetSubscriptionSummaryActionTest {
    @TestSetup
    static void setup() {
        RetentionTestDataFactory.createPlans();
        RetentionTestDataFactory.createSubscription('Summary', 'Lumio Growth', 99, new List<Integer>{ 1100, 1000, 1200 });
    }

    private static GetSubscriptionSummaryAction.Response call(String email) {
        GetSubscriptionSummaryAction.Request req = new GetSubscriptionSummaryAction.Request();
        req.customerEmail = email;
        return GetSubscriptionSummaryAction.run(new List<GetSubscriptionSummaryAction.Request>{ req })[0];
    }

    @IsTest
    static void foundCaseInsensitive() {
        GetSubscriptionSummaryAction.Response r = call('  SUMMARY@Example.com ');
        System.assert(r.found);
        System.assertEquals('Lumio Growth', r.planName);
        System.assertEquals(22.0, r.avgUtilizationPct);
        System.assertEquals(false, r.hasActiveDiscount);
        System.assertNotEquals(null, r.subscriptionId);
    }

    @IsTest
    static void notFound() {
        GetSubscriptionSummaryAction.Response r = call('nobody@example.com');
        System.assertEquals(false, r.found);
        System.assertNotEquals(null, r.message);
    }

    @IsTest
    static void activeDiscountFlag() {
        update new Subscription__c(Id = [SELECT Id FROM Subscription__c LIMIT 1].Id, Discount_Percent__c = 10, Discount_End_Date__c = Date.today().addMonths(1));
        System.assertEquals(true, call('summary@example.com').hasActiveDiscount);
    }
}
