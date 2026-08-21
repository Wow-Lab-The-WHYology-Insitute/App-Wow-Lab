# WOW LAB OS — SAD: Field Masking (mascare la nivel de coloană)

**Status:** propunere de arhitectură, neaplicată
**Data:** 18 august 2026
**Prerechizit pentru:** intrarea datelor reale de școli și copii în producție
**Decizie deschisă care blochează secțiunea 2.2:** cine poate citi PII din `client_contacts` (Anca)

---

## 1. Problema, cu dovadă

Vederea `contracts_billing_masked` maschează corect `billing_rule`, `estimated_value` și
`previous_year_value` pentru utilizatorii fără capabilitate financiară. Interfața afișează
„Finance only". Totul pare în regulă.

Tabelul de bază de sub ea nu maschează nimic, și e citibil direct.

Verificat live, ca `test+ui-ops@wowlab.dev` (rol `operations_manager`, fără nicio
capabilitate financiară), prin apel REST cu cheia `anon` și sesiunea reală a utilizatorului:

```
GET /rest/v1/contracts?select=contract_number,billing_rule,estimated_value
→ 200
[
  { "contract_number": "DEMO-2026-001", "billing_rule": "95 lei / child / session (VAT incl.)" },
  { "contract_number": "DEMO-2026-002", "billing_rule": "80 lei / child + VAT" },
  ...
]
```

Aceeași sesiune, prin vedere:

```
GET /rest/v1/contracts_billing_masked?select=contract_number,billing_rule
→ 200
[ { "contract_number": "DEMO-2026-001", "billing_rule": null }, ... ]
```

Cauza: `authenticated` are `SELECT` la nivel de **tabel** pe `public.contracts`. Izolarea
între organizații ține (RLS e row-level și funcționează), dar nimic nu oprește o sesiune
autentificată să interogheze tabelul de bază în loc de vedere. Cheia `anon` trăiește în
JavaScript-ul din browser; sesiunea e a utilizatorului legitim. Nu e nevoie de nimic special.

`WOWLAB_SAD_Domeniul_Clients_Contracts_CRM.md`, secțiunea 6, cere ca Field Visibility să fie
aplicat „la nivel de bază de date (RLS pe `organization_id` + reguli pe rol), nu doar în
meniu". Vederea face asta corect. Problema e că nu e singura cale către date.

**Ce nu e stricat:** calea de scriere. Politicile `INSERT`/`UPDATE` pe `contracts` verifică
efectiv capabilitatea, nu doar apartenența la organizație. Un `PATCH` ca utilizator Operations
returnează `200` cu corp gol — RLS a filtrat rândul, valoarea a rămas neatinsă. Verificat live.

---

## 2. Domeniul de aplicare

Cinci tabele au `SELECT` acordat lui `authenticated` și conțin coloane pe care nu toți
utilizatorii ar trebui să le citească. Izolarea row-level e prezentă pe toate — problema e
strict column-level, în interiorul unui rând pe care utilizatorul are dreptul să-l vadă.
(`org_settings` a fost investigat — 2.4 — și a ieșit din această listă: nu conține expunerea
pe care o descrie acest paragraf.)

### 2.1 `contracts` — gata de implementat

| Coloană | Cine poate citi |
|---|---|
| `billing_rule` | `finance.operations.*`, `finance.reporting.*`, `clients.create`, platform owner, org owner |
| `estimated_value` | idem |
| `previous_year_value` | idem |

Lista de capabilități replică exact logica din vederea existentă — nu se schimbă
comportamentul, se închide doar calea ocolitoare.

Coloanele rămase (18) primesc `GRANT SELECT` explicit, enumerate pe nume:
`id`, `organization_id`, `client_id`, `legal_entity_id`, `entry_number`, `exit_number`,
`contract_type`, `period_start`, `period_end`, `status`, `renewal_of`, `drive_ref`, `notes`,
`created_at`, `updated_at`, `signed_date`, `offer_structure`, `ac_link`.

Fără wildcard. O coloană nouă adăugată în viitor nu primește automat drept de citire — asta
e intenționat: adăugarea unei coloane trebuie să fie o decizie conștientă despre vizibilitate.

