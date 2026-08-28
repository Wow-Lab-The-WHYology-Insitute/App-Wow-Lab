"use client";

import { createContext, useContext, useEffect, useState } from "react";

// WOW LAB OS has no i18n infrastructure anywhere else in the app today —
// every existing page is hardcoded English. This is genuinely new,
// app-wide plumbing, introduced here because the /contracts rework
// requires it (RO acceptance criterion), not a partial/local hack. Kept
// deliberately minimal (no next-intl/react-i18next dependency, no routing
// changes) — a Context + localStorage-persisted locale + a per-feature
// dictionary passed into useTranslations(), matching this codebase's
// existing "plain, hand-rolled over a new dependency" style (no clsx/cva
// anywhere either). Mounted once in app/(app)/layout.tsx so it's available
// to every authenticated page as this rolls out further; only /contracts
// actually uses it today.

export type Locale = "en" | "ro";

// Was gated off while only /contracts was translated -- flipping to RO
// would have left every other page abruptly English mid-session, reading
// as broken rather than in-progress. All 20 files with real hardcoded
// copy are translated now (verified live, RO walk across all 12 routes,
// twice), so that inconsistency is no longer the common case. A plain
// code constant, not an env var — this codebase has no feature-flag
// infra, and a single line to edit is less deployment friction than a new
// NEXT_PUBLIC_* var that has to be set consistently across local/preview/
// production (this project's own history: preview env vars have been a
// recurring pain point). Revert this one line alone if something turns
// up in real use.
export const LOCALE_SWITCHER_ENABLED = true;

const STORAGE_KEY = "wowlab.locale";

const LocaleContext = createContext<{
  locale: Locale;
  setLocale: (l: Locale) => void;
} | null>(null);

export function LocaleProvider({ children }: { children: React.ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>("en");

  // Read the persisted choice after mount, not in the initial useState
  // initializer — localStorage isn't available server-side, and reading it
  // eagerly would produce a client/server markup mismatch on first paint.
  useEffect(() => {
    const stored = window.localStorage.getItem(STORAGE_KEY);
    if (stored === "en" || stored === "ro") setLocaleState(stored);
  }, []);

  function setLocale(l: Locale) {
    setLocaleState(l);
    window.localStorage.setItem(STORAGE_KEY, l);
  }

  return (
    <LocaleContext.Provider value={{ locale, setLocale }}>
      {children}
    </LocaleContext.Provider>
  );
}

export function useLocale() {
  const ctx = useContext(LocaleContext);
  if (!ctx) throw new Error("useLocale must be used within LocaleProvider");
  return ctx;
}

export type Dictionary = Record<string, Record<Locale, string>>;

// t(key, vars) looks up dict[key][locale] and substitutes {{var}} tokens.
// Falls back to the raw key (visibly wrong, not silently blank) if a
// string is ever missing from the dictionary — a forgotten translation
// should be obvious in the UI, not swallowed.
export function useTranslations(dict: Dictionary) {
  const { locale } = useLocale();
  return function t(key: string, vars?: Record<string, string | number>) {
    const entry = dict[key];
    let str = entry ? entry[locale] : key;
    if (vars) {
      for (const [k, v] of Object.entries(vars)) {
        str = str.split(`{{${k}}}`).join(String(v));
      }
    }
    return str;
  };
}
