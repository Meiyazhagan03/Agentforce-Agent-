// Read-only: runs the policy for each demo customer using the reason "Too expensive".
List<String> emails = new List<String>{ 'priya.nair@example.com', 'daniel.ortiz@example.com', 'ananya.rao@example.com', 'meera.iyer@example.com', 'tomas.weber@example.com' };
for (String e : emails) {
    Subscription__c s = RetentionPolicyService.findByEmail(e);
    Decimal util = RetentionPolicyService.getUtilization(s);
    RetentionPolicyResult r = RetentionPolicyService.evaluate(s, util, 'Too expensive');
    System.debug('OUTCOME|' + s.Account__r.Name + '|' + util + '%|' + r.offerType + '|' + r.proposedPlanName + '|price=' + r.newMonthlyPrice + '|save=' + r.monthlySavings + '|disc=' + r.discountPercent + '/' + r.discountMonths + '|esc=' + r.escalationReason);
}
