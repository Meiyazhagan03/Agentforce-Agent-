/**
 * Deterministic retention guardrails. The agent can only offer what this class returns,
 * and ApplyRetentionOfferAction re-runs it before changing any record.
 * All thresholds come from Retention_Policy__mdt (record "Default").
 */
public with sharing class RetentionPolicyService {
    public static final Set<String> REASONS = new Set<String>{
        'Too expensive', 'Not using enough', 'Missing features',
        'Switching to competitor', 'Business closing', 'Other'
    };

    public class PolicyException extends Exception {
    }

    public static Retention_Policy__mdt getPolicy() {
        Retention_Policy__mdt p = Retention_Policy__mdt.getInstance('Default');
        if (p == null) {
            throw new PolicyException('Retention policy record "Default" is missing.');
        }
        return p;
    }

    /** Maps anything outside the picklist to Other so it escalates rather than guesses. */
    public static String normalizeReason(String reason) {
        if (String.isBlank(reason)) {
            return 'Other';
        }
        for (String r : REASONS) {
            if (r.equalsIgnoreCase(reason.trim())) {
                return r;
            }
        }
        return 'Other';
    }

    public static Id toId(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        try {
            return Id.valueOf(value.trim());
        } catch (Exception e) {
            return null;
        }
    }

    public static Subscription__c getSubscription(Id subscriptionId) {
        if (subscriptionId == null) {
            return null;
        }
        List<Subscription__c> subs = [
            SELECT Id, Name, Account__c, Account__r.Name, Contact__c, Contact__r.Name, Contact__r.Email,
                Plan__c, Plan__r.Name, Plan__r.Tier__c, Plan__r.Tier_Rank__c, Plan__r.Usage_Limit__c,
                Status__c, Renewal_Date__c, Monthly_Price__c, Discount_Percent__c,
                Discount_End_Date__c, Last_Discount_Date__c, Is_Strategic__c
            FROM Subscription__c
            WHERE Id = :subscriptionId
            WITH USER_MODE
            LIMIT 1
        ];
        return subs.isEmpty() ? null : subs[0];
    }

    public static Subscription__c findByEmail(String email) {
        if (String.isBlank(email)) {
            return null;
        }
        String clean = email.trim().toLowerCase();
        List<Subscription__c> subs = [
            SELECT Id, Name, Account__c, Account__r.Name, Contact__c, Contact__r.Name, Contact__r.Email,
                Plan__c, Plan__r.Name, Plan__r.Tier__c, Plan__r.Tier_Rank__c, Plan__r.Usage_Limit__c,
                Status__c, Renewal_Date__c, Monthly_Price__c, Discount_Percent__c,
                Discount_End_Date__c, Last_Discount_Date__c, Is_Strategic__c
            FROM Subscription__c
            WHERE Contact__r.Email = :clean AND Status__c IN ('Active', 'Retained', 'Cancel Requested')
            WITH USER_MODE
            ORDER BY Start_Date__c DESC NULLS LAST
            LIMIT 1
        ];
        return subs.isEmpty() ? null : subs[0];
    }

    /**
     * Average of the latest 3 usage rows divided by the plan usage limit, as a percent.
     * Returns null when there are no usage rows or no usable plan limit (unknown, never guessed).
     */
    public static Map<Id, Decimal> getUtilization(List<Subscription__c> subs) {
        Map<Id, Decimal> result = new Map<Id, Decimal>();
        Set<Id> ids = new Set<Id>();
        for (Subscription__c s : subs) {
            ids.add(s.Id);
        }
        Map<Id, List<Decimal>> units = new Map<Id, List<Decimal>>();
        for (Usage_Record__c u : [
            SELECT Subscription__c, Units_Used__c
            FROM Usage_Record__c
            WHERE Subscription__c IN :ids
            WITH USER_MODE
            ORDER BY Usage_Month__c DESC
        ]) {
            List<Decimal> l = units.get(u.Subscription__c);
            if (l == null) {
                l = new List<Decimal>();
                units.put(u.Subscription__c, l);
            }
            if (l.size() < 3) {
                l.add(u.Units_Used__c == null ? 0 : u.Units_Used__c);
            }
        }
        for (Subscription__c s : subs) {
            List<Decimal> l = units.get(s.Id);
            Decimal limitUnits = s.Plan__r == null ? null : s.Plan__r.Usage_Limit__c;
            if (l == null || l.isEmpty() || limitUnits == null || limitUnits <= 0) {
                result.put(s.Id, null);
                continue;
            }
            Decimal total = 0;
            for (Decimal d : l) {
                total += d;
            }
            result.put(s.Id, (total / l.size() / limitUnits * 100).setScale(1));
        }
        return result;
    }

    public static Decimal getUtilization(Subscription__c sub) {
        return getUtilization(new List<Subscription__c>{ sub }).get(sub.Id);
    }

    public static RetentionPolicyResult evaluate(Subscription__c sub, Decimal avgUtilPct, String reason) {
        Retention_Policy__mdt policy = getPolicy();
        String r = normalizeReason(reason);
        RetentionPolicyResult res = new RetentionPolicyResult();

        // 1. Only active subscriptions get offers.
        if (sub.Status__c != 'Active') {
            res.explanation = 'This subscription is not active, so there is no retention offer to make.';
            return res;
        }
        // 2. Strategic or high-value accounts always go to a human.
        if (sub.Is_Strategic__c == true ||
            (sub.Monthly_Price__c != null && sub.Monthly_Price__c >= policy.Escalation_MRR_Threshold__c)) {
            return escalation(res, 'Strategic or high-value account.');
        }
        // 3. Business closing: nothing to offer.
        if (r == 'Business closing') {
            res.explanation = 'No retention offer applies when a business is closing. A cancellation request can be recorded for the team.';
            return res;
        }
        // 4. Reasons that need a conversation.
        if (r == 'Missing features' || r == 'Switching to competitor' || r == 'Other') {
            return escalation(res, 'Reason "' + r + '" needs a human conversation.');
        }
        // Unknown usage: never guess.
        if (avgUtilPct == null) {
            return escalation(res, 'No usable usage data, so utilization is unknown.');
        }
        // 5. Low utilization: right-size to the next plan down when it is cheaper.
        if (avgUtilPct < policy.Low_Utilization_Threshold_Pct__c && sub.Plan__r != null && sub.Plan__r.Tier_Rank__c != null) {
            Decimal lowerRank = sub.Plan__r.Tier_Rank__c - 1;
            List<Plan__c> lower = [
                SELECT Id, Name, Monthly_Price__c
                FROM Plan__c
                WHERE Is_Active__c = TRUE AND Tier_Rank__c = :lowerRank
                WITH USER_MODE
                LIMIT 1
            ];
            if (!lower.isEmpty() && lower[0].Monthly_Price__c != null && lower[0].Monthly_Price__c < sub.Monthly_Price__c) {
                Plan__c p = lower[0];
                res.offerType = 'Downgrade';
                res.proposedPlanId = p.Id;
                res.proposedPlanName = p.Name;
                res.newMonthlyPrice = p.Monthly_Price__c.setScale(2);
                res.monthlySavings = (sub.Monthly_Price__c - p.Monthly_Price__c).setScale(2);
                res.explanation = 'Your recent usage is about ' + avgUtilPct + '% of your plan, so ' + p.Name +
                    ' at $' + res.newMonthlyPrice + '/month would fit better and save you $' + res.monthlySavings + '/month.';
                return res;
            }
        }
        // 6. Capped discount, once per cooldown window.
        Date cutoff = Date.today().addMonths(-Integer.valueOf(policy.Discount_Cooldown_Months__c));
        if (sub.Last_Discount_Date__c == null || sub.Last_Discount_Date__c <= cutoff) {
            Decimal pct = policy.Max_Discount_Percent__c;
            res.offerType = 'Discount';
            res.discountPercent = pct;
            res.discountMonths = Integer.valueOf(policy.Max_Discount_Months__c);
            res.monthlySavings = (sub.Monthly_Price__c * pct / 100).setScale(2);
            res.newMonthlyPrice = (sub.Monthly_Price__c - res.monthlySavings).setScale(2);
            res.explanation = 'I can offer ' + pct.stripTrailingZeros().toPlainString() + '% off for ' + res.discountMonths +
                ' months, bringing your price to $' + res.newMonthlyPrice + '/month and saving you $' + res.monthlySavings + '/month.';
            return res;
        }
        // 7. Discount already used recently.
        return escalation(res, 'Discount already used within the cooldown period; requires human approval.');
    }

    private static RetentionPolicyResult escalation(RetentionPolicyResult res, String internalReason) {
        res.offerType = 'Escalation';
        res.requiresEscalation = true;
        res.escalationReason = internalReason;
        res.explanation = 'This needs a specialist from our team. I will pass your details along so they can follow up.';
        return res;
    }
}
