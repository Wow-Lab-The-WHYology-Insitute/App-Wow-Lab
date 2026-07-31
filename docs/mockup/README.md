# WOW LAB OS — Product Mockup

`wow_lab_os_mockup.html` is the **single canonical mockup** for WOW LAB OS. No other copy —
in Downloads, in chat history, in an email, anywhere — should be treated as current. Any future
update to the mockup is an edit to **this file**, reviewed via a normal `git diff`/PR, never a
full regeneration from scratch. This replaces the earlier practice of passing detached file
exports across chat sessions, which is exactly how this file ended up with several
stale, conflicting copies floating around before this commit.

## What this is

A static HTML/JS demo with hardcoded, fictional-but-realistic data. There is no real backend —
it does not talk to Supabase, and it is entirely separate from the actual Next.js application in
`app/`. Open the file directly in a browser; nothing needs to be built or served.

## Bilingual

English is the default language; Romanian is a real, switchable locale via the EN/RO toggle in
the top-right, not just a reflection of whatever language a given conversation happened to be in.
This mirrors the app's actual i18n rule. A `?locale=ro` URL parameter works the same way as the
toggle, and combines with `?role=` (e.g. `?locale=ro&role=trainer`).

Proper nouns — real school/company/people names, and official Romanian program names such as
*Școala Altfel*, *Săptămâna Verde*, *Wow Lab Party* — are intentionally **not** translated in
either locale.

## What this version recovered

This mockup reconciles two older, superseded iterations, and restores several things that had
been dropped or simplified along the way:

- A real client list: 15 schools, with real pricing and contacts.
- Real workshop-type billing codes: `SP`, `SPCO`, `SA`, `SV`, `COM`, `EPC`, `EP`, `CD`, `WLP`.
- A dedicated **Onboarding** screen. It's state-gated: a candidate only sees it after staff
  marks them accepted in Recruitment — candidates cannot self-accept.
- A **Media/assets** screen.
- Real module names in lesson plans.
- A 7-tier trainer classification, plus a zone field.

## Known open item

The workshop-type taxonomy (the `TIPS` object) is flagged in-app with a banner. It needs
reconciliation with Anca's Phase 1 feedback — see `wowlab_feedback_analiza.xlsx`, cluster
"Planuri de lecție & taxonomie" — before it can be treated as final.
