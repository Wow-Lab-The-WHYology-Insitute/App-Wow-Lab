# WOW LAB OS — Phase 1 Development Plan

> Plan de dezvoltare pentru Phase 1 (funcționalități de business, peste fundația Phase 0 deja completă). Actualizat pe măsură ce avansăm — verificat periodic față de `docs/progress.md`, ca nimic să nu se piardă.

**Ultima verificare:** 2026-08-10 (Costuri Admin + Offboarding aplicate din răspunsurile Ancăi; Vercel/repo — vezi progress.md #38-41)

**Regulă de întreținere:** orice epic/decizie nouă (din feedback, din Asana, din discuții) primește un rând aici. Când se închide, se marchează ✅ și rămâne ca istoric — nu se șterge.

---

## 1. Rezumat status (dintr-o privire)

| # | Workstream | Status | Sursă | Notă |
|---|---|---|---|---|
| 1 | Vizibilitate financiară Anka (Finance Admin & Reporting) | ✅ **Rezolvat** | progress.md #25 | Aplicat în machetă |
| 2 | Tarif de bază 111 lei/oră, editabil din Setări | ✅ **Rezolvat** | progress.md #25 | Aplicat în machetă |
| 3 | Vizibilitate Sales Manager (billing rule) + client ONG | ✅ **Rezolvat** | progress.md #25 | Aplicat în machetă |
| 4 | Franciza / Platform Owner cross-org stats | 🔵 **Amânat conștient** (Phase 2) | progress.md #25 | Nimic de făcut acum |
| 5 | Structură tabel Plata traineri (Laura) | ✅ **Rezolvat** | progress.md #25 | Aplicat în machetă |
| 6 | **Modul nou: Costuri Admin** (Anka/Laura/Raluca) | 🟢 **Tarife confirmate de Anca, aplicate în machetă** | progress.md #42-43 | Toate tarifele finale (inclusiv corecția pe cifrele Ankăi). Rămâne: construcție reală în Phase 1, confirmare că task-ul Asana chiar există |
| 7 | Recrutare → Academy → Evaluare (flux complet) | 🟢 **Specificat + în machetă** | progress.md #37, #42 | Onboarding + evaluare din sesiunea de taxonomie; checklist real de offboarding aplicat #42 (halat/materiale/acces/exit interview/stare "pe pauză") |
| 8 | Profil & Performanță Trainer | 🟡 **Parțial** | Asana Task 7 (epic) | Zonă/nivel/ore/bonus în machetă; KPI eficiență, disponibilitate, commitment — nefăcute |
| 9 | Planuri de lecție & taxonomie "Tip Atelier" | 🟢 **Construit cu date reale, verificat** | commit d06e3a4 / progress.md #37 | 13 din 15 module reale confirmate, 26 planuri reale, filtrare funcțională. 2 module + cost auto-calc + istoric livrare rămân deschise |
| 10 | Trainer principal/secundar per grupă | 🔴 **Nefăcut, FĂRĂ task Asana** | feedback rd. 43, 75 | **Gap real — niciodată nu a primit propriul task** |
| 11 | Separare Generator cod facturare / Plată traineri | 🔴 **Nefăcut** | feedback rd. 34 | Doar banner de atenționare în machetă |
| 12 | S3 — shell de brand pe restul aplicației reale | ✅ **Complet, verificat pe device real** | progress.md #26-33 | Vezi detaliu §4 |
| 13 | Favicon (aplicația reală) | ⚪ **Neconfirmat** | progress.md #24 | Prompt dat, niciun raport de finalizare primit |
| 14 | Pagină de confirmare /auth/callback (anti-scanner) | ⚪ **Neconfirmat, opțional** | progress.md #24 | Prompt dat, niciun raport primit — neblocant |
| 15 | Developer security review gate | 🔵 **Închis — risc asumat conștient, decizie explicită Mihai (2026-08-07)** | Phase 0 | NU se face review extern; se merge mai departe pe baza suitei de teste RLS + verificării organice de azi (§4) |
| 16 | Repo GitHub — revenire la Privat | 🔵 **Amânat conștient, cu declanșator clar** | progress.md #38-39 | Momentan PUBLIC (decizie explicită Mihai — deploy automat Vercel > protecție date, pe Hobby plan). Revine Privat quando: (a) upgrade Vercel la Pro, ȘI (b) aplicația la o etapă mai matură. Supabase e neconcordat tehnic cu asta — separat |

**Legendă:** ✅ rezolvat/aplicat · 🟢 specificat, gata de construit real · 🟡 parțial/schelet · 🔴 nefăcut · 🔵 amânat conștient · ⚪ neconfirmat (prompt dat, fără raport)

---

## 2. Verificare de completitudine — ce am găsit lipsă

Am comparat: cele 73 de rânduri din `wowlab_feedback_analiza.xlsx`, cele 9 task-uri Asana create, și toate intrările din `progress.md`. Trei lucruri nu aveau încă un loc clar:

1. **Trainer principal/secundar (rândurile 43, 75)** — a fost identificat ca cerință de model de date, dar **nu i s-a creat niciodată un task Asana propriu**. E în lista de mai sus (#10), dar rămâne fără proprietar clar.
2. **Modulul de Costuri Admin** — apărut din răspunsul Laurei, adăugat ca schelet în machetă și notat în progress.md #25, dar **nu are încă task Asana** (ți l-am oferit data trecută, n-am primit confirmare).
3. **Offboarding-ul trainerilor** — fluxul desenat de Anca (prin ChatGPT) acoperă recrutare→onboarding→evaluare foarte detaliat, dar **nu atinge deloc ce se întâmplă când un trainer renunță** (procedură menționată explicit ca "în lucru" în răspunsul inițial al Ancăi, rd. 26). Rămâne un gol real, nu doar o simplificare de machetă.

Restul (S3, favicon, pagina anti-scanner, review de securitate) erau deja notate ca deschise în `progress.md` #24 — le-am adus aici doar ca să fie vizibile într-un singur loc, alături de tot restul planului.

**Actualizare 2026-08-07:** toate cele 3 goluri de mai sus au primit task-uri Asana (Costuri Admin, Offboarding traineri — în așteptare, Trainer principal/secundar) — de confirmat de Mihai că au fost adăugate efectiv.

**Actualizare 2026-08-10:** gap-ul #3 (offboarding) închis — Anca a răspuns complet (checklist, exit interview, revocare acces, stare "pe pauză"), aplicat în machetă (progress.md #42). Gap-urile #1 și #2 rămân deschise — task-urile Asana pentru ele nu sunt încă confirmate ca create.

---

## 3. Detaliu — Recrutare → Academy → Evaluare (azi)

Anca a recreat fluxul cu ChatGPT (2 diagrame: onboarding + evaluare) și a inclus un prompt pentru Claude, cu constrângeri explicite (nu redesenăm aplicația, reutilizăm ecrane existente, minim necesar). Aplicat azi în machetă:

- **Recrutare** — stadii reale (handover Anca→Cătălina, asistare, lecție de test, decizie finală), responsabil + acțiune următoare + termen
- **Portal candidat** — stadiu aliniat la termenii reali din flux
- **Onboarding** — tracker operațional de trainer (contract, module alocate, acces resurse, quiz, certificare)
- **WLab Academy** — module reale (Chemistry for Me, Detective Science, Green Week), 4 stări: alocat → acces → quiz → certificat
- **Evaluări în clasă** — separat 3-luni/la cerere vs. Anual, evaluator, link extern Google Forms (doar status, nu recreat), concluzii + plan de dezvoltare
- **Traineri** — panou nou "Necesită acțiune" (admin trainer view)

**Ce lipsește din fluxul primit:** offboarding-ul (vezi §2, punctul 3) — Anca a zis explicit că procedura e "în lucru", deci normal că nu apare încă. De adăugat ca task separat.

---

## 4. Detaliu — S3 (shell de brand), complet și verificat pe device real

Construit peste `/whoami` și `/admin/users`: sidebar închis (wordmark gradient), nav condiționată de `org.members.manage` (blocată și server-side, nu doar ascunsă cosmetic — confirmat cu Cătălina, fără acces, primește "Access denied" la acces direct), responsive complet pe mobil (sidebar, checkbox-uri, tabel→carduri, spațiu mort din `100vh`/`dvh`, logo în topbar mobil) — **toate confirmate pe iPhone real de Mihai**, nu doar emulat.

**Bonus neplanificat — 2 bug-uri reale de securitate/corectitudine găsite și reparate pe drum**, exact datorită faptului că am testat cu 13 useri reali în loc de fixture-uri:
1. **Tabelul de membri era gol dintotdeauna** (ambiguitate de foreign key în PostgREST, eroare niciodată verificată) — reparat, verificat semantic corect.
2. **Orice DELETE pe cele 4 tabele auditate era anulat silențios** de un bug de trigger vechi (probabil de la construcția inițială a WS-B/WS-D) — asta însemna că funcția "elimină un rol" din `/admin/users` **nu a funcționat niciodată corect**: eșua vizibil în majoritatea cazurilor, dar silențios (fără nicio eroare) în două cazuri — eliminare totală a rolurilor, sau înlocuire cu un set fără suprapunere. Reparat, verificat de două ori independent, inclusiv un audit istoric care a confirmat că niciun user real n-a fost afectat vreodată (nimeni nu încercase de fapt eliminarea unui rol înainte de fix).

**Plus, o a treia descoperire** (progress.md #35-36): userii invitați dar niciodată confirmați nu se pot loga prin formularul public — blocaj structural (`disable_signup`), nu legat de rate-limit. Reparat prin reinvitare directă, nu prin retrimitere de magic-link.

**Plus, verificarea end-to-end pe toate 7 conturile reale** (progress.md #36) — rol, meniu, capabilități, spot-check-uri RPC, toate corecte, 7/7, confirmate manual de Mihai.

**Decizie finală (2026-08-07):** gate-ul formal de review extern de developer **NU se mai face** — Mihai a ales conștient să meargă mai departe fără el, pe baza a ce există deja: suita de teste RLS (12/12 + 8/8 asertări, cu test de sabotaj funcțional), plus cele 3 descoperiri de mai sus găsite organic, cu dovadă live, nu ipotetic. Rândul #15 din tabelul de mai sus e închis oficial cu acest raționament, nu doar amânat.

---

## 5. Ce urmează, în ordine recomandată

1. Trainer principal/secundar, Costuri Admin, Offboarding traineri — task-uri Asana date, de confirmat că au fost adăugate — closes gap-ul de la §2
2. Cere-i Ancăi procedura de offboarding, când e gata — al treilea gap de la §2
3. ~~Taxonomia "Tip Atelier"~~ — ✅ **construită și verificată** (commit d06e3a4, progress.md #37) — vezi rândul #9 din tabel
4. **Separare Generator cod facturare / Plată traineri** — era blocată de taxonomie, acum deblocată, următorul pas real de atacat (rândul #11 din tabel)

*(Gate-ul WS-D nu mai apare aici — închis conștient la §4, nu mai e un pas de făcut.)*
