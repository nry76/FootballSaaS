# Step 1 field map v0.1: what is in each table (for review, no SQL yet)

Status: **PLAN ONLY.** This is the data dictionary behind the 22 tables of [STEP1_PLAN.md](STEP1_PLAN.md). Visual version: click any table in the "1. The tables" card of the Step 1 tab in `docs/visual/product-plan.html`. Field names are working names in plain English; the SQL will use the same names.

**How to read it.** "Type" is in plain words: *text*, *date*, *yes/no*, *choice* (a fixed list), *link to ...* (points at a row in another table; for club-owned tables the link always stays inside the same club), *secret (stored scrambled)* (only an unreadable fingerprint is stored). "Needed" says whether the field must be filled. Every club-owned table carries `club_id` and `id`, and its rows are identified by the pair, so a row can never point at another club's row.

**Gated** fields can be stored only at data level 2 (a place offered and accepted, with the membership consent on file). **No field anywhere holds a password**: logins are held by Supabase's login system, and a club's email or WhatsApp credentials arrive in step 2 in the encrypted vault.


## Block 1 Clubs and access

### 1. `clubs` (Root)

The tenant: one row per club.

* The platform owner creates and suspends clubs; a club cannot edit its own status or slug.
* Only name and slug are readable by a signed-out visitor (the public club page).
* Currency, country, time zone and so on are not here: they are settings (table 15).

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `id` | Unique id of the club (this is the club_id every other table carries) | id | always | generated |
| `name` | The club's display name | text | always | Test Club Alpha |
| `slug` | The club's web address part | text, unique | always | test-club-alpha. Reserved words (admin, api, login) are refused |
| `status` | Whether the club can be used | choice: active, suspended, closed | always | a suspended club's accounts see nothing |
| `created_at` | When the club was created | date and time | always | generated |

### 2. `platform_staff` (Platform)

People who run the platform itself (not club roles).

* No row here gives access to any club's data. Access to a club comes only through a support window (designed, built after the pilot).
* Not readable by anyone but the platform owner.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `user_id` | Their login | link to the login system | always | one row per login |
| `name` | Their name | text | always |  |
| `role` | What they may do on the platform | choice: owner, support | always | owner creates clubs and maintains reference data |
| `active` | Switched on or off | yes/no | always | off = no access at all |
| `created_at` | When added | date and time | always | generated |

### 3. `accounts` (Club)

A login inside one club.

* One login belongs to one club only (decision 2); a person with children at two clubs uses a different email for each.
* A child under 13 can never have an account. A 13 to 17 account needs a guardian's consent on file first.
* Switching an account off takes effect on the next request.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `user_id` | The login (email and password or magic link, held by the login system, not by us) | link to the login system | always | unique across all clubs |
| `person_id` | The person this login belongs to | link to people | always | one account per person |
| `status` | Where the account is | choice: invited, active, disabled | always | invited = created but not yet accepted |
| `status_changed_at` | When the status last changed | date and time | always |  |
| `created_at` | When created | date and time | always | generated |

### 4. `account_roles` (Club)

Which roles each account holds (a person may hold several).

* Only a Manager grants or removes roles; nobody can give themselves a role; the last Manager cannot be removed.
* Rights are the union of all roles held.
* Scope is club-wide in step 1. The scope fields are reserved so a coach can later be limited to their own teams without changing this table.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `account_id` | Whose role | link to accounts | always |  |
| `role` | The role | choice: manager, admin, coach, parent, athlete | always | parent and athlete are given automatically when a guardian or athlete login is created |
| `scope_kind` | What the role covers | choice: club (later: team) | always | always "club" in step 1 |
| `scope_id` | Which team, when scoped | link (reserved) | never in step 1 | empty |
| `granted_by` | Who granted it | link to accounts | always | empty for the first Manager, created with the club |
| `granted_at` | When | date and time | always | generated |

### 5. `invitations` (Club)

