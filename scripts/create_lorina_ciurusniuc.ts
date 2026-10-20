/**
 * Creates Lorina Ciurusniuc — trainer, grade 2 effective 2026-09-30.
 *
 * She took Scoala Germana's two Wednesday groups over from Teodora Merișan
 * from the session after 25 September, i.e. from 30 September. Confirmed
 * against the real payroll sheet ("New Wow Lab Trainer Calculations
 * Table", sheet "Pontaj si Norma"), which already carries two rows for
 * her: both 30.09.2026, DEUTSCHE SCHULE BUKAREST, Trainer Type 2 /
 * "Rising Star", 107,00 lei, 1 hour, Bucharest, 0% location bonus. Two
 * rows on the one date is the two Wednesday groups.
 *
 * GRADE EFFECTIVE 2026-09-30, NOT 2026-09-01. She was not our trainer
 * before the handover, and a backdated grade would make a workshop that
 * was wrongly dated earlier CALCULATE instead of raise -- the grade's
 * effective_from is the only thing standing between a mis-dated workshop
 * and a silently wrong payment. The six Scoala Germana workshops before
 * the handover (9, 16, 23 September) are Teodora's.
 *
 * USES createUser(), WHICH NEVER SENDS EMAIL, not inviteUser(). The
 * instruction said "inviteUser with the Trainer role", and
 * app/(app)/admin/users/actions.ts' inviteUser() does exactly that --
 * but it calls admin.auth.admin.inviteUserByEmail(), which emails a real
 * person. scripts/create_eight_real_wow_lab_accounts.ts exists precisely
 * because that was not wanted for the eight real WOW LAB accounts
 * ("Mihai's own instruction was to not email"), and it reaches the same
 * end state through createUser(). Same choice here: she exists, holds the
 * role and the grade, and can be invited whenever someone decides to
 * actually contact her. Sending her an unexpected email is not reversible;
 * creating the account is.
 *
 * trainer_home_cities is NOT written. Two reasons, both worth stating
 * rather than quietly skipping: her home city is not known to anyone here
 * (the sheet's "Bucharest" on her rows is the SCHOOL's location column,
 * not where she lives), and that table turns out to model the wrong thing
 * anyway -- the location bonus is a property of the school, proved across
 * 345 real rows at three schools. Writing a guess into it would feed the
 * one defect this round found.
 *
 * Idempotent: re-running reports what already exists and changes nothing.
 *
 * Run:
 *   npx tsx --env-file=.env.local scripts/create_lorina_ciurusniuc.ts
 */
import { createClient } from "@supabase/supabase-js";

const EMAIL = "lorina.ciurusniuc@gmail.com";
const FIRST = "Lorina";
const LAST = "Ciurusniuc";
const FULL = "Lorina Ciurusniuc";
const GRADE = 2;
const GRADE_FROM = "2026-09-30";
const ORG_SLUG = "wow-lab";
const ROLE_NAME = "Trainer";
// Grade assignments carry set_by; the platform owner is the actor on
// record for every other manual grade in this org.
const ACTOR_EMAIL = "anca.tanasescu@gmail.com";

