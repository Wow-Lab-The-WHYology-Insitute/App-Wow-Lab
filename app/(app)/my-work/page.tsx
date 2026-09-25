import { createClient } from "@/lib/supabase/server";
import { MyWorkClient } from "./my-work-client";
import { AccessDenied } from "@/components/ui/access-denied";

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
  duration_minutes: number | null;
  organization_id: string;
  trainer_principal_id: string | null;
  trainer_secundar_id: string | null;
  trainer_principal_confirmed_at: string | null;
  trainer_secundar_confirmed_at: string | null;
};

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

  // RLS already scopes a trainer to their own sessions -- but an owner or
  // Operations viewer would get the whole org back, and this page's
  // labels all say "your". The explicit slot filter is what makes the
  // page honest for them too, rather than showing org-wide totals under
  // a first-person heading.
  const { data: sessions } = await supabase
    .from("sessions")
    .select(
      "id, group_id, session_date, duration_minutes, organization_id, trainer_principal_id, trainer_secundar_id, trainer_principal_confirmed_at, trainer_secundar_confirmed_at",
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

  // Only sessions that have already happened can be "missing" a
  // confirmation in any meaningful sense -- a workshop next week isn't
  // late, so counting it would turn a normal state into a warning.
  const unconfirmed = mine.filter((s) => s.session_date <= todayIso && myConfirmedAt(s) === null);

  const groupsAssigned = new Set(mine.map((s) => s.group_id)).size;

  const monthSessions = mine.filter(inThisMonth);
  const minutesThisMonth = monthSessions.reduce((sum, s) => sum + (s.duration_minutes ?? 0), 0);
  const sessionsMissingDuration = monthSessions.filter((s) => s.duration_minutes === null).length;

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

  return (
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
    />
  );
}
