# WOW LAB OS — SAD: Contracte de trainer și furnizor

**Status:** propunere de arhitectură, neimplementată
**Data:** 27 august 2026
**Decizii de la Anca:** primite (§2)
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
contract_type     text not null                      -- vezi §9, decizie deschisă
entry_number      text
exit_number       text
period_start      date
period_end        date
status            text not null default 'draft'      -- draft | sent | signed | expired | terminated
signed_date       date
rate              numeric                            -- 🔒 mascat, vezi §5
rate_unit         text                               -- 🔒 mascat: „lei / oră predată" etc.
drive_ref         text
notes             text
created_at, updated_at
```

🔒 auditat.

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

**`trainer_contracts`:** `rate` și `rate_unit` mascate. Vizibile pentru
`finance.operations.*`, `finance.reporting.*`, org owner. Ascunse pentru toți ceilalți,
inclusiv Cătălina.

**`supplier_contracts`:** `contract_value` mascat. Vizibil pentru `finance.reporting.*` și
org owner. **Nu** pentru `finance.operations.*` — Laura nu vede contractele de furnizor deloc
(§7), deci nici valorile lor.

**Ramura „propriul rând".** Anca a spus că vizibilitatea contractului pentru trainer e opțională
și că renunțăm dacă e complicație. Nu mai e: ramura a fost construită de două ori, la
`users_masked` și în predicatul de la `client_contacts`. Un trainer își vede propriul contract,
cu tarif cu tot, pentru că e al lui.

Recomand s-o construim. 21+ traineri care nu mai întreabă pe WhatsApp, la costul unei linii în
predicat.

Predicatul pentru `trainer_contracts`:

```sql
when tc.user_id = app.current_user_id()                       -- propriul contract
  or (app.belongs_to_org(tc.organization_id)
      and (app.has_capability('finance.operations.*', tc.organization_id)
        or app.has_capability('finance.reporting.*', tc.organization_id)))
then row(tc.rate, tc.rate_unit)
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

Cătălina vede status, entitate și perioadă. **Nu** vede `rate`.

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

---

## 8. Ce nu se construiește în V1

- **Calculul plății trainerilor.** Contractul ține termenii; execuția plății e domeniu Finance
  separat, cu deconturi și ore predate.
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

**Pentru Anca:**

1. **Numerotarea.** Contractele de client au `entry_number`/`exit_number` — registru de intrări
   și ieșiri. Contractele de trainer și furnizor intră în același registru, sau au registre
   separate? În practică registrele sunt de obicei pe entitate legală, ceea ce ar însemna
   registre separate. De confirmat cu ea sau cu contabilitatea.

2. **Tipuri de contract de trainer.** Drepturi de autor, PFA, altceva? Lista determină
   `contract_type`. Nu o inventez.

3. **Tariful stă în platformă?** `rate` presupune că da. Dacă tariful e doar în documentul de
   pe Drive și platforma ține doar referința, coloanele `rate`/`rate_unit` dispar și mascarea
   devine inutilă pe acest tabel. Întrebare simplă, consecință mare.

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

Pașii 1 și 2 nu depind de deciziile deschise din §9 și pot începe imediat. Pașii 3-5 au nevoie
de răspunsurile 2 și 3 de la Anca.

---

## 11. GDPR și retenție

Contractele de trainer conțin date personale — nume, CNP eventual, tarif, coordonate PFA.
Se aplică aceleași reguli ca la `client_contacts`: rezidență UE/Frankfurt, minimizare, drept
la ștergere.

**Tensiune de semnalat, nerezolvată:** dreptul la ștergere intră în conflict cu obligația
legală de păstrare a documentelor contabile. Un contract nu se șterge la cerere pentru că
legea cere păstrarea lui. Anonimizarea unui contract e problematică — un contract fără parte
identificabilă nu mai e contract.

Nu rezolv asta aici. O semnalez pentru că `OPEN_ITEMS.md` conține deja golul de retenție —
nu există niciun mecanism programat, nicăieri — iar contractele de trainer îl fac mai complicat,
nu doar mai mare.
