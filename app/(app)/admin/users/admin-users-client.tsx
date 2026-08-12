"use client";

import { useState, useTransition } from "react";
import {
  inviteUser,
  editRoles,
  disableAccess,
  enableAccess,
} from "./actions";

type Role = { id: string; key: string; display_name: string };
type Member = {
  userId: string;
  email: string;
  status: string;
  roleIds: string[];
  roleLabels: string[];
  firstName: string | null;
  lastName: string | null;
  // Signed URL (private `avatars` bucket), already resolved server-side —
  // null means no avatar set, not "failed to load".
  avatarUrl: string | null;
  // Purely a display label (202608120006) — never touches RLS, sorting,
  // or filtering. Distinguishes WS-D/C1/C2 test fixtures in the Members
  // list without hiding them (Mihai's call — still needed for ongoing
  // Phase 1 verification work).
  isTestAccount: boolean;
};

function displayName(member: Pick<Member, "firstName" | "lastName" | "email">) {
  const full = [member.firstName, member.lastName].filter(Boolean).join(" ");
  return full || member.email;
}

export function AdminUsersClient({
  orgId,
  roles,
  members,
}: {
  orgId: string;
  roles: Role[];
  members: Member[];
}) {
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  // Lifted out of the row/card so the desktop table and the mobile card
  // list (two separate DOM subtrees, shown/hidden purely via CSS — both
  // stay mounted) always agree on which member is being edited and what's
  // currently selected, instead of each holding its own local copy.
  const [editingUserId, setEditingUserId] = useState<string | null>(null);
  const [selectedRolesByUser, setSelectedRolesByUser] = useState<
    Record<string, string[]>
  >({});

  function startEditing(member: Member) {
    setSelectedRolesByUser((prev) => ({ ...prev, [member.userId]: member.roleIds }));
    setEditingUserId(member.userId);
  }

  function cancelEditing(member: Member) {
    setSelectedRolesByUser((prev) => ({ ...prev, [member.userId]: member.roleIds }));
    setEditingUserId(null);
  }

  function selectedRolesFor(member: Member) {
    return selectedRolesByUser[member.userId] ?? member.roleIds;
  }

  function saveEditing(member: Member) {
    const roleIds = selectedRolesFor(member);
    setError(null);
    startTransition(async () => {
      const result = await editRoles(orgId, member.userId, roleIds);
      if (!result.ok) setError(result.error);
    });
    setEditingUserId(null);
  }

  function toggleAccess(member: Member) {
    setError(null);
    startTransition(async () => {
      const result =
        member.status === "disabled"
          ? await enableAccess(orgId, member.userId)
          : await disableAccess(orgId, member.userId);
      if (!result.ok) setError(result.error);
    });
  }

  return (
    <div className="flex flex-col gap-6">
      {error && (
        <p className="font-body text-ink rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">
          {error}
        </p>
      )}

      <InviteForm
        orgId={orgId}
        roles={roles}
        isPending={isPending}
        onSubmit={(email, roleIds, firstName, lastName, phone) => {
          setError(null);
          startTransition(async () => {
            const result = await inviteUser(orgId, email, roleIds, firstName, lastName, phone);
            if (!result.ok) setError(result.error);
          });
        }}
      />

      <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
        <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
          Members ({members.length})
        </h2>

        {/* Desktop/tablet: unchanged table, shown at md and up. */}
        <table className="hidden w-full border-collapse text-sm md:table">
          <thead>
            <tr className="font-body text-muted border-b border-black/5 text-left text-xs font-bold tracking-wide uppercase">
              <th className="py-2 pr-2 font-bold">#</th>
              <th className="py-2 pr-4 font-bold">Email</th>
              <th className="py-2 pr-4 font-bold">Roles</th>
              <th className="py-2 pr-4 font-bold">Status</th>
              <th className="py-2 font-bold">Actions</th>
            </tr>
          </thead>
          <tbody>
            {members.map((member, index) => (
              <MemberTableRow
                key={member.userId}
                member={member}
                index={index}
                roles={roles}
                isPending={isPending}
                editing={editingUserId === member.userId}
                selectedRoles={selectedRolesFor(member)}
                onChangeSelectedRoles={(roleIds) =>
                  setSelectedRolesByUser((prev) => ({ ...prev, [member.userId]: roleIds }))
                }
                onStartEditing={() => startEditing(member)}
                onCancelEditing={() => cancelEditing(member)}
                onSave={() => saveEditing(member)}
                onToggleAccess={() => toggleAccess(member)}
              />
            ))}
          </tbody>
        </table>

        {/* Mobile: table -> cards below md, standard responsive pattern —
            a horizontal-scroll table isn't a real fix on a narrow screen. */}
        <div className="flex flex-col gap-3 md:hidden">
          {members.map((member, index) => (
            <MemberCard
              key={member.userId}
              member={member}
              index={index}
              roles={roles}
              isPending={isPending}
              editing={editingUserId === member.userId}
              selectedRoles={selectedRolesFor(member)}
              onChangeSelectedRoles={(roleIds) =>
                setSelectedRolesByUser((prev) => ({ ...prev, [member.userId]: roleIds }))
              }
              onStartEditing={() => startEditing(member)}
              onCancelEditing={() => cancelEditing(member)}
              onSave={() => saveEditing(member)}
              onToggleAccess={() => toggleAccess(member)}
            />
          ))}
        </div>
      </section>
    </div>
  );
}

