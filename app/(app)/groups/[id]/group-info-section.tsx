"use client";

import { useState, useTransition } from "react";
import { useTranslations } from "@/lib/i18n";
import { groupsDict } from "../i18n";
import { updateGroup } from "../actions";

type ContractOption = { id: string; client_id: string; exit_number: string | null };

// Same shape as clients/[id]/client-info-client.tsx and contracts/[id]/
// contract-detail-client.tsx: one component, local isEditing state, an
// Edit action gated by a capability, swapping to an inline edit form in
// the same file rather than a separate route/modal.
export function GroupInfoSection({
  groupId,
  clientId,
  clientName,
  module,
  deliveryFormat,
  schedulePattern,
  ageRange,
  calendarLink,
  childrenConfirmed,
  childrenBilled,
  notes,
  contractId,
  contractExitNumber,
  contractVisible,
  canManage,
  contractOptions,
}: {
  groupId: string;
  clientId: string;
  clientName: string;
  module: string;
  deliveryFormat: string;
  schedulePattern: string | null;
  ageRange: string | null;
  calendarLink: string | null;
  childrenConfirmed: number | null;
  childrenBilled: number | null;
  notes: string | null;
  contractId: string | null;
  contractExitNumber: string | null;
  contractVisible: boolean;
  canManage: boolean;
  contractOptions: ContractOption[];
}) {
  const t = useTranslations(groupsDict);
  const [isEditing, setIsEditing] = useState(false);

  if (isEditing) {
    return (
      <GroupEditForm
        groupId={groupId}
        clientId={clientId}
        notes={notes}
        contractId={contractId}
        contractOptions={contractOptions}
        onCancel={() => setIsEditing(false)}
        onSaved={() => setIsEditing(false)}
      />
    );
  }

  return (
    <Section
      title={t("section_group_info_title")}
      action={
        canManage && (
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
      <Kv label={t("col_client")} value={clientName} />
      <Kv label={t("col_module")} value={t(`module_${module}`)} />
      <Kv label={t("kv_delivery_format")} value={t(`format_${deliveryFormat}`)} />
      <Kv label={t("col_schedule")} value={schedulePattern || "—"} />
      <Kv label={t("kv_age_range")} value={ageRange || "—"} />
      <Kv
        label={t("kv_calendar")}
        value={calendarLink ? t("open_link") : "—"}
        href={calendarLink ?? undefined}
        external
      />
      <Kv
        label={t("kv_contract")}
        value={
          contractId === null
            ? t("contract_none")
            : !contractVisible
              ? t("contract_hidden")
              : contractExitNumber || t("contract_option_no_exit")
        }
        href={contractId !== null && contractVisible ? `/contracts/${contractId}` : undefined}
      />
      {/* "Confirmed" here is the CONTRACT-TIME headcount (per enrollment,
          at signup) — distinct from each session's own "Present" count
          on GroupDetailClient (who actually showed up to THAT occurrence).
          Two different attendance concepts already existed as separate
          fields -- only the labeling changed here, no new column.

          Deliberately read-only, along with children_billed below, even
          though notes and contract_id right above are now editable
          through the same section. WOWLAB_SAD_Domeniul_Operational_
          Groups_Sessions.md §4 flagged children_billed as possibly
          needing masking for Operations ("de decis la construcție") --
          that question was never actually answered, only deferred, and
          is recorded as its own open item (OPEN_ITEMS.md) rather than
          settled here by giving it a plain, unmasked edit form. Pending
          Anca, not forgotten. */}
      <Kv label={t("kv_children_confirmed")} value={childrenConfirmed?.toString() ?? "—"} />
      <Kv label={t("kv_children_billed")} value={childrenBilled?.toString() ?? "—"} />
      <Kv label={t("kv_notes")} value={notes || "—"} />
    </Section>
  );
}

function GroupEditForm({
  groupId,
  clientId,
  notes,
  contractId,
  contractOptions,
  onCancel,
  onSaved,
}: {
  groupId: string;
  clientId: string;
  notes: string | null;
  contractId: string | null;
  contractOptions: ContractOption[];
  onCancel: () => void;
  onSaved: () => void;
}) {
  const t = useTranslations(groupsDict);
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  const [notesValue, setNotesValue] = useState(notes ?? "");
  // Starts at the group's current contract, not empty and not the client's
  // first contract -- this is showing existing state, not defaulting a
  // fresh selection. The group's own client_id is fixed in this form (not
  // itself editable here), so unlike NewGroupForm there is no "client
  // changed under me" case to guard against.
  const [contractIdValue, setContractIdValue] = useState(contractId ?? "");
  const contractsForClient = contractOptions.filter((c) => c.client_id === clientId);

  function doSave() {
    setError(null);
    startTransition(async () => {
      try {
        const result = await updateGroup(groupId, notesValue, contractIdValue);
        if (!result.ok) setError(result.error);
        else onSaved();
      } catch {
        setError(t("network_error"));
      }
    });
  }

  return (
    <Section title={t("edit_group_title")}>
      {error && (
        <p className="font-body text-ink mb-3 rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">
          {error}
        </p>
      )}
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <select
          value={contractIdValue}
          onChange={(e) => setContractIdValue(e.target.value)}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2 md:col-span-2"
        >
          <option value="">{t("select_contract")}</option>
          {contractsForClient.map((c) => (
            <option key={c.id} value={c.id}>
              {c.exit_number || t("contract_option_no_exit")}
            </option>
          ))}
        </select>
        <textarea
          value={notesValue}
          onChange={(e) => setNotesValue(e.target.value)}
          placeholder={t("notes_placeholder")}
          rows={2}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2 md:col-span-2"
        />
      </div>

      <div className="mt-3 flex gap-2">
        <button
          type="button"
          disabled={isPending}
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
        <h2 className="font-body text-muted text-xs font-bold tracking-wide uppercase">
          {title}
        </h2>
        {action}
      </div>
      {children}
    </section>
  );
}

function Kv({
  label,
  value,
  href,
  external,
}: {
  label: string;
  value: string;
  href?: string;
  external?: boolean;
}) {
  return (
    <div className="flex items-baseline justify-between border-b border-black/5 py-2 text-sm last:border-0">
      <span className="font-body text-muted">{label}</span>
      {href ? (
        <a
          href={href}
          target={external ? "_blank" : undefined}
          rel={external ? "noreferrer" : undefined}
          className="text-brand-pink font-body font-medium hover:underline"
        >
          {value}
        </a>
      ) : (
        <span className="font-body text-ink font-medium">{value}</span>
      )}
    </div>
  );
}
