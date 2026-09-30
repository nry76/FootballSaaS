# UI/UX plan (v0.1, for review, sketches in text only)

Status: **PLAN ONLY. Nothing here is approved.** Clickable HTML mockups come only after you approve these layouts.
All names, dates and amounts below are **sample data**.

---

## 1. Who uses what, on which device

| Role | Main device | Home screen | Emphasis |
|---|---|---|---|
| Manager / Admin | Laptop or desktop | Dashboard ("what needs attention") | Money at risk, deadlines, approvals |
| Coach | Phone or tablet at the pitch, sometimes laptop | Squad view | Fast attendance, quick ratings, numbers |
| Parent | **Phone (PWA)** | Family home | Next session, what's due, drills |
| Player 13-17 | Phone (PWA) | Player home | Schedule, drills, own progress. No fees |
| Player 18+ | Phone (PWA) | Player home | As above plus own fees and consent |
| Platform owner / support | Laptop | Tenant admin | Separate area, never mixed with club screens |

## 2. Principles

1. **"What needs my attention?" first.** Dashboards lead with problems and deadlines, not charts.
2. **Money at risk is always visible, in the club's currency** (sketches show AED, the default), wherever a fine could happen. It makes compliance feel real.
3. **Phone-first for families and coaches; desktop-first for Manager/Admin.**
4. **Calm for children.** No rankings, no "you're behind X", no red for kids' progress. Streaks are weekly and forgiving. A parent can switch engagement features off.
5. **English only at launch, built for the world.** Currency, dates, time zone and weekend days follow the club's settings. Arabic is limited to a few optional fields (e.g. a player's or coach's name in Arabic when the league requires it). Text lives in one translation file so more languages can be added later; no right-to-left layout work now.
6. **Always show the reason.** A blocked action says why and what fixes it ("2 players are missing Emirates ID").
7. **PWA:** installable from the browser, no App Store. Works on poor pitch-side signal for marking attendance (queued and synced). Push notifications are best-effort on iPhone (they need "Add to Home Screen").
8. **Accessibility:** readable contrast, large touch targets (44px), never colour alone (icons and text labels too).

## 3. Navigation per role

```
Manager/Admin (left sidebar)          Coach (bottom tabs on phone)
  Dashboard                             Today
  Compliance                            Squads
  Squads & Players                      Schedule
  Schedule                              Messages
  Fees & Payments                       Drills
  Messages (reports)*
  Media
  Staff & Documents
  Reports
  Settings*   (* Manager only)

Parent / Player (bottom tabs)
  Home | Schedule | Drills | Messages | Fees**   (** parents and adult players only)
```

---

## 4. The four key screens

_Amounts in the sketches are in AED, the default currency; they follow each club's currency setting._

### 4.1 Manager / Admin dashboard (desktop)

Purpose: in ten seconds, see what will cost money or block a match this week.

```
+--------------------------------------------------------------------------------------+
| PASS Abu Dhabi        Season 2026/27 [v]                   (3)              Sara [v]  |
+--------------+-----------------------------------------------------------------------+
| > Dashboard  |  This week                                                            |
|   Compliance |  +--------------+ +--------------+ +--------------+ +----------------+ |
|   Squads     |  | FINES AT RISK| | NEXT DEADLINE| | FEES OVERDUE | | WAITING FOR YOU| |
|   Schedule   |  | AED 4,000    | | Squad list   | | AED 8,400    | | 4 approvals    | |
|   Fees       |  | 2 matches    | | in 3 days    | | 7 players    | | 2 ID checks    | |
|   Messages*  |  | [Review]     | | [Open]       | | [Send remind]| | 2 consents     | |
|   Media      |  +--------------+ +--------------+ +--------------+ +----------------+ |
|   Staff      |                                                                       |
|   Reports    |  Needs attention                              Fee collection (Oct)    |
|   Settings*  |  ---------------------------------------      ----------------------- |
|              |  [!] U12 A Sat match: 9 of 11 players          Collected  72%         |
|              |      on the sheet.  Fine risk AED 2,000        [#########-----]        |
|              |                                  [Fix]          Paid      86 players  |
|              |  [!] U10 B Sat match: no medical staff         Due       19           |
|              |      listed.        Fine risk AED 2,000        Overdue    7           |
|              |                                  [Fix]          Waived     3           |
|              |  [ ] League squad-list deadline in 3 days      [View all fees]        |
|              |      2 of 9 squads incomplete       [Open]                            |
|              |  [ ] 3 staff/player documents expire in        Attendance trend       |
|              |      30 days                        [View]     U10 ~~~~/~~  81%       |
|              |  [ ] 1 message report awaiting review*         U12 ~~\~~~~  74%       |
|              |                                     [Review]   U14 ~~~~~~~  88%       |
|              |                                                                       |
|              |  Coming up (7 days)                                                   |
|              |  Thu 17:30 U10 A training | Fri 14:00 match-sheet deadline | Sat 16:00 |
|              |  U12 A vs Al Wasl | Sat 18:00 U10 B vs Zayed                          |
+--------------+-----------------------------------------------------------------------+
```