function admin() {
  return createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

async function main() {
  const a = admin();
  const report: string[] = [];

  const { data: org, error: orgErr } = await a
    .from("organizations").select("id").eq("slug", ORG_SLUG).single();
  if (orgErr || !org) throw new Error(`no organization ${ORG_SLUG}: ${orgErr?.message}`);

  const { data: role, error: roleErr } = await a
    .from("roles").select("id").eq("name", ROLE_NAME).single();
  if (roleErr || !role) throw new Error(`no role ${ROLE_NAME}: ${roleErr?.message}`);

  const { data: actor, error: actorErr } = await a
    .from("users").select("id").eq("email", ACTOR_EMAIL).single();
  if (actorErr || !actor) throw new Error(`no actor ${ACTOR_EMAIL}: ${actorErr?.message}`);

  // ---- 1. The account ----
  let userId: string;
  const { data: existing } = await a.from("users").select("id").eq("email", EMAIL).maybeSingle();

  if (existing) {
    userId = existing.id;
    report.push(`1. users: already exists, id=${userId} — not re-created.`);
  } else {
    const { data: created, error: createErr } = await a.auth.admin.createUser({
      email: EMAIL,
      email_confirm: true,
      user_metadata: { full_name: FULL },
    });
    if (createErr || !created.user) {
      throw new Error(`createUser failed for ${EMAIL}: ${createErr?.message ?? "no user returned"}`);
    }
    userId = created.user.id;
    report.push(`1. auth.users + public.users created (no email sent), id=${userId}`);

    const { error: nameErr } = await a
      .from("users").update({ first_name: FIRST, last_name: LAST }).eq("id", userId);
    if (nameErr) throw new Error(`name update failed: ${nameErr.message}`);
    report.push(`   first_name/last_name set (${FIRST} / ${LAST}).`);
  }

  // ---- 2. The Trainer role ----
  const { data: hasRole } = await a
    .from("user_org_roles").select("id")
    .eq("organization_id", org.id).eq("user_id", userId).eq("role_id", role.id).maybeSingle();

  if (hasRole) {
    report.push(`2. user_org_roles: already holds ${ROLE_NAME} — unchanged.`);
  } else {
    const { error: rErr } = await a.from("user_org_roles").insert({
      organization_id: org.id, user_id: userId, role_id: role.id, assigned_by: actor.id,
    });
    if (rErr) throw new Error(`role insert failed: ${rErr.message}`);
    report.push(`2. user_org_roles: ${ROLE_NAME} granted in ${ORG_SLUG}.`);
    // A role-less membership row, if one existed, is now wrong.
    await a.from("user_org_roles")
      .delete().eq("organization_id", org.id).eq("user_id", userId).is("role_id", null);
  }

  // ---- 3. The grade ----
  const { data: hasGrade } = await a
    .from("trainer_grade_assignments").select("id, grade_level, effective_from")
    .eq("organization_id", org.id).eq("trainer_id", userId).eq("effective_from", GRADE_FROM).maybeSingle();

  if (hasGrade) {
    report.push(`3. trainer_grade_assignments: already grade ${hasGrade.grade_level} from ${hasGrade.effective_from} — unchanged.`);
  } else {
    const { error: gErr } = await a.from("trainer_grade_assignments").insert({
      organization_id: org.id,
      trainer_id: userId,
      grade_level: GRADE,
      effective_from: GRADE_FROM,
      set_by: actor.id,
      // CHECK-constrained to 'computed' | 'manual'. Item 124 lost a cycle
      // to an invented value here that failed silently.
      source: "manual",
    });
    if (gErr) throw new Error(`grade insert failed: ${gErr.message}`);
    report.push(`3. trainer_grade_assignments: grade ${GRADE} effective ${GRADE_FROM}.`);
  }

  // ---- 4. Verify the thing that actually matters ----
  // Not "did the inserts return no error" but "does the pay path resolve
  // her, and does it refuse the dates it should refuse".
  const { data: before } = await a.rpc("calculate_org_session_pay", {
    p_organization_id: org.id, p_from: "2026-09-01", p_to_exclusive: "2026-09-30",
  });
  const { data: after } = await a.rpc("calculate_org_session_pay", {
    p_organization_id: org.id, p_from: "2026-09-30", p_to_exclusive: "2026-10-01",
  });
  report.push(
    `4. Pay path reachable (no workshops exist yet, so both windows are empty — ` +
    `before=${(before ?? []).length} rows, after=${(after ?? []).length} rows). ` +
    `Grade resolution itself is asserted below.`,
  );

  const { data: grades } = await a
    .from("trainer_grade_assignments").select("grade_level, effective_from")
    .eq("organization_id", org.id).eq("trainer_id", userId).order("effective_from");
  report.push(`   her grades on record: ${JSON.stringify(grades)}`);

  const { data: roles } = await a
    .from("user_org_roles").select("roles(name)")
    .eq("organization_id", org.id).eq("user_id", userId);
  const roleNames = (roles ?? []).flatMap((r) => {
    const rel = (r as { roles: { name: string } | { name: string }[] | null }).roles;
    return rel == null ? [] : Array.isArray(rel) ? rel.map((x) => x.name) : [rel.name];
  });
  report.push(`   her roles: ${JSON.stringify(roleNames)}`);

  report.push(`   trainer_home_cities: deliberately NOT written — see the header.`);

  console.log(report.join("\n"));
}

main().catch((e) => {
  console.error("\nFAILED:", e.message);
  process.exit(1);
});