function InviteForm({
  roles,
  isPending,
  onSubmit,
}: {
  orgId: string;
  roles: Role[];
  isPending: boolean;
  onSubmit: (
    email: string,
    roleIds: string[],
    firstName: string,
    lastName: string,
    phone: string,
  ) => void;
}) {
  const [email, setEmail] = useState("");
  const [selectedRoles, setSelectedRoles] = useState<string[]>([]);
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [phone, setPhone] = useState("");

  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        Invite user
      </h2>
      <div className="flex flex-col gap-3">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="email@wowlab.ro"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <div className="flex flex-col gap-3 md:flex-row">
          <input
            type="text"
            value={firstName}
            onChange={(e) => setFirstName(e.target.value)}
            placeholder="First name (optional)"
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:flex-1"
          />
          <input
            type="text"
            value={lastName}
            onChange={(e) => setLastName(e.target.value)}
            placeholder="Last name (optional)"
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:flex-1"
          />
          <input
            type="tel"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="Phone (optional)"
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 md:flex-1"
          />
        </div>
        <RoleCheckboxes
          roles={roles}
          selected={selectedRoles}
          onChange={setSelectedRoles}
        />
        <button
          type="button"
          disabled={isPending || !email || selectedRoles.length === 0}
          onClick={() => onSubmit(email, selectedRoles, firstName, lastName, phone)}
          className="font-body w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
        >
          Invite
        </button>
      </div>
    </section>
  );
}

type MemberRowProps = {
  member: Member;
  index: number;
  roles: Role[];
  isPending: boolean;
  editing: boolean;
  selectedRoles: string[];
  onChangeSelectedRoles: (roleIds: string[]) => void;
  onStartEditing: () => void;
  onCancelEditing: () => void;
  onSave: () => void;
  onToggleAccess: () => void;
};

function MemberTableRow({
  member,
  index,
  roles,
  isPending,
  editing,
  selectedRoles,
  onChangeSelectedRoles,
  onStartEditing,
  onCancelEditing,
  onSave,
  onToggleAccess,
}: MemberRowProps) {
  const name = displayName(member);
  const hasName = name !== member.email;

  return (
    <tr className="font-body text-ink border-b border-black/5 align-top last:border-0">
      <td className="text-muted py-3 pr-2">{index + 1}</td>
      <td className="py-3 pr-4">
        <div className="flex items-center gap-2">
          <Avatar url={member.avatarUrl} label={name} />
          <div>
            <div className="flex items-center gap-1.5">
              <span className="font-semibold">{name}</span>
              {member.isTestAccount && <Badge tone="outline">Test</Badge>}
            </div>
            {hasName && <div className="text-muted text-xs">{member.email}</div>}
          </div>
        </div>
      </td>
      <td className="py-3 pr-4">
        {editing ? (
          <div className="flex flex-col gap-2">
            <RoleCheckboxes
              roles={roles}
              selected={selectedRoles}
              onChange={onChangeSelectedRoles}
            />
            <div className="flex gap-2">
              <button
                type="button"
                disabled={isPending}
                onClick={onSave}
                className="rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-1 text-xs font-bold text-white uppercase"
              >
                Save
              </button>
              <button
                type="button"
                onClick={onCancelEditing}
                className="text-muted rounded-full border border-black/10 px-3 py-1 text-xs font-semibold uppercase"
              >
                Cancel
              </button>
            </div>
          </div>
        ) : (
          <div className="flex flex-wrap items-center gap-1.5">
            {member.roleLabels.length > 0 ? (
              member.roleLabels.map((label) => (
                <Badge key={label}>{label}</Badge>
              ))
            ) : (
              <span className="text-muted text-xs">(no roles)</span>
            )}
            <button
              type="button"
              onClick={onStartEditing}
              className="text-brand-pink text-xs font-semibold underline"
            >
              edit
            </button>
          </div>
        )}
      </td>
      <td className="py-3 pr-4">
        <Badge tone={member.status === "disabled" ? "pink" : "neutral"}>
          {member.status}
        </Badge>
      </td>
      <td className="py-3">
        <button
          type="button"
          disabled={isPending}
          onClick={onToggleAccess}
          className="text-muted rounded-full border border-black/10 px-3 py-1 text-xs font-semibold uppercase transition-colors hover:border-brand-pink hover:text-brand-pink disabled:opacity-50"
        >
          {member.status === "disabled" ? "Re-enable" : "Disable"}
        </button>
      </td>
    </tr>
  );
}

