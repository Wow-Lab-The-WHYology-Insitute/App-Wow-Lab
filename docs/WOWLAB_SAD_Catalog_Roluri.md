# WOW LAB OS — SAD: Catalog de roluri (revizuit)

**Statut:** secțiune de SAD finalizată pe baza deciziilor luate cu echipa. Înlocuiește modelul vechi de 13 roluri și propunerea de 8 din brief cu un model **restructurat**.

**Mesaj-cheie:** numărul rămâne ~13, dar **setul e altul** — am restructurat, nu redus. Două roluri comasate, unul împărțit în două, unul nou adăugat, unul amânat.

> ⚠️ Restructurarea catalogului de roluri ține de structura organizației → recomand **OK explicit de la Anca** înainte de a o turna în seed.

---

## 1. Decizii încorporate

| Sursă | Decizie |
|---|---|
| brief + realitate (Cătălina) | **Operations + Curriculum → comasate** într-un rol |
| confirmat | **Finance → împărțit în două**: Finance Operations (Laura) + Finance Admin & Reporting (Anka) |
| confirmat | **Evaluator → rol nou** (separat de operațional/finanțe) |
| confirmat (AD-15 / CRM) | **`sales_manager` + `contract_administrator` → rămân** |
| confirmat | **Procurement → amânat din V1** (rămâne în catalog, neinstanțiat) |
| confirmat | **Senior Trainer → păstrat** ca treaptă, eligibil pentru Evaluator |
| AD-1 / memorie | **platform_owner → rămâne** (arhitectural, superuser cross-org, pregătit-de-franciză) |
| AD-6 | **candidate → rămâne** separat (portal magic-link, recrutare) |

---

## 2. Catalogul de roluri V1

| # | `role_key` | Nume afișat | Cine (azi) | Scop pe scurt |
|---|---|---|---|---|
| 1 | `platform_owner` | Platform Owner | Mihai / Anca (tehnic) | superuser cross-org, bypass RLS (vezi §3); pregătit-de-franciză |
| 2 | `organization_owner` | Master / CEO | Anca | vizibilitate totală, strategie, oversight financiar/operațional |
| 3 | `sales_manager` | Sales | (Anca / desemnat) | conversie lead→client, fișa client, reînnoiri, legătura cu ActiveCampaign |
| 4 | `contract_administrator` | Contract Administrator | (Laura / desemnat) | contractele (număr, perioadă, semnat, reînnoire, arhivă), pe entitatea legală |
| 5 | `operations_curriculum_coordinator` | Operations & Curriculum Coordinator | **Cătălina** | planificare, alocare/înlocuiri traineri, curriculum, certificări, readiness |
| 6 | `finance_operations` | Finance Operations | **Laura** | plată traineri, deconturi, facturare școli private, facturare pe prezență |
| 7 | `finance_admin_reporting` | Finance Administration & Reporting | **Anka** | contracte corporate/stat, granturi, import balanță, raportare la nivel de companie |
| 8 | `inventory_custodian` | Inventory Custodian | **Teo** | acuratețe inventar, custodie, validare retur, stări materiale (+ backup) |
| 9 | `community_people` | Community & People | **Alexandra** | onboarding, comunicare internă, echipă, media, cultură |
| 10 | `senior_trainer` | Senior Trainer | (traineri seniori) | tot ce face trainerul + **eligibil pentru Evaluator** |
| 11 | `trainer` | Trainer | trainerii | livrare ateliere, prezență, log experimente, certificări proprii, custodie materiale |
| 12 | `evaluator` | Evaluator | (seniori/coordonatori desemnați) | observare în clasă + evaluare, **doar evaluările alocate** |
| 13 | `candidate` | Candidate | candidați recrutare | acces izolat (magic-link): aplicație, test class |

**Tot 13 roluri ca număr** — dar alt set. Procurement nu mai e instanțiat în V1 (vezi §4); finanțele s-au împărțit; ops+curriculum s-au comasat; a apărut Evaluator.

---

## 3. Rol special: `platform_owner`

Rămâne modelat ca în arhitectura curentă:
- implementat prin **`users.is_platform_owner boolean`**, **nu** forțat în `user_org_roles`;
- rândul `platform_owner` **există** în tabela `roles` (pentru completitudine de UI/capabilități);
- devine **condiția de bypass RLS** în WS-D (singurul care vede cross-org).

Neschimbat de această revizuire.

---

## 4. Procurement — amânat (în catalog, nu în V1)

Conform brief-ului: **fără fluxuri de achiziție în V1**, iar Inventory Custodian „nu e procurement manager". 
- `procurement_manager` **NU se seed-uiește** în V1 (sau se marchează inactiv).
- Comenzile reale rămân pe canalele existente (Auchan, WhatsApp); în platformă, „Comenzi" e doar vizibilitate/planificare, nu flux de aprobare.
- Arhitectura păstrează locul ca să-l putem reintroduce ca rol în Phase 2 fără redesign.

