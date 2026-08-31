# WOW LAB OS — SAD: Contracte de trainer și furnizor

**Status:** propunere de arhitectură, neimplementată
**Data:** 31 august 2026
**Decizii de la Anca:** primite (§2, §12)
**Prerechizit blocant:** `groups.contract_id` (§6) — confirmat de Mihai, de implementat înainte
**Depinde de:** `WOWLAB_SAD_Field_Masking.md` (mecanismul de mascare), `WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md` (contractele de client)

---

## 1. De ce document separat

Platforma are azi un singur fel de contract: cel cu clientul. Bani care intră.

Contractele de trainer și de furnizor sunt bani care ies, iar diferența nu e doar de semn.
Contrapartida e alta, rolurile care le administrează sunt altele, iar regula de segregare a
atribuțiilor din contractele de client se inversează. Un discriminator pe tabelul existent ar
însemna ramuri în fiecare politică RLS și în funcția de mascare — vezi §4 pentru de ce e
periculos, nu doar incomod.

---

## 2. Deciziile Ancăi (august 2026)

| Întrebare | Răspuns |
|---|---|
| Cine citește contractele de trainer | Laura, Anca, Anka |
| Cine citește contractele de furnizor | Anka, Anca |
| Cine creează și editează, ambele feluri | Laura, Anca, Anka |
| Trainerul își vede propriul contract | Nu e obligatoriu. „Dacă aplicația permite și putem seta accesul astfel încât fiecare trainer să vadă doar propriul contract, ar putea fi util, dar dacă e o complicație, renunțăm." |
| Cătălina vede statusul contractului la alocare | Da — și **perioada de valabilitate**, nu doar semnat/nesemnat, ca să nu aloce un trainer cu contract expirat |
| Contracte pe mai multe entități | Da. Un trainer poate avea contracte cu toate cele trei entități simultan, în funcție de proiectul sau clientul pentru care lucrează |

Segregarea e asimetrică și intenționat așa: **Anka vede contractele de trainer, Laura nu le
vede pe cele de furnizor.**

Decizii suplimentare de la Anca, pe cele trei întrebări deschise din §9:

- **Numerotarea.** Un registru per entitate juridică, comun contractelor de client, trainer și
  furnizor — nu un registru separat per tip de contract. Trei registre: Experimente Wow,
  Brandine Advertising, Asociația STEMplicity. Rămâne deschis dacă platforma alocă următorul
  număr sau doar îl înregistrează — azi `entry_number`/`exit_number` sunt text liber, fără
  generare.
- **Tipuri de contract.** PFA, SRL, drepturi de autor. Profesiile liberale (medici, biologi)
  rămân deschise — trimise la contabilitatea ei, nu presupuse aici.
- **Tariful.** Nu stă pe contract. Vine din grad, iar contractul înregistrează **gradul la
  semnare** — vezi §3.2 și §12. De obicei nivelul 1; angajările cu experiență pot începe la
  nivelul 2 sau 3.

Decizii luate cu Mihai:
- Furnizorii primesc tabel propriu, nu text liber.
- Contractul de trainer rămâne în arhivă când persoana își schimbă statusul (candidat →
  trainer) sau pleacă din echipă. Contractul e document, nu proprietate a statusului.
- `groups.contract_id` se adaugă (§6).

---

## 3. Ce se construiește

Trei tabele noi și o coloană nouă pe un tabel existent.

### 3.1 `suppliers` — furnizorii

Contrapartida contractelor de furnizor. Fără ea, un contract cu firma de SEO nu are de ce să
se lege.

```
id                uuid pk
organization_id   uuid not null fk -> organizations
name              text not null          -- denumirea uzuală
legal_name        text                   -- denumirea din registrul comerțului
cui               text
service_type      text                   -- ce prestează: SEO, contabilitate, IT etc.
status            text not null default 'active'   -- active | inactive
notes             text
created_at, updated_at
```

🔒 auditat (trigger `row_history`).

`status` urmează convenția din `DATABASE_CONVENTIONS.md` §12: o valoare de status care
înseamnă „nu mai lucrăm cu ei" înlocuiește ștergerea fizică. Un furnizor cu contracte în
istoric nu se șterge.

Persoană de contact la furnizor: **nu în V1.** Dacă apare nevoia, se face `supplier_contacts`
după modelul `client_contacts`, cu aceleași reguli de PII.

### 3.2 `trainer_contracts` — contractele cu trainerii

