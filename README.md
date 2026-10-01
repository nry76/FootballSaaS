# FootballSaaS

A multi-tenant SaaS platform for UAE football clubs and academies: league compliance and deadline tracking, squads and jersey numbers, scheduling and attendance, player development, safe messaging, real online payments, and child-safety and data-control features.

## Status: planning only

**No application code and no SQL exist in this repository yet.** We are agreeing the plan first; code starts only after each plan is approved.

| Document | What it is | Status |
|---|---|---|
| [docs/MVP_PLAN.md](docs/MVP_PLAN.md) | **Current focus:** trials, UAE FA registration and scheduling; lifecycle; real Fursan rules and calendar; foundation changes; open questions | Draft v0.4, awaiting review |
| [docs/START_HERE.md](docs/START_HERE.md) | **One-page summary** and a list of what is not planned yet | Read first |
| [docs/visual/product-plan.html](docs/visual/product-plan.html) | **Start here:** the plan as clickable pictures (download and open in a browser) | Draft v0.5 |
| [CLAUDE.md](CLAUDE.md) | Project brief for Claude Code, so work can resume on any machine | Living |
| [drafts/](drafts/db-v0.2-unapproved/README.md) | First SQL draft. Reference only, not approved, out of date | Parked |
| [docs/LEADS_PLAN.md](docs/LEADS_PLAN.md) | Lead management and communication: pipeline, playbooks, channels (WhatsApp, Instagram, email), coach feed, paid classes, phases, questions | Draft v0.1, awaiting review |
| [docs/reference/](docs/reference/) | Transcribed club inputs: UAE FA 2026/27 document list, Fursan weekly schedule | Reference |
| [docs/SCHEMA_PLAN.md](docs/SCHEMA_PLAN.md) | Planned database: entity diagrams, table catalogue, jersey, consent and tenant-isolation logic, roles, data lifecycle | Draft v0.2; MVP_PLAN.md overrides where they differ |
| [docs/UI_UX_PLAN.md](docs/UI_UX_PLAN.md) | Text wireframes for the four key screens plus supporting flows | Draft, awaiting review |
| [docs/TECH_STACK.md](docs/TECH_STACK.md) | Recommended stack | Draft, awaiting review |
| [docs/DECISIONS.md](docs/DECISIONS.md) | Decisions log, open questions, items for legal review | Living document |

## Working agreement
* Plans first; **no coding tasks without explicit approval**.
* Never commit secrets. Configuration goes in environment variables with a `.env.example` file.
* Row-level security on every table; under-18 data and parental consent are hard requirements.
