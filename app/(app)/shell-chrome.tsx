"use client";

import { useState } from "react";
import Image from "next/image";
import { NavLink } from "./nav-link";
import { SignOutButton } from "./sign-out-button";

type NavItem = { href: string; label: string };

// Desktop (md: and up) is unchanged from S3: sidebar is a normal, always-
// visible flex child (sticky, in-flow, w-60). Below md, the same <aside>
// becomes a fixed off-canvas drawer (-translate-x-full by default) toggled
// by the hamburger button, with a backdrop that closes it — standard
// collapse pattern, nothing fancier. The drawer also closes itself when a
// NavLink is actually clicked (onNavigate), not just on backdrop tap.
export function ShellChrome({
  navItems,
  userEmail,
  roleLabel,
  children,
}: {
  navItems: NavItem[];
  userEmail: string;
  roleLabel: string;
  children: React.ReactNode;
}) {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className="flex min-h-screen">
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
        <nav className="flex flex-col gap-1 px-3">
          {navItems.map((item) => (
            <NavLink
              key={item.href}
              href={item.href}
              label={item.label}
              onNavigate={() => setIsOpen(false)}
            />
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
            <div className="font-body truncate text-sm">
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
