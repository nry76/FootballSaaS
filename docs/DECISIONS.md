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
| 16 | **English only at launch.** Arabic only in a few optional fields (e.g. name in Arabic for UAE FA); no RTL work now | |
| 19 | **Global clubs.** Currency is a club setting, **default AED**; country, time zone, tax label, weekend days and age of consent are settings too | Existing bills keep their currency if the setting changes |
| 20 | Competition templates are per league and country; UAE FA is the first | |
| 21 | **MVP = trials + UAE FA registration + scheduling**, on top of the safety foundation (tenancy, consent, roles, deletion) | Other modules wait |
| 22 | **Lifecycle:** enquiry, prospective, committed, confirmed (fee paid), registered. Prospects give only parent name/phone/WhatsApp/email and child name/date of birth/position. Documents, photo, IDs only after commitment and payment | Enforced in the database |
| 23 | Consent in two steps: trial consent (email link), then membership and registration consent (including clinic and UAE FA/FIFA sharing) | |
| 24 | **Payment, including the online gateway, is in the MVP from the start.** Staff can also record POS payments taken on site. Paying makes a child Confirmed, and also unlocks paid extra classes after the free trials | Supersedes "staff-marked first". Gateway/provider still to choose |
| 32 | **Lead management is part of the product**: pipeline, communication log, follow-up playbooks, tasks (including rare coach call tasks). Built in phases A/B/C (see LEADS_PLAN.md) | |
| 33 | **Coaches get a feed** of bookings and paid/unpaid status, by app, email digest or WhatsApp, at each coach's choice. WhatsApp alerts carry minimum information | |
| 34 | Service messages and marketing messages are separate types with separate consent; marketing only to people who contacted the club and opted in | UAE rules to be confirmed by counsel |
| 36 | **Pilot first, then approach clubs.** Nothing has been discussed with Fursan yet. Build a working pilot with sample data, then show it | Payment gateway/provider is **parked** until then; the design stays gateway-neutral (adapter), so a test-mode adapter serves the pilot |
| 37 | Campaigns go **only to people who contacted the club** (and opted in) | Confirmed |
| 38 | **Lead ownership:** default assignment rules (a setting), and any lead can be transferred easily, singly or in bulk | No new role required |
| 39 | **Everything about paid extra classes is a Setting**: price, bundles, cancellation cut-off, refund or credit, pay-at-venue, and so on. In general: club default, overridable per age group | |
| 40 | Plans are presented **visually** (web page), not only as Markdown; the repository also keeps a CLAUDE.md so work can resume locally | |
| 41 | **Focus:** the product exists to make **compliance easier for UAE football academies**. Broader class-management features (as in ClassCard) come later, not now. Aim: release before Statixa | Details of what is in the first release still to agree |
| 42 | **Foundation first.** The owner prefers one strong foundation (no two-release split) so features are added on top without rebuilding. Build in layers: foundation blocks, then features through them (FOUNDATION_PLAN.md) | Supersedes my earlier two-release suggestion. Payment timing is therefore unchanged: gateway in the first release, provider parked |
| 43 | **Multi-sport-ready underneath, football only in the product.** Sport is data (packs); a person is a "participant" in the data and "player" on screen | Football completed first; other sports not designed |
| 44 | Biggest pain to fix first: **registration status is invisible and one wrong upload restarts everything.** So: parents upload (not coaches), instant checks, per-document status, a rejection touches only that document, one live status for parent, coach and manager | |
| 45 | **Pilot scope:** lead management (social, search, website) + FANet.ae registration workflow + scheduling + robust status reporting and communication (WhatsApp, email). See PILOT_SCOPE.md | Later builds: payments, Zoho Books and other integrations |
| 46 | **Online payments and the gateway are a later build** (supersedes 24). The pilot records "fee received" by staff (POS or bank transfer). The fee ledger stays in the foundation | Paid extra classes also later |
| 47 | A person is an **athlete** underneath; the sport pack chooses the word on screen (Player, Swimmer, Tennis player, Fencer), fallback "Athlete". Likely later sports: swimming, tennis, fencing (individual sports are simpler: entries, not a team each weekend) | Supersedes "participant" |
| 48 | **No KPIs or service promises yet** (review times etc.) | |
| 49 | Registration flow: parent uploads, instant checks + AI screening, **reviewer (Admin by default, or a coach) approves**, one zip with files named automatically, reviewer submits in FANet and clicks "Sent to FANet", parent is told; FANet rejections are recorded per document and only that document reopens | Adjusts 28: reviewer is assignable; the change is that nobody retypes from WhatsApp |
| 50 | **AI screens, a person decides.** Real children's documents wait for a vetted AI vendor and a separate consent line; the pilot uses test documents | |
| 51 | **Assisted upload into FANet is later**, only inside the coach's own logged-in session with a person pressing Send, never storing FANet passwords, and only if UAE FA allows it (public FANet terms are silent) | Ask UAE FA first |
| 52 | Competitor facts re-checked from the live sites; ClassCard's pricing conflicts with the owner's scan, so the **pricing unit is still open** | See reference/COMPETITORS.md |
| 53 | **Registration applies to any person role, not only players.** Coaches and other on-field staff also register on FANet; the same engine (rules by role, documents, checks, status, zip) serves them. Whether staff registration is in the pilot is open | Owner-reported UAE FA facts, to verify |
| 54 | An **authorisation status with valid-until date** on people; coaches without it cannot enter the field or dressing room (owner-reported) | Feeds the later match-day check |
| 55 | New foundation block 13: **Outside contacts** (clinic, medical provider, ground contact): messaged by WhatsApp/email with one-time links, no login | |
| 56 | **Match day is designed now, built later**: fixtures, team sheet, authorisation checks, medical provider notice, home/away/goalkeeper kit, notification lists | Owner: "deal with this later" |
| 57 | **Word: "Prospect"** (or Trial), not "lead". Pipeline: Enquiry, Trial booked, Trial done, Offer made, Accepted, Confirmed | Supersedes the word "lead" in earlier files |
| 58 | **UAE FA registration can start before any fee is paid.** The gate for documents is: the club has **offered a place and the parent has accepted**. Confirmed = first term paid (Term 1, Terms 1+2, or the full year of 3 terms) | **Supersedes** decision 22 and hard rule 3 ("after payment") |
| 59 | **Trial allowance counts attendance.** If attendance is taken for a session, no-shows do not count. If it is not taken, the booking counts. Beyond the maximum, the parent asks and a coach approves. All of this is a setting | Owner's idea, turned into a default |
| 60 | **Wallet ticket** (Apple Wallet and Google Wallet) for trial bookings, scanned by the coach as attendance. Needs a developer account and signing certificate for Apple; designed, scheduled after the core pilot | Needs checking for cost and effort |
| 61 | **Coaches and venues are assigned by period**, not fixed to a session. A group has a default venue; a period or a single session can override it. Resolution: session > period > group default | |
| 62 | **Weekend matches are out of the first schedule module.** UAE FA issues fixtures before the season; importing them (file or website) comes later, and only if permitted | Scraping needs a permission check |
| 63 | Registration group = **2027 minus birth year**. Playing **up** is allowed. Playing **down** only for players born September to December of the year just before the group's year. Registration stays with the birth-year group | Owner-reported rule, a rule-set item |
| 64 | **Parents keep access after the athlete turns 18.** The athlete still gives fresh consent, and that consent records the parents' continued access | Keeps the athlete in control |
| 65 | **Admin can see medical records and staff documents** | |
| 66 | **Prospect deletion time is a club setting** (default 90 days). Both Admin and coach may review documents: a setting | |
| 67 | **Coach and staff FANet registration is in the pilot.** Medical staff come through a contracted company and must be pre-registered; only registered professionals can be sent to matches | Staff requirements list still needed |
| 68 | **Kits:** home and away for matches; practice kits separate; goalkeeper practice kit optional. Home kit for home matches, away kit for away, with manual override | Match day still later |
| 69 | **Forms are versioned by season** (for example the UAE FA minor-player approval form, whose footer changes). The system stores each version, pre-fills from the profile, collects signatures, and supports the club stamp | New: forms and signatures |
| 70 | **Two rule layers:** federation (from UAE FA documents) and club add-ons (club forms, utility bills, translations). Clubs differ for the same federation | See reference/CLUB_REGISTRATION_LISTS.md |
| 71 | **Photos: check without AI first; AI clothing/background changes later**, as an explicit club choice. The owner reports some clubs do this and UAE FA has accepted it; that can change | Risk: an altered photo may be rejected and restart that item |
| 72 | Lead sources on day one: Instagram, WhatsApp, website, referral, walk-in. Social channels in order: Instagram, WhatsApp, TikTok, Facebook. Ads: track only; agencies run them | |
| 73 | Product name candidates: **Athlon** or **Sportal**. No decision | Trademark and domain checks needed |
| 35 | Instagram is used to **capture** leads (link, QR, click-to-WhatsApp) at first; a two-way inbox comes later | Instagram does not allow cold DMs |
| 25 | Age groups are defined by **birth years** (name = season end year minus birth year; may span two years; custom groups like "2nd Team" allowed) | From Fursan's calendar |
| 26 | A session can serve several age groups; a player may be in several age groups and several tournaments, with one registration per tournament per season | |
| 27 | Registration document lists come from a **rules table by player category** (Local, UAE Child, UAE Born, Resident > 5, Resident < 5), not code | Fursan/UAE FA 2026/27 list transcribed under docs/reference |
| 28 | Registration is parent self-service; **coaches are not in the registration loop** | Registrar permission for Manager/Admin |
| 29 | Trial policy is a setting: 1 or 5 free trials per club/age group; more by coach invitation only | Counting rule open |
| 30 | AI features (document reading, photo enhancement) are a later phase, after legal review | Non-AI checks first |
| 31 | Medical fitness: platform emails the club's assigned clinic, which answers through a one-time link | Parent agrees first |
| 17 | No leaderboards or child-vs-child ranking | Engagement can be switched off by the parent |
| 18 | Constraints: no secrets in git (`.env.example` only), row-level security on every table, child data and consent are hard requirements | |

## Open (need your answer before SQL)
Newest list: section 10 of [MVP_PLAN.md](MVP_PLAN.md) (10 questions, starting with payment scope and how a child is placed in a registration category).

Older open items:
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
