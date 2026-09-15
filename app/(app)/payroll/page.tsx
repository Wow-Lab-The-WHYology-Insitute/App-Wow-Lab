import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { PayrollClient } from "./payroll-client";
import { AccessDenied } from "@/components/ui/access-denied";

type MembershipRow = { organization_id: string };
type PeriodRow = { id: string; period: string; closed_by: string | null };
type UserLookupRow = { id: string; full_name: string; first_name: string | null; last_name: string | null };

// Same rule as groups/page.tsx's copy: never falls back to a raw email.
function displayName(u: Pick<UserLookupRow, "full_name" | "first_name" | "last_name">) {
  const full = [u.first_name, u.last_name].filter(Boolean).join(" ");
  if (full) return full;
  if (u.full_name && !u.full_name.includes("@")) return u.full_name;
  return "";
}

// finance.operations.* OR org.settings.manage -- matches
// closePayrollPeriod's own gate (app/(app)/payroll/actions.ts) exactly,
// so nobody who can act on this page is kept from reaching it, and
// nobody who can reach it is denied by the action underneath.
export default async function PayrollPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return <AccessDenied reasonKey="access_denied_not_signed_in" />;
  }

  const { data: memberships } = await supabase
    .from("user_org_roles")
    .select("organization_id")
    .eq("user_id", user.id)
    .returns<MembershipRow[]>();

  let orgId: string | null = null;
  for (const m of memberships ?? []) {
    if (
      (await checkCapability(supabase, "finance.operations.*", m.organization_id)) ||
      (await checkCapability(supabase, "org.settings.manage", m.organization_id))
    ) {
      orgId = m.organization_id;
      break;
    }
  }

  if (!orgId) {
    return <AccessDenied reasonKey="access_denied_no_payroll_capability" />;
  }

  const { data: periods } = await supabase
    .from("payroll_periods")
    .select("id, period, closed_by")
    .eq("organization_id", orgId)
    .order("period", { ascending: false })
    .returns<PeriodRow[]>();

  const closerIds = [...new Set((periods ?? []).map((p) => p.closed_by).filter((v): v is string => v !== null))];
  const { data: closers } =
    closerIds.length > 0
      ? await supabase.from("users").select("id, full_name, first_name, last_name").in("id", closerIds).returns<UserLookupRow[]>()
      : { data: [] as UserLookupRow[] };
  const closerNameById = new Map((closers ?? []).map((u) => [u.id, displayName(u) || "Unnamed"]));

  return (
    <div className="mx-auto flex w-full max-w-2xl flex-col gap-6">
      <PayrollClient
        orgId={orgId}
        periods={(periods ?? []).map((p) => ({
          id: p.id,
          period: p.period,
          closedByName: p.closed_by ? closerNameById.get(p.closed_by) ?? "Unknown" : "Unknown",
        }))}
      />
    </div>
  );
}