**Lista de mai sus e text descriptiv, nu sursă de adevăr.** `contract_number` și
`client_contract_number` au apărut inițial aici, apoi au fost înlocuite de `entry_number`/
`exit_number` în 202608180002 — scrisă în aceeași zi cu acest document, dar după el. Găsit la
implementare (202608190001), nu la scrierea acestui document. La momentul implementării,
verifică lista reală de coloane din `information_schema.columns` pe proiectul live — nu copia
de aici, care poate rămâne neactualizată față de o migrație ulterioară, exact cum s-a
întâmplat la primul pas.

### 2.2 `client_contacts` — blocat pe decizie de business

Conține `full_name`, `email`, `phone` — PII sub GDPR, stocat în UE/Frankfurt.

**Nu propun o listă de capabilități aici.** E o decizie de business și de conformitate, nu una
tehnică. Întrebările pentru Anca:

- Un trainer alocat pe o grupă are nevoie de numele persoanei de contact de la școală? De
  telefon? (Probabil da la nume, probabil nu la telefon.)
- Operations vede contactele fără termenii financiari — dar vede și emailurile?
- Există contacte marcate `is_billing_contact` care ar trebui vizibile doar pentru Finance?

Recomandarea mea, ca punct de plecare: `full_name` și `role_at_client` vizibile pentru
oricine vede clientul; `email` și `phone` restricționate la rolurile care comunică efectiv
cu clientul (contract administrator, Finance, sales). Dar e o propunere, nu o decizie.

### 2.3 `users`

`email`, `phone` — PII. Recomand restricționare la deținătorii de `org.members.manage`, plus
propriul rând al utilizatorului (fiecare își vede propriile date, deja acoperit de `/whoami`).

**Platform owner nu primește un bypass aici, spre deosebire de `contracts`.** Verificat live
înainte de implementare: fixture-ul real de platform owner (`test+platform@wowlab.dev`) are
zero rânduri în `user_org_roles` (DATABASE_CONVENTIONS.md #3 — platform owner nu e niciodată
forțat într-un rând `user_org_roles`). Predicatul din 3.1-echivalent pentru `users` verifică
apartenența la organizația *comună* printr-un `EXISTS` pe `user_org_roles`; cu zero rânduri,
acel `EXISTS` nu găsește nimic de verificat, iar bypass-ul propriu al `has_capability()` pentru
`is_platform_owner()` nu apucă să se aplice. Rezultat: platform owner își vede propriul rând
(prima ramură, necondiționată), dar NU vede automat email/telefon pentru alt utilizator, decât
dacă are o apartenență reală la o organizație.

Decizie explicită (Mihai, după ce a văzut comportamentul raportat): **corect așa, nu o gaură de
acoperit.** Platform owner operează platforma, nu o organizație anume — citirea automată a
email-ului și telefonului fiecărei persoane din fiecare organizație nu e un implicit de dorit
sub GDPR. Dacă are nevoie de acces la membrii unei organizații anume, primește o apartenență
reală acolo, ca oricine altcineva. Nu se adaugă o ramură `is_platform_owner()` în predicat.

Diferă intenționat de `contracts`, unde `app.belongs_to_org()` include propriul bypass pentru
`is_platform_owner()` (secțiunea 3.1) — acolo platform owner vede valorile financiare ale
oricărui contract, indiferent de organizație. Nu e o inconsecvență de corectat: `contracts`
mediază acces la date operaționale ale organizației pe care platform owner o supraveghează
structural; `users.email`/`phone` sunt PII personal al fiecărui angajat/colaborator, o categorie
diferită de date, cu o decizie diferită, luată explicit — nu implicit, prin copierea mecanismului
de la `contracts`.

### 2.4 `org_settings` — în afara domeniului de mascare