A single-use, expiring invitation for staff or a second guardian.

* The link carries a secret; only a scrambled copy (hash) is stored, so a database leak cannot be used to accept invitations.
* Single use, expires, and the email it was sent to must match.
* The address is removed when the invitation is used or expires, or the person is deleted.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `email` | Where it was sent | text | always | removed after use or expiry |
| `role` | The role offered | choice: manager, admin, coach, parent | always | a second guardian is invited as parent |
| `for_child_person_id` | For a second guardian: which child they will be linked to | link to people | only for guardians |  |
| `relation` | For a second guardian: mother, father or other | choice | only for guardians |  |
| `token_hash` | Scrambled copy of the secret in the link | secret (stored scrambled) | always | never readable |
| `invited_by` | Who sent it | link to accounts | always |  |
| `expires_at` | When it stops working | date and time | always | default 7 days (a setting) |
| `used_at` | When it was accepted | date and time | empty until used |  |
| `status` | Where it is | choice: pending, used, expired, cancelled | always |  |

### 6. `role_permissions` (Reference)

The fixed list of what each role may do. The same for every club; the app cannot edit it.

* Policies ask "does one of my roles carry this permission?" instead of naming roles, so a role can change without rewriting every rule.
* Parent and athlete rights do not come from here; they come from the relationship (a parent sees their own children).

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `role` | The role | choice | always |  |
| `permission` | One thing it may do | text | always | see the permission list below |

Permission list (what each role carries). Coach, parent and athlete carry no club-wide permission in step 1: a coach sees only their own staff record, and parents and athletes act through their relationship to a child.

| Permission | What it allows | Roles |
|---|---|---|
| `settings.write` | Change club settings | Manager |
| `roles.manage` | Grant and remove roles; invite staff | Manager |
| `accounts.read` | See accounts and roles | Manager, Admin |
| `people.read_all` | See every person in the club | Manager, Admin |
| `people.write_all` | Add and edit any person, contact or relationship | Manager, Admin |
| `private.read` | See identity details at level 2 | Manager, Admin |
| `private.write` | Enter identity details at level 2 | Manager, Admin |
| `offers.make` | Offer a place | Manager, Admin |
| `consents.read` | See consent proof | Manager, Admin |
| `audit.read` | Read the audit log | Manager |
| `deletions.view` | See deletion requests and the ledger | Manager |
| `links.resend` | Ask for a confirmation link to be re-sent | Manager, Admin |

## Block 2 People and families

### 7. `people` (Club)

Anyone the club deals with: staff, guardians and athletes. One row per human.

* A guardian and a child are two separate rows, joined by the relationships table (table 10). A person can be several things at once (a parent who is also a coach).
* Age is worked out from the birth date in the club's time zone, never stored.
* After deletion the row keeps only its id and erased_at, so financial records and audit entries can still point at it without naming anyone.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `first_name` | First name | text | always | Aya |
| `last_name` | Last name | text | always | Tester |
| `name_ar` | Name in Arabic | text | optional | only where UAE FA asks for it |
| `birth_date` | Date of birth | date | always for athletes; optional for adults | age, consent and login rules read this |
| `source` | How the row was created | choice: enquiry_form, staff_added, invitation | always |  |
| `erased_at` | When the person was deleted | date and time | empty until deleted | names and birth date are blanked |
| `created_at` | When created | date and time | always | generated |
| `updated_at` | When last changed | date and time | always | generated |

### 8. `athletes` (Club)

The athlete layer on a person: what is specific to taking part in a sport (decision 47).

