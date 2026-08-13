"use client";

import { useState } from "react";

type OrgRow = { id: string; name: string; slug: string };
type MembershipView = {
  orgLabel: string;
  roleLabel: string;
  capabilities: string[];
};
type SpotCheckResult = { cap: string; org: string; allowed: boolean };

// Tier 3 (S3 restructure): everything that used to render unconditionally
// on /whoami, now collapsed by default behind the same gradient-pill
// disclosure mechanism already established for "+ New client"/"+ New
// contract" (clients-client.tsx / contracts-client.tsx) — same boolean
// state + same button styling, adapted label since this reveals rather
// than creates. The underlying data-fetching in page.tsx is untouched;
// this component only changes how it's presented.
export function TechnicalDetails({
  email,
  userId,
  isPlatformOwner,
  status,
  visibleOrgs,
  memberships,
  spotCheckResults,
}: {
  email: string;
  userId: string;
  isPlatformOwner: boolean;
  status: string;
  visibleOrgs: OrgRow[];
  memberships: MembershipView[];
  spotCheckResults: SpotCheckResult[];
}) {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className="flex flex-col gap-4">
      <button
        type="button"
        onClick={() => setIsOpen((open) => !open)}
        className="font-body w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity hover:opacity-90"
      >
        {isOpen ? "Hide technical details" : "Show technical details"}
      </button>

      {isOpen && (
        <div className="flex flex-col gap-6">
          <Section title="Signed in as">
            <Kv label="Email" value={email} />
            <Kv label="User ID" value={userId} mono />
            <Kv label="Platform owner" value={String(isPlatformOwner)} />
            <Kv label="Status" value={status} />
          </Section>

          <Section title="Organizations visible via RLS">
            {visibleOrgs.length === 0 ? (
              <Empty>None</Empty>
            ) : (
              <ul className="flex flex-col gap-2">
                {visibleOrgs.map((o) => (
                  <li key={o.id} className="font-body text-ink text-sm">
                    <span className="font-semibold">{o.slug}</span> — {o.name}
                  </li>
                ))}
              </ul>
            )}
          </Section>

          <Section title="Your role(s) per organization">
            {memberships.length === 0 ? (
              <Empty>No user_org_roles row for this user</Empty>
            ) : (
              <ul className="flex flex-wrap gap-2">
                {memberships.map((m, i) => (
                  <li key={i}>
                    <Badge>
                      {m.orgLabel}: {m.roleLabel}
                    </Badge>
                  </li>
                ))}
              </ul>
            )}
          </Section>

          <Section title="Resolved capabilities per organization">
            <div className="flex flex-col gap-4">
              {memberships.map((m, i) => (
                <div key={i}>
                  <p className="font-body text-ink mb-2 text-sm font-semibold">
                    {m.orgLabel}
                  </p>
                  {m.capabilities.length > 0 ? (
                    <ul className="flex flex-wrap gap-1.5">
                      {m.capabilities.map((key) => (
                        <li key={key}>
                          <Badge mono>{key}</Badge>
                        </li>
                      ))}
                    </ul>
                  ) : (
                    <Empty>None</Empty>
                  )}
                </div>
              ))}
            </div>
          </Section>

          <Section title="Spot-check via app.has_capability() RPC">
            <ul className="flex flex-col gap-1.5">
              {spotCheckResults.map((r, i) => (
                <li
                  key={i}
                  className="font-body text-ink flex items-center gap-2 text-sm"
                >
                  <span className="font-mono text-xs">
                    has_capability(&apos;{r.cap}&apos;, {r.org})
                  </span>
                  <Badge tone={r.allowed ? "neutral" : "pink"}>
                    {String(r.allowed)}
                  </Badge>
                </li>
              ))}
            </ul>
          </Section>
        </div>
      )}
    </div>
  );
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        {title}
      </h2>
      {children}
    </section>
  );
}

function Kv({
  label,
  value,
  mono,
}: {
  label: string;
  value: string;
  mono?: boolean;
}) {
  return (
    <div className="flex items-baseline justify-between border-b border-black/5 py-2 text-sm last:border-0">
      <span className="font-body text-muted">{label}</span>
      <span className={`text-ink ${mono ? "font-mono text-xs" : "font-body font-medium"}`}>
        {value}
      </span>
    </div>
  );
}

function Badge({
  children,
  mono,
  tone = "neutral",
}: {
  children: React.ReactNode;
  mono?: boolean;
  tone?: "neutral" | "pink";
}) {
  return (
    <span
      className={`inline-flex rounded-full px-3 py-1 text-xs font-medium ${mono ? "font-mono" : "font-body"} ${
        tone === "pink"
          ? "bg-brand-pink/10 text-brand-pink"
          : "bg-ink/5 text-ink"
      }`}
    >
      {children}
    </span>
  );
}

function Empty({ children }: { children: React.ReactNode }) {
  return <p className="font-body text-muted text-sm">{children}</p>;
}
