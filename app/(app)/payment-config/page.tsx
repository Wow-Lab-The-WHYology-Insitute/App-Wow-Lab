import { createClient } from "@/lib/supabase/server";
import { checkCapability } from "@/lib/capabilities";
import { displayName } from "@/lib/display-name";
import { PaymentConfigClient } from "./payment-config-client";
import { AccessDenied } from "@/components/ui/access-denied";

type MembershipRow = { organization_id: string };
type UserLookupRow = { id: string; full_name: string; first_name: string | null; last_name: string | null };

type GradeVersion = { id: string; effective_date: string; created_by: string; note: string | null };
type GradeRate = { version_id: string; grade_level: number; rate: number };
type LocationVersion = { id: string; effective_date: string; created_by: string; note: string | null };
type LocationRate = { version_id: string; location_tier: string; bonus_percent: number };
type LanguageVersion = { id: string; effective_date: string; created_by: string; note: string | null };
type LanguageRate = { version_id: string; language_group: string; bonus_percent: number };
type DurationVersion = { id: string; effective_date: string; created_by: string; note: string | null };
type DurationRate = { version_id: string; duration_minutes: number; delivery_context: string; multiplier: number };
type UpliftVersion = { id: string; effective_date: string; created_by: string; note: string | null };
type UpliftRate = { version_id: string; contract_type: string; uplift_percent: number };

// S1-scoped, same pattern as admin/users/page.tsx: find one org where this
// user holds the gating capability, rather than assuming a single global
// org. finance.operations.* OR finance.reporting.* -- the same shared
// predicate as the ten grid tables' own RLS (Sec12.8/Sec12.9), not
// suppliers' narrower single-key gate. This is the nav gate fix from
// Sec-the-bug-Laura-hit: the FINANȚE group itself must widen the same way
// (app/(app)/layout.tsx), or this page exists but Laura can't find it.
export default async function PaymentConfigPage() {
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
      (await checkCapability(supabase, "finance.reporting.*", m.organization_id))
    ) {
      orgId = m.organization_id;
      break;
    }
  }

  if (!orgId) {
    return <AccessDenied reasonKey="access_denied_no_finance_capability" />;
  }

  const [
    { data: gradeVersions },
    { data: gradeRates },
    { data: locationVersions },
    { data: locationRates },
    { data: languageVersions },
    { data: languageRates },
    { data: durationVersions },
    { data: durationRates },
    { data: upliftVersions },
    { data: upliftRates },
  ] = await Promise.all([
    supabase.from("trainer_grade_versions").select("id, effective_date, created_by, note").eq("organization_id", orgId).order("effective_date", { ascending: false }).returns<GradeVersion[]>(),
    supabase.from("trainer_grade_rates").select("version_id, grade_level, rate").eq("organization_id", orgId).returns<GradeRate[]>(),
    supabase.from("location_bonus_versions").select("id, effective_date, created_by, note").eq("organization_id", orgId).order("effective_date", { ascending: false }).returns<LocationVersion[]>(),
    supabase.from("location_bonus_rates").select("version_id, location_tier, bonus_percent").eq("organization_id", orgId).returns<LocationRate[]>(),
    supabase.from("language_bonus_versions").select("id, effective_date, created_by, note").eq("organization_id", orgId).order("effective_date", { ascending: false }).returns<LanguageVersion[]>(),
    supabase.from("language_bonus_rates").select("version_id, language_group, bonus_percent").eq("organization_id", orgId).returns<LanguageRate[]>(),
    supabase.from("duration_multiplier_versions").select("id, effective_date, created_by, note").eq("organization_id", orgId).order("effective_date", { ascending: false }).returns<DurationVersion[]>(),
    supabase.from("duration_multiplier_rates").select("version_id, duration_minutes, delivery_context, multiplier").eq("organization_id", orgId).returns<DurationRate[]>(),
    supabase.from("contract_type_uplift_versions").select("id, effective_date, created_by, note").eq("organization_id", orgId).order("effective_date", { ascending: false }).returns<UpliftVersion[]>(),
    supabase.from("contract_type_uplift_rates").select("version_id, contract_type, uplift_percent").eq("organization_id", orgId).returns<UpliftRate[]>(),
  ]);

  // WHICH VERSION IS IN FORCE, asked of the same function the pay engine
  // asks (202610260001). NOT versions[0].
  //
  // Those two agree only while nothing is dated ahead, and item 147 is the
  // instruction that ends that: the 111-150 scale gets seeded when a signed
  // contract writes it, WITH THAT CONTRACT'S OWN START DATE. A contract
  // starting in January puts the row in the table in December, and from that
  // moment `versions[0]` would label it "current" while payroll correctly
  // keeps paying the version in force until January -- Anca reading 150 at
  // grade 6 and hand-calculating on a number the application is not using.
  // DATABASE_CONVENTIONS.md §22.
  const { data: inForce } = await supabase.rpc("current_grid_versions", {
    p_organization_id: orgId,
  });
  const currentVersionIdByGrid = Object.fromEntries(
    ((inForce ?? []) as { grid: string; version_id: string | null }[]).map((r) => [r.grid, r.version_id]),
  ) as Record<string, string | null>;

  // Batched creator-name lookup across all five grids' versions -- same
  // two-lookup convention as contracts/page.tsx's clientIds/legalEntityIds,
  // one query instead of one per version.
  const creatorIds = [
    ...new Set(
      [
        ...(gradeVersions ?? []),
        ...(locationVersions ?? []),
        ...(languageVersions ?? []),
        ...(durationVersions ?? []),
        ...(upliftVersions ?? []),
      ].map((v) => v.created_by),
    ),
  ];
  const { data: creators } =
    creatorIds.length > 0
      ? await supabase.from("users").select("id, full_name, first_name, last_name").in("id", creatorIds).returns<UserLookupRow[]>()
      : { data: [] as UserLookupRow[] };
  const creatorNameById = new Map((creators ?? []).map((u) => [u.id, displayName(u)]));

  return (
    <div className="flex w-full flex-col gap-6">
      <PaymentConfigClient
        orgId={orgId}
        creatorNameById={Object.fromEntries(creatorNameById)}
        trainerGrades={{ versions: gradeVersions ?? [], rates: gradeRates ?? [], currentVersionId: currentVersionIdByGrid.trainer_grade ?? null }}
        locationBonuses={{ versions: locationVersions ?? [], rates: locationRates ?? [], currentVersionId: currentVersionIdByGrid.location_bonus ?? null }}
        languageBonuses={{ versions: languageVersions ?? [], rates: languageRates ?? [], currentVersionId: currentVersionIdByGrid.language_bonus ?? null }}
        durationMultipliers={{ versions: durationVersions ?? [], rates: durationRates ?? [], currentVersionId: currentVersionIdByGrid.duration_multiplier ?? null }}
        contractTypeUplifts={{ versions: upliftVersions ?? [], rates: upliftRates ?? [], currentVersionId: currentVersionIdByGrid.contract_type_uplift ?? null }}
      />
    </div>
  );
}
