# Right-Size Retention Agent: contest submission kit

Deadline: Oct 31 2026, 11:59pm PT. Target: submit by Oct 30. One entry only.
All figures below marked "projected" are hypothetical, based on stated assumptions.

## 1. Before you record (checklist)

- [ ] Reseed: `sf apex run --file scripts/apex/seed-data.apex -o agentorg`
- [ ] Confirm the agent is Active (Setup, Agentforce Agents) and that you test the active version
- [ ] Clean browser profile; no bookmarks or personal tabs; hide or crop your username/email in Setup headers
- [ ] Open these tabs in order: Agentforce Builder (preview), Subscription SUB list view, Retention Offers list view, Cases list view
- [ ] Do a dry run of Demo 1 and Demo 2, then **reseed again** before the real take
- [ ] 1080p, mp4, under 4:50, narrate the whole time (silent video is disqualified)
- [ ] No tokens, CLI auth output or real emails on screen (`@example.com` only)

## 2. Demo run sheet (exact prompts)

**Demo 1, Northwind (downgrade):**
1. `Hi, I want to cancel, it's too costly. priya.nair@example.com`
   Expect: 22% usage, Lumio Starter at $39, saves $60/month.
2. `Yes, please switch me to Lumio Starter.`
   Expect: "Done! You are now on Lumio Starter at $39.00/month, saving $60.00/month."
3. Show in the org: Subscription now Lumio Starter, $39, Retained; Retention Offer Accepted.

**Demo 2, Atlas Freight (strategic, escalation):** reseed first, then new session.
1. `Cancel our account. meera.iyer@example.com`
   Expect: case number, specialist will follow up.
2. Open the Case: subject "Retention escalation: Atlas Freight Holdings", High priority, full briefing and suggested next step.

**Optional 20-second add-on (guardrail):** new session, `Can I get 50% off? daniel.ortiz@example.com`. The agent offers only the policy 15% for 3 months.

Do not claim a Task is created. The agent user's license cannot create Tasks, so follow-ups are Cases and audit records.

## 3. Narration script (about 4:30, edit to your voice)

**[0:00 to 0:40, slide: problem, user, why it matters]**
"Every subscription business hears the same sentence: 'It's too expensive, I want to cancel.' The usual answer is a blanket discount. That eats margin, and it often misses the real problem: the customer is paying for more than they use. I built the Right-Size Retention Agent in Agentforce for exactly this. It serves subscription customers who are about to leave, and it helps the retention team who handle these chats by hand today. The idea is simple: right-size, don't discount."

**[0:40 to 1:40, Demo 1: Northwind in the preview chat]**
"Here is Priya from Northwind Bakery. She writes that the plan costs too much and gives her email. The agent looks up her subscription and her real usage: about 22 percent of her plan over the last three months. Instead of reaching for a discount, it recommends moving from Growth at 99 dollars to Starter at 39 dollars, saving 60 dollars a month. Every number comes from live Salesforce data and a policy check in code, not from the model's memory."

**[1:40 to 2:30, accept and show records]**
"Priya says yes. The agent applies the change and confirms it. Now look at the org: the subscription is on Starter at 39 dollars and marked Retained, and the retention offer is logged as Accepted, so every decision has an audit trail. The customer stays, the price fits their usage, and no human had to touch it."

**[2:30 to 3:10, Demo 2: Atlas Freight escalation]**
"Now a high-value case. Atlas Freight is a strategic account. The agent doesn't try to negotiate. It escalates straight away and creates a case with a full briefing: the customer, plan, price, renewal date, usage, the reason, what was said, and a suggested next step. A human can pick it up in seconds instead of re-asking everything."

**[3:10 to 4:10, configuration in Agentforce Builder]**
"Under the hood, this is an Agent Script agent with subagents, formerly called topics: verification, retention offer, cancellation request, human escalation, and off-topic. It calls five Apex actions, and the key guardrails live in code. Discounts are capped at 15 percent for three months. Strategic and high-value accounts, and repeat discounts, always escalate to a person. The agent needs an explicit yes before it changes anything, and the Apex re-checks policy on the server before applying. It can never cancel an account. It can only record a cancellation request for a human to process. Policy values sit in custom metadata, so a business user can change them without touching the agent. Everything is grounded in live CRM records."

**[4:10 to 4:50, impact slide]**
"Here is the projected impact, using stated assumptions, for a business with 500 cancellation requests a month. Handling time drops from about 15 minutes to about 2, saving roughly 76 support hours a month. If the save rate rises from 20 to 35 percent on agent-handled requests, that is about 52 more customers kept each month, around 31 thousand dollars a year in recurring revenue, and margin is protected because we right-size instead of discount. These are projections, not production results. That's the Right-Size Retention Agent. Thank you."

## 4. Impact math (so you can defend it)

Assumptions: 500 requests/month, 70% handled by the agent (350), 15 min manual vs 2 min with the agent, $50 average plan value, save rate 20% to 35%.
- Time saved: 350 x 13 min = 4,550 min, about 76 hours/month
- Extra saves: 350 x 15 points = about 52 customers/month
- Revenue: 52 x $50 = about $2.6k MRR retained per month, about $31.5k per year
All hypothetical projections. Say "projected" aloud.

## 5. LinkedIn post (public)

Customers say "it's too expensive" and cancel. Most teams answer with a discount. I wanted to test a different idea: **right-size, don't discount.**

I built the Right-Size Retention Agent with Agentforce. It checks real usage, offers a better-fitting plan when someone is under-using, uses a capped discount only when justified, and hands high-value cases to a human with a full briefing. The guardrails live in code: capped discounts, explicit customer confirmation, and the agent can never cancel an account on its own.

Projected impact (demo assumptions): about 87% faster handling and roughly 52 more customers retained per month at 500 requests/month.

Watch the 5-minute demo below. Built in a Developer Edition org with fictional data.

#AgentforceInAction #SFContest @Trailhead

Checks: post is **public**, has both hashtags, tags **@Trailhead** (select it so it links), and has the video attached.

## 6. Submission steps

1. Post on LinkedIn (public), copy the post URL.
2. Fill the official Google Form: https://docs.google.com/forms/d/e/1FAIpQLSdUbvzV9UbonaITH967HMil8OtN_UDfeGj0Fo041LDQOsmgFw/viewform?usp=sharing&ouid=102346078403322854210
3. Submit by Oct 30, keep a screenshot of the confirmation.
4. Do not enter the same video in any other contest.
