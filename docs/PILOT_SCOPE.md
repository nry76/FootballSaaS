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

## 8. Open questions
1. Working name: is "SportPortal" the product name?
2. Does UAE FA allow a helper tool for FANet, or offer any official upload?
3. Should we only capture and track leads from ads you run elsewhere (recommended), or also create and manage ads?
4. Which social channels first?
5. Default reviewer: Admin or coach?
6. Is there a fixed list of document names UAE FA expects?
7. What does FANet show when it rejects an application?
