# WOW LAB OS — SAD: Domeniul Clients / Contacts / Contracts (CRM operațional)
### + granița de integrare cu ActiveCampaign

**Statut:** secțiune nouă de arhitectură, propusă pentru SAD. Acoperă golul semnalat („Schools/Clients CRM") și fixează cum se leagă de ActiveCampaign (CRM-ul de vânzări existent) și de SmartBill/SAGA (facturarea fiscală).

**Principiu de bază al secțiunii:** platforma **nu rescrie** ce funcționează deja afară. Construim doar partea **operațională și contractuală** a relației cu clientul — restul (lead-uri, pipeline, campanii) rămâne în ActiveCampaign, exact cum facturarea fiscală rămâne în SmartBill/SAGA.

---

## 1. Decizia de arhitectură centrală (propunere AD-15): granița de sisteme

Există trei sisteme care ating „clientul", fiecare cu rolul lui. Regula e: **fiecare layer are un singur sistem-sursă-de-adevăr (system of record).**

| Layer | Sistem-sursă | Ce deține | Ce NU face |
|---|---|---|---|
| **Vânzări & marketing (pre-client)** | **ActiveCampaign** | lead-uri, prospecți, **pipeline/deals**, campanii email, nurturing, marketing B2C părinți, contacte de marketing | — |
| **Operațional & contractual (client activ)** | **WOW LAB OS** | contul de client, contactele de contract, **contractele**, grupele, înscrierile, livrarea, datele de facturare, istoricul | nu ține pipeline de vânzări, nu trimite campanii |
| **Fiscal** | **SmartBill / SAGA** | factura fiscală propriu-zisă | — |

**Punctul de predare (handoff):** când un deal ajunge pe „Won" în ActiveCampaign, prospectul devine **client operațional** în WOW LAB OS. De aici încolo, sursa de adevăr pentru acel client e platforma. Înainte de „Won", sursa de adevăr e ActiveCampaign.

Astfel **nu există dublare de funcție** — același IBSB există în ambele, dar fiecare sistem ține altă felie: ActiveCampaign felia de „cum l-am câștigat / cum îi vorbim", WOW LAB OS felia de „ce contract are, ce grupe, ce livrăm, cât facturăm".

> De ce nu construim pipeline-ul în platformă: e exact capcana pe care brief-ul echipei o interzice peste tot („nu introduce complexitate inutilă", „nu reconstrui ce există"). Aveți deja ActiveCampaign plătit și funcțional; un al doilea pipeline ar însemna dublă întreținere și două surse de adevăr care diverg.

---

## 2. Cum interferează ActiveCampaign — și cum NU

Singurul punct de suprapunere reală e entitatea **Contact / Client**. Îl rezolvăm cu o referință, nu cu o copie.

- Fiecare client din WOW LAB OS poate purta un câmp **`external_crm_ref`** (id-ul contactului/deal-ului din ActiveCampaign). Așa știi că „IBSB" de aici e „IBSB" de acolo, fără să copiezi datele de marketing în platformă.
- **Contactele diferă intenționat.** În ActiveCampaign ai contactul de marketing (cine primește oferte/newslettere). În WOW LAB OS ai contactul **de contract/facturare** (cine semnează, cine primește factura — ex. `vlad.rasnoveanu@lyceefrancais.ro`). Pot fi persoane diferite la aceeași școală. Nu le forțăm să fie identice.
- **Datele de marketing (PII B2C) rămân în ActiveCampaign**, sub regimul lui (AC e găzduit în afara UE). Nu le tragem în platformă — granița UE/Frankfurt a WOW LAB OS rămâne pentru datele **operaționale**. Asta îți ține și suprafața GDPR mai mică, nu mai mare.

### Modul de sincronizare (recomandare în trepte)

| Versiune | Cum se face predarea AC → WOW LAB OS | Efort | Recomandare |
|---|---|---|---|
| **Integrare cerută (V1)** | **Webhook / API one-way AC → WOW LAB OS.** La schimbarea de stadiu pe „Won", ActiveCampaign notifică un endpoint din platformă care creează/actualizează clientul și salvează `external_crm_ref`. Tragem **doar câmpuri operaționale minime**: nume, tip, business line, contactul de contract, referința AC. | mic-mediu | ✅ **decis: se integrează** |
| Fallback / bootstrap | **Manual.** Creare client direct în platformă (pentru import inițial sau dacă webhook-ul pică). | zero | ca plasă de siguranță |
| — | Sincronizare în ambele sensuri | mare, fragil | ❌ nu |

**Decizie (echipă): integrarea cu ActiveCampaign e obligatorie, nu opțională.** One-way AC → platformă. `external_crm_ref` pe client de la început.

> ⚠️ **Notă de securitate (importantă).** Integrarea folosește **credențiale API ActiveCampaign** — deci intră sub regula A4 (cheile în Environment Variables / secret manager, **niciodată în cod**) și e o piesă „care poate pica în tăcere": are nevoie de o **verificare umană la poarta de credențiale** (aceeași grijă ca la OAuth/arhivator). În plus: tragem strict câmpurile operaționale de mai sus, **nu** date de marketing/PII din AC — ca să nu mutăm suprafața GDPR în platformă. AC e găzduit în afara UE; granița UE/Frankfurt a platformei rămâne doar pentru datele operaționale.

---

## 3. Roluri & proprietate (corectează modelul din brief)

Brief-ul echipei scotea `sales_manager` și `contract_administrator`. **Decizie: rămân.** Dar le clarificăm ce fac *în platformă*, fiindcă vânzarea propriu-zisă trăiește în ActiveCampaign.

| Rol | Ce deține în WOW LAB OS | Ce rămâne în ActiveCampaign |
|---|---|---|
| **sales_manager** | conversia lead → client operațional, fișa de client, vizibilitate pe reînnoiri, legătura `external_crm_ref` | pipeline-ul de deals, **ofertele/proposals**, campaniile, nurturing-ul, prospectarea |
| **contract_administrator** | **complet în platformă**: contractele (număr, perioadă, status semnat, reînnoire, arhivă link), pe entitatea legală corectă | — (contractul nu e marketing, e document operațional/legal) |

Restul atingerilor de CRM, conform brief-ului:
- **Master/CEO** (Anca): relații + BD (vede tot CRM-ul operațional).
- **Finance Operations** (Laura): contractele **școli private** + facturare pe prezență.
- **Finance Admin & Reporting** (Anka): contracte **corporate + stat + granturi**, raportare.
- **Operations Coordinator** (Cătălina): `clients.read` (vedere operațională, pentru alocare/grupe), fără partea financiară.

Permisiuni cumulative (multi-rol) ca peste tot — un om poate fi sales_manager + contract_administrator simultan.

---

## 4. Entități (model de date)

Aliniate la convențiile B1 (uuid, `organization_id`, timestamps, snake_case plural, RLS deny-by-default) și la principiul de simplitate (status + note + vederi calculate în loc de entități noi inutile).

### `clients` — contul de client (organizația-client)
Câmpuri-cheie: `id`, `organization_id` (FK — **AD-2: clientul aparține organizației, nu entității legale**), `name`, `client_type` (`private_school` | `state_school` | `corporate` | `parent_b2c` | `special_project`), `business_line`, `status` (`prospect` | `active` | `paused` | `churned`), `external_crm_ref` (id ActiveCampaign, nullable), `notes`. 🔒 audited.

> Notă: `prospect` există ca status doar pentru clienții pre-contract care au ajuns deja în platformă; pipeline-ul real de prospectare rămâne în ActiveCampaign.

### `client_contacts` — mai multe contacte per client
`id`, `organization_id`, `client_id` (FK), `full_name`, `role_at_client` (ex. „Head of Clubs", „Finance"), `email`, `phone`, `is_billing_contact` (bool), `is_primary` (bool), `notes`. **PII** → sub regulile GDPR (anonimizare la retenție). 🔒 audited.

### `contracts` — contractele
`id`, `organization_id`, `client_id` (FK), `legal_entity_id` (FK — **de pe care firmă se facturează**: Experimente Wow / Bradine ADV / STEMplicity), `contract_number`, `contract_type` (`recurring_annual` | `one_off_event` | `framework`), `period_start`, `period_end`, `status` (`draft` | `sent` | `signed` | `expired` | `renewed`), `renewal_of` (FK self, nullable — pentru lanțul de reînnoiri an de an), `billing_rule` (regula per client, ex. „95 lei/copil/ședință" sau „950 lei/atelier + TVA"), `drive_ref` (link la arhiva din Drive, AD-7), `notes`. 🔒 audited.

### Log de comunicare — **rămâne în ActiveCampaign** (nu se construiește în platformă)
Notele/apelurile/email-urile de relaționare rămân în AC. **Excepție acoperită automat:** pentru un client vechi activ sau unul care a fost client în trecut și revine, platforma păstrează deja **istoricul operațional** (contracte an-de-an, grupe/sesiuni, facturare) — vezi mai jos. Nu adăugăm o entitate `client_interactions` în V1.

> Client care revine: înregistrarea `clients` **persistă** (status `churned` → reactivare la `active`), deci tot istoricul lui de contracte și livrare e intact și vizibil la re-onboarding. Asta acoperă fix cazul „a fost client în trecut și revine", fără un log separat de comunicare.

### Reutilizăm ce există deja
- **`groups` / `group_enrollments`** (din domeniul operațional) se leagă de `client_id` → grupele unui client.
- **Facturarea** folosește codurile de azi (TIP-copii-ore-ore) + `contracts.billing_rule`, pe `legal_entity_id`.
- **Prezența** rămâne **numeric-first**: facturarea pe client derivă din numărul de prezențe, fără să ceară fișa nominală a copilului.

### Istoricul / „fișa 360" = vedere calculată, nu entitate grea
Timeline-ul clientului (contracte an-de-an, facturi, grupe/sesiuni livrate) e o **vedere agregată** peste `contracts` + facturare + `groups`/sesiuni. Conform principiului „ResourceConflict/MaterialReturn → vedere calculată" din brief: nu creăm o entitate „history" separată. Comunicarea de relaționare se vede în ActiveCampaign (linkată prin `external_crm_ref`).

---

## 5. Ciclul de viață al clientului (capătul-la-capăt)

```
[ActiveCampaign]                         [WOW LAB OS]                         [SmartBill/SAGA]
 lead → prospect → deal  ── Won ──▶  client (active) ──▶ contract ──▶ groups ──▶ sessions/attendance
                                          │                  │                        │
                                          └─ external_crm_ref └─ legal_entity_id       └─ cod facturare ──▶ factura fiscală
                                                                                                            ──▶ balanță lunară ──▶ Dashboard CEO
```

Predarea e un singur punct: **Won → client activ.** Tot ce e la stânga = ActiveCampaign; tot ce e la dreapta = WOW LAB OS (+ SmartBill/SAGA la capăt). Codul de facturare și balanța închid bucla spre dashboard-ul CEO (munca de acum câteva zile).

---

## 6. Permisiuni (cele 4 niveluri, cu accent pe Field Visibility)

- **Menu:** zona „Clients & Contracts" vizibilă pentru Master, sales_manager, contract_administrator, Finance (ambele), Operations (read).
- **Record:** Finance Operations vede contractele școli private; Finance Admin vede corporate/stat/granturi (segregare). Operations vede clienții, **fără** termenii financiari.
- **Field:** valoarea contractului / `billing_rule` / marja → vizibile pentru Finance + Master **+ sales_manager**; ascunse pentru Operations/Community/Trainer chiar dacă văd fișa clientului. (Exact cazul „Profit Margin ascuns într-un record altfel vizibil" din brief.)

> **CORECȚIE (2026-08-10):** formularea inițială de mai sus era „vizibile doar Finance + Master" — excludea explicit sales_manager. Contrazicea o decizie deja confirmată de Anca/Laura, notată în `docs/progress.md` #25: „Sales Manager vede regula de facturare pt TOTI clientii activi". Implementarea inițială (`contracts_billing_masked`, migrația `202608100004`) a urmat formularea SAD-ului de mai sus, ca sursă mai specifică/recentă pentru acest domeniu — semnalat explicit ca posibil conflict în raportul acelei treceri, nu aplicat orbește. Mihai a confirmat: decizia din progress.md #25 rămâne cea corectă, SAD-ul se corectează s-o reflecte. Vezi `docs/progress.md` pentru intrarea corespunzătoare și migrația de corecție a view-ului.
- **Action:** doar contract_administrator (+ Master) pot crea/edita/marca semnat un contract; sales_manager poate crea client + proposal; Operations doar citește.

Toate aplicate la nivel de bază de date (RLS pe `organization_id` + reguli pe rol), nu doar în meniu.

---

## 7. Legături cu restul arhitecturii

- **Legal entities:** `contracts.legal_entity_id` decide firma de facturare; clientul rămâne al organizației (AD-2).
- **Facturare & coduri:** `contracts.billing_rule` + codul TIP-copii-ore-ore + prezența numeric-first → datele de factură → SmartBill/SAGA → balanță → Dashboard CEO.
- **Operațional:** `groups` legate de `client_id`; livrarea și prezența populează istoricul clientului.
- **GDPR:** `client_contacts` = PII, în UE/Frankfurt, anonimizate la retenție; marketing PII stă în ActiveCampaign sub regimul lui (nu intră în platformă).
- **Audit:** clients/contracts/contacts sunt 🔒 (row-history: cine a schimbat termenii/statusul și când).

---

## 8. Ce NU construim (V1)

- pipeline de vânzări / stadii de deal / **oferte (proposals)** / campanii / automatizări de email → **rămân în ActiveCampaign**;
- factura fiscală propriu-zisă → **rămâne în SmartBill/SAGA**;
- sincronizare bidirecțională cu ActiveCampaign;
- scoring de lead-uri, marketing automation, formulare de captare → ActiveCampaign.
- **ștergere (hard delete) pe `clients` → închis, nu amânat.** `status = 'churned'` e deja
  răspunsul proiectat pentru „acest client nu mai e activ, dar istoricul rămâne" (§4, §9) — o
  funcție de delete ar fi un al doilea răspuns, contradictoriu, la o întrebare deja tranșată de
  aceeași secțiune. Verificat live înainte de a scrie asta (2026-08-25): toți cei 6 clienți reali
  au cel puțin un contract dependent (`contracts.client_id`, `client_contacts.client_id`,
  `groups.client_id` — niciuna dintre cele trei FK-uri nu are `ON DELETE`, deci implicit
  `RESTRICT`); nu există azi niciun rând care s-ar putea șterge fără să lovească restricția
  oricum. Dacă apare vreodată un motiv real să se reconsidere, pornește de la nota asta, nu de
  la zero — vezi și `docs/DATABASE_CONVENTIONS.md` §12 pentru versiunea scurtă, generică.

---

## 9. Decizii — ÎNCHISE (confirmate de echipă)

- [x] **Granița AD-15** (ActiveCampaign = vânzări/marketing; WOW LAB OS = operațional/contractual; predare la „Won") — **APROBATĂ**.
- [x] **Proposals** — **rămân în ActiveCampaign**. În platformă nu construim entitate `proposals`; opțional putem lega oferta AC prin `external_crm_ref`. Platforma ține doar contractul rezultat.
- [x] **Sync** — **integrarea AC e obligatorie**: webhook/API **one-way AC → platformă**, cu `external_crm_ref` pe client. Manualul rămâne doar ca fallback/bootstrap. *(Atenție la poarta de credențiale — vezi nota de securitate din §2.)*
- [x] **Roluri** — **`sales_manager` + `contract_administrator` rămân**, pe lângă split-ul de finanțe (Finance Operations + Finance Admin & Reporting) și rolul nou **Evaluator**. De reflectat în catalogul de roluri din SAD (OK de la Anca pentru structura de roluri).
- [x] **Log de comunicare** — **rămâne în ActiveCampaign**. Nu construim `client_interactions`. Cazul „client vechi care revine" e acoperit de înregistrarea `clients` care persistă (status `churned` → reactivare) + istoricul operațional (contracte/grupe/facturare).

---

## Următorii pași

Toate deciziile din §9 sunt închise — secțiunea e gata de integrat în SAD. Ce urmează:

1. **Catalogul de roluri** (pasul imediat) — reașez catalogul cu `sales_manager` + `contract_administrator` repuse, finanțe împărțite în două și Evaluator adăugat. Mai am de fixat 2–3 puncte deschise din Partea 14 a analizei (comasare Operations+Curriculum? amânare Procurement? soarta `senior_trainer`) ca să-l pot finaliza.
2. **Specificația integrării AC** — un mic document tehnic separat: evenimentul webhook „deal Won", maparea câmpurilor AC → `clients`, gestiunea credențialelor (A4) și poarta de verificare umană.
3. **Mockup** — fișa de client (contacte, contracte, grupe, istoric operațional) + badge „vânzări/oferte în ActiveCampaign" pe zona de pipeline.
3. Reflect domeniul în mockup (fișă client cu contacte, contracte, grupe, istoric + badge „CRM vânzări în ActiveCampaign" pe zona de pipeline).
