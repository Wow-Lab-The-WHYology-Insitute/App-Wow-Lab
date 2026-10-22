import { createClient } from "@/lib/supabase/server";
import { MyWorkClient } from "./my-work-client";
import { AccessDenied } from "@/components/ui/access-denied";
import { PlanDecisionsNotice } from "./plan-decisions-notice";
import type { PlanDecision } from "./plan-decisions-notice";

// The trainer's own view of their own work. Every figure here is
// readable by a trainer today with no schema change -- confirmed
// against the live policies before this was built, not assumed:
//   sessions      -- mywork.* AND (principal = me OR secundar = me)
//   groups        -- mywork.* AND a session in that group with me on it
//   payroll_periods -- mywork.* is an explicit branch (202609150001)
//   trainer_grade_assignments -- trainer_id = app.current_user_id() is
//                    its FIRST branch, so a trainer reads their own grade
//                    without holding any finance capability
//
// The grade RATE is not read here and deliberately not shown: that lives
// in trainer_grade_rates, which is finance-gated, and the grade level is
// the fact the trainer owns. This page shows what someone is, not what
// they are owed.
//
// CONFIRMED vs DELIVERED -- the one real modelling choice on this page.
// "Sessions confirmed" counts the viewer's OWN trainer_*_confirmed_at
// timestamp, never sessions.status. Those two already disagree in every
// row that exists: both live sessions are status='planned' with both
// trainers' confirmations set. sessions.status also allows a separate
// value literally called 'confirmed', so three different things could be
// read as "confirmed" and two of them are Operations' scheduling state,
// not the trainer's assertion. Confirmation is the trainer's own act,
// it's what pay follows (202609150002: "Pay follows this timestamp, not
// attendance_count or status"), and it's the only one of the three with
// an unambiguous meaning today. What "delivered" should mean is an open
// question for Anca -- and not one this page should answer by picking a
// column quietly.

type SessionRow = {
  id: string;
  group_id: string;
  session_date: string;
  start_time: string | null;
  status: string;
  duration_minutes: number | null;
  organization_id: string;
  trainer_principal_id: string | null;
  trainer_secundar_id: string | null;
  trainer_principal_confirmed_at: string | null;
  trainer_secundar_confirmed_at: string | null;
};

type GroupRow = { id: string; client_id: string; module: string; schedule_pattern: string | null };
type ClientRow = { id: string; name: string };
type PayrollPeriodRow = { period: string; closed_at: string | null };
type GradeRow = { grade_level: number };

