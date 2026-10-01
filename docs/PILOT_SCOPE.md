# Pilot scope v0.7 (for review, no SQL yet)

Status: **PLAN ONLY. Nothing here is approved.** This document **supersedes** the earlier MVP scope wherever they differ (notably: payments and the online gateway are now a later build). Visual version: `docs/visual/product-plan.html`.

## 1. The pilot, in the owner's words

**Lead management** (social channels, search, website) + **FANet.ae registration** + **scheduling** + **robust status reporting and communication** (WhatsApp, email). Later builds: online payments, Zoho Books and other integrations.

## 2. What changes from earlier plans

| Earlier | Now |
|---|---|
| Online payment gateway in the first release (decision 24) | **Later build.** The pilot records "fee received" by staff (POS on site or bank transfer). The fee ledger stays in the foundation so payments can be added without rebuilding |
| Paid extra classes after free trials | Later. In the pilot, when free trials run out the parent sees "Ask the coach" and the coach can invite more |
| Coaches removed from registration | **Reviewer is assignable**: Admin by default, or a coach, per club. The change is that **nobody retypes documents from WhatsApp** |
| Review-time target for documents | **No KPIs or service promises yet** |
| "Participant" underneath | **"Athlete" underneath.** On screen the sport pack says Player, Swimmer, Tennis player, Fencer; fallback "Athlete" |
| AI photo and document reading parked | **AI screening is in the pilot**, assistive only (section 4) |

## 3. Registration flow (the owner's vision)

1. **Parent uploads** all documents, shown against the checklist for their child's category.
2. **Instant checks and AI screening** tell the parent right away if something is unreadable, incomplete, expired or does not match. Only that document is affected.
3. **Reviewer** (Admin or coach) approves each document.
4. **Download one zip.** Every file is named automatically, e.g. `PlayerName-KHDA_Certificate_Season2026-27.pdf`. The naming pattern is a setting.
5. **Reviewer submits in FANet.ae** by hand (log in, upload, press Send).
6. **Reviewer clicks "Sent to FANet"** here, optionally with the FANet reference. The parent is told at once.
7. **If FANet rejects**, the reviewer records the reason against the affected document. Only that document reopens; the parent is told the exact fix.

Everyone sees the same live status: the parent (full tracker), the coach (read-only, can nudge), the manager (one queue).

### Assisted upload into FANet: later, and only with permission
Your idea of the AI filling in FANet after the coach logs in is possible in principle, but:
* FANet's **public** terms page covers only payments and privacy and says nothing about automation. That is not permission. The club's own agreement with UAE FA may say something else. **Ask UAE FA before designing this.**
* The safest shape is a helper that works **inside the coach's own logged-in browser session**, fills the form, and stops for the **coach to press Send**. We would never store FANet passwords.
* Until then the zip with correct names, plus a checklist of the values to type, removes most of the error.

## 4. AI screening: rules
* Suggests only. **A person decides.** Never auto-approves.
* Screens well: type of document, readable, both sides, expiry, name and date match, looks like the template. Cannot judge whether a document is genuine.
* Real children's ID documents wait until an AI vendor is chosen with **EU processing, no training on our data, deletion terms and a data-processing agreement**, and parents have a separate consent line for it. The pilot uses **test documents**.
* Every check records what was checked, by machine or by person, and the result.

## 5. Lead management: social, search, website
* **SEO:** each club gets a public page search engines can read (club, age groups, trial times, location).
* **SEM and social:** the ads are run elsewhere. Each campaign gets its own tagged link and landing page; the lead keeps its source; reports show which sources produce **confirmed families**.
* **Later:** send "confirmed" back to ad platforms. Never a child's details.
* Public pages need a **cookie and tracking consent** notice.
* Prospects give the seven fields only. Marketing messages go only to people who contacted the club and opted in.

## 6. Scheduling
Unchanged: drag-and-drop weekly builder over fixed blocks, groups by birth year, combined then split, publish, calendar feed, parent view.

## 7. Communication
WhatsApp and email from day one for **service messages** (confirmations, reminders, status changes, rejections). WhatsApp uses pre-approved templates. Everything goes in one communication log.

## 8. Designed now, built later: staff registration and match day
Facts reported by the owner (to verify with UAE FA): coaches and on-field staff also register on FANet.ae; a coach without authorisation cannot enter the field or dressing room; each team brings its own registered medical professional (person or company) who must be told the match details; match day also sets the kit (home or away; goalkeepers wear a different kit).

* The registration engine is built for **any person role**, so coach registration can be switched on with only a rules table for staff. See FOUNDATION_PLAN.md section 3b.
* **Whether staff registration is part of the pilot is the owner's decision** (question 8).
* Match day (fixtures, team sheet, authorisation checks, medical provider notice, kit instruction, notification lists) is not in the pilot.

## 9. Changes from the owner's answers (v0.8)

| Topic | Now |
|---|---|
| Word | **Prospect**, not lead. Stages: Enquiry, Trial booked, Trial done, Offer made, Accepted, Confirmed |
| Registration gate | Starts when the club has **offered a place and the parent has accepted**. **No fee needed first.** Confirmed = **any payment recorded** (a club can tighten this in Settings) |
| Trial allowance | Counts **attendance**. No-shows do not count when attendance is taken; when it is not, the booking counts. Extra trials: parent asks, coach approves. A **wallet ticket** scanned at the session is the planned attendance method |
| Coaches and venues | Assigned **by period** (for example 1st to 3rd week of September: Coach 3). Group default venue, override by period or session |
| Weekend matches | Not in the first schedule module. UAE FA issues fixtures before the season; import comes later |
| Age rule | Registration group = 2027 minus birth year. Play up: allowed. Play down: only September to December births of the year just before the group's year |
| Forms | Season-versioned templates (for example the UAE FA minor-player approval form), pre-filled, signed, and stamped by the club |
| Rules | Federation layer plus club add-on layer |
| Staff | Coach and staff FANet registration **is in the pilot** |
| Photos | Checked without AI first. AI changes later, as a club choice |
| Access at 18 | Parents keep access, recorded in the athlete's fresh consent |

## 10. What the official UAE FA documents changed (v0.9)
* The authoritative rules are in `docs/reference/UAEFA_OFFICIAL_2026_27.md`. The rule set now follows **UAE FA's own structure** (6 categories x player type x document), not Fursan's five columns.
* The "over 5 years / under 5 years" lists are **two routes** for Born-in-UAE and Resident minors.
* The photo, medical form, staff table, dates and fees are now known (see the reference file).
* Age rules are split into **registration** and **participation**; the earlier checker was too simple.
* **Training groups are not UAE FA teams.** Mapping is by birth year; U18/U5/U6 do not exist at UAE FA.
* **Match-day** rules (kits, match list window, numbers, host duties) are now known and still built later.

**Photo:** the pilot includes a photo helper that runs in the browser (crop to 4 x 6 cm, size, white background, sharpness checks). Background fix and club-kit overlay are later, as club choices; outside links are off by default.

## 11. Open questions
The structural questions are answered. What is left:
1. Questions for **UAE FA itself** (for the owner to put to the federation): (a) can playing in DOFA or YFL count against its A/B crossing rule; (b) may a club record FA-Net outcomes in its own software, given the undertaking; (c) is any assisted upload acceptable?
2. **Programme types** (Academy and League team): accepted as a working split unless corrected.
3. **Priorities, not questions:** photo helper, wallet ticket, AI document checks.
