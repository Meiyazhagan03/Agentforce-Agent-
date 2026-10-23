# PROJECT BRIEF: Right-Size Retention Agent (Agentforce In Action Contest)

> **For Claude Code (VS Code).** Read this whole file before doing anything. It is the single source of truth for the project: context, decisions, data model, Apex actions, agent design, activation, testing, demo and submission. Work phase by phase, keep `PROGRESS.md` updated, and ask the user before doing anything destructive or ambiguous.

---

## 0. How to use this file

1. Put this file in the project root as `PROJECT_BRIEF.md`.
2. Create a short `CLAUDE.md` in the root using the snippet in **Appendix A** (keeps context small on a Pro plan).
3. Start Claude Code and say: *"Read PROJECT_BRIEF.md fully. Summarize the plan in 10 lines, list what you need from me, then start Phase 1."*
4. After each phase: run its acceptance checks, update `PROGRESS.md`, commit to git, then run `/clear` (or `/compact`) before the next phase.

**Ground rules**
- This is a **one-person, ASAP build**. The October contest window closes **Oct 31, 2026, 11:59pm Pacific**. Target: build + test in 1 to 2 days, record and submit with buffer.
- **Never** put real customer data, real emails, real names or credentials anywhere. All data is fictional (use `@example.com`).
- **Never** store passwords or tokens in files. Log in to the org via browser only (`sf org login web`).
- **Salesforce Agentforce changes fast.** Agent Script and the `sf agent` CLI have been evolving (for example, what used to be called a *topic* is now a **subagent** as of about April 2026). Before writing agent files or CLI commands, verify against current docs or installed skills (see Section 4.4). If something in this brief conflicts with the live docs, the live docs win. Tell the user about the difference.
- If any step blocks you for more than about 30 minutes, **stop and use the fallback** noted in that phase, then tell the user.

---

## 1. Project context (carried over from the planning conversation)

**User:** an individual developer in India (Chennai) entering a Salesforce Trailhead contest. India is in the contest's eligible area. The user has an active Trailhead account and LinkedIn account (confirm in Phase 0).

**Chosen contest:** **Agentforce In Action** (sponsored by Salesforce).
- Prize: Apple Watch Ultra. 2 winners per monthly period.
- October 2026 entry period: **Oct 1 to Oct 31, 2026**, deadline **11:59pm Pacific on Oct 31**. Submit at least a day early (target Oct 30 or earlier).
- One entry per person per monthly period. Entry must be original and not submitted to any other contest. (Do **not** reuse this entry for the separate "Agentblazer Effect" contest.)

**Chosen scenario:** the **Right-Size Retention Agent**.
- **Business problem:** subscription customers cancel saying "it's too expensive." Teams usually answer with a blanket discount, which hurts margin and often misses the real cause: the customer is paying for a plan they barely use.
- **Core twist:** *right-size, don't discount.* The agent checks actual usage, offers a cheaper right-sized plan when usage is low, uses a capped discount only when justified, and escalates to a human with an AI-written briefing when the case is high-value or out of policy.
- **Target user:** a SaaS customer wanting to cancel (customer-facing agent). A support or retention team benefits.
- **Fictional company:** "Lumio Suite" (fictional demo SaaS). Do not use any real company's name or logo.

**What the agent does end to end**
1. Customer says they want to cancel because of cost.
2. Agent identifies the customer (by email, demo only) and pulls plan, price, usage and renewal date.
3. Agent finds the real reason (cost vs low usage vs missing features).
4. Agent gets a **policy-checked** offer from deterministic Apex logic (guardrails live in code, not only in the prompt).
5. Customer accepts, so the agent updates the subscription, logs the offer and creates a follow-up Task.
6. If the account is high-value, the request is out of policy, or the customer wants a human, the agent creates a Case with a briefing and hands off.
7. If the customer still wants to leave, the agent **records a cancellation request** for a human to process. The agent never cancels anything itself.

---

## 2. Contest requirements digest (must all be satisfied)

**Entry has 2 parts:** (a) a **public LinkedIn post** with the demo video, including hashtags `#AgentforceInAction` and `#SFContest` and tagging `@Trailhead`; (b) the **official submission form**:
`https://docs.google.com/forms/d/e/1FAIpQLSdUbvzV9UbonaITH967HMil8OtN_UDfeGj0Fo041LDQOsmgFw/viewform?usp=sharing&ouid=102346078403322854210`

**Video rules**
- mp4 or .mov, **5 minutes or less** (judges will not review longer videos).
- **Voiceover throughout.** Silent videos are disqualified.
- Open with the business problem, target user and why it matters.
- Run a **realistic end-to-end demo** from request to resolution.
- **Show the agent configuration** in Agentforce: topics/subagents, actions, guardrails, data grounding.
- **End with a clear value statement**, quantified where possible. Projected outcomes are weighted equally to live production results.
- No real customer data or PII visible at any point (sandbox/Developer Edition is fine and encouraged).
- All materials in English. Original content. No third-party IP.

**Judging (20% each):** Creativity & Innovation, Strength of Agent Concept, Relevance of Use Case, Impact & Outcomes, Clarity of Explanation.

---

## 3. Model strategy for Claude Code (Pro plan, use usage wisely)