```
id                uuid pk
organization_id   uuid not null fk -> organizations
user_id           uuid not null fk -> users          -- trainerul
legal_entity_id   uuid not null fk -> legal_entities -- pe care firmă e încheiat
contract_type     text not null                      -- pfa | srl | drepturi_autor, vezi §2
entry_number      text
exit_number       text
period_start      date
period_end        date
status            text not null default 'draft'      -- draft | sent | signed | expired | terminated
signed_date       date
initial_grade_level  integer not null                 -- 🔒 mascat, vezi §5 și §12 — gradul la semnare (1-6)
drive_ref         text
notes             text
created_at, updated_at
```

🔒 auditat.

**`initial_grade_level` nu e o cheie străină.** Corecție față de o versiune anterioară a acestui
document, care propunea `initial_grade_id uuid fk -> trainer_grades`. Odată ce `trainer_grades`
s-a versionat (§12.9), un „rând" din acel tabel nu mai e o identitate stabilă — e „tariful
nivelului N în versiunea asta". Gradul unui trainer (1-6) e o clasificare stabilă, independentă
de care versiune a grilei e curentă; legarea lui printr-o FK la un rând versionat ar cupla din
nou cele două lucruri pe care §12.9 le separă intenționat. `initial_grade_level` e deci o
valoare simplă, constrânsă (`between 1 and 6`), la fel ca `groups.module` sau `sessions.status`
— nu o relație.

**Tariful nu e pe acest rând.** `initial_grade_level` înregistrează gradul trainerului *la
semnare* — tariful curent se rezolvă prin `trainer_grades` (§12), nu se copiază aici. Cum se
tratează schimbarea tarifului unui grad după ce există contracte semnate pe gradul respectiv
face parte din investigația din §12, nu presupusă aici.

**Un trainer poate avea mai multe rânduri active simultan**, câte unul pe entitate legală.
Nu se pune constrângere unică pe `user_id` — asta e exact ce a spus Anca. Constrângerea
utilă e alta: **cel mult un contract activ per (trainer, entitate, perioadă suprapusă)**, de
implementat ca `EXCLUDE` cu `daterange`, sau ca validare în acțiune dacă `btree_gist` nu e
disponibil. De verificat la implementare, nu de presupus.

`user_id` referă `users`, nu un tabel de traineri — trainerii sunt utilizatori ai platformei.
Fără `ON DELETE`: `users` nu se șterge oricum, iar contractul trebuie să supraviețuiască
schimbării de status a persoanei.

### 3.3 `supplier_contracts` — contractele cu furnizorii

Aceeași structură, cu `supplier_id` în loc de `user_id`, fără `rate`/`rate_unit` (un contract
de servicii are valoare, nu tarif orar):

```
id, organization_id
supplier_id       uuid not null fk -> suppliers
legal_entity_id   uuid not null fk -> legal_entities
entry_number, exit_number
period_start, period_end
status            text not null default 'draft'
signed_date
contract_value    numeric        -- 🔒 mascat
drive_ref, notes
created_at, updated_at
```

🔒 auditat.

### 3.4 `groups.contract_id` — prerechizit, vezi §6

---

## 4. De ce tabele separate, nu un discriminator pe `contracts`

Tentația e să adăugăm `counterparty_type` pe `contracts` și să reutilizăm tot. E greșit din
trei motive, iar al treilea e periculos.

**Contrapartida e polimorfă.** `contracts.client_id` e `NOT NULL`. Un discriminator ar cere
`client_id`, `user_id` și `supplier_id` toate nullable, cu un `CHECK` că exact una e setată.
Asociere polimorfă — cheile străine nu mai garantează nimic la nivel de rând, iar fiecare
join devine condițional.

**Regula de scriere se inversează.** Vezi §7. Politica actuală exclude explicit rolurile
financiare de la scriere; la contractele de trainer, Finance e proprietarul procesului.

**Politicile existente ar începe să arate rânduri noi, tăcut.** Ăsta e motivul decisiv.
Politica de SELECT pe `contracts` are o ramură:

```
app.has_capability('clients.read', organization_id)
  AND NOT app.has_capability('finance.operations.*', organization_id)
  AND NOT app.has_capability('finance.reporting.*', organization_id)
```

Cătălina intră prin ea. Dacă un contract de trainer ar sta în același tabel, ramura asta i
l-ar arăta — fără nicio modificare de politică, fără eroare, fără semnal. Termenii de plată ai
colegilor ei ar deveni vizibili pentru că o ramură scrisă pentru școli nu verifică tipul
contrapartidei.

