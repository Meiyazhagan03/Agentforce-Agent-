@IsTest
private class RecordCancellationRequestActionTest {
    @TestSetup
    static void setup() {
        RetentionTestDataFactory.createPlans();
        RetentionTestDataFactory.createSubscription('Cxl', 'Lumio Growth', 99, new List<Integer>{ 1100, 1000, 1200 });
    }

    private static RecordCancellationRequestAction.Response call(String subId, Boolean confirmed) {
        RecordCancellationRequestAction.Request req = new RecordCancellationRequestAction.Request();
        req.subscriptionId = subId;
        req.reason = 'Too expensive';
        req.customerMessage = 'no thanks, just cancel';
        req.customerConfirmed = confirmed;
        return RecordCancellationRequestAction.run(new List<RecordCancellationRequestAction.Request>{ req })[0];
    }

    @IsTest
    static void notConfirmedDoesNothing() {
        Subscription__c s = [SELECT Id FROM Subscription__c LIMIT 1];
        System.assertEquals(false, call(s.Id, false).success);
        System.assertEquals('Active', RetentionTestDataFactory.reload(s.Id).Status__c);
        System.assertEquals(0, [SELECT COUNT() FROM Case]);
    }

    @IsTest
    static void confirmedRecordsRequestNeverCancels() {
        Subscription__c s = [SELECT Id FROM Subscription__c LIMIT 1];
        GetRetentionOptionsAction.Request g = new GetRetentionOptionsAction.Request();
        g.subscriptionId = s.Id;
        g.reason = 'Too expensive';
        Id offerId = GetRetentionOptionsAction.run(new List<GetRetentionOptionsAction.Request>{ g })[0].retentionOfferId;

        System.assert(call(s.Id, true).success);
        System.assertEquals('Cancel Requested', RetentionTestDataFactory.reload(s.Id).Status__c);
        System.assertEquals('Declined', [SELECT Status__c FROM Retention_Offer__c WHERE Id = :offerId].Status__c);
        System.assertEquals(1, [SELECT COUNT() FROM Case WHERE Subject LIKE 'Process cancellation request%']);
        // Repeat is idempotent: no second case.
        System.assert(call(s.Id, true).success);
        System.assertEquals(1, [SELECT COUNT() FROM Case]);
    }

    @IsTest
    static void alreadyCancelledAndBadId() {
        Subscription__c s = [SELECT Id FROM Subscription__c LIMIT 1];
        update new Subscription__c(Id = s.Id, Status__c = 'Cancelled');
        System.assertEquals(false, call(s.Id, true).success);
        System.assertEquals(false, call('bad', true).success);
    }
}