// Mobile card: same info as the table row (email / roles / status /
// actions), stacked — the standard "table -> cards" responsive pattern,
// not a horizontal-scroll wrapper around the table.
function MemberCard({
  member,
  index,
  roles,
  isPending,
  editing,
  selectedRoles,
  onChangeSelectedRoles,
  onStartEditing,
  onCancelEditing,
  onSave,
  onToggleAccess,
}: MemberRowProps) {
  const name = displayName(member);
  const hasName = name !== member.email;

  return (
    <div className="rounded-xl border border-black/5 p-4">
      <div className="flex items-center gap-2">
        <Avatar url={member.avatarUrl} label={name} />
        <div>
          <p className="font-body text-ink font-semibold break-all">
            <span className="text-muted font-normal">#{index + 1}</span> {name}
            {member.isTestAccount && (
              <span className="ml-1.5 inline-block align-middle">
                <Badge tone="outline">Test</Badge>
              </span>
            )}
          </p>
          {hasName && (
            <p className="font-body text-muted text-xs break-all">{member.email}</p>
          )}
        </div>
      </div>

      {editing ? (
        <div className="mt-3 flex flex-col gap-3">
          <RoleCheckboxes
            roles={roles}
            selected={selectedRoles}
            onChange={onChangeSelectedRoles}
          />
          <div className="flex gap-2">
            <button
              type="button"
              disabled={isPending}
              onClick={onSave}
              className="flex-1 rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-2 text-xs font-bold text-white uppercase disabled:opacity-50"
            >
              Save
            </button>
            <button
              type="button"
              onClick={onCancelEditing}
              className="text-muted flex-1 rounded-full border border-black/10 px-3 py-2 text-xs font-semibold uppercase"
            >
              Cancel
            </button>
          </div>
        </div>
      ) : (
        <>
          <div className="mt-2 flex flex-wrap gap-1.5">
            {member.roleLabels.length > 0 ? (
              member.roleLabels.map((label) => (
                <Badge key={label}>{label}</Badge>
              ))
            ) : (
              <span className="text-muted text-xs">(no roles)</span>
            )}
          </div>

          <div className="mt-2">
            <Badge tone={member.status === "disabled" ? "pink" : "neutral"}>
              {member.status}
            </Badge>
          </div>

          <div className="mt-3 flex gap-2">
            <button
              type="button"
              onClick={onStartEditing}
              className="text-brand-pink flex-1 rounded-full border border-black/10 px-3 py-2 text-xs font-semibold uppercase"
            >
              Edit roles
            </button>
            <button
              type="button"
              disabled={isPending}
              onClick={onToggleAccess}
              className="text-muted flex-1 rounded-full border border-black/10 px-3 py-2 text-xs font-semibold uppercase transition-colors hover:border-brand-pink hover:text-brand-pink disabled:opacity-50"
            >
              {member.status === "disabled" ? "Re-enable" : "Disable"}
            </button>
          </div>
        </>
      )}
    </div>
  );
}

// Signed URL (already resolved server-side) or an initials placeholder —
// never a broken-image icon for members who haven't set one.
function Avatar({ url, label }: { url: string | null; label: string }) {
  if (url) {
    // eslint-disable-next-line @next/next/no-img-element -- dynamic, short-lived signed URL, not a static asset next/image can usefully optimize
    return <img src={url} alt="" className="h-8 w-8 shrink-0 rounded-full object-cover" />;
  }
  const initials =
    label
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part[0]?.toUpperCase())
      .join("") || "?";
  return (
    <span
      aria-hidden="true"
      className="bg-ink/10 text-ink flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-xs font-bold"
    >
      {initials}
    </span>
  );
}

function RoleCheckboxes({
  roles,
  selected,
  onChange,
}: {
  roles: Role[];
  selected: string[];
  onChange: (roleIds: string[]) => void;
}) {
  return (
    <div className="flex flex-col gap-2 md:flex-row md:flex-wrap md:gap-3">
      {roles.map((role) => (
        <label
          key={role.id}
          className="font-body text-ink flex items-center gap-1.5 text-xs"
        >
          <input
            type="checkbox"
            checked={selected.includes(role.id)}
            onChange={(e) => {
              onChange(
                e.target.checked
                  ? [...selected, role.id]
                  : selected.filter((id) => id !== role.id),
              );
            }}
            className="accent-[#EC008C]"
          />
          {role.display_name}
        </label>
      ))}
    </div>
  );
}

function Badge({
  children,
  tone = "neutral",
}: {
  children: React.ReactNode;
  tone?: "neutral" | "pink" | "outline";
}) {
  return (
    <span
      className={`font-body inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${
        tone === "pink"
          ? "bg-brand-pink/10 text-brand-pink"
          : tone === "outline"
            ? "text-muted border border-black/15"
            : "bg-ink/5 text-ink"
      }`}
    >
      {children}
    </span>
  );
}
