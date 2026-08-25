"use client";

import { useState, useTransition } from "react";
import { updateContract } from "../actions";

// Matches the contracts.offer_structure check constraint (202608160002)
// exactly — same list as page.tsx's own display-only copy.
const OFFER_STRUCTURE_LABELS: Record<string, string> = {
  fixed_price_group_workshop: "Fixed price per group workshop",
  price_per_child_present: "Price per child present",
  price_per_child_enrolled: "Price per child enrolled",
  price_per_contract: "Price per contract",
};

const CONTRACT_TYPES = ["recurring_annual", "one_off_event", "framework"];

type Contract = {
  id: string;
  client_id: string;
  legal_entity_id: string;
  entry_number: string | null;
  exit_number: string | null;
  contract_type: string;
  status: string;
  period_start: string | null;
  period_end: string | null;
  renewal_of: string | null;
  billing_rule: string | null;
  estimated_value: number | null;
  previous_year_value: number | null;
  drive_ref: string | null;
  notes: string | null;
  offer_structure: string | null;
  ac_link: string | null;
};

type Option = { id: string; name: string };

// Statuses where a save is a correction, not routine editing — SAD's
// framing is "terms frozen," but freezing without a delete or revert path
// (there is neither, deliberately — Thread 1) would leave wrong records
// permanently wrong. The audit trail (fixed this same rollout, see
// row_history's actor_user_id work) is the actual control now: editing
// stays possible, but the caller has to explicitly acknowledge that the
// change lands in the audit log before it's saved.
const FROZEN_STATUSES = ["signed", "expired", "renewed"];

export function ContractDetailClient({
  contract,
  clientName,
  legalEntityName,
  financeVisible,
  canManage,
  clientOptions,
  legalEntityOptions,
}: {
  contract: Contract;
  clientName: string;
  legalEntityName: string;
  financeVisible: boolean;
  canManage: boolean;
  clientOptions: Option[];
  legalEntityOptions: Option[];
}) {
  const [isEditing, setIsEditing] = useState(false);

  if (isEditing) {
    return (
      <ContractEditForm
        contract={contract}
        financeVisible={financeVisible}
        clientOptions={clientOptions}
        legalEntityOptions={legalEntityOptions}
        onCancel={() => setIsEditing(false)}
        onSaved={() => setIsEditing(false)}
      />
    );
  }

  return (
    <Section
      title="Details"
      action={
        canManage && (
          <button
            type="button"
            onClick={() => setIsEditing(true)}
            className="font-body text-brand-pink text-xs font-semibold underline"
          >
            Edit
          </button>
        )
      }
    >
      <Kv
        label="Client"
        value={clientName}
        href={`/clients/${contract.client_id}`}
      />
      <Kv label="Legal entity" value={legalEntityName} />
      <Kv label="Entry number" value={contract.entry_number || "—"} />
      <Kv label="Exit number" value={contract.exit_number || "—"} />
      <Kv
        label="Period"
        value={`${contract.period_start ?? "—"} → ${contract.period_end ?? "—"}`}
      />
      <Kv
        label="Renewal of"
        value={contract.renewal_of ?? "—"}
        mono={Boolean(contract.renewal_of)}
      />
      <div className="flex items-baseline justify-between border-b border-black/5 py-2 text-sm last:border-0">
        <span className="font-body text-muted">Billing rule</span>
        <span className="text-ink font-body font-medium">
          <MaskedValue value={contract.billing_rule} financeVisible={financeVisible} />
        </span>
      </div>
      <Kv
        label="Drive archive"
        value={contract.drive_ref ? "Open link" : "—"}
        href={contract.drive_ref ?? undefined}
        external
      />
      <Kv
        label="Offer structure"
        value={
          contract.offer_structure
            ? (OFFER_STRUCTURE_LABELS[contract.offer_structure] ?? contract.offer_structure)
            : "—"
        }
      />
      <Kv
        label="AC link"
        value={contract.ac_link ? "Open link" : "—"}
        href={contract.ac_link ?? undefined}
        external
      />
      <Kv label="Notes" value={contract.notes || "—"} />
    </Section>
  );
}

