/**
 * ONE-TIME VERIFICATION (item 96). Walks the three new pay-calculation
 * inputs through the real app on app.wowlab.ro, in wow-lab-test-b -- not
 * through SQL, per the standing rule this session keeps proving out.
 *
 *  1. addGroup with a language, updateGroup changing it plus an address
 *     that looks like Bucharest -- confirms both write paths land.
 *  2. addSession for a Bucharest-based trainer (location_tier='bucuresti',
 *     what a confirmed pre-fill would submit) and for a Cluj-based one
 *     (location_tier='', what "could not decide" leaves behind) --
 *     confirms both land, including the blank one landing as NULL, not
 *     coerced into a guess.
 *  3. The pre-fill's own two-part condition (home city == bucuresti AND
 *     the resolved address contains a Bucharest signal), evaluated here
 *     against the real fetched values -- NOT an observation of the
 *     browser executing the real React effect (no browser automation
 *     tool is available in this environment; see the report for this
 *     limitation stated plainly).
 *  4. The RSC payload for the group page actually carries the right
 *     trainerHomeCities/groupAddress data to the client -- proves
 *     page.tsx's data wiring, which is the wiring most likely to hide a
 *     real bug (wrong prop, empty object from a failed capability
 *     check), independent of point 3.
 *  5. All four resolvers the calculation will call succeed (not raise)
 *     for the resulting session, against test-b's own organization_id --
 *     using minimal fixture rates this script seeds and tears down
 *     itself, since wow-lab-test-b has no real pay-grid data of its own
 *     on purpose.
 *
 * Every fixture this script creates -- grids, home cities, group,
 * sessions -- is deleted in a finally block, in FK-safe order.
 *
 * Run: npx tsx --env-file=.env.local scripts/verify_pay_inputs_through_app.ts
 */
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { createServerClient } from "@supabase/ssr";
import { execSync } from "node:child_process";
import { writeFileSync, unlinkSync } from "node:fs";

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
const SITE_URL = "https://app.wowlab.ro";

const ACTION_IDS = {
  addGroup: "7f697b876f3e4fa536a1c1f7df2e15451b0edd8f9b",
  updateGroup: "7fa089c4c3c41b361cb12edb666ae2a3cba3fc8a15",
  addSession: "7f822372abe1d9258785ff62d822a4b93cb0404bcf",
};

function admin() {
  return createSupabaseClient(SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY!, { auth: { autoRefreshToken: false, persistSession: false } });
}

async function signIn(a: ReturnType<typeof admin>, email: string) {
  const { data: link, error } = await a.auth.admin.generateLink({ type: "magiclink", email });
  if (error || !link) throw new Error(`generateLink failed for ${email}: ${error?.message}`);
  const jar = new Map<string, string>();
  const authClient = createServerClient(SUPABASE_URL, ANON_KEY, {
    cookies: {
      getAll: () => [...jar.entries()].map(([name, value]) => ({ name, value })),
      setAll: (cs: { name: string; value: string }[]) => {
        for (const { name, value } of cs) {
          if (value) jar.set(name, value);
          else jar.delete(name);
        }
      },
    },
  });
  const { error: verifyErr } = await authClient.auth.verifyOtp({ token_hash: link.properties!.hashed_token!, type: "magiclink" });
  if (verifyErr) throw new Error(`verifyOtp failed for ${email}: ${verifyErr.message}`);
  return [...jar.entries()].map(([n, v]) => `${n}=${v}`).join("; ");
}

async function callAction(pagePath: string, actionName: keyof typeof ACTION_IDS, args: unknown[], cookieHeader: string) {
  const res = await fetch(`${SITE_URL}${pagePath}`, {
    method: "POST",
    headers: {
      Cookie: cookieHeader,
      "Next-Action": ACTION_IDS[actionName],
      Accept: "text/x-component",
      "Content-Type": "text/plain;charset=UTF-8",
    },
    body: JSON.stringify(args),
  });
  const text = await res.text();
  return { status: res.status, text };
}

