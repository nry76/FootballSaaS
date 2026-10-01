# What the lawyer must review (draft 1)

**Status: a list to hand over, written by Claude, not a lawyer.** Every legal statement below is **unverified**; the lawyer confirms or corrects it. Nothing here is advice. Nothing has been sent to anyone.

Why now: a lawyer takes weeks, and children's data is the highest-risk part of the product. Sportal needs this finished before any real family's data is held.

Tags: **[L]** needs a lawyer, **[FA]** needs UAE FA's answer, **[Owner]** your decision first.

## A. Choose the lawyer first
Ask for someone who knows **UAE data protection (children's data)** and, ideally, **EU data rules**, because data is hosted in Frankfurt. One firm covering both is simplest; two is acceptable. [Owner]

## B. Questions for the lawyer (most important first)

| # | Question | Why it matters | Where it comes from |
|---|---|---|---|
| 1 | **Which law(s) apply** to UAE children's data held on EU servers? (UAE federal data law, EU GDPR, and whether any free-zone rules apply) | Everything else depends on it | DECISIONS "For legal review" |
| 2 | **Who is responsible for the data: the club or Sportal?** (Our assumption: the club decides why data is used; Sportal only handles it on the club's behalf.) | Decides who signs what, and who is liable | Unverified assumption |
| 3 | **Moving data out of the UAE** to Frankfurt: allowed? Any notice or approval needed? | Hosting region is already chosen | TECH_STACK |
| 4 | **Age of consent** for a child's data and for a 13-17 year old's own login. Is "under 13 no login, 13-17 login after parent's email consent, 18+ fresh consent" acceptable? | Core consent design | Decisions 4, 5, 6 |
| 5 | **Consent wording** the parent sees, and what proof we must keep (date, version, email) | Enforced in the database | Decision 5 |
| 6 | **Retention.** Is keeping financial records for **1 year** after a deletion request enough? We suspect UAE tax and accounting rules require **longer (possibly five years)**: unverified | Could force a redesign of deletion | Decision 11 |
| 7 | **Deletion and backups.** What we delete at once, what stays in backups and for how long; the 7-day cooling-off idea | Wording for Terms and Privacy | Decision 11, open list |
| 8 | **Marketing messages** (WhatsApp, email, SMS): what UAE rules say about opt-in, who we may contact (only people who enquired and opted in), opt-out, time of day | Decision 34 says the lawyer must confirm | Decision 34 |
| 9 | **Photos of children, Emirates ID and passport copies, medical forms**: are these "sensitive data"? Extra consent, storage or access rules? | We hold them only after a place is accepted | Decisions 78, 79, 94 |
| 10 | **Prospect data** (7 fields) kept 90 days by default: is that reasonable? | Club setting, default 90 days | Decision 66 |
| 11 | **Sending real children's documents to an AI vendor** (later phase): consent, contract, EU/UAE transfer rules | Parked until this is answered | Decisions 30, 50 |
| 12 | **Outside contacts** (clinic, medical company) reached by one-time link without a login: any rules on sharing a child's details with them? | Parent agrees first | Decisions 31, 55 |
| 13 | **Rights of parents and players**: see, correct, export, delete. Time limits for answering | Needs screens and a process | Standard |
| 14 | **Data breach duty**: who must be told, how fast, by whom | Needs a written process | Standard |
| 15 | **Do we need to register** with a data authority or appoint a data-protection officer? | May apply to Sportal, to clubs, or both | Unverified |
| 16 | **Platform support access.** Sportal staff seeing a club's data to help: what consent and logging? | The "support grant" idea | Open list |
| 17 | **Liability and insurance**: limits of liability in the club contract; cover for a data leak | Business risk | New |

## C. Questions for UAE FA (not the lawyer)
| # | Question | Where it comes from |
|---|---|---|
| FA-1 | The **FA-Net undertakings** forbid disclosing access to third parties. Does a club using Sportal to prepare documents and record FA-Net outcomes stay inside the undertakings? (Decision 113 says recording is fine: your answer; confirm in writing) | FANET_UNDERTAKINGS.md |
| FA-2 | **Assisted upload** (Sportal filling FA-Net for the user) needs UAE FA's permission | Decision 113 |
| FA-3 | **DOFA and YFL do not count** against the A/B crossing rule: confirm in writing | Decision 112 |

## D. Documents to be written (the lawyer reviews or drafts)
1. **Terms of Use** for parents and players, including the deletion and 1-year financial-record statement and parental responsibility.
2. **Privacy Policy** in plain English: what we hold, why, how long, who sees it, where it is stored.
3. **Consent texts:** parent consent for a child; own-login consent at 13; fresh consent at 18; photo consent; **separate** marketing consent.
4. **Club agreement** between Sportal and each club, including who is responsible for the data and the club's duties (for example, telling parents).
5. **Data processing terms** inside or beside the club agreement.
6. **List of outside tools we use** and agreements with each: database and storage host (Supabase), web host (Vercel), error tracking (Sentry), email sender, any messaging channel, any AI vendor later.
7. **Cookie notice** (kept to the minimum).
8. **Breach and rights-request process**, one page each.

## E. Decide before the lawyer meeting [Owner]
* Which company or person is **Sportal** legally (the lawyer will ask)?
* WhatsApp route: official or unofficial (see decision 114). Tell the lawyer which one is being considered; consent and marketing answers differ.
* Is the pilot club (Fursan) approached before or after the legal pack? Nothing is promised to anyone yet.

## F. Suggested order
1. Choose a lawyer (A).
2. Send questions 1-8 first (they shape the design); 9-17 in the second meeting.
3. Draft documents (D) after the answers.
4. Hold all real children's data until Terms, Privacy and consent texts are signed off. Test data only until then.
