"use client";

import { useState, useTransition } from "react";
import { useTranslations } from "@/lib/i18n";
import { groupsDict } from "../i18n";
import { updateGroup } from "../actions";

// EMPTY is what an unset field renders. It stays visible on purpose — in an
// internal record "nobody has filled this in" is information, and a row that
// disappears hides the fact that the field exists. Only its WEIGHT was wrong:
// in text-ink font-medium it looked exactly as substantial as a real value,
// and six of the thirteen rows on a live group are empty today, so the panel
// read as six filled fields that happened to say nothing.
const EMPTY = "—";

type ContractOption = { id: string; client_id: string; exit_number: string | null };
type ContactOption = { id: string; client_id: string; full_name: string };

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
  address,
  addressIsOverride,
  onSiteContactId,
  onSiteContactName,
  onSiteContactPhone,
  onSiteContactNotYetTrainerFacing,
  onSiteContactVisible,
  languageGroup,
  canManage,
  canWriteChildrenConfirmed,
  contractOptions,
  contactOptions,
}: {
  groupId: string;
  clientId: string;
  clientName: string | null;
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
  address: string | null;
  addressIsOverride: boolean;
  onSiteContactId: string | null;
  onSiteContactName: string | null;
  onSiteContactPhone: string | null;
  onSiteContactNotYetTrainerFacing: boolean;
  onSiteContactVisible: boolean;
  languageGroup: string | null;
  canManage: boolean;
  canWriteChildrenConfirmed: boolean;
  contractOptions: ContractOption[];
  contactOptions: ContactOption[];
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
        childrenConfirmed={childrenConfirmed}
        address={address}
        addressIsOverride={addressIsOverride}
        onSiteContactId={onSiteContactId}
        languageGroup={languageGroup}
        schedulePattern={schedulePattern}
        deliveryFormat={deliveryFormat}
        canManage={canManage}
        canWriteChildrenConfirmed={canWriteChildrenConfirmed}
        contractOptions={contractOptions}
        contactOptions={contactOptions}
        onCancel={() => setIsEditing(false)}
        onSaved={() => setIsEditing(false)}
      />
    );
  }

  return (
    <Section
      title={t("section_group_info_title")}
      action={
        (canManage || canWriteChildrenConfirmed) && (
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
      <Kv label={t("col_client")} value={clientName ?? t("client_hidden")} />
      <Kv label={t("col_module")} value={t(`module_${module}`)} />
      <Kv label={t("kv_delivery_format")} value={t(`format_${deliveryFormat}`)} />
      <Kv
        label={t("kv_language")}
        value={languageGroup ? t(`language_${languageGroup}`) : EMPTY}
      />
      {/* The sublabel is the honest half. For nine of the ten formats this
          field holds a date someone picked expecting a workshop to exist;
          saying what it is here costs nothing and is where it gets read. */}
      <Kv
        label={t("col_schedule")}
        value={schedulePattern || EMPTY}
        sublabel={
          deliveryFormat === "scoli_private_recurente"
            ? t("schedule_kv_hint_recurring")
            : t("schedule_kv_hint_oneoff")
        }
      />
      <Kv label={t("kv_age_range")} value={ageRange || EMPTY} />
      <Kv
        label={t("kv_address")}
        value={address || EMPTY}
        sublabel={address && addressIsOverride ? t("address_override_hint") : undefined}
      />
      <Kv
        label={t("kv_onsite_contact")}
        value={
          onSiteContactId === null
            ? EMPTY
            : !onSiteContactVisible
              ? t("client_hidden")
              : `${onSiteContactName}${onSiteContactPhone ? ` · ${onSiteContactPhone}` : ""}`
        }
        sublabel={
          onSiteContactVisible && onSiteContactNotYetTrainerFacing ? t("contact_not_trainer_facing_hint") : undefined
        }
      />
      <Kv
        label={t("kv_calendar")}
        value={calendarLink ? t("open_link") : EMPTY}
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

          Editable as of Anca's 2026-09-11 decision (canWriteChildren
          Confirmed, contracts.* holders only) -- this read-view Kv still
          renders for everyone who can see the group at all; only the
          edit form below is gated. children_billed stays read-only:
          WOWLAB_SAD_Domeniul_Operational_Groups_Sessions.md §4 flagged it
          as possibly needing masking for Operations ("de decis la
          construcție") -- that question was never actually answered,
          only deferred, and is recorded as its own open item
          (OPEN_ITEMS.md) rather than settled here by giving it a plain,
          unmasked edit form. Pending Anca, not forgotten. */}
      <Kv label={t("kv_children_confirmed")} value={childrenConfirmed?.toString() ?? EMPTY} />
      <Kv label={t("kv_children_billed")} value={childrenBilled?.toString() ?? EMPTY} />
      <Kv label={t("kv_notes")} value={notes || EMPTY} clamp />
    </Section>
  );
}