Fiecare din cele cinci ramuri ale politicii ar trebui revizuită și restrânsă. Cinci ocazii de
a greși tăcut, contra unui tabel nou.

---

## 5. Mascarea termenilor financiari

Aceeași problemă ca la `contracts`, aceeași soluție — mecanismul din
`WOWLAB_SAD_Field_Masking.md` §3, aplicat a treia oară.

**`trainer_contracts`:** `initial_grade_level` mascat — nu `rate`, care nu mai există pe acest
tabel (§3.2). Scopul mascării se mută, nu dispare: gradul e la fel de sensibil ca un tarif —
a ști că cineva e „Glowing Senior 2" plus acces la grila din `trainer_grades` (§12) dă tariful
orar la fel de direct ca o coloană `rate` necriptată. Vizibil pentru `finance.operations.*`,
`finance.reporting.*`, org owner. Ascuns pentru toți ceilalți, inclusiv Cătălina.

**`supplier_contracts`:** `contract_value` mascat. Vizibil pentru `finance.reporting.*` și
org owner. **Nu** pentru `finance.operations.*` — Laura nu vede contractele de furnizor deloc
(§7), deci nici valorile lor.

**Ramura „propriul rând".** Anca a spus că vizibilitatea contractului pentru trainer e opțională
și că renunțăm dacă e complicație. Nu mai e: ramura a fost construită de două ori, la
`users_masked` și în predicatul de la `client_contacts`. Un trainer își vede propriul contract,
cu gradul lui cu tot, pentru că e al lui.

Recomand s-o construim. 21+ traineri care nu mai întreabă pe WhatsApp, la costul unei linii în
predicat.

Predicatul pentru `trainer_contracts`:

```sql
when tc.user_id = app.current_user_id()                       -- propriul contract
  or (app.belongs_to_org(tc.organization_id)
      and (app.has_capability('finance.operations.*', tc.organization_id)
        or app.has_capability('finance.reporting.*', tc.organization_id)))
then tc.initial_grade_level
else null
```

`organization_id` se citește din rând, niciodată din parametru — capcana de oracol din
Field Masking §5.3.

Capcanele 5.1, 5.2, 5.4, 5.6 și 5.7 se aplică integral. Mai ales 5.7: `GRANT`/`REVOKE` pe
funcție trebuie să ruleze cât timp rolul executant e încă membru al rolului proprietar. A
căzut tăcut o dată deja.

---

## 6. Verificarea Cătălinei la alocare

Cerința: „are trainerul contract valid cu entitatea care facturează grupa asta".

### 6.1 Lanțul, și de ce e rupt azi

```
group → contract → legal_entity → trainer_contracts(trainer, entity, valid azi)
```

Primul pas nu există. `groups` are doar `client_id`; nu există `contract_id` nicăieri în
schemă. Iar SAD-ul de Clients & Contracts se contrazice: diagrama din §5 arată
`client → contract → groups`, dar descrierea entităților spune că grupele se leagă de
`client_id`. Implementarea a urmat a doua variantă.

Funcționează cât timp un client are un singur contract. Se rupe la reînnoire (2025-26 și
2026-27 coexistă, legate prin `renewal_of`) și la tipuri multiple (contract recurent pe
Experimente Wow plus un eveniment unic pe Bradine — două entități, același client).

### 6.2 `groups.contract_id`

```
contract_id  uuid null fk -> contracts
```

Nullable: grupele existente nu-l au, iar o grupă poate exista înainte de semnarea
contractului.

**Nu servește doar verificarea Cătălinei.** Facturarea folosește `contracts.billing_rule` plus
prezența. Dacă grupa nu știe sub ce contract e livrată, nu se știe ce regulă se aplică atunci
când clientul are două. Coloana e prerechizit pentru facturare corectă, nu doar pentru alocare.

Migrarea grupelor existente: unde clientul are exact un contract, se poate popula automat;
unde are mai multe, rămâne null și se completează manual. De raportat câte cad în fiecare caz
înainte de a rula ceva.

### 6.3 Ce vede Cătălina

La alocare, per trainer și per grupă:

- **Verde** — contract semnat cu entitatea corectă, valabil azi
- **Roșu** — niciun contract valid cu acea entitate
- **Portocaliu** — contract valid, dar expiră în mai puțin de 30 de zile
- **Gri** — nu se poate verifica: grupa nu are `contract_id`

