# WOW LAB OS — Progress Log

> Jurnal de progres al construcției. Actualizat pe măsură ce avansăm. Recomandat: ține-l în repo la `docs/progress.md`.
> **Convenție de timp:** fiecare intrare poartă data/ora **Bucureștiului**. Cele scrise de Claude au ora luată din sistem la momentul scrierii; cele adăugate de tine — notează ora de atunci.

**Ultima actualizare:** 2026-07-09 17:33 (ora București)

**Unde suntem acum:** Phase 0 → **WS-B COMPLET** (B1–B5 aplicate, Checkpoint A/B/C/D toate verzi, tot pe GitHub). Urmează **WS-D** (RLS) — prima poartă cu review de developer.

**Coordonate proiect:**
- Repo: `github.com/Wow-Lab-The-WHYology-Insitute/App-Wow-Lab` (branch `main`)
- Supabase project ref: `dbchdbxojeczjglugbhe` (EU/Frankfurt)
- Platformă: `app.wowlab.ro`
- Secrete (token Supabase, parolă DB): doar în terminal/env, **niciodată în cod**

---

## Snapshot status

| Zonă | Status |
|---|---|
| Infra (GitHub, Vercel, Supabase Frankfurt, domeniu+SSL, 2 owneri) | ✅ gata |
| Mediu dev (Supabase CLI linkat, repo conectat la GitHub, .gitignore) | ✅ gata |
| WS-B · B1 convenții | ✅ |
| WS-B · B2 tenancy + identitate | ✅ aplicat |
| WS-B · Checkpoint A | ✅ verde |
| WS-B · B3 permisiuni + audit + storage | ✅ aplicat |
| WS-B · Checkpoint B | ✅ verde |
| WS-B · row_history pe legal_entities + file_refs | ✅ |
| WS-B · B4 seed 14 roluri (14/38/119, idempotent) | ✅ aplicat |
| WS-B · Checkpoint C (SQL + C.7 reconciliere) | ✅ verde |
| DATABASE_CONVENTIONS.md creat ca fișier (docs/, commit b8e4d90) | ✅ |
| WS-B · B5 org + entități + 7 useri test | ✅ aplicat (commit 526bae7) |
| WS-B · Checkpoint D | ✅ verde |
| **WS-B COMPLET** | ✅ **2026-07-09** |
| WS-D (RLS, poartă review developer) | 🔶 în curs (D0) |

---

## Ce există în baza de date (schema public) acum

11 tabele: `organizations`, `legal_entities`, `users`, `user_org_roles`, `org_settings` (B2) · `roles`, `capabilities`, `role_capabilities`, `audit_log`, `row_history`, `file_refs` (B3).
Toate cu RLS pornit **deny-by-default** (politicile permisive vin în WS-D). `roles`/`capabilities`/`role_capabilities` sunt goale (se populează la B4).

**Tabele auditate (au trigger row_history pe UPDATE+DELETE):** `user_org_roles`, `org_settings`, `legal_entities`, `file_refs`.
→ Regulă permanentă: orice tabel „audited" nou din fazele viitoare primește același trigger `row_history`.

---

## Jurnal cronologic

**Sesiune (iulie 2026)**

1. **Mediu dev — reparație de fundație.** La pornire, migrările nu ajungeau în Supabase și folderul local părea gol. Cauze descoperite și rezolvate:
   - Supabase CLI nu era instalat → instalat (`npm install --save-dev supabase`), `supabase init`, link la project ref `dbchdbxojeczjglugbhe`.
   - Migrările erau scrise, dar **neaplicate** → aplicate cu `supabase db push`. **Lecție:** a scrie un fișier de migrare ≠ a crea tabelul; trebuie `db push`.
   - Folderul local **nu era un repo git** → conectat la repo-ul GitHub existent (era gol, fără conflicte); creat `main`, push. Acum: laptop → GitHub → Vercel + Supabase.
   - Creat `.gitignore` (node_modules, .env*, supabase/.temp/, pattern-uri de credențiale). `config.toml` + `migrations/` rămân urmărite.