Notes
* The four cards are clickable filters. "Needs attention" is sorted by **money at risk, then time left**.
* Every row has one primary button that goes straight to the fixing screen.
* Admin sees the same screen without the Manager-only items (marked `*`).
* Empty state: "Nothing needs attention. Next league deadline: 14 Oct."

---

### 4.2 Coach squad view

One squad, three tabs. Phone layout stacks; the sketch is tablet/desktop.

#### 4.2a Attendance tab (default: today's session pinned at top)

```
+--------------------------------------------------------------------------------------+
| U12 A  [v]      Attendance | Ratings | Numbers                        Thu 17:30 train |
+--------------------------------------------------------------------------------------+
| Today, Zayed Sports City       Going 14  Can't 2  No reply 3      [Mark all present] |
| ------------------------------------------------------------------------------------ |
|  Player            #    RSVP        Today                     Last 5 sessions        |
|  Omar Al-Hashmi    7    Going       (P) (L) (A) (E)           o o o - o   4/5        |
|  Khalid Nasser     10   Going       (P) (L) (A) (E)           o o o o o   5/5        |
|  Zayed Farooq      1 GK No reply    (P) (L) (A) (E)           o - o o -   3/5        |
|  Adam R. (up)      7    Can't       (P) (L) (A) (E)           o o - - o   3/5        |
|  ...                                                                                 |
|  (P)=present (L)=late (A)=absent (E)=excused     Auto-saves. Works offline, syncs.   |
|                                                                                      |
|  (up) = playing up from U11. Shows the squad(s) each player is in.                   |
+--------------------------------------------------------------------------------------+
```

* Tap once to mark; state shown by icon **and** text.
* Players whose consent is pending do not appear at all (the system is not allowed to hold their data yet).
* Long-press a player to open their profile, rate, or message their parent.

#### 4.2b Ratings tab

```
+--------------------------------------------------------------------------------------+
| U12 A [v]      Attendance | Ratings | Numbers                                          |
+---------------------------+----------------------------------------------------------+
| Players                   |  Omar Al-Hashmi              Last rated 12 days ago      |
| > Omar Al-Hashmi          |                                                          |
|   Khalid Nasser           |  New rating, Thu 17 Oct                                  |
|   Zayed Farooq            |  Technical            1 2 [3] 4 5    trend: up           |
|   Adam R.                 |  Physical             1 2 3 [4] 5    trend: steady       |
|   ...                     |  Tactical             1 2 [3] 4 5    trend: up           |
|                           |  Decision-making      1 [2] 3 4 5    trend: steady       |
|  Filter: not rated in     |  Personality/         1 2 3 4 [5]    trend: steady       |
|  30 days (6)              |  creativity                                              |
|                           |  Note (shared with Omar and his parents)                 |
|                           |  [ Great first touch this week. Work on scanning...   ]  |
|                           |  [Save rating]   [Assign a drill for Decision-making]    |
|                           |                                                          |
|                           |  Progress over time: small line per pillar (last 6)      |
+---------------------------+----------------------------------------------------------+
```

* Notes are visible to the player and parents, so the wording prompt reads "Shared with Omar and his parents".
* "Assign a drill" opens the drill library pre-filtered to the weakest pillar.
* The progress chart compares a child only with **their own past**, never with others.

#### 4.2c Numbers tab (jersey numbers)

```
+--------------------------------------------------------------------------------------+
| U12 A [v]      Attendance | Ratings | Numbers                Season 2026/27  [Lock kit]|
+--------------------------------------------------------------------------------------+
|   1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 ...                     |
|  GK  .  .  .  .  .  Om  .  .  Kh  .  GK GK  .  .  .  .  .  .  .                     |
|  Legend: name = taken here | . = free | GK = goalkeeper-only | X = retired            |
|          * = also worn in another squad (same player, one kit)                        |
| ------------------------------------------------------------------------------------ |
|  Players without a number (2)         Number conflicts / extra kits (1)              |
|  Zayed Farooq       [Choose]           Adam R.: #7 in U11, #14 in U12                 |
|  Yousef Amin        [Choose]           reason: "#7 taken in U12"      [Review]        |
+--------------------------------------------------------------------------------------+
```