Ultima stare e obligatorie. O grupă fără contract nu trebuie să arate verde — mai bine „nu
știu" decât o afirmație falsă.

Cătălina vede status, entitate și perioadă. **Nu** vede `initial_grade_level`.

---

## 7. Permisiuni

### 7.1 Conflictul de segregare a atribuțiilor

Politica actuală pe `contracts` exclude explicit rolurile financiare de la scriere:

```
contracts.* AND NOT finance.reporting.* AND NOT finance.operations.*
```

Anca a spus că Laura și Anka creează contractele de trainer și furnizor. **Nu e o contradicție
— e o regulă care nu era universală.**

La contractele de client, regula are sens: cine vede banii care intră nu scrie termenii pe care
îi încasăm. La plata trainerilor, Finance *este* proprietarul procesului — Laura gestionează
deja plata trainerilor și deconturile. A o exclude ar însemna ca altcineva să scrie termenii pe
care ea îi execută.

**Regula corectă, scrisă explicit:** segregarea atribuțiilor se aplică contractelor de venit,
nu celor de cost.

### 7.2 Matricea

| | `trainer_contracts` | `supplier_contracts` |
|---|---|---|
| Anca (`organization_owner`) | citește, scrie, valori | citește, scrie, valori |
| Laura (`finance_operations`) | citește, scrie, valori | — |
| Anka (`finance_admin_reporting`) | citește, scrie, valori | citește, scrie, valori |
| Cătălina (`operations_manager`) | citește status/entitate/perioadă, fără valori | — |
| Trainer | propriul rând, cu valori | — |
| Restul | — | — |

Capabilități: **nu inventăm chei noi înainte de a verifica ce există.** `clients.convert` și
`crm_link.*` erau deja seed-uite pentru exact funcționalitățile pe care le construiam. Prima
sarcină la implementare e un inventar al catalogului de capabilități pentru orice
trainer/supplier/vendor.

Dacă nu există nimic potrivit, propun `trainer_contracts.*` și `supplier_contracts.*` ca
wildcard-uri literale — cu grijă la capcana de rezolvare: wildcard-urile sunt rânduri literale,
iar rezolverul face potrivire pe prefix cu limită de punct.

Accesul Cătălinei nu cere capabilitate nouă: `trainers.allocate`, pe care îl are deja.

**Actualizare — la implementarea `suppliers` (§3.1): wildcard-ul de fallback nu a fost necesar.**
Verificat live, nu presupus: `finance.reporting.*` este ținut azi de exact cele trei roluri care
trebuie să vadă/scrie `suppliers` — `finance_admin_reporting` (Anka), `organization_owner` (Anca)
și `platform_owner` — și de niciun altul. Nici `contracts.*` (îl ține și
`contract_administrator`, exclus explicit de matrice) nici `org.settings.manage` (o capabilitate
de administrare a organizației, nu o cheie de date de business — n-are ce căuta pe un tabel nou)
nu se potrivesc; `finance.reporting.*` da.

Un al doilea candidat exista, respins deliberat: `grants.*` e ținut azi de exact aceiași trei
oameni, dar e o coincidență de rol, nu o potrivire de domeniu — `grants.*` înseamnă finanțare
de tip grant primită de organizație (bani care intră), nu plăți către furnizori (bani care ies).
Reutilizarea lui ar lega accesul la `suppliers` de o cheie dintr-un domeniu fără legătură, doar
pentru că azi se întâmplă să fie ținută de aceiași oameni — s-ar rupe tăcut în ziua în care
cineva capătă `grants.*` fără `finance.reporting.*` sau invers. `finance.reporting.*` e alegerea
corectă și pentru că e deja cheia de demascare pt `trainer_contracts.initial_grade_level`/
`supplier_contracts.contract_value` (§5) — reutilizarea ei pt CRUD pe `suppliers` ține accesul
și mascarea pe aceeași cheie, nu pe două chei diferite care ar putea diverge.

Predicatul RLS pe `suppliers`, identic pe SELECT/INSERT/UPDATE:

```
app.is_platform_owner() OR app.has_capability('finance.reporting.*', organization_id)
```

Confirmat live înainte de a scrie asta: `organization_owner` ține `finance.reporting.*` direct
(nu doar prin bypass-ul `is_platform_owner()`) — Anca e acoperită de propria ei capabilitate,
nu de excepția de platform owner. Predicatul de două ramuri e complet, fără o a treia ramură
pentru `org.settings.manage`.

