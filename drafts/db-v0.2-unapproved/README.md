# DRAFT SQL, NOT APPROVED, OUT OF DATE

This is the first database draft, written **before** the plans were agreed. It is kept only as reference so nothing is lost.

* **Do not run it in a real project.** It predates the MVP plan (trials, registration rules, lead management, age groups, bookings) and the plan says several tables will change.
* It was written to the v0.2 schema plan: tenant walls, row-level security on every table, the parental-consent gate, jersey-number rules.
* Checked once against PostgreSQL 16 with stand-in Supabase pieces (`test-stubs.sql`: fake `auth`, `storage` and roles). Files `00` to `14` loaded without errors. `15_seed.sql` had one fix applied and was not re-confirmed.
* Real SQL starts only after the plans are approved. See `docs/DECISIONS.md` and `docs/MVP_PLAN.md`.
