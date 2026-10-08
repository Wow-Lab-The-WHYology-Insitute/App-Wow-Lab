"use client";

import { useState, useTransition } from "react";
import { useTranslations } from "@/lib/i18n";
import { suppliersDict } from "../i18n";
import { updateSupplier } from "../actions";

const STATUS_KEYS: Record<string, string> = {
  active: "status_active",
  inactive: "status_inactive",
};
const STATUSES = Object.keys(STATUS_KEYS);

type Supplier = {
  id: string;
  name: string;
  legal_name: string | null;
  cui: string | null;
  service_type: string | null;
  status: string;
  notes: string | null;
  user_id: string | null;
};

export type MemberOption = { id: string; name: string };

export function SupplierInfoClient({
  supplier,
  canEdit,
  linkedUserName,
  memberOptions,
}: {
  supplier: Supplier;
  canEdit: boolean;
  // Resolved by the server component, not looked up out of memberOptions:
  // the read view renders for viewers who get no memberOptions at all,
  // including the supplier themselves via the self-read branch.
  linkedUserName: string | null;
  memberOptions: MemberOption[];
}) {
  const t = useTranslations(suppliersDict);
  const [isEditing, setIsEditing] = useState(false);

  if (isEditing) {
    return (
      <SupplierEditForm
        supplier={supplier}
        memberOptions={memberOptions}
        onCancel={() => setIsEditing(false)}
        onSaved={() => setIsEditing(false)}
      />
    );
  }

  return (
    <Section
      title={t("supplier_info_title")}
      action={
        canEdit && (
          <button
            type="button"
            onClick={() => setIsEditing(true)}
            className="font-body text-brand-pink text-xs font-semibold underline"
          >
            {t("edit")}
          </button>
        )
      }
    >
      <Kv label={t("detail_legal_name")} value={supplier.legal_name || "—"} />
      <Kv label={t("detail_cui")} value={supplier.cui || "—"} />
      <Kv label={t("detail_service_type")} value={supplier.service_type || "—"} />
      {/* Three distinct states, deliberately not collapsed into two: no
          link at all ("—"), a link whose person this viewer may not see
          (linked_user_hidden), and a resolved name. The middle case is
          real -- users' own SELECT RLS is narrower than this page's gate. */}
      <Kv
        label={t("detail_linked_user")}
        value={
          !supplier.user_id ? "—" : (linkedUserName ?? t("linked_user_hidden"))
        }
      />
      <Kv label={t("detail_notes")} value={supplier.notes || "—"} />
    </Section>
  );
}

function SupplierEditForm({
  supplier,
  memberOptions,
  onCancel,
  onSaved,
}: {
  supplier: Supplier;
  memberOptions: MemberOption[];
  onCancel: () => void;
  onSaved: () => void;
}) {
  const t = useTranslations(suppliersDict);
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  const [name, setName] = useState(supplier.name);
  const [legalName, setLegalName] = useState(supplier.legal_name ?? "");
  const [cui, setCui] = useState(supplier.cui ?? "");
  const [serviceType, setServiceType] = useState(supplier.service_type ?? "");
  const [status, setStatus] = useState(supplier.status);
  const [notes, setNotes] = useState(supplier.notes ?? "");
  const [userId, setUserId] = useState(supplier.user_id ?? "");

  function doSave() {
    setError(null);
    startTransition(async () => {
      try {
        const result = await updateSupplier(supplier.id, name, legalName, cui, serviceType, status, notes, userId);
        if (!result.ok) setError(result.error);
        else onSaved();
      } catch {
        setError(t("network_error"));
      }
    });
  }

  return (
    <Section title={t("edit_supplier_title")}>
      {error && (
        <p className="font-body text-ink mb-3 rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">
          {error}
        </p>
      )}
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder={t("name_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        />
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        >
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {t(STATUS_KEYS[s])}
            </option>
          ))}
        </select>
        <input
          type="text"
          value={legalName}
          onChange={(e) => setLegalName(e.target.value)}
          placeholder={t("legal_name_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        />
        <input
          type="text"
          value={cui}
          onChange={(e) => setCui(e.target.value)}
          placeholder={t("cui_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        />
        <input
          type="text"
          value={serviceType}
          onChange={(e) => setServiceType(e.target.value)}
          placeholder={t("service_type_edit_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        />
        {/* Linked person. The empty option is not a placeholder -- it is the
            correct, selectable value for the 17 suppliers that are companies
            and for undoing a wrong link, which is the whole reason this
            field is here (OPEN_ITEMS item 105: the five seeded links were
            matched by eye). If the current link points at someone this
            viewer cannot resolve, the saved value is still preserved as an
            option so saving the form does not silently clear it. */}
        <select
          value={userId}
          onChange={(e) => setUserId(e.target.value)}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        >
          <option value="">{t("linked_user_none")}</option>
          {userId && !memberOptions.some((m) => m.id === userId) && (
            <option value={userId}>{t("linked_user_hidden")}</option>
          )}
          {memberOptions.map((m) => (
            <option key={m.id} value={m.id}>
              {m.name}
            </option>
          ))}
        </select>
        <textarea
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder={t("notes_placeholder")}
          rows={2}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2 md:col-span-2"
        />
      </div>

      <div className="mt-3 flex gap-2">
        <button
          type="button"
          disabled={isPending || !name.trim()}
          onClick={doSave}
          className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-4 py-1.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
        >
          {t("save")}
        </button>
        <button
          type="button"
          onClick={onCancel}
          className="text-muted rounded-full border border-black/10 px-4 py-1.5 text-xs font-semibold uppercase"
        >
          {t("cancel")}
        </button>
      </div>
    </Section>
  );
}

function Section({
  title,
  action,
  children,
}: {
  title: string;
  action?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="font-body text-muted text-xs font-bold tracking-wide uppercase">{title}</h2>
        {action}
      </div>
      {children}
    </section>
  );
}

function Kv({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-baseline justify-between border-b border-black/5 py-2 text-sm last:border-0">
      <span className="font-body text-muted">{label}</span>
      <span className="text-ink font-body font-medium">{value}</span>
    </div>
  );
}