* Football only today. The sport pack decides the word on screen (Player, Swimmer...).
* The pipeline stage (enquiry, trial, offer, confirmed) is not stored here in step 1; it arrives with the status engine and prospect pipeline.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `person_id` | The person | link to people | always | one athlete row per person |
| `sport` | Which sport | link to sport_packs | always | football |
| `position_wanted` | Position they would like to play | choice from the sport pack | club setting: hidden, optional or required | goalkeeper, defender, midfielder, forward, not sure |
| `previous_club` | Previous club or academy | text | club setting: hidden, optional or required |  |
| `source` | Where the enquiry came from | choice: instagram, whatsapp, website, referral, walk_in, other | always | decision 72; step 4 grows this into a full lead record |
| `enquiry_at` | When the enquiry was submitted | date and time | always | generated |

### 9. `contact_points` (Club)

Phone, WhatsApp, email and address of a person, with proof of confirmation.

* Email confirmation is recorded here (verified_at). Until the link is clicked the only message the system may send to that address is the confirmation link.
* WhatsApp is a separate row so the parent can opt in separately from the phone number ("same as phone" copies the number).
* A guardian cannot confirm using the child's own email address.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `person_id` | Whose contact | link to people | always |  |
| `kind` | What kind | choice: phone, whatsapp, email, address | always |  |
| `value` | The number, address or text | text | always | address is free text in step 1 |
| `label` | Optional note | text | optional | mobile, work, home |
| `is_primary` | The preferred one for its kind | yes/no | always |  |
| `verified_at` | When it was confirmed | date and time | empty until confirmed | email: set when the link is clicked |
| `created_at` | When added | date and time | always | generated |

### 10. `relationships` (Club)

Links a guardian to a child.

* Both people must belong to the same club (the double key makes a cross-club link impossible).
* may_consent controls who can accept an offer and give consent; an Admin cannot do it for them.
* continues_after_18 can be set only by the athlete's own consent (decision 64).
* The last guardian of a child still on file cannot be deleted (P5).

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `guardian_person_id` | The guardian | link to people | always |  |
| `child_person_id` | The child or athlete | link to people | always |  |
| `relation` | How they are related | choice: mother, father, other | always | UAE FA rules name the mother and the father |
| `may_consent` | May give consent and accept offers | yes/no | always | yes for the first guardian |
| `is_primary_contact` | The club's first point of contact | yes/no | always |  |
| `continues_after_18` | Keeps access after the athlete turns 18 | yes/no | set only by the athlete | default no until the athlete says so |
| `created_at` | When linked | date and time | always | generated |
| `ended_at` | When the link ended | date and time | empty while active |  |

### 11. `person_private_details` (Club)

Identity details needed for registration. Gated: only at level 2.

* Stored only after a place is offered, a guardian marked "may consent" has accepted, and the membership consent is on file. No payment is needed.
* Withdrawing the membership consent hides the whole row at once, even from a Manager.
* A guardian's details (their passport) are allowed once any linked child is at level 2.
* Documents and photos are not here: they arrive in step 2 as files with their own checks.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `person_id` | Whose details | link to people | always | one row per person |
| `emirates_id_number` | Emirates ID number | text | optional | 784-XXXX-XXXXXXX-X, test numbers only |
| `emirates_id_expiry` | Emirates ID expiry | date | optional |  |
| `passport_number` | Passport number | text | optional |  |
| `passport_expiry` | Passport expiry | date | optional |  |
| `nationality` | Nationality | text | optional |  |
| `birth_country` | Country of birth | text | optional | decides "Born in UAE" later |
| `resident_since` | Resident in the UAE since | date | optional | decides the 5-year route later |
| `school_name` | Current school | text | optional | for the continuation certificate |
| `uaefa_id_number` | UAE FA ID number | text | optional | not published; optional (decision 95) |
| `updated_at` | When last changed | date and time | always | generated |

### 12. `sport_packs` (Reference)

What differs from sport to sport, as data.