Verificat live înainte de a scrie orice migrație (raport 2026-08-21): `settings` e gol pe
ambele rânduri care există (`{}`, câte un rând per organizație — `wow-lab` și
`wow-lab-test-b`, singurele două organizații existente) și n-a fost scris niciodată — nici
`seed.sql` nu populează chei în el. `evaluations_confidential` e un flag boolean de politică,
el însuși neconfidențial (valoare `true` pe ambele rânduri azi), nu o coloană cu conținut
sensibil. Nicio cale din aplicație nu citește `org_settings` — grep pe tot repo-ul (`app/`,
`lib/`, orice convenție de nume) nu găsește nicio referință; singurele apariții sunt în SQL
(schema, politici RLS, trigger-ul de audit, `seed.sql`, suitele de test din `db/tests/`).
**Nu există o expunere de închis.**

`org_settings` iese din domeniul de mascare al acestui document.

**Convenție, în locul mascării:** `settings` e pentru flag-uri de politică organizațională, atât.
Nu are voie să conțină secrete, credențiale, tokenuri sau PII. Orice dată sensibilă primește
propria coloană, cu propriul grant, decisă în momentul în care e introdusă — nu aruncată
într-un blob opac și mascată ulterior, după fapt.

`evaluations_confidential` e flag-ul de politică OD-7 și va fi citit de modulul de evaluări
când acesta va exista. Nu e o gaură rămasă deschisă — e o coloană care își așteaptă
consumatorul.

### 2.5 `file_refs`

Are deja o coloană `gdpr_class` — clasificarea există, dar nimic nu o aplică. De rezolvat
împreună cu politica de retenție, nu izolat.

### 2.6 `row_history` și `audit_log` — fir separat, altă problemă

Ambele sunt deja închise la nivel de rând: politica cere `org.audit.read`, pe care îl are doar
`organization_owner`. Un utilizator Operations primește `[]`. **Nu e o cale deschisă azi.**

Dar structural sunt o expunere paralelă: `row_history.old_values`/`new_values` sunt instantanee
brute ale rândurilor, deci conțin `billing_rule` istoric în clar, plus PII din `client_contacts`
și `users`. Verificat ca Owner — `billing_rule` apare nemascat în jsonb. `audit_log.payload`
conține emailuri reale de invitație.

Devine problemă în ziua în care cineva primește `org.audit.read` fără drept financiar.

Mascarea unui instantaneu jsonb e o problemă diferită de mascarea unei coloane — nu se rezolvă
cu același mecanism. Recomand tratare separată, după ce cele cinci de mai sus sunt închise.
Împreună cu ea: o convenție despre ce are voie să intre în `audit_log.payload`, scrisă înainte
să existe zece tipuri de evenimente, nu după.

---

## 3. Mecanismul ales

Trei piese, fiecare aleasă pentru că evită o capcană dovedită (secțiunea 5).

### 3.1 Funcție `SECURITY DEFINER` în schema `app`

```sql
create function app.masked_contract_financials(target_contract_id uuid)
returns record
language sql
security definer
set search_path = ''
as $$
  select case
    when app.belongs_to_org(c.organization_id)
     and (
       app.has_capability('finance.operations.*', c.organization_id)
       or app.has_capability('finance.reporting.*', c.organization_id)
       or app.has_capability('clients.create', c.organization_id)
     )
    then row(c.billing_rule, c.estimated_value, c.previous_year_value)
    else null
  end
  from public.contracts c
  where c.id = target_contract_id;
$$;
```

**Predicatul e dublu, nu simplu.** Verifică și apartenența la organizația *rândului*, și
capabilitatea. `organization_id` se citește din rând, după `id`, în interiorul funcției —
niciodată primit ca parametru de la apelant.

Asta închide scenariul de oracol: un utilizator Finance din organizația A care apelează cu un
`id` de contract din organizația B e verificat contra apartenenței reale la B, nu contra a ce a
trimis el. Primește `null`, nu datele lui B.

**Schema `app` nu e expusă prin PostgREST.** Verificat live, nu presupus din config:

```
POST /rest/v1/rpc/has_capability  (Accept-Profile: app)
→ 406 PGRST106
   "Invalid schema: app"
   "hint": "Only the following schemas are exposed: public, graphql_public"
```

Deci funcția nu e apelabilă din browser. Predicatul dublu rămâne totuși necesar — expunerea
schemei e o setare de configurare, nu o garanție de cod, iar fișierul local de configurare a
fost deja găsit în urma proiectului live de trei ori în această fază.