Switch models with `/model` in Claude Code. If the `opusplan` option is available, it uses Opus for planning and Sonnet for execution, which fits this project well. Pro plans have tighter usage limits, so default to Sonnet and use Opus only where the task is genuinely hard.

| Task | Model | Why |
|---|---|---|
| Phase 0 planning, architecture review, final policy-logic review | **Claude Opus 5.5** (short, in plan mode) | Best reasoning for design decisions; keep sessions brief |
| Writing metadata XML (objects, fields, permission sets), Apex classes, Apex tests, seed script | **Claude Sonnet 5.5** (default) | Strong code quality at good cost |
| Writing agent definition (Agent Script / subagent instructions), debugging agent routing and action-calling problems | **Claude Sonnet 5.5**; escalate to **Opus 5.5** if stuck after 2 failed attempts | Agent debugging is the riskiest part, so spend Opus tokens here only when needed |
| Deploy-fix loops, renames, small edits, formatting, README/PROGRESS updates, listing files | **Claude Haiku 5.5** | Cheap and fast for mechanical work |
| Demo narration script, LinkedIn post, impact statement | **Claude Sonnet 5.5** | Good writing without Opus cost |

Usage tips: keep `CLAUDE.md` short, `/clear` between phases, avoid pasting huge logs (use `| tail -50`), and do not let Claude Code re-read large files repeatedly.

---

## 4. Phase 0: Environment setup

### 4.1 Manual steps the USER must do (Claude Code cannot do these)
1. Make sure you have a **Salesforce Developer Edition org with Agentforce enabled**. If not, sign up for a free Agentforce-enabled Developer Edition through Trailhead/Salesforce developer signup (verify the current signup page). Use a **fresh org with no real data**.
2. In the org: **Setup → Einstein Setup → turn on Einstein** (and generative AI features if shown). Then **Setup → Agentforce Agents → turn on Agentforce**. Names of these settings move around, so follow what the org shows.
3. Confirm you can open **Agentforce Studio / Agentforce Builder** from Setup (quick-find "Agentforce").
4. Confirm you have an active **Trailhead account** and a **LinkedIn account**.

### 4.2 Tooling check (Claude Code can run these)
```bash
node --version
sf --version            # Salesforce CLI (sf v2). If missing: npm install --global @salesforce/cli
sf plugins              # make sure agent commands exist: try `sf agent --help`
git --version
```
VS Code extensions to confirm are installed: **Salesforce Extension Pack** (and the **Agentforce DX** extension if available), plus Claude Code.

### 4.3 Project and org connection
```bash
sf project generate -n lumio-retention-agent --template standard
cd lumio-retention-agent
git init
sf org login web --alias agentorg --set-default      # user completes login in the browser
sf org display -o agentorg                            # confirm connection (do not print tokens into files)
```
- Set `sourceApiVersion` in `sfdx-project.json` to the org's current API version (check `sf org display` or `sf org list api`/docs). Do not guess an old version.
- Add a `.gitignore` entry for `.sfdx/`, `.sf/`, `node_modules/`, any `*.mp4` and `.env`.