export default async function MyWorkPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return <AccessDenied reasonKey="access_denied_not_signed_in" />;
  }

  const today = new Date();
  const monthStart = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), 1))
    .toISOString()
    .slice(0, 10);
  const todayIso = today.toISOString().slice(0, 10);

  // Convention §16: the school year runs 1 September - 31 August, labelled by
  // its starting year. Needed because "Groups assigned" used to count every
  // group the viewer had EVER been on, with no date bound at all -- a figure
  // that only grows, and that would still name a school somebody left two
  // years ago.
  const schoolYearStart = `${today.getUTCMonth() >= 8 ? today.getUTCFullYear() : today.getUTCFullYear() - 1}-09-01`;

  // RLS already scopes a trainer to their own sessions -- but an owner or
  // Operations viewer would get the whole org back, and this page's
  // labels all say "your". The explicit slot filter is what makes the
  // page honest for them too, rather than showing org-wide totals under
  // a first-person heading.
  const { data: sessions } = await supabase
    .from("sessions")
    .select(
      "id, group_id, session_date, start_time, status, duration_minutes, organization_id, trainer_principal_id, trainer_secundar_id, trainer_principal_confirmed_at, trainer_secundar_confirmed_at",
    )
    .or(`trainer_principal_id.eq.${user.id},trainer_secundar_id.eq.${user.id}`)
    .returns<SessionRow[]>();

  const mine = sessions ?? [];

  // Which timestamp is "mine" depends on which slot I hold on that row --
  // never the co-trainer's, which is a different person's assertion.
  const myConfirmedAt = (s: SessionRow) =>
    s.trainer_principal_id === user.id
      ? s.trainer_principal_confirmed_at
      : s.trainer_secundar_confirmed_at;

  const inThisMonth = (s: SessionRow) => s.session_date >= monthStart;

  const confirmedThisMonth = mine.filter((s) => inThisMonth(s) && myConfirmedAt(s) !== null).length;

  // A workshop that has not happened is not work done. Both figures below
  // used to count the future, which was harmless while the schedule stopped
  // a week out and became a lie the moment 202610200009 generated the year:
  // October's hours already counted 28 October, days before it ran.
  const hasHappened = (s: SessionRow) => s.session_date <= todayIso;
  const notCancelled = (s: SessionRow) => s.status !== "cancelled";

  // Only sessions that have already happened can be "missing" a
  // confirmation in any meaningful sense -- a workshop next week isn't
  // late, so counting it would turn a normal state into a warning.
  const unconfirmed = mine.filter((s) => s.session_date <= todayIso && myConfirmedAt(s) === null);

  // Bounded to the current school year, and cancelled workshops do not make
  // a group "assigned" -- a group whose only session this year was called off
  // is not work.
  const groupsAssigned = new Set(
    mine.filter((s) => s.session_date >= schoolYearStart && notCancelled(s)).map((s) => s.group_id),
  ).size;

  // Taught, not scheduled: happened, and not cancelled.
  const monthSessions = mine.filter((s) => inThisMonth(s) && hasHappened(s) && notCancelled(s));
  const minutesThisMonth = monthSessions.reduce((sum, s) => sum + (s.duration_minutes ?? 0), 0);
  const sessionsMissingDuration = monthSessions.filter((s) => s.duration_minutes === null).length;

  // ---- What is next, READ-ONLY ---------------------------------------------
  // The page's whole content used to be four numbers, with no route forward:
  // a trainer landing here saw counters and no way to reach the workshop they
  // had just taught. This list is the route -- it names the next few and links
  // into the group page, where the confirm button already lives.
  //
  // DELIBERATELY NO CONFIRM BUTTON HERE. That would be this page's first write
  // path, first pending state and first error surface, four days before the
  // first trainer ever signs in. The button stays where it is tested.
  const upcomingSessions = mine
    .filter((s) => s.session_date >= todayIso && notCancelled(s))
    .sort((a, b) => a.session_date.localeCompare(b.session_date))
    .slice(0, 5);

  const upcomingGroupIds = [...new Set(upcomingSessions.map((s) => s.group_id))];
  const { data: upcomingGroups } = upcomingGroupIds.length > 0
    ? await supabase
        .from("groups")
        .select("id, client_id, module, schedule_pattern")
        .in("id", upcomingGroupIds)
        .returns<GroupRow[]>()
    : { data: [] as GroupRow[] };
  const groupById = new Map((upcomingGroups ?? []).map((g) => [g.id, g]));

  // A trainer CAN read the clients behind their own groups (checked live, not
  // assumed: Lorina's session returns exactly one client row). Where RLS
  // legitimately filters it, the name resolves to null and the row renders
  // without a school rather than with an id -- item 66.
  const upcomingClientIds = [
    ...new Set((upcomingGroups ?? []).map((g) => g.client_id)),
  ];
  const { data: upcomingClients } = upcomingClientIds.length > 0
    ? await supabase
        .from("clients")
        .select("id, name")
        .in("id", upcomingClientIds)
        .returns<ClientRow[]>()
    : { data: [] as ClientRow[] };
  const clientNameById = new Map((upcomingClients ?? []).map((c) => [c.id, c.name]));

  const upcoming = upcomingSessions.map((s) => {
    const group = groupById.get(s.group_id);
    return {
      id: s.id,
      groupId: s.group_id,
      sessionDate: s.session_date,
      startTime: s.start_time,
      durationMinutes: s.duration_minutes,
      schoolName: group ? (clientNameById.get(group.client_id) ?? null) : null,
      module: group?.module ?? null,
      confirmed: myConfirmedAt(s) !== null,
    };
  });

  // Close state for the current month. mywork.* is an explicit branch on
  // this table's SELECT policy, so a trainer genuinely can read whether
  // their own month is closed -- that's what makes the unconfirmed
  // warning actionable rather than just alarming.
  const { data: periods } = await supabase
    .from("payroll_periods")
    .select("period, closed_at")
    .eq("period", monthStart)
    .returns<PayrollPeriodRow[]>();
  const monthClosed = (periods ?? []).some((p) => p.closed_at !== null);

  // Own-row branch on trainer_grade_assignments; most recent assignment
  // effective on or before today.
  const { data: grades } = await supabase
    .from("trainer_grade_assignments")
    .select("grade_level")
    .eq("trainer_id", user.id)
    .lte("effective_from", todayIso)
    .order("effective_from", { ascending: false })
    .limit(1)
    .returns<GradeRow[]>();

  // ---- Decisions on my proposed experiments, not yet acknowledged ----
  // "Unseen" is a comparison between two columns on the same row
  // (decision_seen_at vs decided_at), and PostgREST cannot filter one column
  // against another -- so the decided rows come back and the comparison
  // happens here. The volume makes that free: a trainer has one row per
  // session they are on, and only decided ones are fetched at all.
  //
  // Why the comparison rather than `decision_seen_at is null`: a second
  // decision on the same row (changes requested, re-proposed, validated again)
  // must notify again even though the trainer had acknowledged the first one.
  const { data: decisionRows } = await supabase
    .from("session_lesson_plans")
    .select("id, session_id, lesson_plan_id, status, decision_note, decided_at, decision_seen_at")
    .eq("trainer_id", user.id)
    .not("decided_at", "is", null)
    .returns<{
      id: string;
      session_id: string;
      lesson_plan_id: string;
      status: string;
      decision_note: string | null;
      decided_at: string;
      decision_seen_at: string | null;
    }[]>();

  const unseen = (decisionRows ?? []).filter(
    (r) => r.decision_seen_at === null || r.decision_seen_at < r.decided_at,
  );

  const sessionById = new Map(mine.map((s) => [s.id, s]));
  const unseenPlanIds = [...new Set(unseen.map((r) => r.lesson_plan_id))];
  const { data: unseenPlans } = unseenPlanIds.length > 0
    ? await supabase
        .from("lesson_plans")
        .select("id, canonical_title")
        .in("id", unseenPlanIds)
        .returns<{ id: string; canonical_title: string }[]>()
    : { data: [] as { id: string; canonical_title: string }[] };
  const planTitleById = new Map((unseenPlans ?? []).map((p) => [p.id, p.canonical_title]));

  const decisions: PlanDecision[] = unseen.flatMap((r) => {
    const session = sessionById.get(r.session_id);
    // A decided row whose session this viewer cannot see is not renderable --
    // and should not be, since the link to the group would 404 for them.
    if (!session) return [];
    return [{
      rowId: r.id,
      groupId: session.group_id,
      sessionDate: session.session_date,
      planTitle: planTitleById.get(r.lesson_plan_id) ?? "—",
      status: r.status,
      note: r.decision_note,
    }];
  });

  return (
    <div className="flex flex-col gap-page">
      {/* gap-page / gap-section from the four-value scale in globals.css:
          40px between the page's major blocks, 24px between sibling cards in
          one grid. Both were a flat 24px/16px, which made the three stat cards
          and the grade card below them read as one undifferentiated run. */}
      <PlanDecisionsNotice decisions={decisions} />
      <MyWorkClient
      hasAnySessions={mine.length > 0}
      confirmedThisMonth={confirmedThisMonth}
      unconfirmedCount={unconfirmed.length}
      monthClosed={monthClosed}
      monthStart={monthStart}
      groupsAssigned={groupsAssigned}
      minutesThisMonth={minutesThisMonth}
      sessionsMissingDuration={sessionsMissingDuration}
      gradeLevel={grades?.[0]?.grade_level ?? null}
      upcoming={upcoming}
      todayIso={todayIso}
      />
    </div>
  );
}