**Proprietarul funcției trebuie să fie un rol fără `BYPASSRLS`.** `postgres` are `BYPASSRLS`
setat în acest proiect (`rolbypassrls = true`, deși `rolsuper = false`). O funcție
`SECURITY DEFINER` deținută de el ar sări peste izolarea între organizații.

### 3.2 Vederea rămâne `security_invoker = true`

Nu se schimbă. Izolarea între organizații continuă să se rezolve prin grants-urile apelantului,
pe mecanismul care funcționează deja azi. Vederea obține coloanele mascate prin lateral join:

```sql
create or replace view public.contracts_billing_masked
with (security_invoker = true) as
select
  c.id, c.organization_id, /* ... toate coloanele nemascate ... */
  f.billing_rule, f.estimated_value, f.previous_year_value
from public.contracts c
cross join lateral app.masked_contract_financials(c.id)
  as f(billing_rule text, estimated_value numeric, previous_year_value numeric);
```

Un singur apel de funcție pe rând, nu unul pe coloană. Verificarea de capabilitate se face o
dată, cele trei valori se rezolvă împreună. Forma actuală face până la nouă apeluri
`has_capability` pe rând — asta e și o îmbunătățire de performanță, nu doar de securitate.

### 3.3 Grants pe tabelul de bază

```sql
revoke select on public.contracts from authenticated;
grant select (id, organization_id, client_id, legal_entity_id, contract_number,
              contract_type, period_start, period_end, status, renewal_of,
              drive_ref, notes, created_at, updated_at, client_contract_number,
              signed_date, offer_structure, ac_link)
  on public.contracts to authenticated;
```

**Ordinea contează și e contraintuitivă.** Vezi capcana 5.2.

`INSERT` și `UPDATE` rămân neatinse — politicile lor verifică deja capabilitatea corect.

---

## 4. Alternative respinse

**Mascare doar în stratul aplicație.** Un `if` în React nu e o graniță de securitate. Dovedit
de scurgerea din secțiunea 1: interfața afișa „Finance only" în timp ce REST-ul returna
plaintext în aceeași sesiune.

**`REVOKE SELECT (coloană)` peste un grant pe tabel.** Inert. Vezi capcana 5.2.

**Reatribuire de proprietar + `security_invoker = false`.** Funcționează, dovedit prin test —
dar mută evaluarea RLS pe rolul proprietar, exact mecanismul care a cedat în test. Cere ca
rolul să fie `INHERIT`, lucru pe care niciun mesaj de eroare din Postgres nu-l semnalează.
Funcția lasă `security_invoker = true` neatins, deci suprafața aia de eșec nu există deloc.

---

## 5. Capcane dovedite

Toate au fost găsite rulând, nu raționând. Documentate ca să nu le mai descopere nimeni.

### 5.1 `NOINHERIT` rupe potrivirea politicilor `TO authenticated`

Un rol membru al lui `authenticated` dar declarat `NOINHERIT` **nu** satisface politicile
`TO authenticated`. Rezultatul în test: vederea a returnat zero rânduri pentru toată lumea —
Finance și non-Finance deopotrivă. Nu o scurgere, o golire completă a paginii.

Potrivirea de rol în RLS urmează privilegiile efective moștenite, nu simpla apartenență.
Corectat prin `INHERIT`. Nu apare în niciun mesaj de eroare.

### 5.2 `REVOKE SELECT (coloană)` e inert peste un grant pe tabel

Un grant la nivel de tabel acoperă toate coloanele. Un `REVOKE` pe coloană poate retrage doar
un grant pe coloană — care n-a fost niciodată emis. Migrația rulează fără eroare, raportează
succes, și nu schimbă nimic.

Verificat cu `has_column_privilege()` înainte și după, pe un tabel de unică folosință:

| Stare | `authenticated` poate citi coloana? |
|---|---|
| `GRANT SELECT` pe tabel | da |
| `+ REVOKE SELECT (col)` | **da — neschimbat** |
| `+ REVOKE SELECT` pe tabel | nu |
| `+ GRANT SELECT (coloane permise)` | doar cele permise |

