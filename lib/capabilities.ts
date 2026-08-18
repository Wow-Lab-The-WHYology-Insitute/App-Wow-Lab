import { createClient } from "@/lib/supabase/server";

// Extracted from app/(app)/layout.tsx (originally written for its own
// nav-gating checks, then found to be the only capability check in the
// app with retry/error handling — every other page-level capability
// check, e.g. contracts/page.tsx's canManageContracts(), called
// supabase.rpc("has_capability", ...) directly with no error handling at
// all). Shared here so any capability-gated UI decision can use the same
// retry-once-then-fail-closed behavior, not just the sidebar.
//
// On error (not "capability denied", an actual failed request) this still
// defaults to false — hiding the gated UI stays the correct fail-closed
// default, since real access is enforced by RLS regardless of what the UI
// shows, so failing open here would just be misleading, not safer. What
// this adds over a bare rpc() call: one immediate retry (no backoff
// needed, this is a single fast RPC call) as cheap insurance against a
// one-off transient hiccup, and an explicit console.error if it fails
// twice — so a repeat of this isn't silent next time, it leaves a trace
// in Vercel's function logs keyed on the exact capability/org that
// failed.
export async function checkCapability(
  supabase: Awaited<ReturnType<typeof createClient>>,
  cap: string,
  org: string,
): Promise<boolean> {
  let lastError: unknown = null;
  for (let attempt = 1; attempt <= 2; attempt++) {
    const { data, error } = await supabase.rpc("has_capability", { cap, org });
    if (!error) return Boolean(data);
    lastError = error;
  }
  console.error(
    `has_capability RPC failed twice (cap=${cap}, org=${org}) — defaulting to false (RLS remains the real access control regardless of this UI gate):`,
    lastError,
  );
  return false;
}
