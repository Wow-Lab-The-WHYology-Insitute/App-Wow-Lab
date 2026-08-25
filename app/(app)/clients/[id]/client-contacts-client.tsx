"use client";

import { useState, useTransition } from "react";
import { addClientContact, updateClientContact, deleteClientContact } from "../actions";

type Contact = {
  id: string;
  full_name: string;
  role_at_client: string | null;
  email: string | null;
  phone: string | null;
  is_billing_contact: boolean;
  is_primary: boolean;
  contact_purpose: string | null;
};

// Matches the client_contacts.contact_purpose check constraint
// (202608160002) exactly.
const CONTACT_PURPOSE_LABELS: Record<string, string> = {
  signing_authority: "Signing authority",
  trainer_facing: "Trainer-facing",
  finance_facing: "Finance-facing",
  general: "General",
};

// Anca's finding: a school's operational (trainer-facing) contact,
// signing contact, and billing contact are often 3 different people —
// trainer_facing gets its own badge tone so it reads at a glance, since
// this is the contact a future Trainer Dashboard would eventually surface.
export function ClientContactsClient({
  clientId,
  organizationId,
  contacts,
  canManage,
}: {
  clientId: string;
  organizationId: string;
  contacts: Contact[];
  canManage: boolean;
}) {
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [confirmingDeleteId, setConfirmingDeleteId] = useState<string | null>(null);

  function handleDelete(contactId: string) {
    setError(null);
    startTransition(async () => {
      const result = await deleteClientContact(contactId);
      if (!result.ok) setError(result.error);
      setConfirmingDeleteId(null);
    });
  }

  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="font-body text-muted text-xs font-bold tracking-wide uppercase">
          Contacts ({contacts.length})
        </h2>
        {canManage && (
          <button
            type="button"
            onClick={() => setIsFormOpen((open) => !open)}
            className="font-body w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-4 py-1.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity hover:opacity-90"
          >
            + New contact
          </button>
        )}
      </div>

      {error && (
        <p className="font-body text-ink mb-4 rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">
          {error}
        </p>
      )}

      {isFormOpen && (
        <div className="mb-4">
          <ContactForm
            isPending={isPending}
            submitLabel="Create contact"
            onSubmit={(fullName, role, email, phone, purpose, isPrimary, isBilling) => {
              setError(null);
              startTransition(async () => {
                const result = await addClientContact(
                  organizationId,
                  clientId,
                  fullName,
                  role,
                  email,
                  phone,
                  purpose,
                  isPrimary,
                  isBilling,
                );
                if (!result.ok) setError(result.error);
                else setIsFormOpen(false);
              });
            }}
          />
        </div>
      )}

      {contacts.length === 0 ? (
        <p className="font-body text-muted text-sm">No contacts on file.</p>
      ) : (
        <ul className="flex flex-col gap-3">
          {contacts.map((c) =>
            editingId === c.id ? (
              <li key={c.id} className="border-b border-black/5 pb-3 last:border-0 last:pb-0">
                <ContactForm
                  isPending={isPending}
                  submitLabel="Save"
                  initial={c}
                  onCancel={() => setEditingId(null)}
                  onSubmit={(fullName, role, email, phone, purpose, isPrimary, isBilling) => {
                    setError(null);
                    startTransition(async () => {
                      const result = await updateClientContact(
                        clientId,
                        c.id,
                        fullName,
                        role,
                        email,
                        phone,
                        purpose,
                        isPrimary,
                        isBilling,
                      );
                      if (!result.ok) setError(result.error);
                    });
                    setEditingId(null);
                  }}
                />
              </li>
            ) : (
              <li key={c.id} className="border-b border-black/5 pb-3 last:border-0 last:pb-0">
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <p className="font-body text-ink font-semibold">
                      {c.full_name}
                      {c.role_at_client && (
                        <span className="text-muted ml-2 font-normal">{c.role_at_client}</span>
                      )}
                    </p>
                    <p className="font-body text-muted mt-1 text-xs">
                      {c.email || "—"} {c.phone ? `· ${c.phone}` : ""}
                    </p>
                    <div className="mt-1.5 flex flex-wrap gap-1.5">
                      {c.contact_purpose && (
                        <Badge tone={c.contact_purpose === "trainer_facing" ? "pink" : "neutral"}>
                          {CONTACT_PURPOSE_LABELS[c.contact_purpose] ?? c.contact_purpose}
                        </Badge>
                      )}
                      {c.is_primary && <Badge>Primary</Badge>}
                      {c.is_billing_contact && <Badge>Billing contact</Badge>}
                    </div>
                  </div>
                  {canManage && (
                    <span className="flex shrink-0 gap-3">
                      <button
                        type="button"
                        onClick={() => setEditingId(c.id)}
                        className="text-brand-pink text-xs font-semibold underline"
                      >
                        edit
                      </button>
                      <button
                        type="button"
                        onClick={() => setConfirmingDeleteId(c.id)}
                        className="text-brand-pink text-xs font-semibold underline"
                      >
                        delete
                      </button>
                    </span>
                  )}
                </div>
                {confirmingDeleteId === c.id && (
                  <div className="font-body text-ink mt-2 rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">
                    <p>
                      Delete <strong>{c.full_name}</strong>? This cannot be undone.
                    </p>
                    <div className="mt-2 flex gap-2">
                      <button
                        type="button"
                        disabled={isPending}
                        onClick={() => handleDelete(c.id)}
                        className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-3 py-1 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
                      >
                        Confirm delete
                      </button>
                      <button
                        type="button"
                        onClick={() => setConfirmingDeleteId(null)}
                        className="text-muted rounded-full border border-black/10 px-3 py-1 text-xs font-semibold uppercase"
                      >
                        Cancel
                      </button>
                    </div>
                  </div>
                )}
              </li>
            ),
          )}
        </ul>
      )}
    </section>
  );
}

