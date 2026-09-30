# Foundation plan v0.1 (for review, no SQL yet)

Status: **PLAN ONLY. Nothing here is approved.** Visual version: the "Foundation" tab of `docs/visual/product-plan.html`.

Goal (from the product owner): a foundation strong enough that features are added on top **without demolishing and rebuilding**, ready for other sports, football built and completed first.

## 1. Three layers

| Layer | What it is | Changes when... |
|---|---|---|
| **Sport packs** | Data that differs by sport: what a person is called, positions, age-group naming, rule sets (e.g. UAE FA 2026/27), whether shirt numbers and match sheets exist | A sport or a season changes. No code |
| **Product features** | Registration, schedule, trials and leads, payments, coach feed, later progress, messaging, photos | We add or improve a feature |
| **Foundation blocks** | The twelve shared building blocks below | Rarely. This is the part that must be right first |

## 2. The thirteen foundation blocks

| # | Block | Job | Used by |
|---|---|---|---|
| 1 | Clubs and access | Each club walled off; roles and permissions | Everything |
| 2 | People and families | Parents, children, relationships (mother, father, other) | Registration, schedule, payments, leads |
| 3 | Settings engine | Club default, override per group or session | Everything |
| 4 | Consent and data stages | What may be stored at each stage; two-step consent | Registration, leads |
| 5 | Rules engine | Requirements by the person's profile; versioned | Registration; later match-day checks |
| 6 | Documents and checks | Files, instant automatic checks, human review, expiry | Registration; later staff files |
| 7 | **Status engine** | Any process is steps with history; one truth for parent, coach and manager | Registration, leads, payments |
| 8 | Messages and log | Email, WhatsApp, in-app; everything recorded | Registration, leads, coach feed, schedule |
| 9 | Tasks | Assigned to-dos with due dates | Registration, leads |
| 10 | Scheduling engine | Weekly rules become dated sessions | Schedule, trials, coach feed |
| 11 | Ledger and payments | Charges, payments, receipts, gateway adapter | Payments, leads |
| 12 | Audit and deletion | Who did what; self-serve removal | Everything |
| 13 | Outside contacts | People and companies who are not users but must be told things or asked to act: clinics, a match-day medical provider, ground contacts. They get messages and one-time links, no login | Registration (medical fitness), match day (later) |

Blocks 7 (status engine) and 5 (rules engine) are what make new features cheap: registration, lead pipeline and payment follow-up are all "steps with history", and registration lists, match-day checks and future sports' requirements are all "rules by profile".

## 3. Multi-sport: what changes in the design

Sport is **data**, not a separate product. Do not build a "sport designer". Football screens only, for now.

| # | Change | Why |
|---|---|---|
| S1 | A `sport` on every group, competition, rule set and position list. A club offers one or more sports | A club may run football and another sport |
| S2 | Underneath, a person is an **athlete**; the screen says "player", "swimmer", "fencer", etc. from a per-sport dictionary (fallback "Athlete") | Avoids football words in the data |
| S7 | A sport pack says how people **take part**: *team picked for each fixture* (football: match sheet) or *individual entries to events* (swimming, tennis, fencing). Individual sports are simpler | Football is the hardest case, so the foundation covers the others |
| S3 | Football-only ideas become **switches on the sport pack**: shirt numbers, match sheets, fines, goalkeeper ranges | Other sports may not have them |
| S4 | "Age group" becomes a general **group** (age group, team, level, custom like "2nd Team"), still defined by birth years when it is an age group | Fits football and other sports |
| S5 | Rule sets are keyed by **sport × governing body × season** (UAE FA 2026/27 is one) | Same engine, other bodies later |
| S6 | Sports with no federation still work: the rules engine can be empty | Many academies have no compliance list |

Honest limit: only football is designed against real documents. A second sport should be tested **on paper** against a real example before we promise it.

## 3b. Staff, outside parties and match day (facts added by the owner; verify with UAE FA)

Reported by the owner, **not yet checked against UAE FA regulations**: coaches and other on-field staff must also be registered on FANet.ae; a coach without UAE FA authorisation cannot enter the field or the dressing room; each team must bring its own registered medical professional (a trained person, or their company), who must be told about each match (time, place); and match-day rules cover which kit is worn (home or away, and a different kit for goalkeepers).

