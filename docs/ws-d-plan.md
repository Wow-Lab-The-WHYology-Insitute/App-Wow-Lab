# WOW LAB OS — WS-D (RLS) Plan & metoda de verificare

**Statut:** săptămâna critică. Poarta de review de developer e **amânată** (nu avem developer acum) → WS-D **nu** se declară „sigur” doar pe baza testelor; construim cu grijă și etichetăm riscul. Verificarea rulează **ca utilizatorii de test**, nu prin service role.

---

## 1. Modelul mental (ce se schimbă acum)

- Până acum: toate tabelele au RLS pornit, **deny-by-default, fără politici** → printr-o conexiune normală **nimeni nu vede nimic**.
- Tot ce am verificat până acum a fost prin **service role**, care **OCOLEȘTE RLS** → inutil pentru a dovedi izolarea.
- WS-D scrie **politicile permisive** (cine ce vede/face) și **dovedește granițele** rulând ca fiecare user de test.

---

## 2. Cum testezi RLS „ca un user” în SQL Editor (tehnica de impersonare)

Într-o tranzacție, te dai drept un user și RLS se aplică. Șablon:

```sql
begin;
  -- devii rol "authenticated" (nu mai ești superuser care ocolește RLS)
  select set_config('role', 'authenticated', true);
  -- setezi identitatea: auth.uid() va întoarce acest sub
  select set_config('request.jwt.claims',
    json_build_object('sub', (select id from users where email = 'test+catalina@wowlab.dev'),
                      'role','authenticated')::text, true);

  -- ... aici rulezi interogarea de testat, ex.:
  select count(*) from legal_entities;   -- ce vede Cătălina

rollback;   -- nu persistă nimic
```

Ideea: **schimbi doar emailul** din bloc ca să testezi alt user. `rollback` la final. Claude Code va salva suita completă ca fișier `.sql` în repo (verificat că merge), iar tu o rulezi bloc cu bloc în SQL Editor și-mi spui rezultatele. Așa e „automatizat (fișier versionat) + rulat manual de tine”, cum ai cerut.

> Regula de aur a testelor: fiecare test are un rezultat **așteptat** („trebuie să vadă X rânduri” / „trebuie să vadă 0”). Un test fără așteptare nu dovedește nimic.

---

## 3. Ordinea de lucru

### D0 — Funcțiile-helper (fundația, cea mai delicată)
- `app.is_platform_owner()` — bypass-ul (user cu `users.is_platform_owner = true` vede tot).
- `app.has_capability(cap, org)` — rezolvă rolurile user-ului în `org`, le unește și face **potrivire pe prefix/glob** pe wildcard-uri (cine are `curriculum.*` trece la `curriculum.lessons.read`). ← fix riscul semnalat la B4.
- `app.belongs_to_org(org)` — user-ul are vreun rol în org.
- Toate `SECURITY DEFINER` cu `search_path` fixat (ca să citească tabelele de permisiuni în siguranță).
- **O eroare aici acordă/blochează greșit în tăcere** → punctul #1 de review.

### D1 — Politicile per tabel
- Referință (`roles`, `capabilities`, `role_capabilities`): citire pentru autentificați.
- Tenancy (`organizations`, `legal_entities`, `users`, `user_org_roles`, `org_settings`): org-scoped, pe capabilități, cu bypass platform_owner.
- Fiecare tabel: ce capabilitate guvernează citirea/scrierea (harta tabel→capabilitate).

### D2 — Suita de teste (impersonare, pozitiv + negativ)
- Pentru fiecare user de test: ce **poate** vedea și ce **nu poate**.
- Obligatoriu **teste negative** (așteptare = 0 rânduri).

### D3 — Cele 4 scenarii critice de izolare
1. **Cross-org:** `u_user_b` (org_b) → `select from legal_entities` → **0 rânduri** din wow-lab.
2. **Own-data:** `u_trainer_a` → vede doar ce e al lui, nu datele altor traineri.
3. **OD-7 confidențialitate:** trainerul evaluat **nu** vede propria evaluare când `evaluations_confidential = true` (se testează pe bune când există tabelul de evaluări; în Phase 0 pregătim doar mecanismul).
4. **Segregare finanțe:** `u_finance_ops_a` → **nu** vede raportarea/profitabilitatea companiei; `u_finance_admin_a` → da.

### D4 — Review (amânat) + threat model
- Când ai developer: ~2-3 ore pe checklist-ul din secțiunea 6.

---

## 4. Testul „trebuie să pică” (dovada că suita are dinți)

După ce totul e verde, **strici intenționat o politică** (ex. scoți condiția de org dintr-un tabel) și confirmi că **un test negativ devine roșu** (ex. org_b începe să vadă wow-lab). Dacă nimic nu se înroșește, suita nu testează nimic. Apoi repui politica. Fără pasul ăsta, „verde” nu înseamnă nimic.

---

## 5. Metoda de verificare (rezumat, cum ai cerut)

- **Claude Code** scrie politicile + **salvează suita de teste ca `db/tests/rls_ws_d.sql`** în repo (verificată că rulează), commit + push.
- **Tu** rulezi blocurile în SQL Editor (impersonare), manual, și-mi raportezi.
- **Automatizăm rularea; NU auto-verzim „aprobarea” de securitate** — aia rămâne cu ochi de om (review amânat, dar obligatoriu înainte de go-live cu date reale).

---

## 6. Checklist pentru developer (când e disponibil) — poarta amânată

1. `app.has_capability` — glob-matching corect (nici prea larg: `curriculum.*` să NU acopere `curriculumX`; nici prea îngust: să acopere `curriculum.lessons.read`) + rezolvarea corectă a org-ului.
2. Bypass-ul `is_platform_owner` — exact (nici toți superuseri, nici platform owner blocat).
3. Testele **negative chiar pică** când strici o politică.
4. Nicio politică nu se bazează pe service role / nu presupune superuser.
5. `SECURITY DEFINER` + `search_path` fixat pe toate funcțiile-helper (fără hijack).
6. Threat model scurt: ce se întâmplă cu un JWT expirat / user dezactivat / rol scos.

---

## 7. Riscul, spus pe față

RLS pică **în tăcere**: o politică subtil greșită trece toate testele dacă și testul e subtil greșit. Fără review de developer, WS-D e „construit cu grijă și testat”, **nu** „garantat etanș”. Mergem înainte pe fazele de construcție, dar **înainte de a pune date reale de școli/copii în producție**, poarta asta trebuie trecută.
