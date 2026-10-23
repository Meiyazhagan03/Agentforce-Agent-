@IsTest
private class RetentionPolicyServiceTest {
    @TestSetup
    static void setup() {
        RetentionTestDataFactory.createPlans();
    }

    private static Subscription__c load(Subscription__c s) {
        return RetentionPolicyService.getSubscription(s.Id);
    }

    private static RetentionPolicyResult eval(Subscription__c s, String reason) {
        Subscription__c l = load(s);
        return RetentionPolicyService.evaluate(l, RetentionPolicyService.getUtilization(l), reason);
    }

    @IsTest
    static void rule1NotActive() {
        Subscription__c s = RetentionTestDataFactory.createSubscription('Rule1', 'Lumio Growth', 99, new List<Integer>{ 1100, 1000, 1200 });
        update new Subscription__c(Id = s.Id, Status__c = 'Cancel Requested');
        System.assertEquals('None', eval(s, 'Too expensive').offerType);
    }

    @IsTest
    static void rule2StrategicAndHighValue() {
        Subscription__c s = RetentionTestDataFactory.createSubscription('Rule2', 'Lumio Pro', 249, new List<Integer>{ 100, 100, 100 });
        update new Subscription__c(Id = s.Id, Is_Strategic__c = true);
        RetentionPolicyResult r = eval(s, 'Too expensive');
        System.assertEquals('Escalation', r.offerType);
        System.assert(r.requiresEscalation);

        Subscription__c big = RetentionTestDataFactory.createSubscription('Rule2b', 'Lumio Enterprise', 1800, new List<Integer>{ 71000, 69500, 72500 });
        System.assertEquals('Escalation', eval(big, 'Too expensive').offerType);
    }

    @IsTest
    static void rule3BusinessClosing() {
        Subscription__c s = RetentionTestDataFactory.createSubscription('Rule3', 'Lumio Growth', 99, new List<Integer>{ 1100, 1000, 1200 });
        RetentionPolicyResult r = eval(s, 'Business closing');
        System.assertEquals('None', r.offerType);
        System.assert(!r.requiresEscalation);
    }

    @IsTest
    static void rule4EscalatingReasons() {
        Subscription__c s = RetentionTestDataFactory.createSubscription('Rule4', 'Lumio Growth', 99, new List<Integer>{ 1100, 1000, 1200 });
        for (String reason : new List<String>{ 'Missing features', 'Switching to competitor', 'Other', 'gibberish', null }) {
            System.assertEquals('Escalation', eval(s, reason).offerType, String.valueOf(reason));
        }
    }

    @IsTest
    static void rule5Downgrade() {
        Subscription__c s = RetentionTestDataFactory.createSubscription('Rule5', 'Lumio Growth', 99, new List<Integer>{ 1100, 1000, 1200 });
        Subscription__c l = load(s);
        System.assertEquals(22.0, RetentionPolicyService.getUtilization(l));
        RetentionPolicyResult r = eval(s, 'Too expensive');
        System.assertEquals('Downgrade', r.offerType);
        System.assertEquals('Lumio Starter', r.proposedPlanName);
        System.assertEquals(39, r.newMonthlyPrice);
        System.assertEquals(60, r.monthlySavings);
        System.assertEquals('Downgrade', eval(s, 'Not using enough').offerType);
    }

    @IsTest
    static void rule6DiscountHighUsage() {
        Subscription__c s = RetentionTestDataFactory.createSubscription('Rule6', 'Lumio Pro', 249, new List<Integer>{ 15200, 15900, 16000 });
        RetentionPolicyResult r = eval(s, 'Too expensive');
        System.assertEquals('Discount', r.offerType);
        System.assertEquals(15, r.discountPercent);
        System.assertEquals(3, r.discountMonths);
        System.assertEquals(37.35, r.monthlySavings);
        System.assertEquals(211.65, r.newMonthlyPrice);
    }

    @IsTest
    static void rule6DiscountWhenNoCheaperPlan() {
        Subscription__c s = RetentionTestDataFactory.createSubscription('Rule6b', 'Lumio Starter', 39, new List<Integer>{ 150, 140, 160 });
        System.assertEquals('Discount', eval(s, 'Too expensive').offerType);
    }

    @IsTest
    static void rule6DiscountWhenCooldownElapsed() {
        Subscription__c s = RetentionTestDataFactory.createSubscription('Rule6c', 'Lumio Pro', 249, new List<Integer>{ 15200, 15900, 16000 });
        update new Subscription__c(Id = s.Id, Last_Discount_Date__c = Date.today().addMonths(-13));
        System.assertEquals('Discount', eval(s, 'Too expensive').offerType);
    }

    @IsTest
    static void rule7CooldownEscalates() {
        Subscription__c s = RetentionTestDataFactory.createSubscription('Rule7', 'Lumio Pro', 224.10, new List<Integer>{ 17000, 17400, 17600 });
        update new Subscription__c(Id = s.Id, Last_Discount_Date__c = Date.today().addMonths(-4));
        RetentionPolicyResult r = eval(s, 'Too expensive');
        System.assertEquals('Escalation', r.offerType);
        System.assert(r.escalationReason.contains('cooldown'));
    }

    @IsTest
    static void noUsageRowsEscalates() {
        Subscription__c s = RetentionTestDataFactory.createSubscription('NoUsage', 'Lumio Growth', 99, new List<Integer>());
        System.assertEquals(null, RetentionPolicyService.getUtilization(load(s)));
        System.assertEquals('Escalation', eval(s, 'Too expensive').offerType);
    }

    @IsTest
    static void helpers() {
        System.assertEquals('Too expensive', RetentionPolicyService.normalizeReason(' too expensive '));
        System.assertEquals(null, RetentionPolicyService.toId('nope'));
        System.assertEquals(null, RetentionPolicyService.toId(null));
        System.assertEquals(null, RetentionPolicyService.getSubscription(null));
        System.assertEquals(null, RetentionPolicyService.findByEmail(' '));
        System.assertEquals(15, RetentionPolicyService.getPolicy().Max_Discount_Percent__c);
    }
}