---

## 8. Ce nu se construiește în V1

- **Execuția plății trainerilor.** Modelul de calcul e documentat în §12; rularea ei efectivă —
  interfața, deconturile, aprobarea — e domeniu Finance separat, în afara acestui V1.
- **Facturi de la furnizori.** Contractul, nu tranzacțiile.
- **Lanț de reînnoire** pe contractele de trainer. `renewal_of` a fost lăsat afară și la
  contractele de client, din același motiv: o cheie străină fără flux în spate nu e o
  funcționalitate.
- **`supplier_contacts`.** Vezi §3.1.
- **Ștergere.** Ambele tabele urmează convenția din `DATABASE_CONVENTIONS.md` §12: status
  `terminated`, nu ștergere fizică. Excepție posibilă pentru `draft`, dacă se dovedește
  necesar — dar abia după ce există date reale.

---

## 9. Decizii deschise

**Pentru Anca — răspunse, vezi §2:**

1. **Numerotarea** — rezolvat. Un registru per entitate juridică, comun celor trei tipuri de
   contract, nu un registru separat per tip. Rămâne deschis dacă platforma alocă numărul sau
   doar îl înregistrează.

2. **Tipuri de contract de trainer** — rezolvat. PFA, SRL, drepturi de autor. Profesiile
   liberale (medici, biologi) rămân deschise, trimise la contabilitatea ei.

3. **Tariful stă în platformă?** — rezolvat, dar nu cum specula întrebarea. Tariful nu stă pe
   `trainer_contracts` deloc; nici nu rămâne doar pe Drive. Contractul înregistrează gradul la
   semnare (`initial_grade_level`, §3.2), iar tariful curent se rezolvă prin `trainer_grades`
   (§12). Mascarea nu devine inutilă — se mută pe coloana de grad (§5).

**Pentru Mihai:**

4. **`groups.contract_id` — migrarea grupelor existente.** Câte grupe au un client cu exact un
   contract (se populează automat) și câte au mai multe (rămân null)? De raportat înainte de a
   rula ceva.

5. **Constrângerea de suprapunere** pe `(user_id, legal_entity_id, perioadă)` — `EXCLUDE` cu
   `btree_gist`, sau validare în acțiune? De verificat dacă extensia e disponibilă pe Supabase.

---

## 10. Ordinea de implementare

Fiecare pas trece prin protocolul din `WOWLAB_SAD_Field_Masking.md` §6: tranzacție cu rollback,
asserțiuni scrise, migrație de revenire în același commit, una singură pe rundă.

1. **`groups.contract_id`** — prerechizit, independent de restul. Coloană, cheie străină,
   raport de migrare, populare unde e neambiguu.
2. **`suppliers`** — tabel, RLS, CRUD complet după tiparul de la `clients`.
3. **`trainer_contracts`** — tabel, RLS, mascare, CRUD.
4. **`supplier_contracts`** — același tipar, mai simplu.
5. **Verificarea Cătălinei** — la alocare, în interfața de grupe.

Răspunsurile 2 și 3 de la Anca au sosit (§2) — pașii 3-5 nu mai sunt blocați de ele. Pasul 3
rămâne blocat pe `trainer_grades` (§12): `initial_grade_level` e `not null`, deci tabelul de
grade trebuie să existe și să aibă cel puțin un rând înainte ca primul `trainer_contracts` să
poată fi scris.

---

## 11. GDPR și retenție

Contractele de trainer conțin date personale — nume, CNP eventual, gradul (care determină
tariful, §3.2), coordonate PFA.
Se aplică aceleași reguli ca la `client_contacts`: rezidență UE/Frankfurt, minimizare, drept
la ștergere.

**Tensiune de semnalat, nerezolvată:** dreptul la ștergere intră în conflict cu obligația
legală de păstrare a documentelor contabile. Un contract nu se șterge la cerere pentru că
legea cere păstrarea lui. Anonimizarea unui contract e problematică — un contract fără parte
identificabilă nu mai e contract.

Nu rezolv asta aici. O semnalez pentru că `OPEN_ITEMS.md` conține deja golul de retenție —
nu există niciun mecanism programat, nicăieri — iar contractele de trainer îl fac mai complicat,
nu doar mai mare.

---

## 12. Modelul de plată al trainerilor

Confirmat de Anca sau verificat direct pe datele ei — nu presupus. Elementele încă deschise
sunt marcate explicit la §12.10, nu amestecate în restul textului.