Secvența corectă e inversă: revoci pe tabel, apoi acorzi explicit lista permisă.

### 5.3 Funcția `SECURITY DEFINER` ca oracol RPC

Dacă funcția ajunge într-o schemă expusă de PostgREST și primește `EXECUTE` pentru
`authenticated`, devine apelabilă direct cu orice `id`. Fiind `SECURITY DEFINER`, sare peste
RLS la citire. O funcție care verifică doar capabilitatea ar permite unui Finance din
organizația A să citească datele organizației B.

Două apărări, ambele necesare: schema `app` neexpusă, și predicatul dublu din 3.1.

### 5.4 Transferul de proprietate cere drepturi pe schemă

`ALTER ... OWNER TO` eșuează cu „permission denied for schema X" până când noul rol primește
`USAGE, CREATE` pe schema X. Nu e suficient un grant pe tabel.

**X depinde de unde trăiește obiectul, nu e mereu `public`.** Testul care a găsit inițial
această capcană a fost făcut împotriva alternativei respinse din secțiunea 4 (reatribuirea
proprietății VEDERII, care trăiește în `public`) — de-acolo vine „schema public" de mai sus.
Implementarea aleasă (3.1) nu reatribuie vederea; reatribuie FUNCȚIA, care trăiește în schema
`app`. Grant-ul aplicat efectiv în 202608190001 e `grant usage, create on schema app to
app_masking_owner`, nu pe `public`. Regula generală — rolul nou are nevoie de `USAGE, CREATE`
pe schema obiectului pe care urmează să-l dețină — rămâne corectă; doar schema concretă diferă
după caz. De verificat la fiecare pas viitor din secțiunea 7, nu presupus din acest exemplu.

### 5.5 `postgres` are `BYPASSRLS` în acest proiect

`rolbypassrls = true`, deși `rolsuper = false`. Orice obiect deținut de `postgres` care rulează
cu drepturile proprietarului sare peste RLS. Motivul pentru care 3.1 cere un proprietar dedicat
fără `BYPASSRLS`.

### 5.6 `ALTER FUNCTION ... OWNER TO` cere apartenență temporară la rolul țintă

Eșuează cu `42501: must be able to SET ROLE "app_masking_owner"` dacă rolul care execută
`ALTER` (aici, `postgres`) nu e membru al rolului țintă. `CREATE ROLE` nu acordă automat
apartenență inversă — proprietarul creator nu devine membru al rolului creat doar prin faptul
că l-a creat.

Găsit rulând efectiv migrația (`scripts/verify_contracts_field_masking.sql`), nu presupus
dinainte. Corectat prin acordare temporară, imediat înaintea transferului, retrasă imediat
după:

```sql
grant app_masking_owner to postgres;
alter function app.masked_contract_financials(uuid) owner to app_masking_owner;
revoke app_masking_owner from postgres;
```

Apartenența nu rămâne ca stare permanentă — `postgres` nu are nevoie de nimic în plus de la
`app_masking_owner` odată ce transferul de proprietate s-a încheiat, iar lăsarea ei ar lărgi
inutil suprafața fără niciun beneficiu (postgres oricum ocolește RLS peste tot, per 5.5).

**Corecție ulterioară (vezi 5.7): secvența de mai sus a retras apartenența prea devreme.**
`revoke app_masking_owner from postgres` a rulat corect DUPĂ transferul de proprietate, dar
ÎNAINTE de `revoke execute ... from public` / `grant execute ... to authenticated` de mai jos
în migrație (secțiunea 3.1) — moment în care apartenența era deja necesară din nou, pentru un
motiv diferit de cel documentat aici.

### 5.7 `GRANT`/`REVOKE` pe o funcție cer apartenență activă la rolul proprietar, nu doar la momentul transferului

Nu doar `ALTER ... OWNER TO` (5.6) cere ca rolul care execută comanda să fie membru al
rolului țintă — orice `GRANT`/`REVOKE` ulterior pe acel obiect cere același lucru, evaluat
din nou, la momentul în care rulează, nu moștenit din faptul că apartenența a existat cândva.

