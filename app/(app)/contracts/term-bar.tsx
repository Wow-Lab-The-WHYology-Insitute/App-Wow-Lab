// School contracts run 01.09 -> 30.06 — renewal pressure is the single
// most decision-relevant fact on this list, so it gets encoded visually
// rather than left as two plain date columns. Pure presentational
// component: the caller (contracts-client.tsx) decides WHETHER to render
// a bar at all (a one_off_event contract with period_start === period_end
// renders a single date and skips this entirely) — TermBar itself always
// assumes a real range.

function daysBetween(from: Date, to: Date) {
  return Math.round((to.getTime() - from.getTime()) / 86_400_000);
}

function monthsBetween(from: Date, to: Date) {
  return Math.max(
    0,
    (to.getFullYear() - from.getFullYear()) * 12 + (to.getMonth() - from.getMonth()),
  );
}

// Exported so anything else that needs to know "is this contract overdue /
// in the renewal-critical window" (the /contracts overdue banner) uses the
// exact same math TermBar renders, rather than a second copy that could
// silently drift from what the bar on screen actually shows.
export function getTermStatus(
  periodStart: string,
  periodEnd: string,
  status: string,
  now: Date,
) {
  const start = new Date(periodStart);
  const end = new Date(periodEnd);

  const totalMs = end.getTime() - start.getTime();
  const elapsedMs = now.getTime() - start.getTime();
  const fraction = totalMs > 0 ? Math.min(1, Math.max(0, elapsedMs / totalMs)) : 1;

  const isPast = end.getTime() < now.getTime();
  const isFuture = start.getTime() > now.getTime();
  const isRenewalCritical = !isPast && !isFuture && fraction >= 0.85 && status === "signed";

  return { isPast, isFuture, fraction, isRenewalCritical };
}

export function TermBar({
  periodStart,
  periodEnd,
  status,
  now,
  labels,
}: {
  periodStart: string;
  periodEnd: string;
  status: string;
  /** Passed in rather than computed with `new Date()` internally, so the component stays deterministic for tests/screenshots. */
  now: Date;
  labels: {
    endsIn: (days: number) => string;
    endedAgo: (months: number) => string;
    startsIn: (days: number) => string;
  };
}) {
  const start = new Date(periodStart);
  const end = new Date(periodEnd);
  const { isPast, isFuture, fraction, isRenewalCritical } = getTermStatus(
    periodStart,
    periodEnd,
    status,
    now,
  );

  let label: string;
  if (isPast) {
    label = labels.endedAgo(monthsBetween(end, now));
  } else if (isFuture) {
    label = labels.startsIn(daysBetween(now, start));
  } else {
    label = labels.endsIn(daysBetween(now, end));
  }

  return (
    <div className="flex flex-col gap-1">
      <div
        role="img"
        aria-label={label}
        className="h-[3px] w-full overflow-hidden rounded-[2px]"
        style={{ backgroundColor: "rgba(36,26,34,0.08)" }}
      >
        <div
          className="h-full rounded-[2px]"
          style={{
            width: `${fraction * 100}%`,
            background: isPast
              ? "#8b8088"
              : "linear-gradient(90deg, #EC008C 0%, #FAA21B 100%)",
          }}
        />
      </div>
      <span
        className={`text-[11px] ${isRenewalCritical ? "font-medium" : "text-muted"}`}
        style={isRenewalCritical ? { color: "#FAA21B" } : undefined}
      >
        {label}
      </span>
    </div>
  );
}