### 12.1 Formula

```
tarif_grad × coeficient_durată × (1 + bonus_locație + bonus_limbă)
```

Rezultatul e suma **netă**. Uplift-ul de tip de contract (§12.4) se aplică peste acest
rezultat — formula de mai sus nu-l include. Verificată de Anca pe patru exemple lucrate din
procedura lor.

### 12.2 Grade: șase, nu șapte

Scala are **șase niveluri**, nu șapte cum presupunea versiunea precedentă a acestui document.
Progresia e automată:

```
grad = min(6, floor(workshop-uri_livrate / 36) + 1)
```

Verificat pe toți cei 27 de traineri din fișierul lor de urmărire — nicio excepție. Praguri:
0 / 36 / 72 / 108 / 144 / 180 workshop-uri.

Reguli de numărare, confirmate de Anca:

- un workshop unde trainerul e **secundar** contează
- un workshop de 2 ore contează ca **unul**, nu ca două
- planurile de lecție **nu** contează

Motivul, pentru că explică toată scala: gradul răsplătește experiența de predare la clasă, nu
contribuția în general. Numărătoarea e un **număr simplu** de sesiuni livrate unde trainerul
apare ca principal SAU secundar — nu o sumă ponderată.

### 12.3 Scrierea planurilor de lecție nu e un grad

E un tip de lucru separat, plătit per unitate — **120 lei net per plan**, fix, indiferent de
vechime. Fișierul lor îl modelează ca un al șaptelea grad, pe o școală fictivă „New Lesson
Plan". **Nu reproducem asta aici.** E o categorie de plată diferită de scala pe traineri, nu o
treaptă suplimentară pe ea.

### 12.4 Tipul de contract schimbă suma

O singură grilă netă, plus un procent de uplift per tip de contract: drepturi de autor
plătește net; PFA și SRL plătesc **net + 11.1%**. `trainer_contracts.contract_type` (§3.2) nu
mai e doar etichetă administrativă — alimentează calculul (§12.1). Se modelează ca procent pe
tipul de contract (`contract_type_uplifts`, §12.8), nu ca grile nete duplicate per tip.

Confirmat de Anca: 11% și 11.1% erau același număr — 11% a fost un lapsus. Fără ambiguitate
rămasă.

### 12.5 Bonusul de locație e relativ la trainer, nu la școală

Un trainer din Cluj care predă în Cluj ia 0%; același trainer care se deplasează în București
ia 100%. Fișierul lor modelează bonusul ca proprietate a școlii — funcționează doar atât timp
cât toți trainerii sunt din București, ceea ce nu mai e cazul.

**Confirmat: doar 2 din cei 11 traineri activi locuiesc în afara Bucureștiului** — Alexandra
Nuțu (Cluj) și Viorel Tobosaru (Cernavodă). Regula contează chiar la doar 2 din 11: modelul
„proprietate a școlii" citește nivelul de bonus direct din orașul școlii, presupunând implicit
că orice trainer pornește din București. Pentru Alexandra, presupunerea asta se inversează de
două ori: un workshop la o școală din Cluj — unde locuiește, deci n-a călătorit deloc — ar primi
bonusul de „oraș îndepărtat" ca și cum ar fi venit din București; iar un workshop la o școală
din București — unde chiar a călătorit — ar primi 0%, ca și cum ar fi acasă. Modelul corect,
(domiciliul trainerului, locul livrării), citește ambele cazuri corect, pentru că întreabă de
unde a plecat trainerul, nu doar unde a ajuns.

**Corecție: nu pe `users`.** O versiune anterioară a acestui document propunea o coloană de
oraș de domiciliu pe `users`, rezolvată împreună cu locul livrării într-un tarif de bonus.
Greșit: singurele două puncte confirmate sunt „domiciliu = livrare → 0%" și „Alexandra sau
Viorel livrează în București → 100%" — nu există o regulă confirmată pentru orice altă pereche
(de ex. Alexandra livrează într-un oraș care nu e nici Cluj, nici București). O coloană pe
`users` plus un rezolver ar cere inventarea unei reguli generale (domiciliu × livrare) pe care
nimeni n-a confirmat-o, ca să rezolve o problemă care apare pentru 2 din 11 oameni.