2. **B1 — Convenții.** `DATABASE_CONVENTIONS.md` creat; cele 10 puncte revizuite și acceptate (conforme cu planul: uuid, tenancy org_id, platform_owner prin flag, timestamps, roluri ca date, RLS deny-by-default, audit append-only, GDPR UE/36 luni, migrări vs seed).

3. **B2 — Tenancy + identitate.** Migrări aplicate: `organizations`, `legal_entities`, `users`, `user_org_roles`, `org_settings`. `roles` a apărut ca schelet (pentru FK-ul `user_org_roles.role_id`).

4. **Checkpoint A — verde.**
   - A1: cele 5 tabele există.
   - A2: RLS `true` pe toate (inclusiv `roles`).
   - A3: `organization_id` NOT NULL pe legal_entities/user_org_roles/org_settings; absent pe `organizations` (0).
   - A4: `created_at`/`updated_at` peste tot.
   - A5: unicitate confirmată — `user_org_roles` are **o singură** constrângere unică **compusă** pe `(organization_id, user_id, role_id)` (`user_org_roles_unique_organization_user_role`) → multi-rol funcționează.

5. **B3 — Permisiuni + audit + storage** (prompt ajustat idempotent, ca să nu recreeze `roles`). Aplicat: `capabilities`, `role_capabilities`, `audit_log` (append-only), `row_history`, `file_refs`; `roles` aliniat.

6. **Checkpoint B — verde.**
   - B.1: tabele de referință fără org_id, tabele de business cu org_id.
   - B.2: triggere — `audit_log_prevent_modification` pe UPDATE+DELETE (append-only ✅), row_history pe user_org_roles+org_settings, `set_updated_at` peste tot.
   - B.3 comportamental: TEST 1 append-only **PASS** (UPDATE și DELETE respinse), TEST 2 row_history **PASS** (old/new populate), TEST 3 updated_at „FAIL" = **fals-negativ** (now() e înghețat per tranzacție; funcția `trigger_set_updated_at` confirmată corectă prin inspecția definiției).