| # | Change to the foundation | Why |
|---|---|---|
| S8 | **Registration applies to any person, not only athletes.** The rules engine is keyed by *person role* (athlete, coach, assistant, team manager, medical), so a coach's FANet registration uses the same documents, checks, status timeline and zip as a player's | Same machinery, no second system |
| S9 | An **authorisation status with a valid-until date** on each person (for example "authorised on FANet until 30 Jun 2027"), visible everywhere it matters | A coach without it cannot enter the field |
| S10 | **Outside contacts** (foundation block 13): a medical provider, a clinic, a ground contact. They are told things by WhatsApp or email and answer through one-time links. The clinic in the registration flow is the first user | Match-day medical cover needs it |
| S11 | The **fixture** is a first-class thing: opponent, home or away, venue, kick-off, competition, team sheet, who must be present | Everything on match day hangs off it |
| S12 | **Kits are club data**: kit sets (home, away, goalkeeper, maybe third) with colours; a fixture picks the outfield kit and the goalkeeper kit (home or away, avoiding a colour clash) | The wear-this message to parents and players |

**Match day is designed now and built later** (owner's call). It will need: a check that every listed player and staff member is authorised; the medical provider assigned and confirmed; a notification list per fixture (parents of selected players, coaches, medical provider, ground contact) with the right message for each; and the kit instruction.

## 3c. Further foundation changes from the owner's answers (v0.8)

| # | Change | Why |
|---|---|---|
| S13 | **Forms and signatures** inside the documents block: season-versioned form templates, pre-filled from the profile, parent and club signatures, club stamp, output as a PDF | The UAE FA minor-player form, club registration forms, terms and conditions |
| S14 | **Two rule layers**: federation rules (from UAE FA documents) and club add-ons. A requirement carries holder, alternatives, language, certified translation, colour, both sides, validity and issuer variants | Clubs differ for the same federation |
| S15 | **Layered defaults for coach and venue**: group default, overridden by a period, overridden by a single session. Coach assignments are dated periods, not a field on the session | Coaches and venues change by week |
| S16 | **Eligibility rules in the sport pack**: registration group by birth year; play up allowed; play down only for September to December births of the year before the group's year | Football's age rule |
| S17 | **Attendance proof**: scannable ticket (Apple Wallet / Google Wallet) issued on booking, scanned by the coach; counts toward the trial allowance | Reliable attendance |
| S18 | **Terms and fee options**: a season has terms (3 at most clubs); fee options are Term 1, Terms 1+2, or the year. Payment itself is a later build | "Confirmed = first term paid" |
| S19 | **Consent purposes** grow: club terms and waiver, media, school engagement, clinic sharing, federation sharing, AI screening. Each versioned and signed | Seen in a real club's terms |

## 4. Registration: no one in the dark, no restarts

Your pain: parents do not know where they are, cannot tell if documents are complete, and a wrong upload by a coach restarts the whole process.

| Design rule | Effect |
|---|---|
| Parent uploads directly; **coaches do not upload registration documents** | Removes the source of the wrong uploads |
| **Instant checks at upload** (format, readable, both sides present, dates, name match) | Mistakes are caught in seconds, before the club ever sees them |
| Every document has its own status: not uploaded, in review, approved, needs a new copy | Progress is never all-or-nothing |
| **A rejection touches only that document**; approved ones stay approved | No restart |
| The parent is told immediately (WhatsApp/email/in-app) with the exact fix | No waiting to find out |
| One live status timeline per registration, dated, with who did each step | Parent, coach (read-only, can nudge) and manager see the same thing |
| If UAE FA itself rejects, the reason is recorded against the affected document and only that item reopens | Federation-side rejections do not restart either |
| Review target (for example one working day) is a setting, shown to the parent | Sets expectations |

## 5. Build order (layers, not shortcuts)

1. **Foundation blocks 1-4, 12** (clubs, people, settings, consent, audit), with tests that one club can never see another's data and that a child's data is blocked until consent.
2. **Blocks 5-9** (rules, documents, status, messages, tasks) proven end to end by **registration**.
3. **Block 10** (scheduling engine) proven by the **schedule builder**.
4. **Block 11** (ledger and payments), then **trials and leads** on top.
5. Everything later (progress, messaging, photos, match-day checks, other sports) reuses the same blocks.

Each step ships something usable, but always through the blocks, never around them.

## 6. Answered
* Naming: **athlete** underneath, sport word on screen (decision 47).
* Likely later sports: swimming, tennis, fencing; individual sports are simpler.
* Review-time targets: none yet (decision 48).
* Today the club re-enters documents by hand into FANet from parents' WhatsApp messages (decision 49).

## 7. Still open
See PILOT_SCOPE.md section 8 (product name, UAE FA's stance on helper tools, ads scope, social channels, default reviewer, document naming list, what FANet shows on rejection).
