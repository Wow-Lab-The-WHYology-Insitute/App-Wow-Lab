"use client";

import { useTransition } from "react";
import { signOut } from "./actions";

export function SignOutButton() {
  const [isPending, startTransition] = useTransition();

  return (
    <button
      type="button"
      disabled={isPending}
      onClick={() => startTransition(() => signOut())}
      className="font-body text-muted rounded-full border border-black/10 px-4 py-1.5 text-xs font-semibold tracking-wide uppercase transition-colors hover:border-brand-pink hover:text-brand-pink disabled:opacity-50"
    >
      {isPending ? "Signing out…" : "Sign out"}
    </button>
  );
}
