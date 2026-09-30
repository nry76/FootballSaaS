# FootballSaaS

A multi-tenant SaaS platform for UAE football clubs and academies: league compliance and deadline tracking, squads and jersey numbers, scheduling and attendance, player development, safe messaging, real online payments, and child-safety and data-control features.

## Status: planning only

**No application code and no SQL exist in this repository yet.** We are agreeing the plan first; code starts only after each plan is approved.

| Document | What it is | Status |
|---|---|---|
| [docs/SCHEMA_PLAN.md](docs/SCHEMA_PLAN.md) | Planned database: entity diagrams, table catalogue, jersey, consent and tenant-isolation logic, roles, data lifecycle | Draft, awaiting review |
| [docs/UI_UX_PLAN.md](docs/UI_UX_PLAN.md) | Text wireframes for the four key screens plus supporting flows | Draft, awaiting review |
| [docs/TECH_STACK.md](docs/TECH_STACK.md) | Recommended stack | Draft, awaiting review |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Decisions log, open questions, items for legal review | Living document |

## Working agreement
* Plans first; **no coding tasks without explicit approval**.
* Never commit secrets. Configuration goes in environment variables with a `.env.example` file.
* Row-level security on every table; under-18 data and parental consent are hard requirements.