**Nu eșuează cu o eroare.** Rulate după ce apartenența a fost retrasă, `revoke execute ...
from public` și `grant execute ... to authenticated` s-au încheiat cu succes — dar cu
avertismente `01006`/`01007` („no privileges could be revoked"/„no privileges were
granted"), nu erori — și n-au schimbat nimic. ACL implicit al unei funcții noi (proprietarul
are tot, `PUBLIC` are `EXECUTE`) rămâne `NULL` până la primul `GRANT`/`REVOKE` explicit care
îl atinge; materializarea aceea, găsită rulând, nu reușește să elimine `PUBLIC` când rolul
care încearcă nu mai are autoritate asupra obiectului — rezultatul e ACL-ul implicit
„înghețat" ca stare explicită, cu `PUBLIC` încă prezent.

Verificat direct: reprodus pe o funcție de unică folosință, în tranzacție cu rollback.
Rulând perechea revoke/grant CÂT TIMP `postgres` era încă membru al rolului proprietar →
ACL final corect, fără `PUBLIC`. Aceeași pereche, identică, rulată DUPĂ retragerea
apartenenței → `PUBLIC` supraviețuiește, `authenticated` nu primește niciodată un grant
explicit al lui — exact starea găsită live pe `app.masked_contract_financials` după
202608190001.

Ordinea corectă — apartenența cedată ultima, nu imediat după transferul de proprietate:

```sql
grant app_masking_owner to postgres;
alter function app.masked_contract_financials(uuid) owner to app_masking_owner;
revoke execute on function app.masked_contract_financials(uuid) from public;
grant execute on function app.masked_contract_financials(uuid) to authenticated;
revoke app_masking_owner from postgres;
```

**Recurentă la toate cele cinci tabele rămase** (secțiunea 7) — orice funcție `SECURITY
DEFINER` deținută de un rol dedicat, urmată de orice grant/revoke pe acea funcție, trebuie să
păstreze apartenența temporară până DUPĂ ultimul astfel de grant/revoke, nu doar până după
`ALTER OWNER TO`. Motivul explicit pentru care există această secțiune de capcane: găsită
rulând, nu anticipată la scrierea mecanismului pentru `contracts`.

---

## 6. Protocol de testare fără branching

Supabase Branching cere plan Pro. Nu îl avem, și nu trecem pe Pro acum. Nu există bază de date
izolată pe care să se exerseze o migrație.

Ce înlocuiește branch-ul — trei reguli, obligatorii pentru fiecare migrație de securitate:

### 6.1 Rulare în tranzacție cu rollback, cu asserțiuni scrise

Nu „am verificat manual". Un script care se termină cu excepție ridicată deliberat, iar înainte
de ea verifică fiecare punct și spune care a picat.

Setul minim de asserțiuni pentru `contracts`:

1. Utilizator Finance din organizația A vede valorile reale, toate rândurile
2. Utilizator non-Finance din organizația A vede `null`, toate rândurile
3. Ambii văd **zero** rânduri din organizația B (seed-uită în aceeași tranzacție)
4. Interogare directă pe tabelul de bază pentru coloanele restricționate → `insufficient_privilege`
5. `addContract` și `markContractSigned` (`.select("id")`) funcționează în continuare

Simularea de sesiune se face prin `set_config('request.jwt.claims', ...)` plus
`SET LOCAL ROLE authenticated`, cu UUID-urile reale ale utilizatorilor fixture. Se rezolvă
toate ID-urile cât timp scriptul e încă privilegiat, apoi se comută o singură dată — nu se
încearcă întoarcerea la `postgres` (`RESET ROLE` revine la `cli_login_postgres`).

**Rândurile-fixture trebuie să satisfacă și politicile row-level neînrudite cu masking-ul, nu
doar să existe în organizația corectă.** Găsit rulând testul pentru `contracts`: politica de
`SELECT` deja existentă (202608100003) mai desparte `finance_operations` de
`finance_reporting` la nivel de RÂND, după `client_type` al clientului
(`private_school`/`parent_b2c` vs restul) — complet independent de mascarea coloanelor pe
care o testează acest document. Un rând-fixture cu un `client_type` ales arbitrar poate face
utilizatorul Finance de test să nu vadă rândul deloc, ceea ce ar pica asserțiunea 1 dintr-un
motiv care n-are nicio legătură cu masking-ul — o falsă alarmă care ar cere depanare pe
mecanismul greșit. Rândurile-fixture trebuie alese sau seed-uite ca să satisfacă explicit și
politica row-level relevantă a fiecărui utilizator de test testat, verificată separat de
mecanismul propriu-zis pe care asserțiunea îl vizează.

