# Decisions log and open questions

## Decided

| # | Decision | Notes |
|---|---|---|
| 1 | Multi-tenant SaaS; one org type ("Club") | Platform owner manages tenants and billing |
| 2 | **One account per club** | A person in two clubs needs a different email for each (open question 5 in the schema plan) |
| 3 | Manager and Admin are separate permission levels; a person can hold several roles | |
| 4 | **Age tiers:** under 13 no login (parent acts); 13-17 own login after verified parental consent; 18+ adult | |
| 5 | Parental consent by direct email to the parent, before the child's data is processed | Enforced in the database |
| 6 | **Turning 18: fresh consent from the player** | Grace period and parent-access rules to confirm |
| 7 | **Parent-driven child registration** | Staff-invite shortcut still to decide |
| 8 | **Platform support access** only when a club approves it: time-limited, read-only | Max 7 days proposed |
| 9 | Compliance rules: **platform templates, club can adjust** | Clubs see "template updated" prompts |
| 10 | Payments: **each club plugs in its own gateway keys** | Platform never holds the money. Gateway choice deferred |
| 11 | **Deletion:** everything deleted except **financial records, kept 1 year** from the request | Must be stated in Terms/Privacy; counsel to confirm the period |
| 12 | Parents are responsible for data their children enter | Terms clause |
| 13 | **Hosting: Supabase Frankfurt**, aiming to meet EU data-protection standards | |
| 14 | **PWA only**, no app stores | |
| 15 | **Video deferred**; photos only in v1 | |
| 16 | English first; Arabic/RTL designed in from the start | |
| 17 | No leaderboards or child-vs-child ranking | Engagement can be switched off by the parent |
| 18 | Constraints: no secrets in git (`.env.example` only), row-level security on every table, child data and consent are hard requirements | |

## Open (need your answer before SQL)
See section 8 of [SCHEMA_PLAN.md](SCHEMA_PLAN.md) (7 questions) and section 9 of [UI_UX_PLAN.md](UI_UX_PLAN.md) (5 questions). In short:
* Grace period after 18; do parents lose access at 18?
* Cooling-off window for deletion (7 days proposed)
* Admin vs Manager on medical records and HR documents
* Staff-invite shortcut for existing rosters
* One-email-per-club consequence
* Support grant limits
* Age groups: single birth year or two-year bands?
* Coach-to-player direct messaging, attendance states, rating scale wording

## Later, on purpose
Payment gateway, video, WhatsApp/SMS, ID-verification vendor, FANet.ae automation.

## For legal review
* Which law(s) govern children's data for UAE clubs hosted in the EU
* Adequacy of a 1-year financial-record retention against clubs' tax/accounting duties
* Terms and Privacy Policy wording (kept vs deleted, backups, parental responsibility)
