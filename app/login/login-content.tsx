"use client";

import Image from "next/image";
import { LocaleProvider, LOCALE_SWITCHER_ENABLED, useTranslations } from "@/lib/i18n";
import { LocaleSwitcher } from "@/components/ui/locale-switcher";
import { loginDict } from "./i18n";
import { LoginForm } from "./login-form";

// A second, independent LocaleProvider mount -- not the one in
// app/(app)/layout.tsx, which /login can never reach (it's structurally
// outside that route group, and even if it weren't, that layout redirects
// unauthenticated requests to /login before its own LocaleProvider is
// constructed). Both instances read the same "wowlab.locale" localStorage
// key, so a returning user's stored preference still applies here; a
// first-time invitee has nothing stored, which is what the switcher below
// is for. See docs/OPEN_ITEMS.md for the full investigation.
export function LoginContent({ hasCallbackError }: { hasCallbackError: boolean }) {
  return (
    <LocaleProvider>
      <LoginCard hasCallbackError={hasCallbackError} />
    </LocaleProvider>
  );
}

function LoginCard({ hasCallbackError }: { hasCallbackError: boolean }) {
  const t = useTranslations(loginDict);

  return (
    <main className="flex min-h-screen items-center justify-center bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] p-6">
      <div className="relative w-full max-w-[420px] rounded-2xl bg-white p-10 shadow-xl">
        {LOCALE_SWITCHER_ENABLED && (
          <div className="absolute top-4 right-4">
            <LocaleSwitcher />
          </div>
        )}
        <div className="flex flex-col items-center text-center">
          <Image
            src="/logo-wowlab.png"
            alt="WOW LAB"
            width={220}
            height={73}
            priority
            className="h-12 w-auto"
          />
          <h1 className="font-display mt-6 text-2xl text-brand-pink">
            WOW LAB OS
          </h1>
          <p className="font-body text-muted mt-2 text-sm">{t("subtitle")}</p>
        </div>
        {hasCallbackError && (
          <p className="font-body text-ink mt-6 rounded-lg bg-brand-pink/10 px-3 py-2 text-center text-sm">
            {t("callback_error")}
          </p>
        )}
        <div className="mt-8">
          <LoginForm />
        </div>
      </div>
    </main>
  );
}
