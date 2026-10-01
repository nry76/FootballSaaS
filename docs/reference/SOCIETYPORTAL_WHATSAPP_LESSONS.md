# What SocietyPortal teaches us about WhatsApp and email

Source: the owner's other product, `nry76/SocietyPortal` (housing societies, India). Read on 2026-10-01 by Claude: the Baileys and WhatsApp-web.js server READMEs, the channel table (`20260909150000_org_channels.sql`), the platform-pool migration header, the sender code outline and the notes in `docs/REQUIREMENTS.md`. **Not read: the rest of the repo, and `SECRETS.md` on purpose.** Unverified: whether it works in production.

## What it does
| Idea | How SocietyPortal does it | Use for Sportal |
|---|---|---|
| **One setting per club picks the channel** | WhatsApp mode: off / official (Meta) / whatsapp-web.js / Baileys. One secret per club | Same shape: a club-level channel setting, so the route can change without a rebuild |
| **Same "plug" for both private servers** | Both expose start, stop, logout, ping, send, qr, status, so the app does not care which is behind it | Keeps WhatsApp swappable (decision 114) |
| **Passwords and keys live in Supabase Vault** | The table holds only a pointer; only server functions read the real value | Fits our rule: never commit or store secrets in plain rows |
| **Changes go through checked, logged functions** | No direct edits to channel settings; every change checks permission and is audited | Fits our audit block |
| **Baileys needs an always-on small server** | Supabase functions cannot hold a live WhatsApp connection. One server hosts every society's session, with faults isolated per society | A cost and upkeep item for Sportal if Baileys is chosen |
| **Shared number vs the club's own** | A club can request the platform's shared number; the platform owner approves and can suspend any time. Official numbers are always per club | Worth copying if clubs have no WhatsApp number of their own |
| **Email: three senders** | Gmail login, Amazon SES, Resend | Email is the safe fallback channel |
| **The QR code step** | An admin scans a QR code in Settings to link the number | A real set-up step for each club |

## What its own notes admit (the important part)
* `REQUIREMENTS.md` says the single-number Baileys model **"does not scale, ToS risk"** and plans to **move to the official WhatsApp Cloud API or a business service provider** later. So your own earlier conclusion matches my warning.
* The Baileys server stores each WhatsApp login **unencrypted on disk**. Known and accepted there; for children's data this needs a harder look.
* whatsapp-web.js was dropped because it ran out of memory.
* The code comments say live sending was **not tested with real credentials**.

## What I did not see (check before copying)
* No sign of **consent, opt-out or marketing versus service** handling in the sender outline I read. Sportal must have this (decision 34), whatever the channel.
* No sign of sending limits or slow-down. Unofficial routes are usually banned for bulk or fast sending.

## Suggested use (a proposal, not decided)
1. Copy the **pattern**: club-level channel setting, same plug for every channel, secrets in Vault, checked and logged changes.
2. **Consent check sits in front of every channel**, so changing the channel can never skip it.
3. If Baileys is used for the pilot, label it a stop-gap and plan the move to the official route; ask the lawyer (LEGAL_REVIEW_LIST, section E).
4. Use **service messages only** (status updates the parent asked for) on an unofficial number. No marketing through it.
