# FootballSaaS: project brief for Claude Code

Read this first. It replaces the chat history, which does not travel with the repository.

## What this is
A multi-tenant SaaS for football clubs and academies, starting with UAE clubs. First customer type: an academy like Fursan Hispania (pilot target; **not yet approached**, so nothing here is promised to anyone).
Core idea: a parent does the whole journey alone (enquiry, trial, commit and pay, documents, UAE FA registration, schedule), and coaches and managers stop answering one-to-one questions.

## Current phase: PLANNING ONLY
**Do not write SQL or application code until the product owner (the repository owner) explicitly approves the plan.** They want to review and iterate first so nothing is redone. Present plans visually (see below), not as long Markdown.

Pilot scope (see `docs/PILOT_SCOPE.md`): **lead management (social, search, website) + FANet.ae registration workflow + scheduling + robust status reporting and communication (WhatsApp, email)**, on a safe foundation (tenants, roles, consent, deletion). **Online payments, the gateway and Zoho Books are later builds**; the pilot records "fee received" by staff. Where PILOT_SCOPE.md and older plans differ, PILOT_SCOPE.md and DECISIONS.md win.

## Who you are talking to
Non-technical product owner. Prefer plain words, pictures and short answers. Ask before structural decisions. Say plainly when something is unverified. When they answer a question, record it in `docs/DECISIONS.md`.

## Where things are
| Path | What |
|---|---|
| `docs/START_HERE.md` | One-page summary, plus gaps not yet planned (import of existing students, club set-up, legal pack, WhatsApp set-up, pricing, support) |
| `docs/LEGAL_REVIEW_LIST.md` | Questions and documents for the lawyer and UAE FA (draft by Claude, unverified) |
| `docs/PILOT_SCOPE.md` | **Current scope.** Pilot pillars, FANet registration flow, AI screening rules, lead sources, what changed |
| `docs/MVP_PLAN.md` | Lifecycle, foundation changes F1-F15, registration rules, schedule builder, questions |
| `docs/LEADS_PLAN.md` | Lead pipeline, channels (WhatsApp/Instagram/email), coach feed, paid classes, phases, foundation changes F16-F23 |
| `docs/FOUNDATION_PLAN.md` | **Read this early.** The 13 shared foundation blocks, multi-sport approach, registration status design, build order |
| `docs/reference/COMPETITORS.md` | Notes on ClassCard, Statixa and FANet.ae, checked from the live sites (pricing conflict flagged) |
| `docs/SCHEMA_PLAN.md` | Earlier (v0.2) table catalogue; MVP_PLAN and LEADS_PLAN override where they differ |
| `docs/UI_UX_PLAN.md` | Earlier text wireframes (dashboard, coach view, parent home, compliance) |
| `docs/TECH_STACK.md` | Supabase (Frankfurt), Next.js, PWA only, and why |
| `docs/DECISIONS.md` | **Source of truth for what is decided and what is open** |
| `docs/reference/UAEFA_OFFICIAL_2026_27.md` | **Authoritative UAE FA rules** (registration circular, competitions circular and regulations): categories, documents, photo, medical, staff, dates, fees, fines, kits, numbers, match list, A/B teams |
| `docs/reference/FANET_UNDERTAKINGS.md` + `PCMA_FORM_2026_27.md` | FA-Net confidentiality and password rules (no third-party disclosure; we never hold credentials) and the medical form handling (clinic fills; one upload of the signed copy) |
| `docs/reference/CLUB_PRICING_2026_27.md` | How Fursan, G Reds and an Elite league squad price: terms, installments, sibling discounts, programme types, place holds |
| `docs/reference/CLUB_REGISTRATION_LISTS.md` | How four clubs list requirements, the UAE FA minor-player form, KHDA certificate, one club's T&Cs: the key finding is federation rules + club add-ons |
| `docs/reference/` | Hand transcriptions of the club's UAE FA 2026/27 document list and weekly schedule (not official) |
| `docs/visual/product-plan.html` | The visual plan (open in a browser). Kept in step with the docs |
| `docs/visual/schema-plan-v0.2.html` | Older visual schema map (v0.2, out of date on MVP points) |
| `drafts/db-v0.2-unapproved/` | First SQL draft. **Reference only, out of date, never run it** |

## Design stance
**Foundation first, no rebuilds.** Build shared blocks (tenancy, people, settings, consent, rules engine, documents, status engine, messages, tasks, scheduling engine, ledger, audit) and put features on top through them. **Sport is data, not code**: a person is an `athlete` underneath and the sport pack picks the word on screen (Player, Swimmer, Fencer...); positions, age-group naming, rule sets and switches like shirt numbers live in a sport pack. Only football is built; do not build a generic sport designer. Purpose of the product: make **compliance easy for UAE football academies**; wider class management comes later.

## Hard rules
1. Never commit secrets. Environment variables and a `.env.example` only.
2. Row-level security on every table. Every tenant-owned row has `club_id`, and child tables use composite keys `(club_id, id)` so cross-club links are impossible.
3. Under-18 data and parental consent are enforced in the database, not the UI. Prospects give only 7 fields (parent name, phone, WhatsApp, email; child name, birth date, position). Documents, photo and IDs only after the club has **offered a place and the parent has accepted** (payment is NOT needed first; Confirmed = any payment recorded; a club can tighten this in Settings). The word is **prospect**, not lead.
4. Money is stored as whole numbers of the currency's smallest unit, with a currency code on every row. Currency is a club setting (default AED).
5. Everything tunable is a **setting** with a club default, overridable per age group where it makes sense.
6. Messages are two kinds: service and marketing, with separate recorded consent. Marketing only to people who contacted the club and opted in. UAE rules need a lawyer's confirmation.
7. No leaderboards or ranking of children.
8. Deletion: remove everything except financial records, kept 1 year (must be stated in the Terms).

## Stack (agreed direction)
Supabase (Postgres with RLS, Auth, Storage, Edge Functions, Vault, pg_cron), region **Frankfurt**; Next.js + TypeScript on Vercel; Tailwind + shadcn/ui; supabase-js with generated types (no ORM for user reads); **PWA only**, no app stores; English only (Arabic only in a few optional name fields); Vitest, Playwright, pgTAP; Sentry without session replay on children's screens.

## Parked on purpose
Payment provider/gateway, match day (fixtures, kits, medical provider notices), talks with Fursan, the WhatsApp number, AI photo and document reading, video, FANet.ae automation, legal review (consent age by country, UAE marketing rules, retention period).

## Working with the visual plan
`docs/visual/product-plan.html` is a plain HTML file with a small script; open it in a browser. When plans change, update the Markdown in `docs/` first, then the HTML to match. (On claude.ai it was also published as a private artifact; the file in the repo is the durable copy.)

## Resuming locally
```
git clone https://github.com/nry76/FootballSaaS.git
cd FootballSaaS
git checkout claude/brave-planck-c47qs6   # the working branch
claude                                    # start Claude Code in this folder
```
Then ask: "Read CLAUDE.md and docs/DECISIONS.md and tell me where we are."

## Git
Work on branch `claude/brave-planck-c47qs6`. Do not open pull requests unless asked.
