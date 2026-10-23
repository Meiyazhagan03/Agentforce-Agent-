@IsTest
public class RetentionTestDataFactory {
    public static List<Plan__c> createPlans() {
        List<Plan__c> plans = new List<Plan__c>{
            new Plan__c(Name = 'Lumio Starter', Tier__c = 'Starter', Tier_Rank__c = 1, Monthly_Price__c = 39, Usage_Limit__c = 1000, Seat_Limit__c = 3, Is_Active__c = true),
            new Plan__c(Name = 'Lumio Growth', Tier__c = 'Growth', Tier_Rank__c = 2, Monthly_Price__c = 99, Usage_Limit__c = 5000, Seat_Limit__c = 10, Is_Active__c = true),
            new Plan__c(Name = 'Lumio Pro', Tier__c = 'Pro', Tier_Rank__c = 3, Monthly_Price__c = 249, Usage_Limit__c = 20000, Seat_Limit__c = 40, Is_Active__c = true),
            new Plan__c(Name = 'Lumio Enterprise', Tier__c = 'Enterprise', Tier_Rank__c = 4, Monthly_Price__c = 1800, Usage_Limit__c = 100000, Seat_Limit__c = 500, Is_Active__c = true)
        };
        insert plans;
        return plans;
    }

    public static Plan__c plan(String name) {
        return [SELECT Id, Name FROM Plan__c WHERE Name = :name LIMIT 1];
    }

    /** Creates account, contact, subscription and 3 usage rows. */
    public static Subscription__c createSubscription(String key, String planName, Decimal price, List<Integer> usage) {
        Account a = new Account(Name = key + ' Co');
        insert a;
        Contact c = new Contact(FirstName = 'Test', LastName = key, Email = key.toLowerCase() + '@example.com', AccountId = a.Id);
        insert c;
        Subscription__c s = new Subscription__c(
            Account__c = a.Id, Contact__c = c.Id, Plan__c = plan(planName).Id, Status__c = 'Active',
            Start_Date__c = Date.today().addMonths(-18), Renewal_Date__c = Date.today().addDays(30),
            Monthly_Price__c = price, Is_Strategic__c = false
        );
        insert s;
        List<Usage_Record__c> rows = new List<Usage_Record__c>();
        for (Integer i = 0; i < usage.size(); i++) {
            rows.add(new Usage_Record__c(
                Subscription__c = s.Id, Usage_Month__c = Date.today().toStartOfMonth().addMonths(-(i + 1)),
                Units_Used__c = usage[i], Active_Seats__c = 3
            ));
        }
        insert rows;
        return s;
    }

    public static Subscription__c reload(Id subId) {
        return [
            SELECT Id, Status__c, Plan__c, Plan__r.Name, Monthly_Price__c, Discount_Percent__c, Discount_End_Date__c, Last_Discount_Date__c
            FROM Subscription__c WHERE Id = :subId
        ];
    }
}
