# Step 1 plan v0.1: the safe foundation (for review, no SQL yet)

Status: **PLAN ONLY. No SQL or application code has been written.** The owner has answered the seven proposals (section 11): P1, P3, P4, P5 and P7 are accepted; **P2 is revised below and P6 has been explained; both await a yes**. Visual version: the "Step 1" tab of `docs/visual/product-plan.html` (open in a browser; it has a role matrix, a "try to break in" box and a child-data gate you can click).

Step 1 is the first item of the build order in [FOUNDATION_PLAN.md](FOUNDATION_PLAN.md) section 5: **blocks 1 to 4 and 12** (clubs and access, people and families, settings, consent and data stages, audit and deletion), proven by tests that one club can never see another's data and that a child's data stays blocked until consent.

**Decided for this step** (decisions 114 and 115): the code lives in this repository in `supabase/` and `web/`; everything is built and tested with **invented test data only**; legal review is not on the path of this step.

---

## 1. What step 1 is, in one paragraph

A club exists, with staff, parents and children in it, and **the database refuses everything it must refuse**. A parent can send a short enquiry, confirm by an emailed link, accept a place and give consent; the club sees only what its role allows; settings resolve from a club default; every change is audited; and a family can ask to be deleted. There are no documents, no schedule, no messages, no money yet. Those sit on top, later, through the same walls.

## 2. Tables (22)

"Reference" tables are the same for every club (platform-maintained, read-only to the app). All other tables carry `club_id` and use composite keys `(club_id, id)`, so a row can never point at another club's row.

| Block | Table | What it holds | Kind |
|---|---|---|---|
| 1 Clubs and access | `clubs` | The tenant: name, slug, country, status | Root |
| | `platform_staff` | Platform owner and support logins (not club roles) | Platform |
| | `accounts` | A login inside one club (one login = one club, decision 2) with status | Club |
| | `account_roles` | The set of roles each account holds (a person may hold several) | Club |
| | `invitations` | Single-use, expiring invite for staff or a second guardian; token stored hashed | Club |
| | `role_permissions` | Fixed role-to-permission map (Manager, Admin, Coach, Parent, Athlete) | Reference |
| 2 People and families | `people` | Anyone: staff, guardian, athlete. First and last name, optional Arabic name, birth date, adult or child. **A guardian and a child are two separate rows**, joined by `relationships` | Club |
| | `athletes` | The athlete layer on a person: sport, position wanted, previous club (decision 47) | Club |
| | `contact_points` | Phone, WhatsApp, email and home address per person, with verified date | Club |
| | `relationships` | Guardian to child: mother, father, other; may consent; keeps access after 18 | Club |
| | `person_private_details` | ID numbers, nationality, residency, school. **Gated**: only after an accepted offer and membership consent | Club |
| | `sport_packs` | Football only: the word on screen, positions, age naming | Reference |
| | `club_sports` | Which sports a club offers (football for now) | Club |
| 3 Settings | `setting_definitions` | Every setting: key, type, allowed range, platform default, which levels may override | Reference |
| | `setting_values` | A club's value, with a level (club now; group and session reserved) | Club |
| 4 Consent and stages | `consent_purposes` | Versioned purposes and wording: trial, membership and registration, marketing; service vs marketing | Reference |
| | `consents` | Append-only proof: who, what purpose, which wording version, when, granted or withdrawn | Club |
| | `consent_links` | One-time emailed links; token stored hashed; expiry | Club |
| | `place_offers` | The club's offer of a place and the guardian's acceptance. It is the second half of the gate (decision 58), pulled forward from the prospect pipeline | Club |
| 12 Audit and deletion | `audit_log` | Who did what to which record: ids and field names, never personal values. Append-only | Club |
| | `deletion_requests` | A request, its cooling-off window, its status | Club |
| | `erasure_ledger` | What was deleted, what was kept, and the date any kept item is purged | Club |

Counts: 1 root, 1 platform, 4 reference, 16 club-owned.

### How the rules are kept in one place
Policies never contain rules of their own; they call four small functions, so later steps change a function, not every policy:

| Function | Question it answers |
|---|---|
| `my_club()` | Which club is this login in, and is the account active? |
| `has_permission(permission)` | Does one of my roles carry this permission? |
| `can_see_person(person)` | Is this person me, my child, or someone my role may see? (Step 3 adds "in my group" for coaches here) |
| `data_level(person)` | A, B or C (section 4), worked out from consents and the offer, **never stored**, so it cannot go stale |

## 3. Who sees what

