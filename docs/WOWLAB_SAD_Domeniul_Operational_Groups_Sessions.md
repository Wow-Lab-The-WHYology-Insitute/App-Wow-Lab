# WOW LAB OS — SAD: Domeniul Operational (Grupe / Sesiuni / Prezență / Experimente Livrate)

**Statut:** document nou, scris azi — nu exista niciun SAD pentru acest domeniu (spre deosebire de Clients & Contracts). Construit pe baza a trei surse reale, nu presupuneri: `wow_lab_master_analysis.md` (procesul actual, din foi de calcul reale, folosite azi de echipă), taxonomia de curriculum construită anterior (13/15 module reale), și răspunsul complet al Ancăi despre trainer principal/secundar.

---

## 1. Decizia centrală de arhitectură: Grupă ≠ Sesiune

Confirmat direct din procesul real actual al echipei (`wow_lab_master_analysis.md`, secțiunile 4B/4C, surse: foile de calcul reale de Prezență și Experimente Livrate, ambele active azi):

> *"Structură: Școală → Grupă → Sesiuni săptămânale cu dată, număr de copii, nume trainer, P/A per copil"*
> *"Structură: Școală, Grupă, Nume experiment, Dată, Trainer, Modul"*

O **grupă** e containerul de înscriere (cine, la ce modul, cu ce program recurent). O **sesiune** e o apariție individuală, datată, cu propriul trainer alocat, propria prezență, propriul experiment predat. Această distincție nu e o alegere de design — e cum funcționează deja procesul real, azi.

**Consecință directă pentru trainer principal/secundar:** răspunsul Ancăi confirmă explicit rotația "sesiune cu sesiune" — *"rolurile se pot inversa... legate doar de un anumit curs/atelier"*. Alocarea de principal/secundar trăiește deci pe `sessions`, nu pe `groups`.

---

## 2. Entități (schema propusă)

### `groups` — containerul de înscriere
`id`, `organization_id`, `client_id` (FK → `clients`, deja confirmat în SAD Clients & Contracts), `module` (una din cele 13 module curriculare reale confirmate), `delivery_format` (`recurring` | `scoala_altfel` | `saptamana_verde` | `party` | `corporate` | `custom` — **decizie de lucru, risc acceptat**: split de la "Tip atelier", interpretare proprie, nu confirmată explicit de Anca, dar aleasă conștient azi de Mihai), `schedule_pattern` (text liber, ex. "Marți 14:00" — recurent) sau NULL pt evenimente unice, `children_confirmed` (int, după contract), `children_billed` (int, după livrare — pot diferi, confirmat din taxonomia anterioară), `status` (`active` | `paused` | `ended`), `notes`. 🔒 audited.

### `sessions` — apariții individuale, datate
`id`, `organization_id`, `group_id` (FK), `session_date`, `trainer_principal_id` (FK → `users`, nullable), `trainer_secundar_id` (FK → `users`, nullable), `status` (`planned` | `delivered` | `cancelled`), `attendance_count` (int, nullable — **numeric-first**, nu cere fișă nominală de copil), `experiment_delivered` (text liber acum — legătură la baza de planuri de lecție rămâne pt mai târziu, quando aceea există real în aplicație), `notes`. 🔒 audited.

**De ce NU tabele separate pentru Attendance/Delivered Experiments:** relația e 1:1 cu sesiunea (o singură cifră de prezență, un singur experiment per sesiune, confirmat din structura reală a foii de calcul) — conform principiului deja stabilit în SAD Clients & Contracts ("nu crea entități noi inutile, folosește câmpuri/vederi calculate în loc"), le păstrăm ca și coloane pe `sessions`, nu tabele proprii.

> Dacă vreodată o școală cere prezență nominală, pe copil (nu doar cifră) — asta ar deveni un tabel copil separat (`session_child_attendance`), NU o schimbare a principiului numeric-first implicit. Nu construim asta acum, fiindcă nu există cerere reală pt el.

---

## 3. Decizii de lucru, cu sursa lor explicită

| Decizie | Sursă | Status |
|---|---|---|
| Grupă/Sesiune ca tabele separate | `wow_lab_master_analysis.md` §4B/4C, proces real actual | ✅ Confirmat din date reale |
| Principal/Secundar pe sesiune, cu rotație | Răspunsul complet al Ancăi | ✅ Confirmat explicit |
| Prezență numeric-first | Convenție stabilită Phase 0 | ✅ Confirmat |
| Split Modul + Format livrare (2 câmpuri) | Interpretare Mihai, azi | ⚠️ Risc acceptat conștient, NU confirmat de Anca |
| `children_confirmed` vs `children_billed` separate | Taxonomie construită anterior (progress.md #37) | ✅ Deja aplicat în machetă |

---

## 4. Permisiuni (cele 4 niveluri, mirror pe modelul Clients & Contracts)

- **Menu:** Grupe & Înscrieri — Master, Operations, Finance Operations, Finance Admin & Reporting, Trainer/Senior Trainer (filtrat pe "ale mele"). Planificare & Alocări — Master, Operations, Finance Admin & Reporting (confirmat din decizia #25 — Anka are vizibilitate pe Planificare/Grupe).
- **Record:** Trainer/Senior Trainer văd DOAR sesiunile la care sunt alocați (principal SAU secundar) — nu tot tabelul de grupe.
- **Field:** fără câmpuri financiare sensibile pe acest domeniu direct (billing_rule rămâne pe `contracts`) — dar `children_billed` ar putea avea sens mascat pt Operations, de decis la construcție (nu blocant).
- **Action:** alocarea principal/secundar pe sesiune — Operations (Cătălina) decide/editează; Finance Admin & Reporting are vizibilitate, NU editare (per interpretarea răspunsului Ancăi — "Finance Admin cere acces" citit ca vizibilitate, nu proprietate asupra deciziei — de reconfirmat la construcție dacă ambiguu).

---

## 5. Ce NU construim acum

- **Tabelul de Disponibilitate Traineri** (`wow_lab_master_analysis.md` §4A) — instrument complet nou, nu există nici măcar ca foaie de calcul azi. Util pt Scheduling & Allocation, dar separat, mai târziu.
- **Legătura reală la baza de planuri de lecție** — `experiment_delivered` rămâne text liber până planurile de lecție există ca tabel real în aplicație (doar în machetă acum).
- **Prezență nominală pe copil** — rămâne numeric-first, cum e stabilit.

---

## 6. Legături cu restul arhitecturii

- `groups.client_id` → `clients` (Clients & Contracts, deja construit).
- `sessions.trainer_principal_id`/`trainer_secundar_id` → `users` (Phase 0).
- Facturarea viitoare va deriva din `sessions.attendance_count` agregat, nu din fișe nominale — consecvent cu principiul deja aplicat la Clients & Contracts.

---

## 7. Decizii deschise / de confirmat mai târziu (neblocante)

- Split Modul/Format — risc acceptat, de revizuit dacă Anca semnalează confuzie la folosire reală.
- Cine editează efectiv alocarea principal/secundar (Cătălina exclusiv, sau și Finance Admin) — ambiguitate reținută din răspunsul original, de clarificat la construcția UI-ului, nu blocant pt schemă.