* Same for every club; maintained by the platform owner.
* Only football is filled in. Other sports are not designed (decision 43).

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `code` | Short name | text, unique | always | football |
| `name` | Display name | text | always | Football |
| `person_word` | What an athlete is called on screen | text | always | Player (fallback: Athlete) |
| `person_word_plural` | Plural | text | always | Players |
| `positions` | The list of positions | list of text | always | goalkeeper, defender, midfielder, forward |
| `age_group_rule` | How groups are named | text | always | "U" + season end year minus birth year |
| `has_shirt_numbers` | Shirt numbers exist | yes/no | always | yes |
| `has_match_sheets` | A team is picked for each fixture | yes/no | always | yes (individual sports: no) |

### 13. `club_sports` (Club)

Which sports a club offers.

* Football for every club today. Exists so groups and rule sets can carry a sport from day one.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `sport` | Which sport | link to sport_packs | always | football |
| `is_default` | The club's main sport | yes/no | always |  |

## Block 3 Settings

### 14. `setting_definitions` (Reference)

Every setting that exists: its type, limits, default and who may change it.

* A club can only set a key that is defined here, with a value of the right type and within range.
* Same for every club; the app cannot edit it.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `key` | The setting's name | text, unique | always | deletion_cooling_off_days |
| `area` | Where it appears in Settings | text | always | Privacy and data |
| `label` | Plain-words label | text | always | Days before a deletion completes |
| `value_type` | Kind of value | choice: text, number, yes/no, choice, list, time zone | always |  |
| `allowed` | Allowed values or range | text | optional | 1 to 30 |
| `platform_default` | Value used when a club has not set one | value | always | 7 |
| `levels_allowed` | Where it may be overridden | list: club, group, session | always | group and session are reserved for step 3 |
| `editable_by` | Who may change it | choice: manager, platform_owner | always | age_of_consent: manager may raise, only platform owner may lower |
| `floor_value` | Lowest value a club may choose | value | optional | age_of_consent: 18 |

Settings that exist in step 1 (all with a platform default; a club overrides at club level):

| Key | What it controls | Default | Who changes it |
|---|---|---|---|
| `country` | Country | AE | Manager |
| `time_zone` | Time zone | Asia/Dubai | Manager |
| `currency` | Currency (used from step 4) | AED | Manager |
| `weekend_days` | Weekend days (used from step 3) | Sat, Sun | Manager |
| `language` | Language | en | Manager |
| `age_of_consent` | Age at which the athlete's own consent replaces the guardian's | 18, a club may raise it; only the platform owner may lower it | Manager (raise) / platform owner (lower) |
| `min_login_age` | Youngest age with an own login | 13, may be raised, not lowered | Manager (raise) / platform owner (lower) |
| `grace_days_after_18` | Days to give own consent after turning 18 before data is hidden | 30 | Manager |
| `deletion_cooling_off_days` | Days before a deletion completes | 7 | Manager |
| `prospect_delete_after_days` | Days before a prospect who never converted is deleted | 90 | Manager |
| `financial_retention_months` | Months financial records are kept after a deletion | 12 | Platform owner |
| `confirmation_link_valid_hours` | How long an emailed confirmation link works | 72 | Manager |
| `invitation_valid_days` | How long a staff or guardian invitation works | 7 | Manager |
| `enquiry_form_fields` | For address, previous club and position: hidden, optional or required | all three optional | Manager |
| `support_window_min_minutes` | Shortest support window a club may open (used after the pilot) | 5 | Platform owner |
| `support_window_max_days` | Longest support window (used after the pilot) | 7 | Platform owner |

### 15. `setting_values` (Club)

A club's own value for a setting.

* Resolution order: session, then group, then club, then platform default. Step 1 builds the club level and tests the others with stand-ins.
* Only a Manager changes a value; each change is audited with the key and value (settings are not personal data).
* Creating a club creates its starting values in one step.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `key` | Which setting | link to setting_definitions | always |  |
| `level` | At which level it applies | choice: club (later: group, session) | always | club in step 1 |
| `level_id` | Which group or session | link (reserved) | empty at club level |  |
| `value` | The value | value, checked against the definition | always | AED |
| `changed_by` | Who last changed it | link to accounts | always |  |
| `changed_at` | When | date and time | always | generated |

