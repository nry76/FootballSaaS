# How SocietyPortal builds email and WhatsApp (reference for Sportal's step 2)

Source: the owner's private repository `nry76/SocietyPortal` (read on 2026-10-01, shallow copy, commit `be123c6`). SocietyPortal is a multi-tenant billing product for residential societies, built on the same stack (Supabase, edge functions, Vault). Nothing here is copied into Sportal; this is what we reuse as a pattern and what we change. Where this file and a later decision differ, DECISIONS.md wins.

## 1. What it does, in plain words

| Piece | How it works | Where (in SocietyPortal) |
|---|---|---|
| **One sending identity per club** | A table `org_channels` holds, per society, how WhatsApp and email are sent. It never holds a password: it holds a pointer to a secret in **Supabase Vault** (encrypted; only the server side can read it) | `supabase/migrations/20260909150000_org_channels.sql`, `20260909160000_channel_secret_reader.sql` |
| **Settings changed only through checked functions** | A society's admin changes mode or credentials through database functions that check the permission, **require a reason**, and write an audit row that records *that* a credential changed and *which field names*, never the values | same file |
| **One send function per channel** | `send-email` and `send-whatsapp` are the only doors. Every other part of the product calls them; none talks to a provider directly | `supabase/functions/send-email`, `send-whatsapp` |
| **One place that decides whose credentials** | `resolveChannelCredentials` picks the club's own credentials ("bring your own") or the platform's shared pool. Neither send function repeats that logic | `supabase/functions/_shared/org-context.ts` |
| **One place that talks to providers** | Email: Gmail (OAuth), Amazon SES, **Resend**. WhatsApp: two private servers (Baileys, whatsapp-web.js) or the **official Meta Cloud API** | `supabase/functions/_shared/senders.ts` |
| **Shared pool with approval** | A club can ask to use the platform's shared WhatsApp number or email sender; the platform owner approves or suspends it; the shared number's messages are prefixed with the club's name. Official WhatsApp is never pooled (it is verified per number) | `20260918270000_channel_ownership_platform_pool.sql` |
| **A log of every attempt** | `comm_log` records each send as sent, failed or skipped (channel, purpose, person, recipient, provider message id, who triggered it). It is **append-only** and is written only by one function, which also writes the matching audit row in the same transaction | `20260918250000_comm_log.sql`, `20260918280000_log_communication_via.sql` |
| **Usage for billing** | The log records whether a send used the club's own channel or the platform pool, so a monthly count per club falls out of it | `20260918310000_platform_channel_usage.sql` |
| **A persistent WhatsApp server** | Edge functions cannot hold a live connection, so the Baileys server is a small always-on machine. One process serves every club; a club's session is claimed by the first request that arrives with that club's key. A person links their phone by scanning a QR code | `wa-server-baileys/` |
| **Attachments** | A document (invoice) is turned into a PDF by a small cloud function and sent as a WhatsApp document or email attachment; if PDF creation fails it falls back to text | `senders.ts`, `cloud-functions/html-to-pdf` |

## 2. What is good and carries over

1. **Credentials in Vault, pointers in tables.** Matches our hard rule 1 and TECH_STACK.
2. **Two single doors** (one send function per channel) with credential resolution and logging in shared code. New features never talk to providers.
3. **Append-only log written by one function, with the audit row in the same transaction.** Matches our block 8 ("everything recorded") and step 1's audit rules.
4. **Settings changed by checked functions, with a reason, audited by field name.** Matches our block 3 and test A2.
5. **Provider-neutral sender module.** Same idea as our gateway adapter (decision 36); a test-mode adapter fits in the same place.
6. **Per-club ownership of channels with a platform approval step** is a ready-made answer for "which WhatsApp number" later.

## 3. What it does not have, and Sportal needs

| Gap in SocietyPortal | Why Sportal needs it | Plan |
|---|---|---|
| **No consent or opt-in.** Any send goes out | Service vs marketing consent is a hard rule (6); children's families | A database check `may_contact(person, channel, kind)` **before** anything is queued (test G11) |
| **No queue, retries or schedule.** Each send is a direct call inside the request; a failure is logged and forgotten | "Robust status reporting": the parent must see sent, delivered or failed, and reminders must go out on time | A **message outbox table** with states; a scheduled job (pg_cron) sends, retries with back-off, and marks the result. The two single doors stay, behind the outbox |
| **No delivery or read receipts, no inbound messages** (replies, STOP) | Parents reply on WhatsApp; opt-outs must be honoured | Provider webhooks into an edge function that updates the outbox and a suppression list |
| **No templates.** The official API is used for plain text only | WhatsApp only allows a business to start a conversation with **pre-approved templates** (PILOT_SCOPE section 7) | A `message_templates` table (name, language, variables, approval state); official API only |
| **Unofficial WhatsApp (Baileys) is the main working path.** SocietyPortal's own requirements document calls it a scaling and terms-of-service risk and plans to move to the Cloud API | We handle children's families; a banned number stops the whole product | **Official WhatsApp Cloud API** (or a business solution provider) for Sportal; a test-mode adapter for the pilot. The Baileys server is not copied |
| **Personal values in the audit row.** `log_communication` copies the recipient (email or phone) into the audit log | Step 1 rule: audit rows hold ids and field names, never personal values (test A2) | Log the `contact_point` id, not the address; the log row keeps no body text |
| **An append-only log that keeps recipients forever** | Deletion must remove everything except financial records (decision 11, test D2) | The log stores a reference to the person and contact point; on erasure the references are cleared and the row reduced to channel, purpose, status, time |
| **No sending limits or quiet hours** | Over-messaging parents is a trust risk | A per-club setting for quiet hours and a daily cap per recipient |
| **Gmail OAuth as a main email path** | A club's own Gmail is a poor sender for parents' consent emails | **Resend or Postmark** with a dedicated domain (SPF, DKIM, DMARC), as TECH_STACK already says; keep SES-style signing out |

## 4. What this means for the steps

* **Step 1 (safe foundation):** only the pieces that do not need a provider: `consents`, `consent_links`, a **test inbox** that shows the email on screen, and the audit and consent rules above. No send function yet.
* **Step 2 (messages block):** the outbox, templates, the two single doors, Vault-held credentials per club, the log with erasure-safe references, delivery webhooks, suppression list. Email through Resend; WhatsApp through the official API behind the same door.
* **Later:** the shared-pool-with-approval idea and per-message billing, if Sportal ever offers a platform number.

## 5. Not checked

I read the code and migration comments only. I did not run SocietyPortal, did not read `SECRETS.md`, and did not check whether its dev project has live credentials. Behaviour described is what the code says it does.