**Decizie: nivelul se înregistrează direct pe sesiune, de către cine o introduce.**
`sessions.location_tier` ține nivelul deja rezolvat pentru acea sesiune — nu domiciliul
trainerului, nu locul livrării separat, ci concluzia. Cine introduce sesiunea știe deja unde s-a
predat (nimic altceva nu ține asta) și, în practică, știe sau poate afla de unde a plecat
trainerul — Cătălina face alocarea, are contextul. Asta evită rezolvarea cazului general
nespecificat: nu mai există o pereche de valori de combinat, doar un răspuns pe care un om
l-a stabilit o dată, per sesiune. `public.users` nu capătă nicio coloană nouă pentru asta —
verificat direct în `information_schema`: cele 12 coloane ale tabelului (`id`, `email`,
`full_name`, `status`, `is_platform_owner`, `created_at`, `updated_at`, `first_name`,
`last_name`, `phone`, `avatar_url`, `is_test_account`) rămân neschimbate.

### 12.6 Școala Altfel / Săptămâna Verde — excepția de 2 ore

Workshop-urile de 2 ore de acest tip folosesc coeficientul ×2, nu ×1.5 (§12.7).
`groups.delivery_format` (deja în schemă, valorile `scoala_altfel`/`saptamana_verde`) ține deja
distincția, deci regula se aplică automat din câmpul existent — nicio coloană nouă doar pentru
asta.

Anca a aprobat renunțarea la artificiul actual: azi trainerii împart un singur workshop de 2
ore în două intrări de câte o oră ca să ocolească limita de ×1.5. Cu excepția explicită,
artificiul dispare.

### 12.7 Coeficienții de durată

| Durată | Coeficient |
|---|---|
| sub 1h | 1.0 |
| 1h | 1.0 |
| 1.5h | 1.2 |
| 2h | 1.5 (×2 pentru Școala Altfel/Săptămâna Verde, §12.6) |

Nimic mai lung de 2h nu există azi; dacă va exista, se împarte în workshop-uri separate.

### 12.8 Tabelele de configurare

**Cinci** tabele de valori de politică, nu patru — `contract_type_uplifts` se adaugă față de
lista din investigația precedentă (§12.4). Toate administrate integral de Finance, cerința
explicită a Ancăi: schimbarea unei sume nu trebuie să ceară o modificare de cod.

- **`trainer_grades`** — șase niveluri (§12.2), tariful net per nivel. Nivelul de pe
  `trainer_contracts.initial_grade_level` (§3.2) e o valoare simplă (1-6), nu o cheie străină
  către acest tabel — vezi corecția din §3.2.
- **`location_bonuses`** — procent de bonus per nivel de locație, rezolvat direct din
  `sessions.location_tier` — §12.5, nu dintr-un domiciliu de trainer stocat separat.
- **`language_bonuses`** — procent de bonus per grup de limbă.
- **`duration_multipliers`** — coeficientul per durată de workshop (§12.7).
- **`contract_type_uplifts`** — procent de uplift per tip de contract (§12.4).

Structura exactă (coloane, chei, RLS) nu e proiectată aici. **Construite goale — Finance le
populează** după ce Anca dă cele șase sume exacte din grila nouă (§12.10).

### 12.9 Perioadele de valabilitate — decizie

Nimic din schema actuală tratează valori care variază în timp — verificat, nu presupus, în
investigația care a precedat această secțiune. Fiecare valoare din fiecare tabel de la §12.8,
plus gradul fiecărui trainer, are nevoie de o rezolvare temporală: calculul (§12.1) trebuie să
folosească valoarea în vigoare la **data sesiunii**, nu valoarea curentă la momentul
calculului. Fără asta, o modificare de grilă rescrie tăcut plăți deja aprobate.

**Grilele de politică (§12.8) folosesc grile versionate — varianta „versiuni", nu validitate
pe rând.** O versiune are o dată de intrare în vigoare și ține toate rândurile ei; o schimbare
de tarife creează o versiune nouă, nu editează rânduri existente. Motivul e evenimentul deja
documentat: singura revizuire cunoscută a grilei de grade a mutat toate cele șase niveluri
deodată, pe 30.05.2026 — mecanismul trebuie să aibă forma evenimentului pe care îl
înregistrează, nu forma opusă. Suprafețele de eșec diferă în fel, nu doar în grad: rezolvarea
„ultima versiune cu data ≤ data sesiunii" poate întoarce zero rânduri sau exact unul —
niciodată două, prin construcție. Validitatea pe rând (`valid_from`/`valid_to`) poate întoarce
zero **sau** două, iar două rânduri valide simultan nu e o eroare vizibilă — e un număr greșit
calculat tăcut.