function GroupEditForm({
  groupId,
  clientId,
  notes,
  contractId,
  childrenConfirmed,
  address,
  addressIsOverride,
  onSiteContactId,
  languageGroup,
  schedulePattern,
  deliveryFormat,
  canManage,
  canWriteChildrenConfirmed,
  contractOptions,
  contactOptions,
  onCancel,
  onSaved,
}: {
  groupId: string;
  clientId: string;
  notes: string | null;
  contractId: string | null;
  childrenConfirmed: number | null;
  address: string | null;
  addressIsOverride: boolean;
  onSiteContactId: string | null;
  languageGroup: string | null;
  schedulePattern: string | null;
  deliveryFormat: string;
  canManage: boolean;
  canWriteChildrenConfirmed: boolean;
  contractOptions: ContractOption[];
  contactOptions: ContactOption[];
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
  const [childrenConfirmedValue, setChildrenConfirmedValue] = useState(
    childrenConfirmed?.toString() ?? "",
  );
  // Only the group's own override, never the resolved client-default value
  // this form was passed -- editing this field must not accidentally save
  // the client's address back onto the group as if it were an override.
  const [addressValue, setAddressValue] = useState(addressIsOverride ? (address ?? "") : "");
  const [onSiteContactIdValue, setOnSiteContactIdValue] = useState(onSiteContactId ?? "");
  const [languageGroupValue, setLanguageGroupValue] = useState(languageGroup ?? "");
  // Editable for the first time as of 2026-10-12 (item 119). The column has
  // always had an UPDATE grant; it simply had no control after creation, so a
  // mistyped schedule could only be corrected with direct SQL. Kept as free
  // text here rather than re-deriving the create form's day/time or date/time
  // widgets: the existing values are in two different shapes ("Tuesday 16:00"
  // and "2026-09-30 14:00") and a widget that could not represent one of them
  // would silently destroy it on the next save.
  const [schedulePatternValue, setSchedulePatternValue] = useState(schedulePattern ?? "");
  const contractsForClient = contractOptions.filter((c) => c.client_id === clientId);
  const contactsForClient = contactOptions.filter((c) => c.client_id === clientId);

  function doSave() {
    setError(null);
    startTransition(async () => {
      try {
        const result = await updateGroup(
          groupId,
          notesValue,
          contractIdValue,
          childrenConfirmedValue,
          addressValue,
          onSiteContactIdValue,
          languageGroupValue,
          schedulePatternValue,
        );
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
        {canManage && (
          <>
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
            <input
              type="text"
              value={addressValue}
              onChange={(e) => setAddressValue(e.target.value)}
              placeholder={t("address_override_placeholder")}
              className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2 md:col-span-2"
            />
            <div className="md:col-span-2">
              <p className="font-body text-ink text-xs font-bold">
                {deliveryFormat === "scoli_private_recurente"
                  ? t("schedule_recurring_label")
                  : t("schedule_oneoff_label")}
              </p>
              <p className="text-muted font-body mb-1 text-xs">
                {deliveryFormat === "scoli_private_recurente"
                  ? t("schedule_recurring_hint")
                  : t("schedule_kv_hint_oneoff")}
              </p>
              <input
                type="text"
                value={schedulePatternValue}
                onChange={(e) => setSchedulePatternValue(e.target.value)}
                placeholder={t("schedule_edit_placeholder")}
                className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 w-full rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
              />
            </div>
            <select
              value={languageGroupValue}
              onChange={(e) => setLanguageGroupValue(e.target.value)}
              className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
            >
              <option value="">{t("select_language")}</option>
              <option value="ro_en">{t("language_ro_en")}</option>
              <option value="fr_de_es">{t("language_fr_de_es")}</option>
            </select>
            <select
              value={onSiteContactIdValue}
              onChange={(e) => setOnSiteContactIdValue(e.target.value)}
              className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2 md:col-span-2"
            >
              <option value="">{t("select_onsite_contact")}</option>
              {contactsForClient.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.full_name}
                </option>
              ))}
            </select>
            {contactsForClient.length === 0 && (
              <p className="font-body text-muted -mt-2 text-xs md:col-span-2">
                {t("no_contacts_for_client_hint")}
              </p>
            )}
            <textarea
              value={notesValue}
              onChange={(e) => setNotesValue(e.target.value)}
              placeholder={t("notes_placeholder")}
              rows={2}
              className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2 md:col-span-2"
            />
          </>
        )}
        {canWriteChildrenConfirmed && (
          <input
            type="number"
            min="0"
            value={childrenConfirmedValue}
            onChange={(e) => setChildrenConfirmedValue(e.target.value)}
            placeholder={t("children_confirmed_placeholder")}
            className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
          />
        )}
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
    <section className="rounded-2xl border border-black/5 bg-white p-section shadow-sm">
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
  sublabel,
  clamp,
}: {
  label: string;
  value: string;
  href?: string;
  external?: boolean;
  sublabel?: string;
  /** Long free text (notes): clamp to three lines with a click to expand. */
  clamp?: boolean;
}) {
  const [expanded, setExpanded] = useState(false);
  const isEmpty = value === EMPTY;
  // Stacked under sm:, two columns from sm: up.
  //
  // Stacked, because at 320px the panel's usable width is 272px and
  // justify-between had nothing left to distribute: the first row rendered
  // "ClientȘcoala Franceză (Lycee Francais)" as one run-on word. The value is
  // what a trainer opened the sheet for, so it gets the full width rather than
  // being truncated.
  //
  // Two columns rather than justify-between from sm: up, changed 2026-10-13.
  // justify-between pinned the label hard left and the value hard right of a
  // ~1240px card, which put ~900px of nothing between a label and the thing it
  // names — you read the label, then travel. Worse, right-aligning values of
  // different lengths gave the value column a ragged LEFT edge, so there was
  // no consistent place to start reading. A fixed 200px label column with the
  // value left-aligned right after it fixes both, and the card stays wide.
  //
  // No border between rows any more either: thirteen hairlines in one card
  // read as stripes. py-snug (16px) of whitespace separates them, which is the
  // same job done by removing something instead of adding one.
  return (
    <div className="flex flex-col gap-0.5 py-snug text-sm">
      <div className="flex flex-col items-start gap-0.5 sm:flex-row sm:items-start sm:gap-tight">
        <span className="font-body text-muted sm:w-[200px] sm:shrink-0">{label}</span>
        {href ? (
          <a
            href={href}
            target={external ? "_blank" : undefined}
            rel={external ? "noreferrer" : undefined}
            title={value}
            className="text-brand-pink font-body min-w-0 font-medium hover:underline"
          >
            {value}
          </a>
        ) : (
          <span
            title={value}
            onClick={clamp && !isEmpty ? () => setExpanded((v) => !v) : undefined}
            className={`font-body min-w-0 ${
              isEmpty ? "text-muted font-normal" : "text-ink font-medium"
            } ${clamp && !isEmpty ? `cursor-pointer ${expanded ? "" : "line-clamp-3"}` : ""}`}
          >
            {value}
          </span>
        )}
      </div>
      {sublabel && (
        <span className="font-body text-muted text-xs sm:ml-[calc(200px+var(--spacing-tight))]">
          {sublabel}
        </span>
      )}
    </div>
  );
}
