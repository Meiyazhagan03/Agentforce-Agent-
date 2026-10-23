| Phase | Status | Notes |
|---|---|---|
| 0 Environment | Done | sf 2.155.7, node 24, org agentorg connected (API 68.0); `sf agent` has generate/validate/publish authoring-bundle, preview, activate, test. sourceApiVersion set to 68.0 |
| 1 Data model deployed | Done | Objects + Retention_Policy__mdt Default record verified via query (15/3/50/1000/12) and describe (5 fields); Policy Values section added to the mdt layout |
| 2 Apex actions + tests | In progress | Service, 5 actions, tests deployed and compiling. Tests blocked until the admin user has Retention_Agent_Access (custom fields have no FLS yet) |
| 3 Permission set + seed data | In progress | Retention_Agent_Access deployed; awaiting assignment to admin and agent user. Seed script not written |
| 4 Agent built (Path A/B) | | |
| 5 Testing | | |
| 6 Activation | | |
| 7 Video recorded | | |
| 8 Post + form submitted | | |
