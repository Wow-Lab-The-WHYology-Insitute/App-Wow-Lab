"use client";

import { useState } from "react";
import Image from "next/image";
import { NavLink } from "./nav-link";
import { SignOutButton } from "./sign-out-button";
import { useTranslations, LOCALE_SWITCHER_ENABLED } from "@/lib/i18n";
import { LocaleSwitcher } from "@/components/ui/locale-switcher";
import { chromeDict } from "./i18n";

type NavItem = { href: string; labelKey: string };
type NavGroup = { labelKey?: string; items: NavItem[] };

// Desktop (md: and up) is unchanged from S3: sidebar is a normal, always-
// visible flex child (sticky, in-flow, w-60). Below md, the same <aside>
// becomes a fixed off-canvas drawer (-translate-x-full by default) toggled
// by the hamburger button, with a backdrop that closes it — standard
// collapse pattern, nothing fancier. The drawer also closes itself when a
// NavLink is actually clicked (onNavigate), not just on backdrop tap.
//
// The only real movement in this app. ease-OUT, not ease-in-out: a panel that
// is arriving should start fast and settle, where ease-in-out starts slowly
// and reads as lag. motion-safe: because this is the one transform in the
// codebase and the only transition that reduced-motion users have reason to
// care about — the other ~79 are colour and opacity. Tokens from globals.css.
export function ShellChrome({
  navGroups,
  userEmail,
  orgLabel,
  isTestOrg,
  roleLabel,
  avatarUrl,
  children,
}: {
  navGroups: NavGroup[];
  userEmail: string;
  orgLabel: string;
  isTestOrg: boolean;
  roleLabel: string;
  avatarUrl: string | null;
  children: React.ReactNode;
}) {
  const [isOpen, setIsOpen] = useState(false);
  const t = useTranslations(chromeDict);

  return (
    <div className="flex min-h-dvh">
      <aside
        className={`bg-sidebar fixed inset-y-0 left-0 z-40 flex w-60 flex-col motion-safe:transition-transform motion-safe:duration-[var(--duration-panel)] motion-safe:ease-out-panel md:sticky md:top-0 md:h-screen md:flex-shrink-0 md:translate-x-0 md:transition-none ${
          isOpen ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        <div className="flex items-center gap-2 p-6">
          <Image
            src="/logo-wowlab.png"
            alt=""
            width={28}
            height={28}
            className="h-7 w-auto"
          />
          <span className="font-display bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] bg-clip-text text-lg leading-none text-transparent">
            WOW LAB OS
          </span>
        </div>
        <nav className="flex flex-col gap-4 px-3">
          {navGroups.map((group, i) => (
            <div key={group.labelKey ?? i} className="flex flex-col gap-1">
              {group.labelKey && (
                <span className="font-body px-3 text-[10px] font-bold tracking-wide text-white/30 uppercase">
                  {t(group.labelKey)}
                </span>
              )}
              {group.items.map((item) => (
                <NavLink
                  key={item.href}
                  href={item.href}
                  label={t(item.labelKey)}
                  onNavigate={() => setIsOpen(false)}
                />
              ))}
            </div>
          ))}
        </nav>
      </aside>

      {isOpen && (
        <button
          type="button"
          aria-label={t("aria_close_menu")}
          onClick={() => setIsOpen(false)}
          className="fixed inset-0 z-30 bg-black/40 md:hidden"
        />
      )}

      <div className="bg-ink/[0.03] flex min-w-0 flex-1 flex-col">
        <header className="flex items-center justify-between gap-3 border-b border-black/5 bg-white px-4 py-4 md:px-8">
          <div className="flex min-w-0 items-center gap-3">
            <button
              type="button"
              aria-label={t("aria_open_menu")}
              onClick={() => setIsOpen(true)}
              className="text-ink shrink-0 rounded-lg p-1.5 hover:bg-black/5 md:hidden"
            >
              <svg
                width="20"
                height="20"
                viewBox="0 0 20 20"
                fill="none"
                aria-hidden="true"
              >
                <path
                  d="M2.5 5h15M2.5 10h15M2.5 15h15"
                  stroke="currentColor"
                  strokeWidth="1.6"
                  strokeLinecap="round"
                />
              </svg>
            </button>
            <Image
              src="/logo-wowlab.png"
              alt=""
              width={22}
              height={22}
              className="h-[22px] w-auto shrink-0 md:hidden"
            />
            <TopbarAvatar url={avatarUrl} label={userEmail} />
            {/* The Test badge sits OUTSIDE the truncated line, next to the
                avatar, and never shrinks.
                It used to live inside the `· {orgLabel}` span, which is inside
                a `truncate` container: measured at 320px the org span starts at
                x=319 and the role span at x=398, both past the right edge, so
                on a phone the badge was simply not on screen. The organisation
                name and the role can keep truncating — they are context. The
                badge is a warning, and a warning that disappears on exactly the
                screen where the mistake is easiest to make is not a warning.
                This project has already mixed real and test data once. */}
            {isTestOrg && (
              <span className="shrink-0">
                <Badge tone="outline">{t("badge_test")}</Badge>
              </span>
            )}
            {/* In a TEST org below sm:, this line yields to the badge instead
                of competing with it. Measured: with the badge taking its 43px,
                the truncated box was left 4px at 320 and rendered a single
                letter beside it — debris, not context. The order of priority
                is the one that was decided: the badge is the warning, the
                email / organisation / role are context, so the context is what
                goes when there is not room for both. In a non-test org nothing
                changes at any width, and from sm: up nothing changes at all
                (74px at 390, 286px at 768). */}
            <div
              className={`font-body min-w-0 truncate text-sm ${
                isTestOrg ? "hidden sm:block" : ""
              }`}
            >
              <span className="text-ink font-semibold">{userEmail}</span>
              {orgLabel && <span className="text-muted ml-2">· {orgLabel}</span>}
              {roleLabel && <span className="text-muted ml-2">· {roleLabel}</span>}
            </div>
          </div>
          {/* Moved here 2026-10-29 (item 165) -- this used to live on four
              individual pages (clients, suppliers, groups, contracts), none
              of which a pure Trainer role can even reach (no groups.read/
              clients.read/etc.). A role that can only ever open one or two
              screens still needs to be able to find this, so it belongs
              beside identity in the shell, not inside any one page -- the
              component's own original comment already named this move as
              the next step once more than one page used translations. */}
          <div className="flex shrink-0 items-center gap-3">
            {LOCALE_SWITCHER_ENABLED && <LocaleSwitcher />}
            <SignOutButton />
          </div>
        </header>
        <main className="flex-1 p-8">{children}</main>
      </div>
    </div>
  );
}

// Signed URL (already resolved server-side, private `avatars` bucket) or
// an initials placeholder — same fallback treatment as the /admin/users
// members list, duplicated locally rather than shared (this codebase's
// established convention for small presentational helpers).
function TopbarAvatar({ url, label }: { url: string | null; label: string }) {
  if (url) {
    // eslint-disable-next-line @next/next/no-img-element -- dynamic, short-lived signed URL, not a static asset next/image can usefully optimize
    return <img src={url} alt="" className="h-7 w-7 shrink-0 rounded-full object-cover" />;
  }
  const initials =
    label
      .split(/[\s@.]+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part[0]?.toUpperCase())
      .join("") || "?";
  return (
    <span
      aria-hidden="true"
      className="bg-ink/10 text-ink flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-[10px] font-bold"
    >
      {initials}
    </span>
  );
}

// Same shape as admin-users-client.tsx's own Badge — a second copy, not a
// shared component. One prior call site is nowhere near item 29's own
// stated threshold for extracting a small duplicated helper ("the next
// time a sixth call site needs it"); this is the second.
function Badge({
  children,
  tone = "neutral",
}: {
  children: React.ReactNode;
  tone?: "neutral" | "pink" | "outline";
}) {
  return (
    <span
      className={`font-body inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${
        tone === "pink"
          ? "bg-brand-pink/10 text-brand-pink"
          : tone === "outline"
            ? "text-muted border border-black/15"
            : "bg-ink/5 text-ink"
      }`}
    >
      {children}
    </span>
  );
}