async function main() {
  const a = admin();
  const report: string[] = [];
  const cleanup: (() => Promise<void>)[] = [];

  try {
    const { data: org } = await a.from("organizations").select("id").eq("name", "WOW LAB Test Org B").single();
    const orgId = org!.id;
    const { data: client } = await a.from("clients").select("id").eq("organization_id", orgId).limit(1).single();
    const { data: trainerB1 } = await a.from("users").select("id").eq("email", "maxdigitalro+trainerb1@gmail.com").single();
    const { data: trainerB2 } = await a.from("users").select("id").eq("email", "maxdigitalro+trainerb2@gmail.com").single();
    const { data: opsManager } = await a.from("users").select("id").eq("email", "test+ui-ops-manager-b@wowlab.dev").single();

    // ---- Fixtures: home cities ----
    const { error: hcErr } = await a.from("trainer_home_cities").insert([
      { organization_id: orgId, trainer_id: trainerB1!.id, city: "Bucuresti", set_by: opsManager!.id },
      { organization_id: orgId, trainer_id: trainerB2!.id, city: "Cluj", set_by: opsManager!.id },
    ]);
    if (hcErr) throw new Error(`seeding trainer_home_cities failed: ${hcErr.message}`);
    cleanup.push(async () => {
      await a.from("trainer_home_cities").delete().in("trainer_id", [trainerB1!.id, trainerB2!.id]);
    });

    // ---- Fixtures: minimal pay grids for test-b, dated to always resolve ----
    async function seedVersion(table: string, ratesTable: string, ratesRows: Record<string, unknown>[]) {
      const { data: version, error: vErr } = await a
        .from(table)
        .insert({ organization_id: orgId, effective_date: "2020-01-01", created_by: opsManager!.id, note: "item 96 verification fixture" })
        .select("id")
        .single();
      if (vErr || !version) throw new Error(`seeding ${table} failed: ${vErr?.message}`);
      cleanup.push(async () => {
        await a.from(ratesTable).delete().eq("version_id", version.id);
        await a.from(table).delete().eq("id", version.id);
      });
      const { error: rErr } = await a.from(ratesTable).insert(ratesRows.map((r) => ({ organization_id: orgId, version_id: version.id, ...r })));
      if (rErr) throw new Error(`seeding ${ratesTable} failed: ${rErr.message}`);
      return version.id;
    }

    await seedVersion("trainer_grade_versions", "trainer_grade_rates", [{ grade_level: 1, rate: 100 }]);
    await seedVersion("location_bonus_versions", "location_bonus_rates", [
      { location_tier: "bucuresti", bonus_percent: 0 },
      { location_tier: "imprejurimi", bonus_percent: 25 },
      { location_tier: "alte_orase", bonus_percent: 100 },
    ]);
    await seedVersion("language_bonus_versions", "language_bonus_rates", [
      { language_group: "ro_en", bonus_percent: 0 },
      { language_group: "fr_de_es", bonus_percent: 20 },
    ]);
    await seedVersion("duration_multiplier_versions", "duration_multiplier_rates", [
      { duration_minutes: 60, delivery_context: "standard", multiplier: 1.0 },
    ]);

    const { error: tgaErr } = await a.from("trainer_grade_assignments").insert({
      organization_id: orgId,
      trainer_id: trainerB1!.id,
      grade_level: 1,
      effective_from: "2020-01-01",
      set_by: opsManager!.id,
      source: "manual",
    });
    if (tgaErr) throw new Error(`seeding trainer_grade_assignments failed: ${tgaErr.message}`);
    cleanup.push(async () => {
      await a.from("trainer_grade_assignments").delete().eq("trainer_id", trainerB1!.id).eq("effective_from", "2020-01-01");
    });

    // ---- 1. addGroup with a language ----
    const opsCookie = await signIn(a, "test+ui-ops-manager-b@wowlab.dev");
    const rAddGroup = await callAction(
      "/groups",
      "addGroup",
      [orgId, client!.id, "green_energy", "parteneriate_companii", "", "active", "", "", "", "ro_en"],
      opsCookie,
    );
    const { data: createdGroup } = await a
      .from("groups")
      .select("id, language_group, address")
      .eq("organization_id", orgId)
      .eq("client_id", client!.id)
      .eq("module", "green_energy")
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (!createdGroup) {
      report.push(`1. addGroup: HTTP ${rAddGroup.status}, FAIL -- no group landed. Response: ${rAddGroup.text}`);
      throw new Error("addGroup did not create a group -- aborting rest of verification");
    }
    const groupId = createdGroup.id;
    cleanup.push(async () => {
      await a.from("sessions").delete().eq("group_id", groupId);
      await a.from("groups").delete().eq("id", groupId);
    });
    report.push(`1. addGroup with language='ro_en': HTTP ${rAddGroup.status}, DB shows language_group=${createdGroup.language_group} -> ${createdGroup.language_group === "ro_en" ? "PASS" : "FAIL"}`);

    // ---- 1b. updateGroup: change language, add a Bucharest-looking address ----
    const bucharestAddress = "Bulevardul Timisoara 26, sector 6, Bucuresti";
    const rUpdateGroup = await callAction(`/groups/${groupId}`, "updateGroup", [groupId, "", "", "", bucharestAddress, "", "fr_de_es"], opsCookie);
    const { data: updatedGroup } = await a.from("groups").select("language_group, address").eq("id", groupId).single();
    const groupUpdateLanded = updatedGroup?.language_group === "fr_de_es" && updatedGroup?.address === bucharestAddress;
    report.push(`1b. updateGroup changes language to 'fr_de_es' and sets a Bucharest address: HTTP ${rUpdateGroup.status}, DB shows language_group=${updatedGroup?.language_group}, address=${updatedGroup?.address} -> ${groupUpdateLanded ? "PASS" : "FAIL"}`);

    // ---- 2. addSession, Bucharest-based trainer, location_tier as a confirmed pre-fill would submit ----
    const today = new Date().toISOString().slice(0, 10);
    const rSession1 = await callAction(
      `/groups/${groupId}`,
      "addSession",
      [orgId, groupId, today, trainerB1!.id, "", "planned", "", "", "60", "", "", "bucuresti"],
      opsCookie,
    );
    const { data: session1 } = await a
      .from("sessions")
      .select("id, location_tier")
      .eq("group_id", groupId)
      .eq("trainer_principal_id", trainerB1!.id)
      .maybeSingle();
    report.push(`2. addSession, Bucharest-based trainer, location_tier='bucuresti': HTTP ${rSession1.status}, DB shows location_tier=${session1?.location_tier} -> ${session1?.location_tier === "bucuresti" ? "PASS" : "FAIL"}`);

    // ---- 2b. addSession, Cluj-based trainer, location_tier left blank (pre-fill could not decide) ----
    const rSession2 = await callAction(
      `/groups/${groupId}`,
      "addSession",
      [orgId, groupId, today, trainerB2!.id, "", "planned", "", "", "60", "", "", ""],
      opsCookie,
    );
    const { data: session2 } = await a
      .from("sessions")
      .select("id, location_tier")
      .eq("group_id", groupId)
      .eq("trainer_principal_id", trainerB2!.id)
      .maybeSingle();
    report.push(`2b. addSession, Cluj-based trainer, location_tier left blank: HTTP ${rSession2.status}, DB shows location_tier=${session2?.location_tier === null ? "NULL" : session2?.location_tier} -> ${session2?.location_tier === null ? "PASS (landed as NULL, not guessed)" : "FAIL"}`);

    // ---- 3. The pre-fill condition itself, evaluated against the real fetched values ----
    const { data: homeCities } = await a.from("trainer_home_cities").select("trainer_id, city").in("trainer_id", [trainerB1!.id, trainerB2!.id]);
    const cityByTrainer = Object.fromEntries((homeCities ?? []).map((r) => [r.trainer_id, r.city]));
    function wouldPrefillBucharest(trainerId: string, address: string | null) {
      const homeCity = cityByTrainer[trainerId]?.trim().toLowerCase();
      const addressLooksLikeBucharest = (address ?? "").toLowerCase().includes("bucur");
      return homeCity === "bucuresti" && addressLooksLikeBucharest;
    }
    const b1WouldPrefill = wouldPrefillBucharest(trainerB1!.id, updatedGroup?.address ?? null);
    const b2WouldPrefill = wouldPrefillBucharest(trainerB2!.id, updatedGroup?.address ?? null);
    report.push(`3. Pre-fill condition (home city + address), same expression as the form: trainerB1 (Bucuresti) -> ${b1WouldPrefill} -> ${b1WouldPrefill ? "PASS (would pre-fill)" : "FAIL"}; trainerB2 (Cluj) -> ${b2WouldPrefill} -> ${!b2WouldPrefill ? "PASS (would NOT pre-fill)" : "FAIL"}`);
    report.push(`   NOTE: this evaluates the same boolean expression the form uses, against real data -- it does not observe a real browser render NewSessionForm and execute the actual React effect. No browser-automation tool is available in this environment; see the written report for this limitation stated plainly.`);

    // ---- 4. RSC payload carries the right data to the client ----
    const pageRes = await fetch(`${SITE_URL}/groups/${groupId}`, { headers: { Cookie: opsCookie } });
    const pageHtml = await pageRes.text();
    const payloadHasTrainerB1City = pageHtml.includes(trainerB1!.id) && pageHtml.includes("Bucuresti");
    const payloadHasAddress = pageHtml.includes("Bulevardul Timisoara");
    report.push(`4. RSC payload for /groups/${groupId} carries trainerHomeCities (trainerB1 id + "Bucuresti") -> ${payloadHasTrainerB1City ? "PASS" : "FAIL"}; carries groupAddress ("Bulevardul Timisoara...") -> ${payloadHasAddress ? "PASS" : "FAIL"}`);

    // ---- 5. Every resolver the calculation will call, for this session's own org ----
    // No public.* wrapper exists for any resolve_* function (they live in
    // app schema, SECURITY INVOKER, never exposed through PostgREST) --
    // .rpc() from supabase-js can't reach them. Shells out to the same
    // `supabase db query --linked` this whole session already uses for
    // raw SQL, while these fixtures are still alive (before cleanup).
    const resolverSql = `
select 'resolve_trainer_grade' as check_name, (app.resolve_trainer_grade('${trainerB1!.id}', '${today}') = 1) as pass
union all
select 'resolve_trainer_grade_rate', (app.resolve_trainer_grade_rate('${orgId}', 1, '${today}') = 100)
union all
select 'resolve_duration_multiplier', (app.resolve_duration_multiplier('${orgId}', 60, 'parteneriate_companii', '${today}') = 1.0)
union all
select 'resolve_location_bonus', (app.resolve_location_bonus('${orgId}', 'bucuresti', '${today}') = 0)
union all
select 'resolve_language_bonus', (app.resolve_language_bonus('${orgId}', 'fr_de_es', '${today}') = 20);
`;
    const resolverSqlPath = "/tmp/verify_pay_inputs_resolver_check.sql";
    writeFileSync(resolverSqlPath, resolverSql);
    try {
      const resolverOutput = execSync(`npx supabase db query --linked --file ${resolverSqlPath}`, { encoding: "utf8" });
      report.push(`5. Resolver checks (raw SQL, since no public.* wrapper exposes these through PostgREST):\n${resolverOutput.split("\n").filter((l) => l.includes("check_name") || l.includes("pass")).join("\n")}`);
      const parsed = JSON.parse(resolverOutput.slice(resolverOutput.indexOf("{")));
      for (const row of parsed.rows ?? []) {
        report.push(`5. ${row.check_name} -> ${row.pass ? "PASS" : "FAIL"}`);
      }
    } catch (err) {
      report.push(`5. Resolver checks FAILED to run: ${err}`);
    } finally {
      unlinkSync(resolverSqlPath);
    }

    console.log("\n" + report.join("\n"));
    const anyFail = report.some((r) => r.includes("FAIL"));
    console.log(anyFail ? "\nAt least one check failed -- see FAIL lines above." : "\nAll checks passed.");
  } finally {
    for (const fn of cleanup.reverse()) {
      await fn();
    }
    console.log("\nFixtures cleaned up.");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