### 4.4 Make sure Claude Code knows current Agent Script and `sf agent` syntax
Agent Script is new and Claude's built-in knowledge of it is unreliable. Do one of these (in order of preference):
1. Check whether Salesforce or community skills are installed and use them (for example Salesforce's `afv-library` skills such as `agentforce-development`, or a community "salesforce-agent-script" skill). If the user allows, install one.
2. Fetch the official docs and read them before writing any `.agent` file or CLI command:
   - Agent Script guide: `https://developer.salesforce.com/docs/ai/agentforce/guide/agent-script.html`
   - Agent Script reference and patterns: linked from that guide.
3. Run `sf agent --help` and the `--help` of each subcommand to confirm flags on the installed CLI version.

Known points (verify, they may change): the flow is `sf agent generate authoring-bundle`, then `sf agent validate authoring-bundle`, then `sf agent preview`, then `sf agent publish authoring-bundle`, then **`sf agent activate`**. **Publishing does NOT activate the agent.** Use `--json` where it helps you parse results. Agent Script is not JavaScript or Python, so do not guess syntax.

**Acceptance:** `sf org display -o agentorg` works; `sf agent --help` lists agent commands; git repo initialized; `PROGRESS.md` created.

---

## 5. Architecture overview

```
Customer chat (Agentforce preview)
        |
 Right-Size Retention Agent (Agentforce, Atlas reasoning, subagents + guardrails)
        |  calls 5 Apex actions (@InvocableMethod)
        v
 Apex action layer  --->  RetentionPolicyService (deterministic guardrails, reads Retention_Policy__mdt)
        |
        v
 Salesforce data: Account, Contact, Plan__c, Subscription__c, Usage_Record__c,
                  Retention_Offer__c, Case, Task
```
Design principle: **the LLM converses; Apex decides.** The agent can only offer what `GetRetentionOptions` returns, and `ApplyRetentionOffer` re-validates everything server-side. This is the "guardrails" story for the demo.

---

## 6. Data model

Create with source-format metadata under `force-app/main/default/` (objects, fields, tabs optional, page layouts optional). Use standard **Account**, **Contact**, **Case**, **Task**.

### 6.1 `Plan__c` (label: Plan)
| Field label | API name | Type | Notes |
|---|---|---|---|
| Plan Name | `Name` | Text(80) | standard name field |
| Monthly Price | `Monthly_Price__c` | Currency(10,2) | list price |
| Usage Limit | `Usage_Limit__c` | Number(10,0) | included usage units per month |
| Seat Limit | `Seat_Limit__c` | Number(5,0) | |
| Tier | `Tier__c` | Picklist | Starter, Growth, Pro, Enterprise |
| Tier Rank | `Tier_Rank__c` | Number(2,0) | 1=Starter, 2=Growth, 3=Pro, 4=Enterprise |
| Is Active | `Is_Active__c` | Checkbox | default true |
| Description | `Public_Description__c` | Text(255) | customer-friendly summary |

### 6.2 `Subscription__c` (label: Subscription; Name = Auto Number `SUB-{00000}`)
| Field label | API name | Type | Notes |
|---|---|---|---|
| Account | `Account__c` | Lookup(Account) | required |
| Contact | `Contact__c` | Lookup(Contact) | the customer; email used for lookup |
| Plan | `Plan__c` | Lookup(Plan__c) | |
| Status | `Status__c` | Picklist | Active, Cancel Requested, Retained, Cancelled (default Active) |
| Start Date | `Start_Date__c` | Date | |
| Renewal Date | `Renewal_Date__c` | Date | |
| Monthly Price | `Monthly_Price__c` | Currency(10,2) | what the customer pays now, after any discount |
| Discount Percent | `Discount_Percent__c` | Percent(3,0) | current discount, if any |
| Discount End Date | `Discount_End_Date__c` | Date | |
| Last Discount Date | `Last_Discount_Date__c` | Date | used for cooldown rule |
| Is Strategic | `Is_Strategic__c` | Checkbox | forces human escalation |

### 6.3 `Usage_Record__c` (label: Usage Record; Name = Auto Number `USG-{00000}`)
| Field label | API name | Type |
|---|---|---|
| Subscription | `Subscription__c` | Lookup(Subscription__c) |
| Usage Month | `Usage_Month__c` | Date (first day of month) |
| Units Used | `Units_Used__c` | Number(10,0) |
| Active Seats | `Active_Seats__c` | Number(5,0) |

### 6.4 `Retention_Offer__c` (label: Retention Offer; Name = Auto Number `RO-{00000}`)
| Field label | API name | Type | Notes |
|---|---|---|---|
| Subscription | `Subscription__c` | Lookup(Subscription__c) | |
| Reason | `Reason__c` | Picklist | Too expensive, Not using enough, Missing features, Switching to competitor, Business closing, Other |
| Customer Message | `Customer_Message__c` | Long Text Area(5000) | |
| Offer Type | `Offer_Type__c` | Picklist | Downgrade, Discount, Escalation, None |
| Proposed Plan | `Proposed_Plan__c` | Lookup(Plan__c) | |
| Discount Percent | `Discount_Percent__c` | Percent(3,0) | |
| Discount Months | `Discount_Months__c` | Number(2,0) | |
| Monthly Savings | `Monthly_Savings__c` | Currency(10,2) | |
| Status | `Status__c` | Picklist | Proposed, Accepted, Declined, Escalated |
| Case | `Case__c` | Lookup(Case) | set on escalation |
| Agent Summary | `Agent_Summary__c` | Long Text Area(5000) | |

### 6.5 Custom Metadata Type `Retention_Policy__mdt` (label: Retention Policy)
| Field | API name | Type | Default record value |
|---|---|---|---|
| Max Discount Percent | `Max_Discount_Percent__c` | Number(5,2) | 15 |
| Max Discount Months | `Max_Discount_Months__c` | Number(2,0) | 3 |
| Low Utilization Threshold Pct | `Low_Utilization_Threshold_Pct__c` | Number(5,2) | 50 |
| Escalation MRR Threshold | `Escalation_MRR_Threshold__c` | Number(10,2) | 1000 |
| Discount Cooldown Months | `Discount_Cooldown_Months__c` | Number(3,0) | 12 |

Create one record with DeveloperName **`Default`** (`force-app/main/default/customMetadata/Retention_Policy.Default.md-meta.xml`). Read it in Apex with `Retention_Policy__mdt.getInstance('Default')`.

**Acceptance (Phase 1):** `sf project deploy start -d force-app -o agentorg` succeeds; objects and fields visible in Setup → Object Manager.

---

## 7. Policy logic (deterministic, lives in Apex)

Create `RetentionPolicyService` (`with sharing`). Method `evaluate(Subscription__c sub, Decimal avgUtilPct, String reason)` returns a result object with: `offerType` (Downgrade | Discount | Escalation | None), `proposedPlanId`, `proposedPlanName`, `newMonthlyPrice`, `monthlySavings`, `discountPercent`, `discountMonths`, `requiresEscalation`, `escalationReason`, `explanation`.

**Utilization** = average `Units_Used__c` of the subscription's **latest 3** `Usage_Record__c` rows, divided by the plan's `Usage_Limit__c`, times 100. If there are no usage rows, treat utilization as unknown and escalate (do not guess).

**Rules, evaluated in this order (first match wins):**
1. `Status__c != 'Active'` returns `None` with explanation "subscription is not active."
2. `Is_Strategic__c = true` **or** `Monthly_Price__c >= Escalation_MRR_Threshold__c` returns **Escalation** ("strategic or high-value account").
3. `reason == 'Business closing'` returns `None` (no offer; agent should offer to record the cancellation request).
4. `reason` in (`Missing features`, `Switching to competitor`, `Other`) returns **Escalation** ("needs a human conversation").
5. (`reason` is `Too expensive` or `Not using enough`) **and** `avgUtilPct < Low_Utilization_Threshold_Pct__c` **and** an active plan exists with `Tier_Rank__c = current rank - 1` **and** its price is lower than the customer's current `Monthly_Price__c` returns **Downgrade** to that plan. `monthlySavings = current Monthly_Price__c - new plan price`.
6. Else if discount eligible (`Last_Discount_Date__c` is null **or** older than `Discount_Cooldown_Months__c` months) returns **Discount** with `discountPercent = Max_Discount_Percent__c`, `discountMonths = Max_Discount_Months__c`, `newMonthlyPrice = Monthly_Price__c * (1 - pct/100)`, `monthlySavings = Monthly_Price__c * pct/100`.
7. Else returns **Escalation** ("discount already used within cooldown; requires human approval").

Never exceed the policy cap anywhere, even if the caller passes bigger numbers.

---

## 8. Apex actions (invocable) spec

Create each as its own class with an `@InvocableMethod` that takes `List<Request>` and returns `List<Response>`. Use `@InvocableVariable` with clear `label`, `description` and `required` on **every** field. **The descriptions are what the LLM reads**, so write them like instructions. Use `with sharing`, bulk-safe code, no SOQL/DML in loops, and `WITH USER_MODE` or `Security.stripInaccessible` where practical.

| # | Class / method label | Inputs | Outputs | Behavior |
|---|---|---|---|---|
| 1 | `GetSubscriptionSummaryAction` "Get Customer Subscription" | `customerEmail` (String, required) | `found` (Boolean), `subscriptionId`, `customerName`, `accountName`, `planName`, `planTier`, `monthlyPrice`, `renewalDate`, `avgUtilizationPct`, `hasActiveDiscount`, `isStrategic`, `status`, `message` | Finds active-ish subscription via `Contact__r.Email` (case-insensitive). Computes utilization. If none found, `found=false` with a polite message. Return only data about that one customer. |
| 2 | `GetRetentionOptionsAction` "Get Retention Options" | `subscriptionId` (required), `reason` (String, required: one of the 6 picklist values), `customerMessage` (String) | `offerType`, `proposedPlanId`, `proposedPlanName`, `newMonthlyPrice`, `monthlySavings`, `discountPercent`, `discountMonths`, `requiresEscalation`, `escalationReason`, `explanation`, `retentionOfferId` | Calls `RetentionPolicyService.evaluate`. Inserts a `Retention_Offer__c` with Status `Proposed` (or `Escalated` if escalation) so there is an audit trail. |
| 3 | `ApplyRetentionOfferAction` "Apply Retention Offer" | `subscriptionId`, `retentionOfferId`, `customerConfirmed` (Boolean, required) | `success`, `message`, `newPlanName`, `newMonthlyPrice`, `confirmationText` | **Only** if `customerConfirmed = true`. Re-run policy server-side and compare to the stored offer. If mismatch or over cap, fail safely. Downgrade: set `Plan__c`, `Monthly_Price__c`, clear discount fields. Discount: set `Monthly_Price__c`, `Discount_Percent__c`, `Discount_End_Date__c = today + months`, `Last_Discount_Date__c = today`. Set subscription `Status__c = 'Retained'`, offer `Status__c = 'Accepted'`. Create a `Task` ("Retention offer accepted: send confirmation") on the Contact/Account. |
| 4 | `EscalateToHumanAction` "Escalate to Human Agent" | `subscriptionId`, `reason`, `conversationSummary` (String, required: 3 to 5 sentences) | `success`, `caseNumber`, `message` | Creates a `Case` (Subject "Retention escalation: <Account>", Priority High, Origin Web) linked to Account and Contact. `Description` is a briefing built in Apex: customer, plan, price, renewal date, utilization, stated reason, offer proposed (if any), the agent's `conversationSummary`, and a suggested next step. Updates the offer to `Escalated` and links the Case. |
| 5 | `RecordCancellationRequestAction` "Record Cancellation Request" | `subscriptionId`, `reason`, `customerMessage`, `customerConfirmed` (Boolean, required) | `success`, `message` | Only if confirmed. Sets subscription `Status__c = 'Cancel Requested'`, marks any open offer `Declined`, creates a `Task` for a human to process the cancellation. **Never sets Cancelled.** |

Shared helper classes: `RetentionPolicyService`, `RetentionPolicyResult` (inner or separate class), and a small `RetentionTestDataFactory` (test-only, `@IsTest`).

**Tests:** one test class per action plus policy tests. Cover every rule branch in Section 7, the "not confirmed" paths, "email not found", and "no usage rows". Target **85%+ coverage**. Run:
```bash
sf apex run test -o agentorg --code-coverage --result-format human --wait 10
```
**Acceptance (Phase 2):** all tests pass; coverage 85%+; deploy succeeds.

---

## 9. Permission set and agent user

Create permission set **`Retention_Agent_Access`** with:
- Object permissions: Read/Create/Edit on `Subscription__c`, `Retention_Offer__c`; Read on `Plan__c`, `Usage_Record__c`; Read on Account and Contact; Create/Read/Edit on Case and Task.
- Field-level read/edit access on all custom fields above (including `Retention_Offer__c` fields).
- Apex class access to all 5 action classes plus `RetentionPolicyService`.
- Custom metadata read is available to Apex automatically.

The agent runs as an **agent user**. In the org, the **Einstein Agent User** (or equivalent agent-user profile and the Agentforce agent permission sets) must be created and assigned **`Retention_Agent_Access`**. Read the current docs ("Agent User Setup") for the exact profile/permission-set names and how the `default_agent_user` is referenced in the agent definition. A very common failure is the agent user lacking access to the Apex classes or fields.

Also assign `Retention_Agent_Access` to the **user's own admin user** so they can inspect the data.

**Acceptance:** `sf org assign permset --name Retention_Agent_Access -o agentorg` succeeds for the admin user; agent user is created and has the permission set.

---

## 10. Seed data (fictional only)

Create `scripts/apex/seed-data.apex`. Make it **idempotent** (delete previous demo records by a marker like Account name suffix or a `Demo_` prefix, then recreate). Run with:
```bash
sf apex run --file scripts/apex/seed-data.apex -o agentorg
```

**Plans**
| Name | Tier | Rank | Price | Usage Limit | Seats |
|---|---|---|---|---|---|
| Lumio Starter | Starter | 1 | 39 | 1,000 | 3 |
| Lumio Growth | Growth | 2 | 99 | 5,000 | 10 |
| Lumio Pro | Pro | 3 | 249 | 20,000 | 40 |
| Lumio Enterprise | Enterprise | 4 | 1,800 | 100,000 | 500 |

**Customers** (use these exact fictional emails so the demo script works)
| Account | Contact | Email | Plan | Monthly Price | Last 3 months usage | Avg util | Strategic | Last discount | Expected agent outcome |
|---|---|---|---|---|---|---|---|---|---|
| Northwind Bakery Co | Priya Nair | `priya.nair@example.com` | Growth | 99 | 1,100 / 1,000 / 1,200 | 22% | No | none | **Downgrade** to Starter, saves $60/mo |
| Blue Harbor Logistics | Daniel Ortiz | `daniel.ortiz@example.com` | Pro | 249 | 15,200 / 15,900 / 16,000 | 78.5% | No | none | **Discount** 15% for 3 months, saves about $37.35/mo |
| Greenleaf Studios | Ananya Rao | `ananya.rao@example.com` | Pro | 224.10 (10% discount) | 17,000 / 17,400 / 17,600 | 86.7% | No | 4 months ago | **Escalation** (discount used within cooldown) |
| Atlas Freight Holdings | Meera Iyer | `meera.iyer@example.com` | Enterprise | 1,800 | 71,000 / 69,500 / 72,500 | 71% | Yes | none | **Escalation** (strategic / high-value) |
| Sunrise Cafe | Tomas Weber | `tomas.weber@example.com` | Starter | 39 | 150 / 140 / 160 | 15% | No | none | **Discount** (no cheaper plan exists) |

Usage months: the 3 months before the current month (first day of each). Subscriptions: Status `Active`, Start about 12 to 30 months ago, Renewal about 3 to 5 weeks from today (use relative dates in the script). Greenleaf's `Last_Discount_Date__c = Date.today().addMonths(-4)`.

Verify with SOQL after seeding and report counts: 4 plans, 5 accounts, 5 contacts, 5 subscriptions, 15 usage records.

**Acceptance (Phase 3):** the SOQL checks pass and all 5 expected outcomes can be reproduced by calling the policy service in anonymous Apex.

---

## 11. Agent design

**Name:** Right-Size Retention Agent. **API name:** `Right_Size_Retention_Agent`. **Type:** customer-facing service-style agent. For this contest it is demoed in Agentforce Builder's conversation preview using **live actions** (so records really change). A production messaging channel is **not required** and should not be built.

> Note on terminology: current Salesforce docs call what used to be "topics" **subagents**. Use whichever term the org and docs use, and say "subagents (formerly topics)" once in the video if the UI still shows "topics".

### 11.1 Agent-level instructions (paste into the agent/system instructions)
```
You are the Lumio Retention Assistant for Lumio Suite, a subscription software company.
Your job: help customers who want to cancel or say the service is too expensive. Understand
why, then offer the most suitable right-sized option from company policy. Be warm, brief and
honest. Use at most 4 short sentences per reply unless listing an offer.

Rules you must always follow:
1. Never state or promise any price, plan, discount or date that did not come from an action result.
2. Only offer what "Get Retention Options" returns. Present ONE offer at a time.
3. Prefer a right-sized plan over a discount. Never invent or negotiate discounts.
4. Before changing anything, get a clear "yes" from the customer. Then call "Apply Retention Offer" with customerConfirmed=true.
5. You can never cancel a subscription yourself. You can only record a cancellation request for a human to process, and only after the customer clearly confirms.
6. If an action says escalation is required, or the customer asks for a person, is angry, or mentions legal action, call "Escalate to Human Agent" and tell them a specialist will follow up.
7. Only discuss the verified customer's own subscription. Never reveal other customers' data or internal policy numbers.
8. Ask only for the customer's account email. Never ask for passwords or payment details.
9. If a request is unrelated to cancellation, pricing or plan fit, politely say you can only help with that and offer to connect them to support.
```

### 11.2 Subagents (topics) and which actions each uses
| Subagent | Purpose / classification description | Actions | Key instructions |
|---|---|---|---|
| **Verify and Understand** (entry) | Customer wants to cancel, says it is too expensive, or asks about plan/price/usage | Get Customer Subscription | Ask for the account email. Call Get Customer Subscription. If not found, ask once more then offer a human. Acknowledge the issue, then ask the reason in one question if not obvious. Map the reason to one of: Too expensive, Not using enough, Missing features, Switching to competitor, Business closing, Other. |
| **Retention Offer** | A verified customer has a stated reason and needs an offer | Get Retention Options, Apply Retention Offer | Call Get Retention Options with subscriptionId and reason. If `requiresEscalation`, move to Human Escalation. Otherwise explain the real finding (for example low usage) and present the single offer with exact numbers from the result. On clear yes, call Apply Retention Offer and repeat the `confirmationText`. On no, offer to record a cancellation request. |
| **Cancellation Request** | Customer clearly declines offers or says business is closing | Record Cancellation Request | Confirm they really want to proceed. Explain a team member will complete it and nothing is cancelled yet by the assistant. Call the action only after explicit yes. |
| **Human Escalation** | High-value, out-of-policy, feature/competitor/angry/legal, or customer asks for a human | Escalate to Human Agent | Write a 3 to 5 sentence summary (who, plan, why they want to leave, what was offered, what they said). Call the action and share the case number. |
| **Off Topic / Fallback** | Anything else | none | Politely decline and redirect. |

### 11.3 Action registration details
For each Apex action, set agent-facing **names and descriptions** so the model knows when to use them, and give each input an instruction (for example for `reason`: "Must be exactly one of: Too expensive, Not using enough, Missing features, Switching to competitor, Business closing, Other"). Mark `customerConfirmed` as **never set true unless the customer has just said yes**. Show outputs the agent may quote vs outputs it should keep internal (hide internal ids from the customer-facing text).

### 11.4 Data grounding story (for the video)
Grounded in live CRM records: subscription, plan, price, renewal date, 3-month usage trend. Offers and numbers come from Apex that reads a policy record, not from the model's memory. Every offer is logged in `Retention_Offer__c` for audit.

---

## 12. Build the agent

### Path A (preferred if it works within about 45 minutes): Agent Script via CLI
1. Read the current Agent Script docs (Section 4.4). Confirm Apex actions are referenced with the `apex://ClassName` style target (verify exact syntax).
2. Optionally bootstrap: `sf agent generate authoring-bundle ...` (check `--help`; it may accept a spec file).
3. Write the `.agent` file in the authoring bundle: config (name, description, agent user), variables if needed, the 5 subagents above, actions bound to the 5 Apex classes with input/output definitions, and the instructions from Section 11.
4. Validate, then preview with live actions (check `sf agent preview --help` for the flag):
```bash
sf agent validate authoring-bundle --api-name Right_Size_Retention_Agent -o agentorg
sf agent preview --api-name Right_Size_Retention_Agent -o agentorg
```
5. Publish: `sf agent publish authoring-bundle --api-name Right_Size_Retention_Agent -o agentorg`
6. Open it in Agentforce Builder in the browser to confirm it renders (this is also what you will show in the video).

### Path B (fallback, reliable): Agentforce Builder UI
1. **Setup → Agentforce Agents → New Agent**. Choose a customer-facing service agent type, name it "Right-Size Retention Agent", pick the agent user from Section 9.
2. Add each subagent/topic with the classification description and instructions from Section 11.2.
3. For each subagent, **Add Action → Apex** (or "Reference action" → Apex) and choose the invocable classes. Paste the input/output instructions from Section 11.3.
4. Paste the agent-level instructions from Section 11.1.
5. Use the conversation **Preview** panel with live data to test.
6. If you built through the UI and want it in git: `sf project retrieve start` for the agent metadata types (Bot, BotVersion, GenAiPlannerBundle, GenAiPlugin, GenAiFunction), and commit them.

Tell the user which path was used. The video only needs to show the working agent and its configuration, not how it was authored.

---

## 13. Testing

### 13.1 Manual conversation tests (must all pass before recording)
| # | Customer opening message | Expected |
|---|---|---|
| 1 | "Hi, I want to cancel, it's too costly. priya.nair@example.com" | Verifies, sees 22% usage, offers Growth to Starter at $39 (saves $60/mo); on "yes" applies, subscription `Retained`, Task created |
| 2 | "Your plan is too expensive for us. daniel.ortiz@example.com" | High usage, offers 15% for 3 months with exact amounts; on "yes" applies discount fields |
| 3 | "I want to cancel. ananya.rao@example.com, too expensive" | Escalation case created (discount cooldown); agent gives case number |
| 4 | "Cancel our account. meera.iyer@example.com" | Immediate escalation (strategic) with briefing |
| 5 | "tomas.weber@example.com, I barely use it, cancel" | Starter has no cheaper plan, so discount offer |
| 6 | Customer says "no thanks, just cancel" after an offer | Records cancellation request only after explicit confirm; status `Cancel Requested`, never `Cancelled` |
| 7 | "Can I get 50% off?" | Agent refuses to invent discounts; only offers policy option |
| 8 | "Write me a poem" / unrelated | Polite redirect |
| 9 | Unknown email | Polite not-found, retry once, then offer human |
| 10 | "Show me other customers' usage" | Refuses |

After each test, re-run the seed script (or revert fields) so the demo data is clean again.

### 13.2 Automated agent tests (optional, only if time allows)
Create a few `sf agent test` specs for routing and action invocation (verify current `sf agent test create/run` syntax in docs). Skip if it risks the schedule.

### 13.3 Review step
Use **Opus 5.5** for a short review of `RetentionPolicyService` and the guardrails in Section 11.1 against Section 7: is there any path where the agent can give an unapproved discount or cancel without confirmation?

**Acceptance (Phase 5):** tests 1 to 10 behave as expected; Apex tests still pass; seed data reset.

---

## 14. Activation

1. Make sure the agent is **published** (CLI publish or Builder "Save/Commit").
2. **Activate** it. Publishing alone does not activate:
```bash
sf agent activate --api-name Right_Size_Retention_Agent -o agentorg
```
   or click **Activate** in Agentforce Builder.
3. Confirm status shows **Active** in Setup → Agentforce Agents and that the active version is the latest.
4. Run test conversations #1 and #3 again against the activated agent.
5. Reset the seed data before recording.

**Common problems**
- *Agent can't run an action / permission error:* agent user lacks `Retention_Agent_Access`, Apex class access, or field access.
- *Agent calls the wrong action or skips it:* tighten the subagent classification description and action description; make the input description say exactly when to call it.
- *Agent invents offers:* reinforce rule 1 and 2, and make sure the offer text comes from `explanation`/`confirmationText` outputs.
- *Preview works but changes nothing:* you are in simulated mode; switch to live actions.
- *Activate fails:* check agent user, required fields on the agent, and `sf agent activate --help`.

---

## 15. Demo video plan (5 minutes max, narrated throughout)

**Recording tips:** use OBS Studio or another screen recorder, 1080p, export **mp4**. Use a clean browser profile with no bookmarks or personal tabs. Hide your org username/email in Setup headers (crop or blur in editing). Do not show access tokens, CLI auth output, or any real emails. Keep it under **4:50** to be safe. Speak the whole time.

**Segments (about 290 seconds total)**
| Time | Segment | On screen |
|---|---|---|
| 0:00 to 0:40 | Use case context | Slide or simple visual: problem, target user, why it matters |
| 0:40 to 1:40 | Demo 1: Northwind (downgrade) | Agentforce preview chat; customer record shows plan, usage |
| 1:40 to 2:40 | Offer accepted, records updated | Subscription now Starter $39, Retention Offer Accepted, Task created |
| 2:40 to 3:15 | Escalation: Atlas Freight | Chat, then the Case with the AI briefing |
| 3:15 to 4:15 | Agent configuration | Subagents, actions, guardrails/instructions, Apex policy and CMDT, data grounding |
| 4:15 to 4:50 | Outcomes and impact | Summary slide with numbers |

**Narration script (edit to your voice)**
> **[0:00]** "Every subscription business hears the same sentence: 'It's too expensive, I want to cancel.' The usual answer is a blanket discount, which eats margin and often misses the real problem: the customer is paying for more than they use. I built the Right-Size Retention Agent in Agentforce to fix that. It's for subscription customers who want to leave, and for the retention team who currently handle these chats by hand."
>
> **[0:40]** "Here's Priya from Northwind Bakery. She says the plan is too costly. The agent verifies her subscription and checks her actual usage: about 22 percent of her plan over the last three months. Instead of discounting, it recommends moving her from Growth at 99 dollars to Starter at 39 dollars, saving 60 dollars a month. Every number comes from live Salesforce data and a policy check, not from the model's guesswork."
>
> **[1:40]** "Priya says yes. The agent applies the change. You can see the subscription is now on Starter, the offer is logged as accepted for audit, and a follow-up task is created. The customer stays, the price fits their usage, and no human touched it."
>
> **[2:40]** "Now a high-value case: Atlas Freight is a strategic account. The agent doesn't try to negotiate. It creates a case with a full briefing: plan, usage, reason, what was said, and a suggested next step, so a human can pick up in seconds instead of re-asking everything."
>
> **[3:15]** "Under the hood: the agent has subagents for verification, offers, cancellation requests, and human escalation. It calls five Apex actions. The key guardrails live in code: discounts are capped at 15 percent for three months, strategic accounts and repeat discounts always escalate, the agent needs explicit customer confirmation before changing anything, and it can never cancel an account, only record a request for a human. Policy values sit in custom metadata, so a business user can change them without touching the agent."
>
> **[4:15]** "The impact, as a projection for a business with 500 cancellation requests a month: handling time drops from about 15 minutes to 2, saving roughly 76 support hours a month; save rate improves from 20 to a projected 35 percent on agent-handled requests, retaining about 52 extra customers a month, around 31 thousand dollars a year in recurring revenue, while protecting margin by right-sizing instead of discounting. That's the Right-Size Retention Agent. Thank you."

> The impact numbers above come from the planning spreadsheet (`Agentforce_Retention_Agent_Plan.xlsx`, Impact Calculator) and are **hypothetical projections**. Say "projected" or "estimated" aloud. Replace with the user's own numbers if they change them.

---

## 16. Impact statement (for the video end and the post)
- **Handling time:** about 15 min to about 2 min per request (about 87% faster) for agent-resolved cases.
- **Support time saved:** about 76 hours per month at 500 requests/month with 70% agent resolution.
- **Retention:** projected save rate 20% to 35% on agent-handled requests, about 52 more customers saved per month.
- **Revenue:** about $2.6k MRR retained per month, about $31.5k per year (assuming $50 average plan value).
- **Margin:** right-size-first approach avoids unnecessary discounts; discounts are capped and audited.
- All figures are **hypothetical projections** based on stated assumptions. State that clearly.

---

## 17. LinkedIn post and submission

**Post draft (edit freely, keep it public)**
> Customers say "it's too expensive" and cancel. Most teams respond with a discount. I wanted to test a different idea: **right-size, don't discount.**
>
> I built the Right-Size Retention Agent with Agentforce. It checks real usage, offers a better-fitting plan when someone is under-using, uses a capped discount only when justified, and hands high-value cases to a human with a full briefing. Guardrails live in code: capped discounts, explicit customer confirmation, and it can never cancel an account on its own.
>
> Projected impact (demo assumptions): about 87% faster handling and roughly 52 more customers retained per month at 500 requests/month.
>
> Watch the 5-minute demo below. Built in a Developer Edition org with fictional data.
>
> #AgentforceInAction #SFContest @Trailhead

Make sure the post: is **public**, includes **both hashtags**, **tags @Trailhead**, and has the **video attached or linked**. Copy the post URL.

**Submission steps**
1. Post on LinkedIn (public). Copy the link.
2. Fill out the official Google Form (link in Section 2) with the required details and the post link.
3. Submit at least a day before the deadline (Oct 31, 2026, 11:59pm Pacific). Keep a screenshot of the form confirmation.
4. Only **one** entry for October.

---

## 18. Final checklist
- [ ] Org is Developer Edition with fictional data only
- [ ] All 5 Apex actions deployed, tests pass (85%+)
- [ ] Permission set assigned (admin user and agent user)
- [ ] Seed data loads cleanly; 5 expected outcomes reproduce
- [ ] Agent built, published and **activated**
- [ ] Test conversations 1 to 10 pass
- [ ] Seed data reset before recording
- [ ] Video: mp4, 5:00 or less, narrated throughout, shows problem, end-to-end demo, config, and outcomes
- [ ] No real data, tokens, personal emails or usernames visible
- [ ] LinkedIn post public with `#AgentforceInAction`, `#SFContest`, `@Trailhead`
- [ ] Official form submitted, confirmation saved
- [ ] Not submitted to any other contest

---

## Appendix A: `CLAUDE.md` snippet (create in project root)
```md
# Lumio Retention Agent (Agentforce In Action contest)
Full plan: PROJECT_BRIEF.md (read relevant section only, do not re-read the whole file each turn).
Org alias: agentorg. Agent API name: Right_Size_Retention_Agent. Deadline: Oct 31 2026 11:59pm PT.
Rules: fictional data only (@example.com); no secrets in files; verify Agent Script/sf agent syntax
against current docs; publish != activate; guardrails live in Apex; agent never cancels, only records requests.
Models: Sonnet default; Opus only for planning/hard agent debugging; Haiku for small mechanical edits.
Update PROGRESS.md after each phase and commit.
```

## Appendix B: `PROGRESS.md` template
```md
| Phase | Status | Notes |
|---|---|---|
| 0 Environment | | |
| 1 Data model deployed | | |
| 2 Apex actions + tests | | |
| 3 Permission set + seed data | | |
| 4 Agent built (Path A/B) | | |
| 5 Testing | | |
| 6 Activation | | |
| 7 Video recorded | | |
| 8 Post + form submitted | | |
```

## Appendix C: Phase order and rough time (experienced pace)
| Phase | Work | Rough time |
|---|---|---|
| 0 | Environment, CLI, org login | 30 min |
| 1 | Objects, fields, custom metadata | 45 min |
| 2 | Apex policy + 5 actions + tests | 1.5 to 2 hr |
| 3 | Permission set, agent user, seed data | 45 min |
| 4 | Build agent (Path A, fall back to B) | 1.5 to 2.5 hr |
| 5 | Test + fix conversations | 1 to 2 hr |
| 6 | Activate, final reset | 20 min |
| 7 | Record and edit video | 1 to 1.5 hr |
| 8 | Post and submit | 20 min |

Agent testing and the video are where time usually slips, so protect time for them.
