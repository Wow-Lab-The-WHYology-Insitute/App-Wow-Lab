# WOW LAB OS — Ghid operare: Cum introducem o școală în aplicație

**Public:** Anca (și oricine introduce clienți/contracte/grupe manual).
**Istoric:** până la 2026-09-09, această procedură a existat doar într-un mesaj Asana. A rămas neactualizată o zi după ce ecranele s-au schimbat, fără ca nimic să semnaleze asta. De acum trăiește aici, cu un manifest verificabil, nu din memorie.

---

## Obligație de întreținere

Orice schimbare la `clients-client.tsx`, `contracts-client.tsx`, `groups-client.tsx`, la `actions.ts`-urile lor, sau la `i18n.ts`-urile lor **trebuie verificată împotriva acestui ghid** — inclusiv manifestul de mai jos — înainte de a fi integrată.

Verificarea se face manual:

```
npx tsx scripts/check_operator_guide.ts
```

Acest ghid **nu** este verificat automat în CI — în acest proiect nu există CI, și nu îl adăugăm pentru asta. Scriptul se rulează de o persoană, la nevoie.

**Ultima rulare:** 2026-10-12 — 38/38, după reparația de mai jos. Rularea anterioară (2026-09-10) a dat 34/34, iar scriptul **nu a mai fost rulat trei săptămâni** — timp în care `202609210006` a înlocuit lista de șase formate cu cele nouă ale Ancăi plus Custom, iar ghidul a continuat să trimită la trei formate care nu mai existau. Găsit 2026-10-12, din întâmplare, verificând altceva (OPEN_ITEMS.md item 114). Manifestul are acum 38 de rânduri, nu 34: cele trei rânduri moarte au fost înlocuite cu toate cele zece formate reale, pentru ca lista din Pasul 3 să fie verificabilă în întregime, nu doar pe jumătate.

Prima rulare, în 2026-09-10, a găsit o nepotrivire reală (`create_contract`: textul butonului e „Creează contractul", nu „Creează contract" cum scria draftul) — corectată în același commit, în manifest și în Pasul 2 mai jos.

---

## Manifest — fiecare pretenție verificabilă

Fiecare rând de mai jos este o afirmație din procedură care citează text exact dintr-un dicționar i18n (buton, opțiune de listă, valoare implicită) — cu locul exact din cod unde poate fi verificată. `scripts/check_operator_guide.ts` citește acest tabel și compară coloana **Text RO așteptat** cu valoarea reală din dicționarul numit. Un rând care nu se mai potrivește înseamnă că procedura a rămas în urma codului.