Codes: **W** read and change, **R** read, **O** read own (or own children), **OW** read and change own, **OF** read own and act only through a function, **F** only through a function (never a direct table access), **-** nothing.

| Table | Platform owner | Manager | Admin | Coach | Parent | Athlete (own login) | Signed-out visitor |
|---|---|---|---|---|---|---|---|
| `clubs` | W | W (own club) | R | R | R | R | F (public page) |
| `platform_staff` | O | - | - | - | - | - | - |
| `accounts` | - | W | R | O | O | O | - |
| `account_roles` | - | W | R | O | O | O | - |
| `invitations` | - | W | R | - | F | - | F (redeem) |
| `role_permissions` | R | R | R | R | R | R | - |
| `people` | - | W | W | O | OW | O | F (enquiry) |
| `athletes` | - | W | W | - | OW | O | F (enquiry) |
| `contact_points` | - | W | W | - | OW | O | F (enquiry) |
| `relationships` | - | W | W | - | O | O | - |
| `person_private_details` (gated) | - | W | W | - | OW | O | - |
| `sport_packs` | W | R | R | R | R | R | - |
| `club_sports` | - | W | R | R | R | R | - |
| `setting_definitions` | W | R | R | R | R | R | - |
| `setting_values` | - | W | R | R | F | F | - |
| `consent_purposes` | W | R | R | R | R | R | R (public wording) |
| `consents` | - | R | R | - | OF | OF | F (redeem link) |
| `consent_links` | - | F | F | - | - | - | F |
| `place_offers` | - | W | W | - | OF (accept) | - | - |
| `audit_log` | - | R | - | - | - | - | - |
| `deletion_requests` | - | R | - | - | OF | OF | - |
| `erasure_ledger` | - | R | - | - | O | O | - |

Four rules sit above the table, each independent of the others:
1. **Wall.** Every rule starts with "this row's club is my club". No active account means no club and nothing visible.
2. **Permission.** Rights come from `role_permissions`. Only a Manager changes settings and roles; nobody can give themselves a role.
3. **Relationship.** A parent sees own children, an athlete sees self, a coach sees no child at all in step 1 (see proposal P1).
4. **Child gate.** Section 4, on top of everything, including Manager and the all-powerful service key.

The platform owner has **no default access** to any club's people, consents, settings or audit. The "club approves a time-limited support window" feature (decision 8) is **not in step 1**; the single choke-point function `my_club()` is where it will plug in.

## 4. The child gate: three data levels

| Level | Reached when | The database accepts | Still refused |
|---|---|---|---|
| **A. Unconfirmed enquiry** | A parent submits the enquiry form | **Everything the club's form asks** (section 4a) is accepted, so the club never has to ask twice, but it is held **in quarantine**: readable by **no club role** (Manager included), used only by the function that sends the confirmation link, and deleted automatically if the link is not clicked within a few days (a setting, default 7) | Anything beyond the enquiry form: ID numbers, nationality, residency, documents, photo, medical |
| **B. Prospect** | The parent clicks the emailed link (trial consent) | The same enquiry fields now become **visible to the club** (by role, section 3) | ID numbers, nationality, residency, documents, photo, medical |
| **C. Registration** | The club has **offered a place**, a guardian marked "may consent" has **accepted**, and the membership and registration consent is on file. **No payment needed** (decisions 58, 109) | Everything registration needs (step 1 holds the private details; documents and forms arrive in step 2) | Nothing further |

Moves back: withdrawing consent drops the person to the level their remaining consent supports, **immediately and for every role**. When an athlete turns 18 the guardian's consent stops counting; the athlete's own consent is needed, with a grace period (a setting, default 30 days) after which the data is hidden ("Restricted") but the athlete can still sign in and consent. Parents keep access after 18 only if the athlete's own consent says so (decision 64).

Where the guard sits: **inside the tables** (triggers and policies), not in the screens and not in the app code. A test connects as the owner of the database and still cannot read a level A enquiry as a club role, nor store an ID number before level C.

### 4a. The enquiry form (P2, revised after the owner's note)

Several clubs already ask these questions, so the form asks them in one go: **player first name, player last name, date of birth, guardian phone, guardian email, home address, previous club or academy, field position.** We add **guardian name** (someone to address) and **WhatsApp** ("same as phone" ticked by default), which the earlier plan already had. That is **ten fields**; they replace the earlier "seven fields".