7. **Follow-up — row_history extins.** Migrare mică idempotentă: trigger `row_history` atașat și pe `legal_entities` și `file_refs` (erau marcate „audited" fără istoric). Verificat înainte/după. Acum toate cele 4 tabele sensibile au istoric.

8. **B4 — seed aplicat** *(2026-07-09, ~13:30 București)*. 14 roluri / 38 capabilități / 119 role_capabilities, idempotent (re-rulare fără schimbări). Verificări: segregare finanțe corectă (finance_operations 0 raportare, finance_admin_reporting 1); cazul Cătălina = 16 capabilități distincte (7+7+2, zero suprapunere); procurement_manager necreat; finance_manager inexistent. Denumiri aprobate: platform.cross_org.access / platform.admin.manage / platform.org_switcher.use, candidate.portal.access.
   - **Descoperit:** `DATABASE_CONVENTIONS.md` nu fusese scris ca fișier la B1 (doar afișat în chat); convențiile au fost deduse din migrări. De creat ca doc canonic în `docs/`.
   - **Decizie de dus în WS-D:** wildcard-urile (`curriculum.*`, `contracts.*`, `finance.operations.*`, `inventory.*` etc.) sunt stocate ca **un singur rând literal**, nu desfăcute. Resolver-ul de capabilități + RLS din WS-D **trebuie să facă potrivire pe prefix/glob** (și de testat) — altfel un user cu `curriculum.*` nu rezolvă nimic în tăcere.

9. **Checkpoint C — verde** *(2026-07-09, 13:45 București)*. SQL Editor independent: 14 roluri, 0 dubluri, structural corect. C.7 reconciliere: toate cele 14 roluri PASS, zero over/under-grant, zero ambiguitate. `docs/DATABASE_CONVENTIONS.md` creat, comis și împins (b8e4d90).
   - **Item deschis (neblocant):** nu există un artefact SAD Phase 5 în repo — C.7 s-a făcut față de catalogul de 14 roluri aprobat (care e și sursa seed-ului), nu față de un SAD independent. De adus matricea de permisiuni din SAD în `docs/` mai târziu, pentru audit cu adevărat independent.
   - **Reparat:** migrările 202607080003 (B3), 202607080004 (row_history) și `supabase/seed.sql` (B4) erau **aplicate pe DB dar necomise** în git (repo-ul diverja de bază). De aici înainte: **fiecare pas se termină cu commit + push**, ca repo-ul să reproducă mereu baza. *(Rezolvat: commit 5b10e32.)*

10. **B5 — seed aplicat** *(2026-07-09, ~13:50 București, commit 526bae7)*. 2 organizații (`wow-lab` + `wow-lab-test-b` permanent), 3 entități legale sub wow-lab, OD-7 pe ambele, 7 useri de test. Idempotent. `u_catalina` = 16 capabilități (reuniunea celor 3 roluri).

11. **Checkpoint D — verde** *(2026-07-09, 13:58 București)*. D1–D3 ok; D4 cei 7 useri corecți; D5 capabilități rezolvate corecte; **D5b segregare finanțe** (ops 0 / admin 1) ✅; **D6 invariant platform_owner** (flag true, 0 rânduri în user_org_roles) ✅.

12. **WS-B COMPLET** *(2026-07-09)*. Fundația (tenancy, identitate, permisiuni-ca-date, audit, storage) + seed-ul (14 roluri, org-uri, useri de test) sunt aplicate, verificate și pe GitHub. Urmează **WS-D** (RLS) — prima poartă care cere review de developer.

13. WS-D pornit (2026-07-09). Plan salvat la docs/ws-d-plan.md (commit 8087c75). Poarta de review developer: AMANATA (risc etichetat). Urmatorul pas: D0 — functii-helper RLS.

---

## Lecții / capcane (de nu uitat)

- **Migrare scrisă ≠ aplicată.** Tabelele apar doar după `supabase db push`.
- **`now()` e înghețat per tranzacție** → `updated_at == created_at` dacă insert+update sunt în aceeași tranzacție. Nu e bug; a produs un fals-negativ la testul updated_at.
- **Warning Docker la `db push`** („Cannot connect to the Docker daemon") = inofensiv; Docker e doar pentru DB local, nu pentru push pe remote.
- **`roles` a fost creat ca schelet** devreme (FK) → prompturile de schemă trebuie **idempotente**, nu recreează/nu dau drop.
- **Secrete niciodată în cod** — doar env/terminal; `.gitignore` verificat.
- **Verde în checkpoint-uri ≠ izolare RLS sigură** — SQL Editor rulează cu service role (ocolește RLS). Izolarea reală = **WS-D**, cu review de developer.

---

## Ce urmează

**WS-D — RLS (Week 3, prima poartă cu review de developer).** Aici se scriu politicile permisive per tabel și se dovedește izolarea reală:
1. `org_b` (wow-lab-test-b) NU vede datele lui `wow-lab` (cross-org).
2. Trainerul vede doar ce e al lui (own-data).
3. OD-7 chiar ascunde evaluările față de trainerul evaluat.
4. `finance_operations` chiar nu vede profitabilitatea companiei (field/record segregation).
5. **Resolver-ul de capabilități face potrivire pe prefix/glob** pe wildcard-uri (ex. `curriculum.*`) — altfel rezolvă nimic în tăcere.

**Reguli WS-D:** testele trebuie să ruleze **ca utilizatorii de test** (nu ca service role, care ocolește RLS), suita **trebuie să și pică** când strici intenționat o regulă, și e nevoie de **review de developer** (nu te bazezi pe „verde").

**Item deschis:** adus matricea de permisiuni din SAD în `docs/` pentru audit independent.