Playing up/down uses the same picker as the family flow (section 5.2): it shows only numbers free in **both** squads.

---

### 4.3 Player / Parent home (phone, PWA)

Parent view. A player 13-17 sees the same screen without the Fees card and with their own name in the header.

```
+--------------------------------+
| Omar (U11) [v]                 |
+--------------------------------+
| NEXT UP                        |
| Tomorrow, 5:30 pm  Training    |
| Zayed Sports City              |
| [ Going ]  [ Can't go ]        |
|  Reply by 3:00 pm              |
+--------------------------------+
| THIS WEEK                      |
| Thu  Training      Going       |
| Sat  Match vs Al Wasl 4:00 pm  |
|      RSVP needed  [Reply]      |
+--------------------------------+
| FEES                           |
| Academy term 1       AED 450   |
| Due 15 Oct     [ DUE ]         |
| [ Pay now: card / Apple Pay ]  |
+--------------------------------+
| DRILLS FOR OMAR                |
| Wall passing, 10 min           |
|   Done this week: 1 of 2       |
|   [Log it]                     |
| Weak foot dribbling            |
|   [Log it]                     |
+--------------------------------+
| SEASON SO FAR                  |
| Sessions: 9 of 11              |
| 4 weeks in a row               |
| Best wall-pass score: 32       |
+--------------------------------+
| Jersey: #7  (U11 and U12)      |
+--------------------------------+
| Home  Sched  Drills  Msgs  Fees|
+--------------------------------+
```

Behaviour notes
* **Consent banner** replaces everything when consent is pending: "We've emailed the parent at s***@mail.com. Omar's profile is switched on once it's confirmed."
* **Fee status chips:** `PAID`, `DUE`, `OVERDUE`, `WAIVED`, with the word and an icon, not just a colour.
* **Season block** is only about the child's own progress. A parent can switch it off (Settings > Child > Progress badges).
* **Player 13-17** view: no Fees tab; Messages shows a line "Your parent can see this conversation".
* **Parent with two children:** the child switcher at the top; a small badge shows anything needing action for the other child.
* **Report** button is on every message: "Not comfortable with this message?".

---

### 4.4 Compliance checklist screen (per match)

Purpose: the pre-matchday gate. This is what saves the AED 10,000 / 2,000 / 1,000 fines.

```
+--------------------------------------------------------------------------------------+
| < Compliance                                                                         |
| U12 A vs Al Wasl    Sat 19 Oct, 4:00 pm          Match sheet due: Fri 14:00 (1d 4h)   |
| STATUS: BLOCKED (2 blocking items failing)                          [ Re-check now ] |
+---------------------------------------------------------------+----------------------+
| Checklist                                                     | If not fixed         |
| ------------------------------------------------------------- | -------------------- |
| [FAIL] Squad complete: 9 of 11 players on sheet          [v]  | Incomplete squad     |
|         Need 2 more.  Available in squad: Adam R., Hamdan K.  |  2 x AED 1,000       |
|         [Add to match sheet]                                  |  = AED 2,000         |
|                                                               |                      |
| [FAIL] Medical staff listed on sheet                     [v]  | Missing medical      |
|         None listed.  Club medical staff: Dr. Layla M.        |  AED 2,000           |
|         [Add Dr. Layla M.]                                    |                      |
|                                                               | -------------------- |
| [FAIL] Player documents on file (Emirates ID + photo)    [v]  | TOTAL AT RISK        |
|         2 players missing: Hamdan K. (ID), Adam R. (photo)    |  AED 4,000           |
|         [Request from parent]                                 |                      |
|                                                               | Cancelling this      |
| [PASS] Coach licence valid for listed staff                   | match instead: AED   |
| [ .. ] Kit and equipment confirmed (manual)   [ Mark done ]   | 10,000               |
|                                                               |                      |
| [ Mark ready to submit ]  (enabled when all blocking pass)    |                      |
+---------------------------------------------------------------+----------------------+
| Alerts for this match: 3 days, 1 day, 3 hours before deadline   [Change]             |
+--------------------------------------------------------------------------------------+
```

Companion view: **Deadline calendar** (list or month)

