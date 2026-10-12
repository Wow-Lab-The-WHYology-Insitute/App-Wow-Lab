"use client";

import { useLocale } from "@/lib/i18n";

// Scoped to /contracts for now (rendered in its page header), not the
// global topbar — i18n is only wired up on this one page so far; the
// switcher moves to app/(app)/shell-chrome.tsx once more pages adopt
// useTranslations().
export function LocaleSwitcher() {
  const { locale, setLocale } = useLocale();

  return (
    <div
      role="group"
      aria-label="Language"
      className="font-body text-muted inline-flex shrink-0 items-center gap-0.5 rounded-full border border-black/10 p-0.5 text-xs font-medium"
    >
      {(["en", "ro"] as const).map((l) => (
        <button
          key={l}
          type="button"
          onClick={() => setLocale(l)}
          aria-pressed={locale === l}
          // transition-colors STAYS here, unlike the 36 input fields it was
          // stripped from in the same pass. Those had focus:border-*, a colour
          // this class animates, which made focus arrive late. This button's
          // focus state is a ring (box-shadow) — transition-colors does not
          // touch it — so the class exists only for `hover:text-ink` on the
          // next line, which is what it should be for.
          className={`rounded-full px-2.5 py-1 uppercase transition-colors focus-visible:ring-brand-pink focus-visible:outline-none focus-visible:ring-2 ${
            locale === l ? "bg-brand-pink text-white" : "hover:text-ink"
          }`}
        >
          {l}
        </button>
      ))}
    </div>
  );
}
