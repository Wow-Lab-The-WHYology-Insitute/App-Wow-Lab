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
};

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
        onSubmit={(email, roleIds) => {
          setError(null);
          startTransition(async () => {
            const result = await inviteUser(orgId, email, roleIds);
            if (!result.ok) setError(result.error);
          });
        }}
      />

      <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
        <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
          Members
        </h2>
        <table className="w-full border-collapse text-sm">
          <thead>
            <tr className="font-body text-muted border-b border-black/5 text-left text-xs font-bold tracking-wide uppercase">
              <th className="py-2 pr-4 font-bold">Email</th>
              <th className="py-2 pr-4 font-bold">Roles</th>
              <th className="py-2 pr-4 font-bold">Status</th>
              <th className="py-2 font-bold">Actions</th>
            </tr>
          </thead>
          <tbody>
            {members.map((member) => (
              <MemberRow
                key={member.userId}
                orgId={orgId}
                member={member}
                roles={roles}
                isPending={isPending}
                onEditRoles={(roleIds) => {
                  setError(null);
                  startTransition(async () => {
                    const result = await editRoles(
                      orgId,
                      member.userId,
                      roleIds,
                    );
                    if (!result.ok) setError(result.error);
                  });
                }}
                onToggleAccess={() => {
                  setError(null);
                  startTransition(async () => {
                    const result =
                      member.status === "disabled"
                        ? await enableAccess(orgId, member.userId)
                        : await disableAccess(orgId, member.userId);
                    if (!result.ok) setError(result.error);
                  });
                }}
              />
            ))}
          </tbody>
        </table>
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
  onSubmit: (email: string, roleIds: string[]) => void;
}) {
  const [email, setEmail] = useState("");
  const [selectedRoles, setSelectedRoles] = useState<string[]>([]);

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
        <RoleCheckboxes
          roles={roles}
          selected={selectedRoles}
          onChange={setSelectedRoles}
        />
        <button
          type="button"
          disabled={isPending || !email || selectedRoles.length === 0}
          onClick={() => onSubmit(email, selectedRoles)}
          className="font-body w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
        >
          Invite
        </button>
      </div>
    </section>
  );
}

function MemberRow({
  member,
  roles,
  isPending,
  onEditRoles,
  onToggleAccess,
}: {
  orgId: string;
  member: Member;
  roles: Role[];
  isPending: boolean;
  onEditRoles: (roleIds: string[]) => void;
  onToggleAccess: () => void;
}) {
  const [editing, setEditing] = useState(false);
  const [selectedRoles, setSelectedRoles] = useState<string[]>(
    member.roleIds,
  );

  return (
    <tr className="font-body text-ink border-b border-black/5 align-top last:border-0">
      <td className="py-3 pr-4">{member.email}</td>
      <td className="py-3 pr-4">
        {editing ? (
          <div className="flex flex-col gap-2">
            <RoleCheckboxes
              roles={roles}
              selected={selectedRoles}
              onChange={setSelectedRoles}
            />
            <div className="flex gap-2">
              <button
                type="button"
                disabled={isPending}
                onClick={() => {
                  onEditRoles(selectedRoles);
                  setEditing(false);
                }}
                className="rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-1 text-xs font-bold text-white uppercase"
              >
                Save
              </button>
              <button
                type="button"
                onClick={() => {
                  setSelectedRoles(member.roleIds);
                  setEditing(false);
                }}
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
              onClick={() => setEditing(true)}
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
    <div className="flex flex-wrap gap-3">
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
  tone?: "neutral" | "pink";
}) {
  return (
    <span
      className={`font-body inline-flex rounded-full px-2.5 py-0.5 text-xs font-medium ${
        tone === "pink"
          ? "bg-brand-pink/10 text-brand-pink"
          : "bg-ink/5 text-ink"
      }`}
    >
      {children}
    </span>
  );
}
