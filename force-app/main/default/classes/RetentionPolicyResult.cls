public with sharing class RetentionPolicyResult {
    public String offerType = 'None'; // Downgrade | Discount | Escalation | None
    public Id proposedPlanId;
    public String proposedPlanName;
    public Decimal newMonthlyPrice;
    public Decimal monthlySavings;
    public Decimal discountPercent;
    public Integer discountMonths;
    public Boolean requiresEscalation = false;
    public String escalationReason; // internal, goes into the case briefing
    public String explanation; // customer-safe wording the agent may quote
}