Nu conține afirmațiile de comportament (ex. „listele pornesc goale", „data vine completată cu azi", „cele 15 module") — acelea nu sunt text dintr-un dicționar i18n, ci logică de cod, și se verifică manual, la fel ca până acum. Nici afirmațiile despre **conținutul bazei de date** (cele trei entități juridice numite în Pasul 2, numărul de module) nu sunt acoperite: nu sunt șiruri din dicționar, deci scriptul nu le vede. Când se schimbă un vocabular, cineva recitește ghidul — scriptul nu e suficient singur.

Exemplul de mai sus a fost chiar el greșit până la 2026-10-12: scria „cele 13 module", rămas în urmă de la `202610070001` (vet) și mai în urmă după `202610120001` (anatomy). Verificat acum direct în `public.modules`: **15 rânduri**, aceleași 15 chei și în `groups_module_check`.

| Cheie | Export | Fișier | Text RO așteptat |
|---|---|---|---|
| `nav_group_clients_contracts` | `chromeDict` | `app/(app)/i18n.ts` | Clienți și contracte |
| `page_title` | `clientsDict` | `app/(app)/clients/i18n.ts` | Clienți |
| `new_client` | `clientsDict` | `app/(app)/clients/i18n.ts` | + Client nou |
| `client_type_private_school` | `clientsDict` | `app/(app)/clients/i18n.ts` | Școală privată |
| `client_type_state_school` | `clientsDict` | `app/(app)/clients/i18n.ts` | Școală de stat |
| `client_type_corporate` | `clientsDict` | `app/(app)/clients/i18n.ts` | Corporate |
| `client_type_parent_b2c` | `clientsDict` | `app/(app)/clients/i18n.ts` | Părinte B2C |
| `client_type_special_project` | `clientsDict` | `app/(app)/clients/i18n.ts` | Proiect special |
| `select_business_line` | `clientsDict` | `app/(app)/clients/i18n.ts` | Alege linia de business… |
| `business_line_recurring_private_schools` | `clientsDict` | `app/(app)/clients/i18n.ts` | Cluburi recurente în școli private |
| `business_line_state_schools` | `clientsDict` | `app/(app)/clients/i18n.ts` | Școli de stat (Școala Altfel / Săptămâna Verde) |
| `business_line_corporate_events` | `clientsDict` | `app/(app)/clients/i18n.ts` | Corporate și evenimente |
| `create_client` | `clientsDict` | `app/(app)/clients/i18n.ts` | Creează clientul |
| `page_title` | `contractsDict` | `app/(app)/contracts/i18n.ts` | Contracte |
| `new_contract` | `contractsDict` | `app/(app)/contracts/i18n.ts` | + Contract nou |
| `contract_type_recurring_annual` | `contractsDict` | `app/(app)/contracts/i18n.ts` | recurent anual |
| `contract_type_one_off_event` | `contractsDict` | `app/(app)/contracts/i18n.ts` | eveniment unic |
| `contract_type_framework` | `contractsDict` | `app/(app)/contracts/i18n.ts` | contract-cadru |
| `start_date` | `contractsDict` | `app/(app)/contracts/i18n.ts` | Data început |
| `end_date` | `contractsDict` | `app/(app)/contracts/i18n.ts` | Data sfârșit |
| `create_contract` | `contractsDict` | `app/(app)/contracts/i18n.ts` | Creează contractul |
| `mark_as_signed` | `contractsDict` | `app/(app)/contracts/i18n.ts` | Marchează ca semnat |
| `nav_group_operational` | `chromeDict` | `app/(app)/i18n.ts` | Operațional |
| `page_title` | `groupsDict` | `app/(app)/groups/i18n.ts` | Grupe și înscrieri |
| `new_group` | `groupsDict` | `app/(app)/groups/i18n.ts` | + Grupă nouă |
| `edit` | `groupsDict` | `app/(app)/groups/i18n.ts` | Editează |
| `format_scoala_altfel` | `groupsDict` | `app/(app)/groups/i18n.ts` | Școala Altfel |
| `format_saptamana_verde` | `groupsDict` | `app/(app)/groups/i18n.ts` | Săptămâna Verde |
| `format_wow_lab_party` | `groupsDict` | `app/(app)/groups/i18n.ts` | Wow Lab Party |
| `format_parteneriate_companii` | `groupsDict` | `app/(app)/groups/i18n.ts` | Parteneriate cu companii |
| `format_cursuri_deschise` | `groupsDict` | `app/(app)/groups/i18n.ts` | Cursuri deschise |
| `format_scoli_private_ocazionale` | `groupsDict` | `app/(app)/groups/i18n.ts` | Școli private (colaborări ocazionale) |
| `format_scoli_private_recurente` | `groupsDict` | `app/(app)/groups/i18n.ts` | Școli private (colaborări recurente) |
| `format_evenimente_mall` | `groupsDict` | `app/(app)/groups/i18n.ts` | Evenimente/prezentări la mall |
| `format_party_companii` | `groupsDict` | `app/(app)/groups/i18n.ts` | Party în companii |
| `format_custom` | `groupsDict` | `app/(app)/groups/i18n.ts` | Custom |
| `status_active` | `groupsDict` | `app/(app)/groups/i18n.ts` | Activă |
| `create_group` | `groupsDict` | `app/(app)/groups/i18n.ts` | Creează grupa |

---

## Ordinea

Ordinea: întâi clientul, apoi contractul, apoi grupele.

Toate listele derulante pornesc goale și te obligă să alegi — butonul de creare rămâne inactiv până completezi tot ce trebuie. Singura excepție e Starea grupei, care vine pe „Activă"; schimb-o dacă e cazul.

## Pasul 1 — Clientul (școala)

**Meniu → Clienți și contracte → Clienți → „+ Client nou"**

- Numele clientului
- Tipul clientului — Școală privată, Școală de stat, Corporate, Părinte B2C, Proiect special
- Linia de business — cluburi recurente în școli private, școli de stat (Școala Altfel /
  Săptămâna Verde), corporate și evenimente. Opțională — poți lăsa neclasificat.
- Denumire legală, CUI — opționale

Apeși „Creează clientul".

## Pasul 2 — Contractul

**Meniu → Clienți și contracte → Contracte → „+ Contract nou"**

- Client — școala de la pasul 1
- Entitatea juridică — Experimente Wow SRL, Brandine Advertising SRL sau Asociatia STEMplicity. Firma care facturează.
  - „Asociatia" e scris **intenționat fără diacritică**, exact cum apare în aplicație: numele din baza de date se scriu fără diacritice prin convenție, confirmată de Anca pe propriul ei nume (OPEN_ITEMS.md item 42). Ghidul numește ce e pe ecran, deci nu se „corectează" înapoi — corecția în direcția cealaltă, în date, e exact greșeala pe care itemii 35 și 42 o au consemnată.
  - Cele trei sunt entitățile organizației **WOW LAB**. Tabelul `legal_entities` are cinci rânduri în total, două fiind fixturi de test (Test Org B): un `count(*)` fără filtru pe organizație arată cinci și pare o nepotrivire cu „trei" de mai sus. Nu e.
- Tipul contractului — recurent anual, eveniment unic sau contract-cadru
- Număr intrare / Număr ieșire — opționale. Numărul de ieșire trebuie să fie unic; dacă se repetă, primești o eroare (în engleză, deocamdată).
- Data început / Data sfârșit — opționale
- Regulă de facturare — opțională, ex. „95 lei/copil/ședință"
- Valoare estimată / Valoare an anterior — opționale

Apeși „Creează contractul". Se salvează ca ciornă.

Pentru a-l marca semnat: intri pe contract și apeși „Marchează ca semnat". Câmpul de dată vine completat cu ziua de azi — schimbă-l cu data reală a semnării. Pentru contractele deja semnate, asta contează.

## Pasul 3 — Grupele

**Meniu → Operațional → Grupe și înscrieri → „+ Grupă nouă"**

- Client — școala
- Contract — contractul sub care se livrează grupa. Poți să-l lași gol dacă nu e încă semnat și să-l completezi mai târziu, din „Editează" pe pagina grupei.
- Modulul — cele 15 module
- Formatul — una din cele zece de mai jos. Formatul spune **cum și cui** se vinde atelierul; ce se predă e modulul. Sunt două câmpuri separate, nu două feluri de a spune același lucru.
  - **Școli private (colaborări recurente)** — club care se ține săptămânal la o școală privată, pe tot anul școlar. Doar ăsta cere program pe zi și oră (vezi mai jos).
  - **Școli private (colaborări ocazionale)** — o intervenție singulară la o școală privată, nu un club. Exemplul Ancăi: Science Week la IBSB.
  - **Școala Altfel** — programul național Școala Altfel, de regulă în școli de stat.
  - **Săptămâna Verde** — programul național Săptămâna Verde. E alt program, nu o variantă a Școlii Altfel.
  - **Cursuri deschise** — curs la care copiii se înscriu individual, nu printr-o școală. Exemplul Ancăi: cursuri de chimie.
  - **Wow Lab Party** — petrecerea unui copil.
  - **Party în companii** — același produs, dar la o firmă (ex. petrecerea angajaților). Dacă e party și e la firmă, alegi ăsta, nu „Wow Lab Party".
  - **Parteneriate cu companii** — relație continuă cu o companie, nu un eveniment singular.
  - **Evenimente/prezentări la mall** — eveniment sau prezentare într-un spațiu comercial. Exemplul Ancăi: Barlad Value Center.
  - **Custom** — numai când niciunul din celelalte nouă nu descrie livrarea. Nu e „recurent cu alt nume": clubul săptămânal la școală privată e „Școli private (colaborări recurente)".

  Dacă te-ai obișnuit cu lista veche de șase: *Recurent (club școlar)* → **Școli private (colaborări recurente)**; *Party* → **Wow Lab Party** sau **Party în companii**, după unde se ține; *Corporate* → **Parteneriate cu companii** sau **Evenimente/prezentări la mall**, după dacă e relație continuă sau un eveniment. *Școala Altfel*, *Săptămâna Verde* și *Custom* au rămas la fel. **Cursuri deschise** și **Școli private (colaborări ocazionale)** sunt noi — vechea listă nu avea cum să le exprime.
- Starea — vine pe „Activă"
- Programul:
  - pentru **Școli private (colaborări recurente)**: ziua și ora. Zilele apar deocamdată în engleză (Monday, Tuesday…). Dacă lași ora goală, se pierde și ziua — completează amândouă.
  - pentru celelalte nouă formate (inclusiv Custom): data și ora. Aici ora poate rămâne goală, data se păstrează.
- Interval de vârstă, Link calendar an școlar — opționale

Apeși „Creează grupa".

## Ce nu se poate încă

Numărul de copii confirmați și facturați se vede pe pagina grupei, dar nu se poate completa. Așteaptă răspunsul tău despre cine introduce prezența.

---

Începe cu o singură școală, cap-coadă, și spune-mi cum a mers înainte de restul. Dacă ceva nu e clar în ecran, scrie-mi — probabil e de reparat, nu de explicat.
