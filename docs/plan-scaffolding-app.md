# WOW LAB OS — Plan de scaffolding aplicație (Next.js) + auth

**Ce e asta.** Puntea de la fundația de date (gata) la aplicația reală. Construim scheletul Next.js, legăm autentificarea Supabase, și dovedim că app + auth + RLS lucrează împreună ca un user real logat — nu doar prin impersonare SQL. De aici încolo se construiesc feature-urile Phase 1.

**Ca la WS-D: mergem cu hartă întâi, în pași mici verificați.** Și un punct de onestitate: **auth-ul e pe lista porții de developer** — îl construim cu grijă și îl marcăm pentru review, la fel ca RLS-ul.

---

## 0. Regula de securitate #1 (nenegociabilă)

Aplicația folosește **DOAR cheia `anon`** (publică — e sigură, fiindcă RLS filtrează datele). **Cheia `service_role` NU ajunge NICIODATĂ în aplicație** (nici în browser, nici în codul general de server) — ea **ocolește RLS** și ar anula toată munca de la WS-D. `service_role` se folosește doar în scripturi/procese de încredere, separate.

- `NEXT_PUBLIC_SUPABASE_URL` + `NEXT_PUBLIC_SUPABASE_ANON_KEY` → în Vercel Environment Variables + `.env.local` (gitignored). Publice, ok.
- `service_role` → **nicăieri în app**.

---

## 1. Cum se leagă auth-ul de RLS (de ce contează)

Când un user se loghează, Supabase îi dă un **JWT**. Aplicația trimite acel JWT la fiecare cerere, iar `auth.uid()` din politicile noastre RLS întoarce fix id-ul acelui user. **Aici „se închide bucla":** tot ce am construit la WS-D (izolare pe org, own-data, capabilități) devine real în momentul în care un om chiar se loghează. Până acum am simulat asta cu impersonare; acum devine flux adevărat.

---

## 2. Ordinea de lucru (S0 → S3)

### S0 — Schelet Next.js + pipeline de deploy
- Next.js (App Router) + TypeScript + Tailwind, în repo (repo-ul e gol de app acum).
- O pagină minimă (landing) — doar ca Vercel să aibă ce publica.
- **Verificare:** push → Vercel build ✅ → `app.wowlab.ro` afișează pagina. (Dovada că pipeline-ul laptop → GitHub → Vercel merge și pentru app, nu doar pentru DB.)
- Biblioteci: `@supabase/supabase-js` + `@supabase/ssr` (pentru sesiuni server-side în App Router).

### S1 — Auth (Supabase Auth) — pasul sensibil
- Login / logout, sesiuni prin `@supabase/ssr`, middleware care protejează rutele.
- **Invite-only** (fără înregistrare publică — conform deciziei de arhitectură).
- Metodă recomandată: **magic link (passwordless)** — un admin invită, user-ul primește link pe email, fără parole de gestionat. (Alternativă: email+parolă. De decis — vezi §4.)
- **Verificare:** un user de test se loghează real; o rută protejată respinge accesul fără login.
- 🔴 **Poarta de developer:** configurarea sesiunilor + protejarea rutelor + fluxul de token. Construim cu grijă, marcăm pentru review.

### S2 — „Închiderea buclei" (cel mai important test)
- O pagină protejată care, ca user real logat, **citește prin RLS**: îți arată organizația ta, rolurile și capabilitățile tale (rezolvate din `users` → `user_org_roles` → `role_capabilities`).
- **Verificare:** logat ca `u_owner_a` vezi wow-lab + rolul lui; logat ca un trainer vezi doar ce e al lui. Prima dovadă că app + auth + RLS merg cap-coadă ca flux real (nu impersonare SQL). **Moment mare** — validează toată munca de securitate într-un flux adevărat.

### S3 — Shell-ul aplicației (navigație + brand)
- Sidebar-ul cu navigație pe rol + stilul de brand (culorile + fonturile din mockup: roz/oranj/teal/mov/amber, Bricolage Grotesque + Lora).
- Meniul se afișează în funcție de capabilitățile user-ului (ce am construit deja se reflectă în UI).
- Aici **mockup-ul devine structură reală**.
- `locales` (RO/EN) — setarea de i18n intră tot aici.

→ După S3, intrăm în **Phase 1**: feature-urile de business (clienți, contracte, grupe, prezență) se construiesc în acest shell.

---

## 3. Ce verificăm la fiecare pas (rezumat)

| Pas | Dovada că merge |
|---|---|
| S0 | `app.wowlab.ro` afișează app-ul; Vercel build verde |
| S1 | user de test se loghează real; ruta protejată respinge fără login |
| S2 | logat, vezi DOAR datele tale prin RLS (owner vede org, trainer vede own-data) |
| S3 | meniul se schimbă pe rol; brand-ul se potrivește cu mockup-ul |

---

## 4. Decizii de luat înainte de S1

- **Metoda de auth:** magic link (passwordless, recomandat, se potrivește cu invite-only) vs email+parolă?
- **App Router** (modern, recomandat) — confirmăm, sau ai o preferință?
- **Ordinea:** S0→S1→S2 minimal (dovedim bucla întâi), apoi S3 (shell-ul de brand)? Sau vrei shell-ul de brand mai devreme?

---

## 5. Poarta de developer — ce se adaugă din scaffolding

Pe lângă lista de la WS-D, developer-ul (când e disponibil) verifică și:
- fluxul de auth (sesiuni, refresh de token, protejarea rutelor, logout curat);
- că `service_role` nu apare nicăieri în bundle-ul aplicației (verificare că nu s-a scurs în client);
- că paginile server-side folosesc corect sesiunea user-ului (nu o conexiune privilegiată).

---

## 6. Ce NU facem în scaffolding
- Feature-uri de business (clienți, contracte etc.) — acelea sunt Phase 1, după shell.
- Integrarea ActiveCampaign — Phase 1.
- Design final rafinat — întâi structura funcțională, apoi rafinăm.
