# Tech stack (v0.1, agreed direction, details still open)

Supabase is the base (your choice). The rest is recommended, with the reason.

| Layer | Choice | Why |
|---|---|---|
| Database, auth, files, jobs | **Supabase** (Postgres + row-level security, Auth, Storage, Edge Functions, Vault, `pg_cron`), **Frankfurt (eu-central-1)** | Tenant and child-safety rules live in the database. One project for all clubs. Frankfurt chosen so EU data-protection standards apply. |
| Web app | **Next.js (App Router) + TypeScript**, hosted on **Vercel** with functions pinned to the Frankfurt region | Server rendering suits dashboards; next to the database for low latency. |
| UI | **Tailwind + shadcn/ui** | Accessible components. |
| Languages | English at launch; strings kept in one translation file (**next-intl**) so languages can be added later. Currency, time zone and weekend days come from club settings, using standard `Intl` formatting | Built for global clubs. Arabic only in optional name fields. |
| Data access | **supabase-js + generated types**. No ORM for user-facing reads | ORMs usually bypass row-level security; going through the user's own session keeps it always applied. |
| Mobile | **PWA only.** No App Store or Play Store apps | Your decision: updates ship instantly. Trade-off: iPhone push notifications need "Add to Home Screen". |
| Payments | **Provider-neutral gateway layer**, each club's own keys in Supabase Vault, webhooks handled by Edge Functions | Matches "each club plugs in its own keys". Gateway choice deferred. |
| Email | **Resend or Postmark**, dedicated sending domain (SPF, DKIM, DMARC) | The parental-consent email must reach inboxes. |
| Background jobs | **`pg_cron` + Supabase Queues + Edge Functions** | Deadline alerts, overdue status, ID-image purge, deletion windows, 1-year financial purge. |
| Media | **Supabase Storage, photos only** for now | Video deferred to a later phase. |
| Identity check | **Manual review** by Manager/Admin in v1 | No vendor contract needed; images stay in our storage and are auto-purged. |
| Testing | **Vitest, Playwright, pgTAP**, GitHub Actions, gitleaks | Automated "Club A can never see Club B / unconsented child" tests on every change. |
| Monitoring | **Sentry**; privacy-first analytics; **no session replay** on screens showing children | Session recording of minors' screens is a liability. |
| Secrets | `.env.example` only; Vercel env vars; Supabase Vault; service-role key server-side only | Per your constraint. |

## Considered and not chosen
* Firebase: weak fit for relational data; no equivalent of row-level security.
* Custom Node backend: more to run and secure at this stage.
* Native iOS/Android apps: excluded by your PWA decision.
* Clerk / Auth0: Supabase Auth suffices; age-tier and consent rules are custom anyway.

## Deferred
Payment gateway, video, WhatsApp/SMS, ID-verification vendor, FANet integration.

## To confirm with legal counsel (not decided by us)
* Which data-protection laws apply to a UAE club's data hosted in Frankfurt (EU rules, and the UAE PDPL for UAE residents).
* Data-processing agreements with Supabase, Vercel and the email provider.
* Whether hosting UAE residents' children's data outside the UAE needs additional notices or safeguards.