---

## 5. Multi-rol (permisiuni cumulative)

Un user poate avea mai multe roluri; permisiunile sunt **union** (reconfirmat de brief). Exemple reale, actualizate:

- **Cătălina** = `operations_curriculum_coordinator` (+ opțional `evaluator`). *(Nu mai e „4 roluri" ca în modelul vechi — vezi impactul pe seed, §7.)*
- **Anca** = `organization_owner` (+ opțional `sales_manager`, `evaluator`).
- **Laura** = `finance_operations` (+ opțional `contract_administrator`).
- **Senior trainer** = `senior_trainer` + `evaluator` (când e desemnat).

---

## 6. Maparea rol → familii de capabilități *(pentru seed B4; de confruntat cu SAD Phase 5)*

Indicativ — grant-urile fine sunt în matricea Phase 5, care rămâne autoritatea.

| Rol | Familii de capabilități (principale) |
|---|---|
| `organization_owner` | `*.read` global + `finance.*`, oversight pe tot |
| `sales_manager` | `clients.create/convert/read`, `renewals.read`, `crm_link.*` (referință AC). **Fără** `proposals.*` (în AC) |
| `contract_administrator` | `contracts.*` (full), `clients.read` |
| `operations_curriculum_coordinator` | `operations.*` (planificare, alocare, înlocuiri), `curriculum.*`, `certifications.override`, `clients.read` (ops) |
| `finance_operations` | `finance.operations.*` (plată traineri, deconturi, facturare școli private, attendance billing), `contracts.read` (privat), `clients.read`. **Fără** profitabilitate companie |
| `finance_admin_reporting` | `finance.reporting.*` (companie, corporate/stat, granturi, import balanță, date Dashboard CEO), `contracts.*` (corporate/stat) |
| `inventory_custodian` | `inventory.*` (items, movements, status, validare retur) |
| `community_people` | `community.*` (onboarding, echipă, media, engagement) |
| `senior_trainer` | `trainer.*` + flag eligibil-evaluator |
| `trainer` | `workshops.own`, `attendance.own`, `experiment_logs.own`, `certifications.own`, `materials.custody`, `presentations.own` (save-as) |
| `evaluator` | `evaluations.write/read` **doar pe cele alocate** (acces minim necesar) |
| `candidate` | `candidate.self` (portal izolat) |

---

## 7. Impact pe seed Phase 0 (concret)

Restructurarea atinge WS-B — de actualizat **înainte** de rulare:

- **B4 (roluri):** lista de roluri și `role_capabilities` se rescriu pe catalogul din §2/§6. Numele se schimbă (ex. `finance_manager` → `finance_operations` + `finance_admin_reporting`; `operations_manager` + `curriculum_manager` → `operations_curriculum_coordinator`). `procurement_manager` nu se seed-uiește.
- **Checkpoint C (verificare):** verifica „exact 13 roluri" — **rămâne 13 ca număr**, dar actualizează **lista de nume** la cea din §2.
- **B5 (fixture de test):** `u_catalina` ține acum `operations_curriculum_coordinator` (+ opțional `evaluator`), **nu** vechiul set de 4 roluri.
- **Test RLS de compunere (#4):** se rescrie pe noul set (union `operations_curriculum_coordinator` + `evaluator`), nu pe cele 4 vechi.
- **Neatinse:** `platform_owner` via `is_platform_owner`; `org_b`/`is_test`; trainer own-data; OD-7 (`evaluations_confidential`).
- **WS-D câștigă scenarii noi:** acces-minim pentru `evaluator` (doar evaluările alocate) + **Field Visibility** (mascare termeni financiari de contract pentru roluri non-finance).

---

## 8. Permisiuni — cele 4 niveluri (reconfirmat)

Menu / Record / Field / Action rămân. Nou față de modelul vechi: **Field Visibility** explicit (ex.: valoarea/`billing_rule` a contractului vizibilă doar finance + Master; ascunsă pentru Operations/Community/Trainer chiar dacă văd fișa clientului). Toate aplicate la nivel de bază de date (RLS), nu doar în meniu.

---

## 9. De confirmat

- [ ] **OK de la Anca** pe catalogul restructurat (structură de roluri = autoritatea ei).
- [ ] Cine primește efectiv `evaluator` la start (Cătălina? un senior trainer anume?).
- [ ] `sales_manager` și `contract_administrator` — pe ce persoane reale le punem la go-live (azi par a fi Anca/Laura prin acumulare de roluri).

---

## Următorii pași

1. Anca aprobă catalogul (§9).
2. **Actualizez prompturile B4/B5 + checkpoint C** pe noul set de roluri (ca să poți rula seed-ul corect).
3. Apoi: specificația integrării ActiveCampaign + alinierea mockup-ului (8→ noul set de roluri în comutator, fișa client, 3 categorii inventar, Evaluator, Academie, alerte).