**Se aplică la toate cele cinci tabele din §12.8, inclusiv celor fără nicio dovadă că s-ar fi
schimbat vreodată ca set.** Deliberat: niciunul dintre celelalte patru n-are un istoric de
revizuire documentat, dar aceeași persoană (Finance) le administrează pe toate cinci, iar un
mecanism unic ținut minte o dată e mai sigur decât cinci mecanisme optimizate individual,
fiecare cu propriul mod de a eșua. Costul: la o schimbare care afectează un singur rând,
rândurile neschimbate se re-introduc în versiunea nouă în loc să rămână pe loc — preț mic,
plătit o dată per revizuire.

**Alocarea gradului per trainer NU folosește grile versionate.** Folosește un istoric pe rând,
un rând per trainer per schimbare de grad, cu dată de intrare în vigoare, unde rândul cel mai
recent înaintea datei căutate câștigă — fără pas de închidere, pentru că un rând nou
suprascrie prin faptul că e mai nou, nu pentru că cineva a marcat manual finalul celui vechi.
Motivul separării: gradul fiecărui trainer sunt 27 de fapte independente, nesincronizate —
trainerul X trece pragul de 36 de workshop-uri în ziua lui, fără nicio legătură cu ziua
trainerului Y. Nu există o graniță comună de aliniat, cum există la o grilă. Trebuie **stocat,
nu derivat**: gradul de start pentru o angajare cu experiență (§2, §12.2) e o decizie umană
fără formulă în spate — o funcție de progresie pură nu poate produce acel număr, doar un rând
stocat poate.

**Calculul pe citire (fără stocare, gradul recalculat mereu din numărul de workshop-uri) e
respins**, din două motive independente. Orice corecție de status pe o sesiune existentă
schimbă retroactiv numărul de workshop-uri pentru toate datele ulterioare — nu e o editare
rară de Finance, e un eveniment operațional obișnuit (intrare târzie, corecție), deci expunerea
e mai mare decât la o editare de grilă, nu mai mică. Și o formulă pură n-are unde să țină un
grad de start care a fost o decizie umană, nu un rezultat de calcul. Reconstituirea numărului
istoric din `row_history` ca să compensăm ar însemna folosirea jurnalului de audit ca sursă de
adevăr temporală pentru logica de business — exact riscul semnalat deja în investigația
precedentă, nu unul nou.

**Rezolvarea trebuie să eșueze vizibil la fiecare căutare temporală, independent.** O singură
plată de sesiune are nevoie de cel puțin trei rezolvări temporale reușite: gradul trainerului
la data sesiunii, tariful din grilă la acea dată, și fiecare bonus versionat (locație, limbă)
la acea dată. Niciuna nu se coalesce tăcut la zero, la cea mai apropiată valoare, sau la o
valoare implicită — o rezolvare fără rând găsit oprește calculul, nu returnează un număr
aproximativ. Același principiu ca la §6.3: starea „nu se poate verifica" e o stare vizibilă
proprie, nu se transformă tăcut într-un răspuns valid.

Structura exactă (coloane, funcția de rezolvare) nu e proiectată aici — doar decizia de
formă și motivele ei.

### 12.10 Închis și deschis

**Închis, confirmat de Anca:**

- Regulile de numărare la prag (§12.2) — secundar contează, 2h contează ca unul, planurile de
  lecție nu contează.
- Uplift-ul de tip de contract (§12.4) — 11.1%, nu 11%; cele două cifre erau același număr.
- Orașul de domiciliu al trainerului (§12.5) — necesar, confirmat cu date reale pentru 2 din
  11 traineri activi.

**Deschis, ce rămâne cu adevărat:**

- Cele șase sume exacte din grila nouă (§12.8).
- Tipul de contract pentru profesiile liberale (medici, biologi) — vezi §2, §9 item 2. Rămâne
  relevant aici pentru că determină dacă `contract_type_uplifts` are nevoie de o a treia
  valoare, nu doar drepturi de autor/PFA-SRL.

**Notă despre roster:** 11 traineri activi azi, nu cei 27 din fișierul de urmărire folosit la
verificarea din §12.2 — fișierul e istoric, nu curent. Numele nu se listează aici: sunt date
operaționale care se învechesc în mai puțin de o lună și au un singur loc corect, baza de date,
nu un document de arhitectură.

Modelul de mai sus e confirmat; execuția plății (interfața, deconturile, aprobarea) rămâne în
afara acestui V1, conform §8.