## Block 4 Consent and stages

### 16. `consent_purposes` (Reference)

What can be consented to, and the exact wording shown, by version.

* Wording is versioned; every consent records which version was shown.
* Service and marketing are separate kinds; marketing never rides on service consent.
* Step 1 seeds four purposes with test wording. Clinic sharing and UAE FA sharing are added with their features in step 2.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `code` | Short name | text | always | trial_contact, membership_registration, marketing_email, marketing_whatsapp |
| `version` | Version number | whole number | always | 1 |
| `kind` | Service or marketing | choice: service, marketing | always |  |
| `who_gives` | Who may give it | choice: guardian_or_self | always | guardian for a minor; the athlete themself from 18 |
| `title` | Short title | text | always |  |
| `wording` | The text the parent reads | long text | always | test wording only |
| `effective_from` | From when this version applies | date | always |  |
| `retired_at` | When it was replaced | date | empty while current |  |

### 17. `consents` (Club)

Proof of every consent given or withdrawn. Append-only.

* Written only by the database function that checks a one-time link or a signed-in guardian; never directly by anyone, a Manager included.
* Never edited or deleted. Withdrawal adds a new row that points at the one it withdraws.
* After deletion it shrinks to purpose, date and status (no email, no network details).

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `subject_person_id` | Whose data the consent covers | link to people | always | the child or athlete |
| `purpose_code` | What was consented to | link to consent_purposes | always |  |
| `purpose_version` | Which wording version was shown | whole number | always |  |
| `given_by_person_id` | Who gave it | link to people | always | a guardian, or the athlete themself from 18 |
| `status` | Granted or withdrawn | choice: granted, withdrawn | always |  |
| `withdraws_consent_id` | Which consent this row withdraws | link to consents | only on withdrawal |  |
| `method` | How it was given | choice: email_link, signed_in | always |  |
| `link_id` | The emailed link used | link to consent_links | only for email_link |  |
| `evidence` | Scrambled network and device fingerprint | secret (stored scrambled) | optional | cleared at deletion |
| `recorded_at` | When | date and time | always | generated |

### 18. `consent_links` (Club)

One-time emailed links that confirm an address or record a consent.

* Only a scrambled copy of the secret is stored. Single use; expires; works only in its own club.
* Readable by no one directly. Managers and Admins can ask for a resend through a function.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `person_id` | Whom the link is for | link to people | always |  |
| `contact_point_id` | The email address it was sent to | link to contact_points | always |  |
| `purpose_code` | What clicking it records | link to consent_purposes | always | trial_contact for the first link |
| `token_hash` | Scrambled copy of the secret | secret (stored scrambled) | always | never readable |
| `created_at` | When created | date and time | always | generated |
| `expires_at` | When it stops working | date and time | always | default 72 hours (a setting) |
| `used_at` | When it was clicked | date and time | empty until used |  |

### 19. `place_offers` (Club)

The club's offer of a place and the guardian's acceptance: the second half of the gate.

* Only a Manager or Admin makes an offer. Only a guardian marked "may consent" accepts, and only once.
* Accepting needs the membership consent (consent_id). Payment is not needed (decision 58).
* The deadline for a place hold is reserved for later.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `athlete_person_id` | Who the place is for | link to people | always |  |
| `offered_by` | Who made the offer | link to accounts | always |  |
| `offered_at` | When | date and time | always | generated |
| `status` | Where the offer is | choice: offered, accepted, declined, withdrawn, expired | always |  |
| `accepted_by_person_id` | The guardian who accepted | link to people | only when accepted |  |
| `accepted_at` | When | date and time | only when accepted |  |
| `consent_id` | The membership consent given with the acceptance | link to consents | only when accepted |  |
| `expires_at` | Hold deadline | date and time | reserved | empty in step 1 |
| `note` | Internal note for staff | long text | optional | never shown to the parent |

