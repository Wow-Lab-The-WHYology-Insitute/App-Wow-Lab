"use client";

import { useState } from "react";
import Image from "next/image";
import { NavLink } from "./nav-link";
import { SignOutButton } from "./sign-out-button";

type NavItem = { href: string; label: string };
type NavGroup = { label?: string; items: NavItem[] };

// Desktop (md: and up) is unchanged from S3: sidebar is a normal, always-
// visible flex child (sticky, in-flow, w-60). Below md, the same <aside>
// becomes a fixed off-canvas drawer (-translate-x-full by default) toggled
// by the hamburger button, with a backdrop that closes it — standard
// collapse pattern, nothing fancier. The drawer also closes itself when a
// NavLink is actually clicked (onNavigate), not just on backdrop tap.
export function ShellChrome({
  navGroups,
  userEmail,
  roleLabel,
  avatarUrl,
  children,
}: {
  navGroups: NavGroup[];
  userEmail: string;
  roleLabel: string;
  avatarUrl: string | null;
  children: React.ReactNode;
}) {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className="flex min-h-dvh">
      <aside
        className={`bg-sidebar fixed inset-y-0 left-0 z-40 flex w-60 flex-col transition-transform duration-200 ease-in-out md:sticky md:top-0 md:h-screen md:flex-shrink-0 md:translate-x-0 md:transition-none ${
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
            <div key={group.label ?? i} className="flex flex-col gap-1">
              {group.label && (
                <span className="font-body px-3 text-[10px] font-bold tracking-wide text-white/30 uppercase">
                  {group.label}
                </span>
              )}
              {group.items.map((item) => (
                <NavLink
                  key={item.href}
                  href={item.href}
                  label={item.label}
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
          aria-label="Close menu"
          onClick={() => setIsOpen(false)}
          className="fixed inset-0 z-30 bg-black/40 md:hidden"
        />
      )}

      <div className="bg-ink/[0.03] flex min-w-0 flex-1 flex-col">
        <header className="flex items-center justify-between gap-3 border-b border-black/5 bg-white px-4 py-4 md:px-8">
          <div className="flex min-w-0 items-center gap-3">
            <button
              type="button"
              aria-label="Open menu"
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
            <div className="font-body min-w-0 truncate text-sm">
              <span className="text-ink font-semibold">{userEmail}</span>
              {roleLabel && <span className="text-muted ml-2">· {roleLabel}</span>}
            </div>
          </div>
          <SignOutButton />
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