* **Which optional fields a club asks, and which are required, is a club setting** (`enquiry_form_fields`): address, previous club and position can each be hidden, optional or required. Name, date of birth, guardian email and guardian phone are always asked.
* Address is held as a contact point of the guardian; previous club sits on the athlete layer.
* The quarantine at level A is my proposal for keeping the child-data promise while collecting everything at once. The alternative is a short first form (four fields) and a "tell us more" page after the link is clicked; it holds less but asks the parent twice. **Needs the owner's yes** (section 11).

## 5. Tests (67)

Types: **DB** = database test (pgTAP), run against a real Postgres; **Unit** = Vitest; **Browser** = Playwright through the real screens, phone width; **CI** = a check on every push. Most of the safety is proven at the database, because that is where the rules live.

### W. The club wall (10)
| # | Proves | Type |
|---|---|---|
| W1 | For **every** club-owned table, a user of Club A reads zero rows of Club B. The test loops over the list of all tables, so a new table is covered automatically | DB |
| W2 | A Club A user cannot insert a row labelled Club B, nor move a row to Club B | DB |
| W3 | A row cannot point at another club's row, even with the service key (composite keys) | DB |
| W4 | Asking for a Club B record by its exact id returns "nothing found", so even its existence does not leak | DB |
| W5 | A signed-out visitor sees only the public club page fields and the consent wording | DB |
| W6 | An account that is invited-not-accepted or switched off sees nothing, and switching off takes effect on the next request | DB |
| W7 | The platform owner, with no grant, reads zero rows of any club's people, consents, settings or audit | DB |
| W8 | The same login cannot hold accounts in two clubs (decision 2) | DB |
| W9 | Every table has row-level security switched on. A new table without it **fails the build** | DB |
| W10 | The service key never appears in browser code; secret scanning passes (gitleaks) | CI |

### R. Roles and accounts (11)
| # | Proves | Type |
|---|---|---|
| R1 | Manager changes settings and roles; Admin cannot | DB |
| R2 | Nobody gives themselves a role; Admin cannot grant Manager | DB |
| R3 | The last Manager of a club cannot be removed or demoted | DB |
| R4 | A coach sees no child record in step 1, only their own staff record | DB |
| R5 | A parent sees their own children and nobody else's, including a lookalike name or email | DB |
| R6 | A second guardian invited by link sees the same child; an expired or used invitation shows nothing | DB |
| R7 | An athlete aged 13 to 17 with a login sees only themselves | DB |
| R8 | Under 13: creating a login is refused. 13 to 17: refused until a guardian's consent exists | DB |
| R9 | A person with two roles gets the combined rights | DB |
| R10 | An invitation is single-use, expires, is stored hashed, and a wrong email is refused | DB |
| R11 | The permission map cannot be edited from the app | DB |

### G. The child gate and consent (15)
| # | Proves | Type |
|---|---|---|
| G1 | A level A enquiry (link not yet clicked) is invisible to every club role, Manager included; only the link-sending function sees it | DB |
| G2 | After the email link, the ten enquiry fields become visible by role; fields the club switched off are not shown; required ones are enforced | DB |
| G3 | ID number, nationality and residency are refused until a place is offered, accepted by a guardian, and the membership consent is on file | DB |
| G4 | Access at level C opens at acceptance with **no payment recorded** (decision 58) | DB |
| G5 | Consent can be written only by the function that checks a one-time link. Direct insert, update or delete is refused for every role, Manager included | DB |
| G6 | A link works once, not after expiry, is stored hashed, and Club B's link does nothing in Club A | DB |
| G7 | A guardian cannot confirm using the child's own email address | DB |
| G8 | Only a guardian marked "may consent" can accept an offer; an Admin cannot accept for a parent | DB |
| G9 | Withdrawing the membership consent hides the private details at once, for everyone | DB |
| G10 | Consent rows are append-only: withdrawal adds a row; nothing is edited or deleted | DB |
| G11 | Service and marketing consent are separate: "may we send marketing" is false unless a marketing consent exists | DB |
| G12 | Age arithmetic in Dubai time: the day before the 13th and 18th birthday, on the day, and leap-day births | Unit |
| G13 | At 18 the guardian's consent stops counting; the athlete's own is needed; after the grace period the data is hidden but the athlete can still sign in and consent | DB |
| G14 | Parents keep access after 18 only if the athlete's own consent says so | DB |
| G15 | Only Manager or Admin can make an offer; it cannot be accepted twice; a withdrawn or expired offer cannot be accepted | DB |

