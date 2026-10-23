// Idempotent seed for the Lumio demo. Fictional data only (@example.com).
// Removes ONLY the five demo accounts (and their related records) and the four Lumio plans, then recreates them.
Set<String> acctNames = new Set<String>{ 'Northwind Bakery Co', 'Blue Harbor Logistics', 'Greenleaf Studios', 'Atlas Freight Holdings', 'Sunrise Cafe' };
Set<String> planNames = new Set<String>{ 'Lumio Starter', 'Lumio Growth', 'Lumio Pro', 'Lumio Enterprise' };

List<Account> oldAccts = [SELECT Id FROM Account WHERE Name IN :acctNames];
Set<Id> oldAcctIds = new Map<Id, Account>(oldAccts).keySet();
delete [SELECT Id FROM Task WHERE WhatId IN :oldAcctIds];
delete [SELECT Id FROM Case WHERE AccountId IN :oldAcctIds];
List<Subscription__c> oldSubs = [SELECT Id FROM Subscription__c WHERE Account__c IN :oldAcctIds];
delete [SELECT Id FROM Retention_Offer__c WHERE Subscription__c IN :oldSubs];
delete [SELECT Id FROM Usage_Record__c WHERE Subscription__c IN :oldSubs];
delete oldSubs;
delete [SELECT Id FROM Contact WHERE AccountId IN :oldAcctIds];
delete oldAccts;
delete [SELECT Id FROM Plan__c WHERE Name IN :planNames];

Map<String, Plan__c> plans = new Map<String, Plan__c>{
    'Starter' => new Plan__c(Name = 'Lumio Starter', Tier__c = 'Starter', Tier_Rank__c = 1, Monthly_Price__c = 39, Usage_Limit__c = 1000, Seat_Limit__c = 3, Is_Active__c = true, Public_Description__c = 'For solo users and tiny teams.'),
    'Growth' => new Plan__c(Name = 'Lumio Growth', Tier__c = 'Growth', Tier_Rank__c = 2, Monthly_Price__c = 99, Usage_Limit__c = 5000, Seat_Limit__c = 10, Is_Active__c = true, Public_Description__c = 'For growing teams.'),
    'Pro' => new Plan__c(Name = 'Lumio Pro', Tier__c = 'Pro', Tier_Rank__c = 3, Monthly_Price__c = 249, Usage_Limit__c = 20000, Seat_Limit__c = 40, Is_Active__c = true, Public_Description__c = 'For busy departments.'),
    'Enterprise' => new Plan__c(Name = 'Lumio Enterprise', Tier__c = 'Enterprise', Tier_Rank__c = 4, Monthly_Price__c = 1800, Usage_Limit__c = 100000, Seat_Limit__c = 500, Is_Active__c = true, Public_Description__c = 'For whole organizations.')
};
insert plans.values();

// account, first, last, email, plan, price, usage (oldest..newest ignored; 3 months before this one), strategic, lastDiscountMonthsAgo, discountPct, startMonthsAgo, renewalDays
List<List<Object>> rows = new List<List<Object>>{
    new List<Object>{ 'Northwind Bakery Co', 'Priya', 'Nair', 'priya.nair@example.com', 'Growth', 99, new List<Integer>{ 1100, 1000, 1200 }, false, null, null, 14, 24 },
    new List<Object>{ 'Blue Harbor Logistics', 'Daniel', 'Ortiz', 'daniel.ortiz@example.com', 'Pro', 249, new List<Integer>{ 15200, 15900, 16000 }, false, null, null, 20, 28 },
    new List<Object>{ 'Greenleaf Studios', 'Ananya', 'Rao', 'ananya.rao@example.com', 'Pro', 224.10, new List<Integer>{ 17000, 17400, 17600 }, false, 4, 10, 30, 31 },
    new List<Object>{ 'Atlas Freight Holdings', 'Meera', 'Iyer', 'meera.iyer@example.com', 'Enterprise', 1800, new List<Integer>{ 71000, 69500, 72500 }, true, null, null, 28, 35 },
    new List<Object>{ 'Sunrise Cafe', 'Tomas', 'Weber', 'tomas.weber@example.com', 'Starter', 39, new List<Integer>{ 150, 140, 160 }, false, null, null, 12, 21 }
};

List<Account> accts = new List<Account>();
for (List<Object> r : rows) {
    accts.add(new Account(Name = (String) r[0]));
}
insert accts;

List<Contact> contacts = new List<Contact>();
for (Integer i = 0; i < rows.size(); i++) {
    List<Object> r = rows[i];
    contacts.add(new Contact(FirstName = (String) r[1], LastName = (String) r[2], Email = (String) r[3], AccountId = accts[i].Id));
}
insert contacts;

List<Subscription__c> subs = new List<Subscription__c>();
for (Integer i = 0; i < rows.size(); i++) {
    List<Object> r = rows[i];
    Integer lastDiscMonths = (Integer) r[8];
    Integer pct = (Integer) r[9];
    subs.add(new Subscription__c(
        Account__c = accts[i].Id, Contact__c = contacts[i].Id, Plan__c = plans.get((String) r[4]).Id,
        Status__c = 'Active', Start_Date__c = Date.today().addMonths(-((Integer) r[10])),
        Renewal_Date__c = Date.today().addDays((Integer) r[11]),
        Monthly_Price__c = (Decimal) r[5], Is_Strategic__c = (Boolean) r[7],
        Last_Discount_Date__c = lastDiscMonths == null ? null : Date.today().addMonths(-lastDiscMonths),
        Discount_Percent__c = pct,
        Discount_End_Date__c = pct == null ? null : Date.today().addMonths(2)
    ));
}
insert subs;

List<Usage_Record__c> usage = new List<Usage_Record__c>();
for (Integer i = 0; i < rows.size(); i++) {
    List<Integer> u = (List<Integer>) rows[i][6];
    for (Integer m = 0; m < 3; m++) {
        usage.add(new Usage_Record__c(
            Subscription__c = subs[i].Id, Usage_Month__c = Date.today().toStartOfMonth().addMonths(-(m + 1)),
            Units_Used__c = u[m], Active_Seats__c = 3
        ));
    }
}
insert usage;
System.debug('SEEDED: ' + plans.size() + ' plans, ' + accts.size() + ' accounts, ' + contacts.size() + ' contacts, ' + subs.size() + ' subscriptions, ' + usage.size() + ' usage records');
