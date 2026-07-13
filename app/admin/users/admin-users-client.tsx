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
    <div className="flex flex-col gap-8">
      {error && (
        <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-700">
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

      <table className="w-full border-collapse text-sm">
        <thead>
          <tr className="border-b text-left">
            <th className="py-2 pr-4">Email</th>
            <th className="py-2 pr-4">Roles</th>
            <th className="py-2 pr-4">Status</th>
            <th className="py-2">Actions</th>
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
    <section className="rounded border p-4">
      <h2 className="mb-3 font-medium">Invite user</h2>
      <div className="flex flex-col gap-3">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="email@wowlab.ro"
          className="rounded border border-gray-300 px-3 py-2"
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
          className="w-fit rounded bg-black px-3 py-2 text-white disabled:opacity-50"
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
    <tr className="border-b align-top">
      <td className="py-2 pr-4">{member.email}</td>
      <td className="py-2 pr-4">
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
                className="rounded bg-black px-2 py-1 text-xs text-white"
              >
                Save
              </button>
              <button
                type="button"
                onClick={() => {
                  setSelectedRoles(member.roleIds);
                  setEditing(false);
                }}
                className="rounded border px-2 py-1 text-xs"
              >
                Cancel
              </button>
            </div>
          </div>
        ) : (
          <div className="flex items-center gap-2">
            <span>{member.roleLabels.join(", ") || "(no roles)"}</span>
            <button
              type="button"
              onClick={() => setEditing(true)}
              className="text-xs text-blue-600 underline"
            >
              edit
            </button>
          </div>
        )}
      </td>
      <td className="py-2 pr-4">{member.status}</td>
      <td className="py-2">
        <button
          type="button"
          disabled={isPending}
          onClick={onToggleAccess}
          className="rounded border px-2 py-1 text-xs disabled:opacity-50"
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
        <label key={role.id} className="flex items-center gap-1 text-xs">
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
          />
          {role.display_name}
        </label>
      ))}
    </div>
  );
}