```
+--------------------------------------------------------------------------------------+
| Compliance   Matches | Deadlines                       Competition [All v]           |
+--------------------------------------------------------------------------------------+
| Oct 14  Squad list submission      U10-U12 League    in 3 days      2 squads open     |
| Oct 21  Player registration close  U10-U12 League    in 10 days     done              |
| Nov 01  Transfer window opens      U10-U12 League    in 21 days     -                 |
| Legend: [!] < 3 days   [ ] upcoming   [x] done   [w] waived                           |
| [+ Add club deadline]       Template updated by platform: [Review changes]            |
+--------------------------------------------------------------------------------------+
```

Notes
* Failing rows always say **what is missing, who can fix it, and the money at stake**.
* "Mark ready" stays disabled while a *blocking* item fails; a Manager may **waive** an item with a required reason (recorded).
* Templates come from the platform; the club can edit or add rows. When the platform updates a template, the club sees "Review changes" instead of being changed silently.

---

## 5. Supporting flows to agree early

### 5.1 Parent registration and consent (parent-driven)

```
1 Create account (email)  ->  2 Add child: name, date of birth  ->  3 Tick consents
   |                                                                  (data, messaging, photos)
   v
4 "We've emailed a confirmation link to you."  (one-time, expires in 14 days)
   |
   v  parent clicks the link
5 Consent confirmed  ->  6 Upload child's photo + ID  ->  7 Club reviews  ->  8 Active
```

* Until step 5 the child's profile shows as "waiting for parent confirmation" and nothing else about the child is stored or shown.
* A second guardian is added by invitation, and gets the same confirmation email.
* Optional shortcut (question 4 in the schema plan): staff invite the parent by email; the parent completes steps 1-8.

### 5.2 Choosing a jersey number when playing in two squads

```
+--------------------------------+
| Omar's number                  |
| Omar plays in U11 and U12.     |
| Pick one number for both so    |
| you only need ONE kit.         |
|                                |
|  1  2  3  4  5  6 [7] 8  9     |
| 10 11 12 13 14 15 16 17 18     |
|  ...  (only numbers free in    |
|  both squads are tappable)     |
|                                |
|  #7 is free in both squads.    |
|  [ Choose #7 ]                 |
|                                |
|  Need a different number in    |
|  one squad? Ask the club.      |
+--------------------------------+
```

* Greyed numbers show why on tap: "taken in U12", "goalkeeper only", "retired".
* If the number is locked (kit ordered): "Numbers are locked for this season. Ask the club to change it."

### 5.3 Report a message
Long-press a message > "Not comfortable with this?" > choose a reason (bullying, inappropriate, asked to talk outside the app, pressure/threats, other) > optional note > "Sent to the club's safeguarding contact". The other person is **not told**. The reporter sees a status only.

### 5.4 Delete my data
Settings > Privacy > "Delete my data / my child's data" shows, before confirming, exactly what is deleted and what is kept for 1 year (financial records), then a 7-day undo window. The same wording appears in the Terms.

---

## 6. Settings, language and content

* Club settings (Manager): currency (default AED), time zone, weekend days, tax label. Amounts everywhere use the club's currency and its local formatting.
* Language: English at launch. Optional Arabic-name fields appear only where needed: on the player and staff form when the club's competition requires them, and flagged by the compliance checklist if blank.
* Tone for children: short, warm, no shaming.

## 7. Empty, loading and error states (to design with each screen)
* Empty: explain what to do next with one button ("No squads yet. Create your first squad").
* Offline: banner "Offline, attendance saved on this phone and will sync".
* Blocked by consent: neutral message, never showing the child's data.
* Payment failed: say what happened and offer retry or another method; never a raw gateway error.

## 8. Not sketched yet (next round, on request)
Fees and payments (Manager view), roster/squad builder, drill library, staff HR file, messaging screens, media gallery, reports, platform-owner console, onboarding for a new club, Terms/Privacy pages.

## 9. Open UX questions
1. Should coaches be able to message a player directly (13-17), or always via the parent thread? The plan allows both, with the parent auto-added as an observer. Is that the level of oversight you want?
2. Should the coach see a child's **fee status**? (Plan says no.)
3. Attendance marking: is a four-state tap (present / late / absent / excused) right, or simpler (present / absent)?
4. Rating scale: 1-5 per pillar OK, or do you prefer descriptors (Developing / Secure / Strong)? Descriptors read gentler for children.
5. Which competitions (besides UAE FA) do you expect to need extra local-language fields?
