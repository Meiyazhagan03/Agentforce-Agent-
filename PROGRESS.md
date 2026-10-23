| Phase | Status | Notes |
|---|---|---|
| 0 Environment | Done | sf 2.155.7, node 24, org agentorg connected (API 68.0); `sf agent` has generate/validate/publish authoring-bundle, preview, activate, test. sourceApiVersion set to 68.0 |
| 1 Data model deployed | Done | Objects + Retention_Policy__mdt Default record verified via query (15/3/50/1000/12) and describe (5 fields); Policy Values section added to the mdt layout |
| 2 Apex actions + tests | Done | 35/35 tests pass, org-wide coverage 98% (every class 96%+) |
| 3 Permission set + seed data | Done | Retention_Agent_Access assigned to admin (agent user assignment by user). scripts/apex/seed-data.apex run: 4 plans/5 accounts/5 contacts/5 subs/15 usage. All 5 outcomes verified with scripts/apex/verify-outcomes.apex. Re-run verified idempotent (same counts and outcomes). PermissionSetAssignment confirmed for admin and retention.agent.2026@agentforce.com |
| 4 Agent built (Path A/B) | In progress (Path A) | Authoring bundle Right_Size_Retention_Agent written; sf agent validate passes (0 errors). Preview/tests next. Not published, not activated |
| 5 Testing | | |
| 6 Activation | | |
| 7 Video recorded | | |
| 8 Post + form submitted | | |