function ContractEditForm({
  contract,
  financeVisible,
  clientOptions,
  legalEntityOptions,
  onCancel,
  onSaved,
}: {
  contract: Contract;
  financeVisible: boolean;
  clientOptions: Option[];
  legalEntityOptions: Option[];
  onCancel: () => void;
  onSaved: () => void;
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [needsConfirm, setNeedsConfirm] = useState(false);

  const [clientId, setClientId] = useState(contract.client_id);
  const [legalEntityId, setLegalEntityId] = useState(contract.legal_entity_id);
  const [contractType, setContractType] = useState(contract.contract_type);
  const [periodStart, setPeriodStart] = useState(contract.period_start ?? "");
  const [periodEnd, setPeriodEnd] = useState(contract.period_end ?? "");
  const [entryNumber, setEntryNumber] = useState(contract.entry_number ?? "");
  const [exitNumber, setExitNumber] = useState(contract.exit_number ?? "");
  const [driveRef, setDriveRef] = useState(contract.drive_ref ?? "");
  const [notes, setNotes] = useState(contract.notes ?? "");
  const [offerStructure, setOfferStructure] = useState(contract.offer_structure ?? "");
  const [acLink, setAcLink] = useState(contract.ac_link ?? "");

  // Only meaningful, only ever sent, when financeVisible — for anyone
  // else these three inputs never render at all (see below), so there is
  // no local state here that could accidentally be submitted for a caller
  // who was never shown a real value to edit in the first place.
  const [billingRule, setBillingRule] = useState(contract.billing_rule ?? "");
  const [estimatedValue, setEstimatedValue] = useState(
    contract.estimated_value != null ? String(contract.estimated_value) : "",
  );
  const [previousYearValue, setPreviousYearValue] = useState(
    contract.previous_year_value != null ? String(contract.previous_year_value) : "",
  );

  const isFrozen = FROZEN_STATUSES.includes(contract.status);

  function doSave() {
    setError(null);
    startTransition(async () => {
      const result = await updateContract(
        contract.id,
        clientId,
        legalEntityId,
        contractType,
        periodStart,
        periodEnd,
        entryNumber,
        exitNumber,
        driveRef,
        notes,
        offerStructure,
        acLink,
        financeVisible ? { billingRule, estimatedValue, previousYearValue } : null,
      );
      if (!result.ok) setError(result.error);
      else onSaved();
    });
  }

  function handleSaveClick() {
    if (isFrozen && !needsConfirm) {
      setNeedsConfirm(true);
      return;
    }
    doSave();
  }

  return (
    <Section title="Edit contract">
      {error && (
        <p className="font-body text-ink mb-3 rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">
          {error}
        </p>
      )}
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
        <select
          value={clientId}
          onChange={(e) => setClientId(e.target.value)}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        >
          {clientOptions.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
        <select
          value={legalEntityId}
          onChange={(e) => setLegalEntityId(e.target.value)}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        >
          {legalEntityOptions.map((e) => (
            <option key={e.id} value={e.id}>
              {e.name}
            </option>
          ))}
        </select>
        <select
          value={contractType}
          onChange={(e) => setContractType(e.target.value)}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        >
          {CONTRACT_TYPES.map((ty) => (
            <option key={ty} value={ty}>
              {ty}
            </option>
          ))}
        </select>
        <select
          value={offerStructure}
          onChange={(e) => setOfferStructure(e.target.value)}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        >
          <option value="">Offer structure (optional)</option>
          {Object.entries(OFFER_STRUCTURE_LABELS).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          Period start
          <input
            type="date"
            value={periodStart}
            onChange={(e) => setPeriodStart(e.target.value)}
            className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
          />
        </label>
        <label className="font-body text-muted flex flex-col gap-1 text-xs">
          Period end
          <input
            type="date"
            value={periodEnd}
            onChange={(e) => setPeriodEnd(e.target.value)}
            className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
          />
        </label>
        <input
          type="text"
          value={entryNumber}
          onChange={(e) => setEntryNumber(e.target.value)}
          placeholder="Entry number (optional)"
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        />
        <input
          type="text"
          value={exitNumber}
          onChange={(e) => setExitNumber(e.target.value)}
          placeholder="Exit number (optional)"
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        />
        <input
          type="url"
          value={driveRef}
          onChange={(e) => setDriveRef(e.target.value)}
          placeholder="Drive archive link (optional)"
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        />
        <input
          type="url"
          value={acLink}
          onChange={(e) => setAcLink(e.target.value)}
          placeholder="AC link (optional)"
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        />
        <textarea
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder="Notes (optional)"
          rows={2}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2 md:col-span-2"
        />

        {financeVisible ? (
          <>
            <input
              type="text"
              value={billingRule}
              onChange={(e) => setBillingRule(e.target.value)}
              placeholder="Billing rule"
              className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2 md:col-span-2"
            />
            <input
              type="number"
              step="0.01"
              value={estimatedValue}
              onChange={(e) => setEstimatedValue(e.target.value)}
              placeholder="Estimated value"
              className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
            />
            <input
              type="number"
              step="0.01"
              value={previousYearValue}
              onChange={(e) => setPreviousYearValue(e.target.value)}
              placeholder="Previous year value"
              className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
            />
          </>
        ) : (
          <div className="font-body text-muted flex items-center gap-1.5 rounded-lg border border-dashed border-gray-300 px-3 py-2.5 text-sm md:col-span-2">
            <span className="font-mono tracking-wide">••••• 🔒</span>
            Finance only — billing rule and values aren&apos;t shown to your role, so this form
            can&apos;t edit them either.
          </div>
        )}
      </div>

      {needsConfirm && (
        <p className="font-body text-ink mt-3 rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">
          This contract is <strong>{contract.status}</strong>. Saving will be recorded in the
          audit log. Continue?
        </p>
      )}

      <div className="mt-3 flex gap-2">
        <button
          type="button"
          disabled={isPending || !clientId || !legalEntityId}
          onClick={handleSaveClick}
          className="font-body rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-4 py-1.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
        >
          {needsConfirm ? "Confirm & save" : "Save"}
        </button>
        <button
          type="button"
          onClick={onCancel}
          className="text-muted rounded-full border border-black/10 px-4 py-1.5 text-xs font-semibold uppercase"
        >
          Cancel
        </button>
      </div>
    </Section>
  );
}

function MaskedValue({
  value,
  financeVisible,
}: {
  value: string | null;
  financeVisible: boolean;
}) {
  if (value !== null) return <span>{value}</span>;
  if (financeVisible) return <span className="text-muted">Not set</span>;
  return <span className="text-muted font-mono tracking-wide">••••• 🔒</span>;
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
  mono,
  href,
  external,
}: {
  label: string;
  value: string;
  mono?: boolean;
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
        <span className={`text-ink ${mono ? "font-mono text-xs" : "font-body font-medium"}`}>
          {value}
        </span>
      )}
    </div>
  );
}