## Block 12 Audit and deletion

### 20. `audit_log` (Club)

Who did what to which record. Append-only.

* Holds ids and field names, never names, emails, phones or birth dates. Settings and role changes may carry the key and value because they are not personal data.
* Nobody can edit or delete a row. Only the club's Manager reads it.
* Written by the database itself (triggers), so no screen can forget to.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `id` | Running number | whole number | always | generated |
| `club_id` | Which club | link to clubs | empty for platform actions |  |
| `at` | When | date and time | always | generated |
| `actor_kind` | Who acted | choice: user, system, platform | always | scheduled jobs are "system" |
| `actor_account_id` | Which account | link to accounts | empty for system |  |
| `action` | What happened | text | always | insert, update, delete, consent.redeem, deletion.complete |
| `table_name` | Which table | text | always |  |
| `record_id` | Which row | id | always |  |
| `changed_fields` | Names of fields changed (not values) | list of text | always | first_name, birth_date |
| `note` | Extra context that is not personal | text | optional | settings: key and new value |

### 21. `deletion_requests` (Club)

A request to delete a person, and its progress.

* Only the family (for a child) or the athlete (18 or over) can start one; a Manager cannot erase a family alone (P4).
* Cooling-off window (default 7 days) in which it can be cancelled; then a scheduled job completes it.
* Refused while the person is the only guardian of a child still on file (P5).

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `subject_person_id` | Whose data is to be deleted | link to people | always |  |
| `requested_by_person_id` | Who asked | link to people | always |  |
| `requested_at` | When | date and time | always | generated |
| `status` | Where it is | choice: cooling_off, cancelled, completed | always |  |
| `cooling_off_until` | When the window ends | date and time | always |  |
| `cancelled_at` | When cancelled | date and time | only if cancelled |  |
| `completed_at` | When completed | date and time | only if completed |  |

### 22. `erasure_ledger` (Club)

For each deletion: what was removed, what was kept and for how long.

* Supports the Terms: everything is deleted except financial records, kept 1 year (decision 11). There are no financial tables in step 1, so the ledger shows them as "none yet".
* Holds no personal values.

| Field | What it holds | Type | Needed | Notes or example |
|---|---|---|---|---|
| `club_id` | Which club | link to clubs | always | part of the key |
| `id` | Unique id within the club | id | always | generated |
| `deletion_request_id` | Which request | link to deletion_requests | always |  |
| `item` | What kind of data | text | always | contact points, private details, consent history |
| `outcome` | What happened to it | choice: deleted, kept_reduced, kept | always | kept_reduced = consent history shrunk to purpose, date, status |
| `kept_reason` | Why anything was kept | text | only if kept |  |
| `purge_on` | When the kept item is deleted | date | only if kept | 12 months by default |
| `purged_at` | When it was | date and time | empty until purged |  |

## Plus one temporary table

`test_inbox`: Test-only table (a 23rd, temporary): the emails that would be sent, shown on screen. Dropped when step 2 brings the real outbox.

| Field | What it holds |
|---|---|
| `id` | id |
| `club_id` | which club |
| `to_address` | who it would go to (test addresses only) |
| `subject` | subject line |
| `body` | message text, including the link |
| `created_at` | when |

The step 1 plan said emails would be shown in a test inbox; this is where they are kept. It is not counted in the 22 and is removed in step 2.

## What is deliberately not here

* **Gender, nationality of the guardian, documents, photos, forms, medical files:** step 2 (documents block).
* **Pipeline stage, trial bookings, lead campaign:** step 4. `athletes.source` is only the first piece.
* **Groups, teams, sessions, coach assignment:** step 3.
* **Fees, payments:** step 4. Money fields will follow decision: whole numbers of the smallest unit plus a currency code.
* **Email and WhatsApp credentials, message templates, the outbox:** step 2.