### S. Settings (6)
| # | Proves | Type |
|---|---|---|
| S1 | The value comes from the most specific level: session, then group, then club, then platform default (group and session are tested with stand-in levels; real ones arrive in step 3) | DB |
| S2 | An unknown key, a wrong type or an out-of-range value is refused | DB |
| S3 | One club's setting never changes another's | DB |
| S4 | Only a Manager changes a setting, and each change is audited with key and value (settings are not personal data) | DB |
| S5 | A club cannot lower the age of consent below the platform floor (proposal P3) | DB |
| S6 | Creating a club creates its default settings in one step; if any part fails, nothing is created | DB |

### A. Audit (5)
| # | Proves | Type |
|---|---|---|
| A1 | Every insert, update and delete on a club-owned table writes an audit row (the test loops over all tables) | DB |
| A2 | Audit rows hold ids and field names, never names, emails or birth dates (the test plants strings and searches every audit row) | DB |
| A3 | Audit rows cannot be edited or deleted by anyone | DB |
| A4 | Only that club's Manager reads the audit log | DB |
| A5 | Each row says which account acted; scheduled jobs are marked as the system | DB |

### D. Deletion (8)
| # | Proves | Type |
|---|---|---|
| D1 | A request starts a cooling-off window (setting, default 7 days); cancelling inside it works | DB |
| D2 | At completion the name, birth date, contacts, private details and relationships are gone (the test searches the whole database for planted strings) | DB |
| D3 | Consent history shrinks to type, date and status: no email, no network address | DB |
| D4 | The erasure ledger lists what was deleted, what was kept, and when anything kept is purged | DB |
| D5 | A guardian cannot be erased while still the only guardian of a child on file | DB |
| D6 | Deleting one family leaves another family untouched | DB |
| D7 | Unconfirmed enquiries are deleted after the set days (default 7); prospects who never converted after the club's set time (default 90 days); accepted ones never | DB |
| D8 | Only the family (or the athlete) can start a deletion; completion is by the scheduled job | DB |

### B. Real screens (8)
| # | Proves | Type |
|---|---|---|
| B1 | Parent journey: full enquiry form, test inbox shows the email, link clicked, the club now sees the prospect | Browser |
| B2 | Manager makes an offer; parent accepts and consents; the private details form opens | Browser |
| B3 | Parent withdraws consent; the form closes | Browser |
| B4 | A Club A parent opening a Club B address, even a copied one, gets "not found" | Browser |
| B5 | A coach signs in and sees an empty child list | Browser |
| B6 | Deletion request end to end, with the test clock moved past the cooling-off window | Browser |
| B7 | Platform owner creates a club and invites its first Manager; the default settings exist | Browser |
| B8 | The three parent screens work at phone width and by keyboard alone | Browser |

### M. The test machinery itself (4)
| # | Proves | Type |
|---|---|---|
| M1 | **Sabotage check:** a script removes each wall and gate rule in a scratch copy and proves at least one test then fails, so the tests cannot be empty promises | CI |
| M2 | Every push runs everything on an empty database; red blocks the merge; generated types match the schema | CI |
| M3 | A seed of invented people covers the edge cases (section 6) | DB |
| M4 | A test inbox: emails are shown on screen and never leave the system in test mode | Browser |

Total: 10 + 11 + 15 + 6 + 5 + 8 + 8 + 4 = **67**.

## 6. Test data (all invented)

Two obviously fake clubs, **Test Club Alpha** and **Test Club Beta** (not Fursan, not any real club). Alpha holds the cast; Beta exists so isolation can be tried both ways.

| Person (invented) | Role | Why they exist |
|---|---|---|
| Mona | Manager, Alpha | Settings, roles, offers |
| Adam | Admin, Alpha | Registrar rights without Manager rights |
| Carlos | Coach, Alpha | Proves coaches see no children yet |
| Priya | Parent, Alpha, two children | Own children only; sibling case |
| Pedro | Parent, Alpha | Must never see Priya's children |
| Aya | Athlete, 17, with login | Own record only |
| Ali | Athlete, turns 18 tomorrow | Consent hand-over at 18 |
| Lina | Child, 11, no login | Under 13 refusal |
| Leap | Child born 29 February | Age arithmetic |
| Twin A and Twin B | Children of one parent | Two children, one family |
| Brenda | Manager, Beta | Cross-club attacks |
| Platform owner | Platform | Proves no default access |

Every name, email (ending `@example.test`) and number is made up. No real child is entered at any point in step 1.

## 7. What you can click at the end of step 1 (thin screens, not polished)

