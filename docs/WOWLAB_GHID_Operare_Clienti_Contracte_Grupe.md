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

**Ultima rulare:** 2026-09-09 — 30/30. Prima rulare a găsit o nepotrivire reală (`create_contract`: textul butonului e „Creează contractul", nu „Creează contract" cum scria draftul) — corectată în același commit, în manifest și în Pasul 2 mai jos.

---

## Manifest — fiecare pretenție verificabilă

Fiecare rând de mai jos este o afirmație din procedură care citează text exact dintr-un dicționar i18n (buton, opțiune de listă, valoare implicită) — cu locul exact din cod unde poate fi verificată. `scripts/check_operator_guide.ts` citește acest tabel și compară coloana **Text RO așteptat** cu valoarea reală din dicționarul numit. Un rând care nu se mai potrivește înseamnă că procedura a rămas în urma codului.

Nu conține afirmațiile de comportament (ex. „listele pornesc goale", „data vine completată cu azi", „cele 13 module") — acelea nu sunt text dintr-un dicționar i18n, ci logică de cod, și se verifică manual, la fel ca până acum.

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
| `format_recurring` | `groupsDict` | `app/(app)/groups/i18n.ts` | Recurent (club școlar) |
| `format_scoala_altfel` | `groupsDict` | `app/(app)/groups/i18n.ts` | Școala Altfel |
| `format_saptamana_verde` | `groupsDict` | `app/(app)/groups/i18n.ts` | Săptămâna Verde |
| `format_party` | `groupsDict` | `app/(app)/groups/i18n.ts` | Party |
| `format_corporate` | `groupsDict` | `app/(app)/groups/i18n.ts` | Corporate |
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
- Linie de business, Denumire legală, CUI — opționale

Apeși „Creează clientul".

## Pasul 2 — Contractul

**Meniu → Clienți și contracte → Contracte → „+ Contract nou"**

- Client — școala de la pasul 1
- Entitatea juridică — Experimente Wow SRL, Brandine Advertising SRL sau Asociația STEMplicity. Firma care facturează.
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
- Modulul — cele 13 module
- Formatul — Recurent (club școlar), Școala Altfel, Săptămâna Verde, Party, Corporate sau Custom
- Starea — vine pe „Activă"
- Programul:
  - pentru recurent: ziua și ora. Zilele apar deocamdată în engleză (Monday, Tuesday…). Dacă lași ora goală, se pierde și ziua — completează amândouă.
  - pentru celelalte formate: data și ora. Aici ora poate rămâne goală, data se păstrează.
- Interval de vârstă, Link calendar an școlar — opționale

Apeși „Creează grupa".

## Ce nu se poate încă

Numărul de copii confirmați și facturați se vede pe pagina grupei, dar nu se poate completa. Așteaptă răspunsul tău despre cine introduce prezența.

---

Începe cu o singură școală, cap-coadă, și spune-mi cum a mers înainte de restul. Dacă ceva nu e clar în ecran, scrie-mi — probabil e de reparat, nu de explicat.