function ContactForm({
  initial,
  isPending,
  submitLabel,
  onSubmit,
  onCancel,
}: {
  initial?: Contact;
  isPending: boolean;
  submitLabel: string;
  onSubmit: (
    fullName: string,
    role: string,
    email: string,
    phone: string,
    purpose: string,
    isPrimary: boolean,
    isBilling: boolean,
  ) => void;
  onCancel?: () => void;
}) {
  const [fullName, setFullName] = useState(initial?.full_name ?? "");
  const [role, setRole] = useState(initial?.role_at_client ?? "");
  const [email, setEmail] = useState(initial?.email ?? "");
  const [phone, setPhone] = useState(initial?.phone ?? "");
  const [purpose, setPurpose] = useState(initial?.contact_purpose ?? "general");
  const [isPrimary, setIsPrimary] = useState(initial?.is_primary ?? false);
  const [isBilling, setIsBilling] = useState(initial?.is_billing_contact ?? false);

  return (
    <div className="rounded-xl border border-black/5 bg-ink/[0.02] p-4">
      <div className="grid grid-cols-1 gap-2.5 md:grid-cols-2">
        <input
          type="text"
          value={fullName}
          onChange={(e) => setFullName(e.target.value)}
          placeholder="Full name"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <input
          type="text"
          value={role}
          onChange={(e) => setRole(e.target.value)}
          placeholder="Role at client (optional)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="Email (optional)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <input
          type="tel"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          placeholder="Phone (optional)"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
        <select
          value={purpose}
          onChange={(e) => setPurpose(e.target.value)}
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        >
          {Object.entries(CONTACT_PURPOSE_LABELS).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
        <div className="flex items-center gap-4">
          <label className="font-body text-ink flex items-center gap-1.5 text-xs">
            <input
              type="checkbox"
              checked={isPrimary}
              onChange={(e) => setIsPrimary(e.target.checked)}
              className="accent-[#EC008C]"
            />
            Primary
          </label>
          <label className="font-body text-ink flex items-center gap-1.5 text-xs">
            <input
              type="checkbox"
              checked={isBilling}
              onChange={(e) => setIsBilling(e.target.checked)}
              className="accent-[#EC008C]"
            />
            Billing contact
          </label>
        </div>
      </div>
      <div className="mt-3 flex gap-2">
        <button
          type="button"
          disabled={isPending || !fullName.trim()}
          onClick={() => onSubmit(fullName, role, email, phone, purpose, isPrimary, isBilling)}
          className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-4 py-1.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
        >
          {submitLabel}
        </button>
        {onCancel && (
          <button
            type="button"
            onClick={onCancel}
            className="text-muted rounded-full border border-black/10 px-4 py-1.5 text-xs font-semibold uppercase"
          >
            Cancel
          </button>
        )}
      </div>
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
        tone === "pink" ? "bg-brand-pink/10 text-brand-pink" : "bg-ink/5 text-ink"
      }`}
    >
      {children}
    </span>
  );
}