1. **Platform owner:** create a club, invite its first Manager.
2. **Manager:** sign in, see the people list, edit settings, invite staff, make an offer, read the audit log, see deletion requests.
3. **Parent:** short enquiry, test inbox, confirm link, add a child, accept an offer and consent, withdraw consent, request deletion.
4. **Coach and athlete:** sign in and see exactly what the rules allow (a coach sees no children yet).

## 8. How step 1 is built (small pieces, each ends with green tests)

| Piece | What | Done when |
|---|---|---|
| 1a | Clubs, accounts, roles, invitations, the four helper functions, audit triggers, the seed | W1 to W9, R1 to R3, R9 to R11, A1 to A5 are green |
| 1b | People, athletes, contacts, relationships | R4 to R8 green |
| 1c | Settings engine and club creation | S1 to S6 green |
| 1d | Consent, links, offers, the three-level gate, the age hand-over | G1 to G15 green |
| 1e | Deletion and the 90-day prospect clean-up | D1 to D8 green |
| 1f | The thin screens and the browser tests | B1 to B8, M1 to M4 green |

These are **sizes of work, not time estimates** (decision 48: no promises yet).

**Step 1 is done when:** all 67 tests are green on an empty database in CI, the sabotage check passes, and you have clicked through the four journeys above on a phone-width browser.

## 9. Where the code will live (folders created only after approval)

```
supabase/migrations/    the database, in order (tables, policies, functions)
supabase/tests/         the database tests (pgTAP): W, R, G, S, A, D, M3
supabase/seed.sql       the invented test cast
web/                    the Next.js app and its thin screens
web/tests/              unit tests (Vitest)
web/e2e/                browser tests (Playwright)
.github/workflows/      the check that runs everything on every push
.env.example            names of settings only, never values
```

## 10. Not in step 1 (and why it is safe to leave out)

| Left out | Arrives with | Why leaving it out is safe |
|---|---|---|
| Documents, photos, forms, the rules engine | Step 2 | The gated table `person_private_details` proves the gate now |
| Status timeline engine, messages, tasks, real email and WhatsApp | Step 2 (design: [reference/SOCIETYPORTAL_COMMS.md](reference/SOCIETYPORTAL_COMMS.md)) | Step 1 uses a test inbox |
| Groups, sessions, scheduling | Step 3 | Coaches see no children until then (P1) |
| Ledger, fees, payments | Step 4 | The gate needs no payment |
| Prospect pipeline, trials, lead sources | Step 4 | Only the offer and acceptance are pulled forward |
| Support access grants (decision 8) | After the pilot | `my_club()` is the one place it plugs in |
| Club-specific terms text and forms | Step 2 (forms) | Step 1 uses platform test wording |
| Real clubs, real children, real email | Not in this build | Test data only (decision 115) |

## 11. Proposals and the owner's answers

| # | Proposal | Owner's answer |
|---|---|---|
| P1 | **A coach sees no child in step 1**, only their own staff record, until step 3 attaches them to a group | **Accepted** (decision 116) |
| P2 | **Revised:** the form asks the club's questions in one go (ten fields, section 4a). Until the link is clicked the enquiry sits in quarantine, invisible to the club, deleted after 7 days. Alternative: a short form first, "tell us more" after the link | **Open.** The owner gave the clubs' questions; the quarantine idea needs a yes |
| P3 | **Age of consent** is a club setting that a club can raise and only the platform owner can lower, default 18 | **Accepted** ("whatever", decision 117) |
| P4 | **Only the family or the athlete starts a deletion.** A scheduled job completes it; the Manager cannot erase a family alone | **Accepted** (decision 118) |
| P5 | **A guardian cannot be erased while the only guardian of a child still on file.** Add another guardian or delete the child as well | **Accepted** (decision 119). A guardian and a child are **two separate records** joined by a link; logins are separate again (a child under 13 has no login at all) |
| P6 | **Support access windows wait until after the pilot.** Sometimes a club has a problem and the platform owner would need to look at that club's data. The planned way: the **club clicks "allow support for up to 7 days"**, read-only, and it expires by itself. That button is not built in step 1. While testing there is only invented data, so the builder looks at it in the Supabase dashboard (the database's own admin website) | **Explained, awaiting a yes** |
| P7 | **Real email waits for step 2.** Step 1 shows emails in a test inbox | **Accepted** (decision 120) |

Defaults that are settings and need no answer: cooling-off for deletion 7 days, grace after 18 is 30 days, prospect deletion 90 days, financial records kept 12 months.