### 6.2 Migrație de revenire, scrisă în același commit

Fără branch, singura plasă e să poți da înapoi în treizeci de secunde. Nu „teoretic
reversibil" — un fișier `.sql` care a fost rulat și el în tranzacție cu rollback.

**Nu trăiește în `supabase/migrations/`.** `supabase db push` aplică, în ordine, tot ce
găsește în acel director și nu apare încă în istoricul remote — inclusiv un fișier de
revenire, imediat după cel pe care îl anulează, în aceeași rulare. Găsit la pasul `contracts`
(202608190001/202608190002): `--dry-run` a arătat ambele fișiere ca fiind împinse împreună,
ceea ce ar fi anulat mascarea chiar în momentul aplicării ei.

Convenția: fișierele de revenire trăiesc în `supabase/rollbacks/`, nu în
`supabase/migrations/`, exact ca să nu fie niciodată candidat pentru auto-aplicare. Scrise în
același commit ca migrația pe care o anulează (numele păstrează timestamp-ul migrației
directe, pentru trasabilitate — doar directorul diferă), verificate în aceeași tranzacție cu
rollback din `scripts/verify_*.sql`, dar niciodată așezate acolo unde `db push` le-ar putea
confunda cu o migrație în așteptare. Aplicarea unei reveniri reale rămâne un pas manual,
deliberat: copiază fișierul înapoi în `supabase/migrations/` cu un timestamp nou (nu cel
original — istoricul remote ține minte ce s-a aplicat deja), rulează `db push`, apoi mută-l
înapoi în `supabase/rollbacks/`.

### 6.3 Una singură pe rundă, la oră fără trafic, verificată imediat în aplicație

Nu șase tabele într-o migrație. `contracts` prima. După aplicare, se deschide efectiv pagina
în browser, ca Finance și ca Operations, înainte de a trece la următorul tabel.

### 6.4 Fără SQL ad-hoc pe producție

`supabase db query --linked` deschide o conexiune directă la Postgres care nu poartă
`auth.uid()`. Scrierile prin ea apar în `row_history` cu `actor_user_id: null` — neatribuite
în jurnalul de audit. Pentru o platformă care va ține date despre copii sub GDPR, asta e o
problemă de conformitate.

De aici înainte: schema prin fișiere de migrație, datele de test prin aplicație sau printr-o
migrație de seed marcată, iar `db query` doar pentru citire și pentru tranzacții cu rollback.

---

## 7. Ordinea de aplicare

1. **`contracts`** — mecanismul e dovedit, decizia e luată, vederea există deja
2. **`users`** — listă mică de capabilități, risc scăzut
3. **`client_contacts`** — după decizia Ancăi din 2.2
4. **`file_refs`** — împreună cu politica de retenție
5. **`row_history` / `audit_log`** — fir separat, mecanism diferit

Fiecare pas trece prin protocolul din secțiunea 6, integral.

---

## 8. Ce rămâne deschis

- **Decizie Anca:** cine citește PII din `client_contacts` (blochează pasul 4)
- **Mascarea instantaneelor jsonb** din `row_history` — problemă diferită, mecanism diferit
- **Convenția pentru `audit_log.payload`** — ce are voie să intre acolo, scrisă înainte să
  existe zece tipuri de evenimente
- **Drift între `supabase/config.toml` local și proiectul live** — găsit de trei ori în această
  fază (scheme expuse, redirect URLs: 7 local vs 11 live). Orice verificare făcută din fișier
  în loc de API poate fi falsă. De sincronizat.
- **Review de dezvoltator** pe implementarea finală, înainte ca date reale de școli și copii să
  intre în producție. Rămâne prerechizitul stabilit în WS-D și nu se auto-validează.
