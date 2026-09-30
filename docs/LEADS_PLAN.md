# Lead management and communication plan v0.1 (for review, no SQL yet)

Status: **PLAN ONLY. Nothing here is approved.**
Builds on [MVP_PLAN.md](MVP_PLAN.md) (lifecycle, trials, registration, schedule). Decisions are logged in [DECISIONS.md](DECISIONS.md).

---

## 1. Short answer

**Yes.** Your lifecycle (enquiry → trial → commit → pay → confirmed) is already a sales pipeline. Lead management adds three things on top: a **single communication log**, **automatic follow-up playbooks**, and **tasks** (including the rare "coach, please call this parent"). The heavy part is the communication engine, so this plan builds it in phases (section 9) and says plainly what WhatsApp, Instagram and UAE rules allow.

## 2. Vocabulary (please confirm)

| Word | Meaning here |
|---|---|
| **Lead** | A family that has enquired and has **not yet paid**. One lead = one family, possibly with several children |
| **Pipeline stage** | Where the lead is: New → Contacted → Trial booked → Trial attended → Committed → **Paid** |
| **Confirmed** | Paid. The family leaves the pipeline and becomes members; registration begins |
| **Lost** | Not going ahead, with a reason. Can be reactivated next season |
| **Nurture** | "Not now" or unresponsive. Receives gentle, capped follow-ups |

The stages map onto the player relationship in MVP_PLAN: Enquiry/Prospective = New → Trial attended; Committed; Confirmed.

---

## 3. What the channels really allow (checked today)

