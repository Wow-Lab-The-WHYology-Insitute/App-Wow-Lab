"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

export function NavLink({
  href,
  label,
  onNavigate,
}: {
  href: string;
  label: string;
  onNavigate?: () => void;
}) {
  const pathname = usePathname();
  const active = pathname === href || pathname.startsWith(`${href}/`);

  return (
    <Link
      href={href}
      onClick={onNavigate}
      className={`font-body block rounded-lg px-3 py-2 text-sm font-medium transition-colors ${
        active
          ? "bg-brand-pink text-white"
          : "text-white/60 hover:bg-white/5 hover:text-white/90"
      }`}
    >
      {label}
    </Link>
  );
}