| Channel | What is possible | What is not | Plan |
|---|---|---|---|
| **Email** | Anything, with consent for marketing | Poor deliverability if sent from a shared domain | Day one, from the club's own domain |
| **WhatsApp** (Business Platform) | Free-form replies **within 24 hours** of the parent's last message; **pre-approved templates** any time | No free-form messages outside the 24-hour window. Every template must be approved by Meta and costs per message. [Pricing changes on 1 Oct 2026, including charges for some service messages](https://help.meetergo.com/en/integrations/automation/whatsapp-pricing) | Templates for confirmations, reminders, payment links. Parent opt-in required |
| **Instagram DMs** | Reply within 24 hours after the person messages you | [Businesses cannot send first messages](https://developers.facebook.com/documentation/business-messaging/instagram-messaging/overview); no cold outreach | **Capture** leads from Instagram (bio link, QR code, click-to-WhatsApp); reply inbox later |
| **SMS** | Reliable | UAE sender ID must be approved | Later, if needed |
| **Phone call** | Best for the last mile | Costs a person's time | A **task** for a named staff member, capped |
| **In-app** | Always | Only when they log in | Coach feed and parent home |

### UAE marketing rules: the biggest compliance risk
A vendor summary of [Cabinet Decision 56/2024](https://www.telerivet.com/blog/uae-sms-compliance-tdra-ad-prefix) says telemarketing, which **includes messages sent through social-media apps**, needs prior regulator approval, that promotional consent must be explicit, documented and not assumed from an existing relationship, that promotional sending is limited to **7 am - 9 pm UAE time**, that opt-outs must be honoured promptly, and that penalties can reach **AED 400,000**. These come from vendor blogs, not the regulation. **A lawyer must confirm them, and confirm who needs the approval: each club, or the platform.**

Design consequences, whatever the answer:
1. **Two message types, different rules.**
   * *Service messages* answer something the parent did: trial confirmation, reminders, schedule changes, payment receipt, "documents still missing".
   * *Marketing messages* try to persuade: "spaces left", "join before Friday". These need a separate, explicit, recorded opt-in per channel.
2. The platform **enforces** the rules so no club has to remember them: recorded consent with time and source, quiet hours, frequency caps, one-tap opt-out, and a suppression list.
3. **Only people who contacted the club** are ever messaged. No purchased or cold lists (see question 4).
4. **Parents are the audience, never the child.** No marketing to minors.

---

## 4. Pipeline and workflow

```
NEW ─► CONTACTED ─► TRIAL BOOKED ─► TRIAL ATTENDED ─► COMMITTED ─► PAID = CONFIRMED
 │        │              │                │                │
 └────────┴──────────────┴────────────────┴────────────────┴──► LOST (reason)   or   NURTURE (later)
```

* **Stages move by themselves** when the parent acts: books a trial (Trial booked), the coach marks attendance (Trial attended), the parent taps Join (Committed), a payment succeeds (Confirmed). Staff can also move them by hand.
* **Every lead has an owner** (a staff member), a **next action and date**, and a **source**. Anything overdue is shown at the top.
* **Response time is tracked** ("first reply in 12 minutes"). Speed of reply is the best predictor of conversion.

### Playbooks: automatic follow-up (examples, all editable)

| Trigger | Steps | Stops when |
|---|---|---|
| New enquiry | Instantly: confirmation with trial times (email + WhatsApp). Day 2, no booking: reminder. Day 5: second reminder. Day 7: task for staff to call. Day 14: move to Nurture | They book, reply, opt out, or convert |
| Trial booked | 24 h and 2 h before: reminder with location. After: "how was it?" plus next step | They attend or cancel |
| Trial attended | Same day: thank you + offer/fee. Day 3 no decision: nudge. Day 6: **call task for the coach** (rare, capped) | Committed, or lost |
| Free allowance used up | "Book and pay for another class" with a payment link | They book |
| Committed, unpaid | Payment link, reminders, place released after N days | Paid |
| Confirmed | Switches to the registration checklist reminders (MVP_PLAN section 7) | Registered |
| Lost | Ask the reason (one tap). Reactivation next season | |

Playbooks are lists of *wait, then send template X on channel Y, or create task Z*. They are not a programming tool; the manager edits times and wording.

### Coach calls are the exception
* A call task shows: parent first name and phone, child age group, what happened in the trial, the coach's own trial notes, and a short prompt list. Outcome buttons: *Reached / No answer / Booked / Not interested*, plus a note.
* Limits: one call task per lead per stage, a weekly cap per coach, and never for leads who opted out of calls. Coaches see phone numbers **only for their own open tasks**.

---

## 5. Coaches stay informed without asking

You said the point of the software is communication. The coach gets a **Coach feed**: an ordered log of what happened, always in the app, optionally pushed out.

| Event | Example line | Where it shows |
|---|---|---|
| Booking | "Omar (age 9) booked Thursday U10, free trial 1 of 1" | Feed |
| Paid class | "Yousef booked Thursday U10 extra class: **paid** ✓" or "**unpaid** ✗ (pay-link sent)" | Feed + roster |
| Payment arrives | "Yousef's payment received" | Feed |
| Cancel / no-show | "Adam cancelled Thursday U10" | Feed |
| First-time trialist | "New trialist tonight: Omar, forward" | Pre-session note |
| Allowance used up | "Omar has used his free trials. Invite more?" | Feed with one-tap invite |
| Task assigned | "Please call Mr Ahmed about Omar" | Feed + task list |

* **Pre-session roster:** "Thu 5:00 U10 · 14 members going · 3 trialists (1 free, 1 paid ✓, 1 unpaid ✗)".
* **Delivery per coach, their choice:** instant, a digest before each session, or off; on WhatsApp, email or app.
* **WhatsApp alerts carry the minimum:** first name, class, paid/unpaid. No phone numbers, no documents, no notes.
* Everything sent is written to the same log, so "did the coach know?" always has an answer.

---

## 6. Paid classes and payment (now in the MVP, with the gateway)

* **Every booking is one thing**, whatever it is: a member's regular session, a free trial, a **paid extra class**, or a coach-invited free extra. It has a price (possibly zero), a charge, and a payment state. This replaces the separate "trial booking" idea in MVP_PLAN.
* **Prices are settings** per session type and age group. Optional bundles ("5 classes") come later.
* **Ways to pay:** online by card/wallet through the club's gateway; a **payment link** the parent opens from WhatsApp or email (this matters most for conversion); or at the venue, where staff record a **POS payment** with the terminal reference. Online and POS payments appear in one list per child, so the coach and the manager see one truth.
* **Gateway** (decision needed, question 1): each club uses its own merchant account (already decided), behind a common adapter, so switching gateway means a new adapter, not a redesign. Keys sit in a secrets vault, never in tables.
* **Receipts and tax:** a receipt for every payment; VAT invoices if the club is VAT-registered (a club setting; rate and label already planned).
* **Cancelling:** cancelling early gives the allowance or money back; the cut-off time is a setting (question 7).

---

## 7. Data model additions (plain language)

| Area | New tables | Purpose |
|---|---|---|
| Leads | `leads` (family: contact details, source, owner, stage, next action, lost reason); children stay as `players` in the enquiry/prospective state; `lead_stage_history` | The pipeline |
| Attribution | `lead_sources`, `landing_forms` (a public enquiry link or QR code per source/campaign) | "Which Instagram post brought the family?" |
| Communication | `communications` (immutable log of every message, call and note: channel, direction, service or marketing, template, status sent/delivered/read/failed/replied, who); replaces the earlier notifications outbox as the single source | One timeline per lead and per coach |
| Templates | `message_templates` (channel, purpose, language, WhatsApp approval status, variables) | Pre-approved wording |
| Consent | `channel_consents` (per person, per channel, per purpose: service or marketing; when, how, proof) and `suppressions` (opt-outs, kept as a scrambled hash so they still work after deletion) | Lawful sending |
| Automation | `playbooks`, `playbook_steps`, `playbook_runs` (where each lead is in a playbook, next step time, stop reason) | Follow-up |
| Campaigns (phase B) | `segments`, `campaigns`, `campaign_recipients` | Broadcasts to opted-in people |
| Tasks | `tasks` (assignee, due date, reason, outcome; for calls, follow-ups, clinic chasing) | Human steps |
| Coach feed | `feed_events`, `notification_prefs` | Section 5 |
| Channels | `channel_accounts` (club's WhatsApp number, Instagram account, sender name, email domain; secrets in a vault) | Where messages leave from |
| Bookings | `session_bookings` (type, price, charge link, state) replacing `trial_bookings`; `payment_links` | Section 6 |

**Access:** Manager/Admin see all leads and the whole log. A coach sees the trialists of their own age-group sessions, first names and paid state only, and a lead's phone only through an open task assigned to them. Row-level security and the club wall apply as before.

**Data rules:** the "very little first" rule holds (lead record = the seven fields). Staff-entered leads (from a phone call or an Instagram DM) can receive only **replies and service messages** until the parent opts in to marketing. Leads with no activity for 90 days are deleted; only the scrambled opt-out record is kept.

---

## 8. Sketches

**Pipeline board (manager, desktop)**
```
+------------------------------------------------------------------------------------------+
| Leads   [+ New lead]  Source [All v]  Age group [All v]  Owner [All v]                   |
+----------+-----------+-------------+-------------+------------+----------------------+
| NEW  6   | CONTACTED | TRIAL BOOKED| ATTENDED  5 | COMMITTED 3| PAID this month  14  |
|          |    9      |     7       |             |            |                      |
| Omar A.  | Yousef N. | Adam R.     | Khalid F.   | Hamdan K.  |  (conversion 31%)   |
| U10 IG   | U11 WA    | U9  Thu 5pm | U12 free 1/1| U13 unpaid |                      |
| 12 min ! | 2d        | paid ✓      | call task   | link sent  |                      |
| Zayed F. |    ...    |     ...     |     ...     |    ...     |                      |
+----------+-----------+-------------+-------------+------------+----------------------+
| Overdue follow-ups (4)  · Median first reply 22 min  · Best source: Instagram (41%)      |
+------------------------------------------------------------------------------------------+
```

**One lead, one timeline**
```
+----------------------------------------------------------------+
| Omar A. · U10 · Forward · Instagram · Owner: Sara   Stage: Trial booked |
| Parent: Mr Ahmed  +971 5x xxx xxxx   WhatsApp ✓ (service)  Email ✓      |
+----------------------------------------------------------------+
| Next: call after trial (Coach Hamad)       due Thu 6:30 pm      |
| ---------------------------------------------------------------|
| Tue 09:12  Enquiry received from Instagram bio link             |
| Tue 09:12  Email sent: "Your trial request" (delivered)         |
| Tue 09:13  WhatsApp sent: trial times (read)                    |
| Tue 18:40  Parent booked Thu 5:00 U10 (free 1 of 1)             |
| Wed 17:00  WhatsApp reminder (delivered)                        |
| [ Add note ] [ Send a message v ] [ Create task ] [ Mark lost ] |
+----------------------------------------------------------------+
```

**Coach feed (phone)**
```
+--------------------------------+
| Tonight · Thu 5:00 U10         |
| 14 members going · 3 trialists |
|  Omar   free trial 1 of 1      |
|  Yousef extra class  paid ✓    |
|  Adam   extra class  unpaid ✗  |
+--------------------------------+
| Feed                           |
| 16:02 Yousef paid              |
| 15:40 Adam booked (unpaid)     |
| 12:10 Please call Mr Ahmed     |
|        about Omar  [Open task] |
| Alerts: WhatsApp · digest 4 pm |
+--------------------------------+
```

---

## 9. Phases (so nothing is redone)

| Phase | Adds | Why this order |
|---|---|---|
| **A: in the MVP** | Enquiry links/QR with source tracking; pipeline and manual moves; automatic stage moves; the communication log; email and in-app messages; WhatsApp **service** templates; tasks including coach call tasks; the coach feed and pre-session roster; paid and free bookings; online payment, payment links and POS recording; basic funnel numbers | It carries the whole parent journey and the communication you described |
| **B** | Playbooks that run by themselves; WhatsApp and email **marketing** campaigns to opted-in people; segments; quiet-hours and frequency engine; campaign reports | Needs the consent and approval work to be settled first |
| **C** | Two-way inbox for WhatsApp and Instagram replies; click-to-WhatsApp and Instagram lead-form capture; smart reply suggestions (AI; only after legal review) | Largest and riskiest |

Foundation rule: phase A already creates the **log, consent records, templates, tasks and channel accounts**, so B and C only add screens and rules, not new foundations.

## 10. Foundation changes this adds (continuing MVP_PLAN F1-F15)

| # | Change |
|---|---|
| F16 | A **lead** is a family-level record above the children, with owner, source and stage history |
| F17 | One **communication log** for everything (lead messages, reminders, coach alerts). It replaces the plain notification outbox |
| F18 | **Consent per channel and per purpose** (service vs marketing), with proof, plus a suppression list that survives deletion |
| F19 | **One booking concept** (member session, free trial, paid extra, invited extra) with price and payment state; supersedes trial bookings |
| F20 | **Payment gateway adapter, payment links and POS recording** are part of the first release |
| F21 | **Tasks** are a core concept (call parent, review document, chase clinic) |
| F22 | **Channel accounts** per club (WhatsApp, Instagram, email domain) with secrets in a vault |
| F23 | **Attribution** (source, campaign, form) on every lead |

## 11. Questions (most important first)

1. **Gateway.** Fursan uses a POS on site today: which bank or provider, and do they offer an online gateway with similar fees? Does the club hold the trade licence and bank account needed to open a merchant account? This picks our first adapter.
2. **Terms.** Are "lead" (anyone who has not paid) and the six stages right? Is there a name you already use?
3. **WhatsApp.** Which number would the club use for the platform, and are they happy to route notifications through the official WhatsApp Business Platform (templates, per-message cost)?
4. **Marketing scope.** Confirm the assumption: campaigns go **only to people who contacted the club and opted in**, never to bought lists. And who will take responsibility for the UAE regulator approval question with a lawyer?
5. **Who owns leads.** Manager, Admin, or a dedicated registration/sales person (which would be a new role)?
6. **Coach alerts.** Default channel and what may appear in a WhatsApp alert (first name, class, paid status: OK)?
7. **Paid extra classes.** Price per class or per age group? Any 5-class pass? Cancellation cut-off (for example 12 hours) and refund or credit?
8. **Instagram.** Capture only (link in bio, QR code, click-to-WhatsApp) at first, replies later?
9. **Sources.** Which sources should be on the enquiry list on day one (Instagram, WhatsApp, website, referral, walk-in, school event, other)?
