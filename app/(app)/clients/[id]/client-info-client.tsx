"use client";

import { useState, useTransition } from "react";
import { useTranslations } from "@/lib/i18n";
import { clientsDict } from "../i18n";
import { updateClient } from "../actions";

const CLIENT_TYPE_KEYS: Record<string, string> = {
  private_school: "client_type_private_school",
  state_school: "client_type_state_school",
  corporate: "client_type_corporate",
  parent_b2c: "client_type_parent_b2c",
  special_project: "client_type_special_project",
};
const CLIENT_TYPES = Object.keys(CLIENT_TYPE_KEYS);

function looksLikeUrl(value: string) {
  return value.startsWith("http://") || value.startsWith("https://");
}

type Client = {
  id: string;
  name: string;
  client_type: string;
  business_line: string | null;
  external_crm_ref: string | null;
  notes: string | null;
  legal_name: string | null;
  cui: string | null;
};

export function ClientInfoClient({
  client,
  billedViaValue,
  canEditClient,
  canEditCrmLink,
}: {
  client: Client;
  billedViaValue: string;
  canEditClient: boolean;
  canEditCrmLink: boolean;
}) {
  const t = useTranslations(clientsDict);
  const [isEditing, setIsEditing] = useState(false);

  if (isEditing) {
    return (
      <ClientEditForm
        client={client}
        canEditCrmLink={canEditCrmLink}
        onCancel={() => setIsEditing(false)}
        onSaved={() => setIsEditing(false)}
      />
    );
  }

  return (
    <Section
      title={t("client_info_title")}
      action={
        canEditClient && (
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
      <Kv label={t("detail_business_line")} value={client.business_line || "—"} />
      <Kv
        label={t("detail_external_crm_ref")}
        value={client.external_crm_ref || "—"}
        mono={!(client.external_crm_ref && looksLikeUrl(client.external_crm_ref))}
        href={
          client.external_crm_ref && looksLikeUrl(client.external_crm_ref)
            ? client.external_crm_ref
            : undefined
        }
        external
      />
      <Kv label={t("detail_billed_via")} value={billedViaValue} />
      <Kv label={t("detail_legal_name")} value={client.legal_name || "—"} />
      <Kv label={t("detail_cui")} value={client.cui || "—"} />
      <Kv label={t("detail_notes")} value={client.notes || "—"} />
    </Section>
  );
}

function ClientEditForm({
  client,
  canEditCrmLink,
  onCancel,
  onSaved,
}: {
  client: Client;
  canEditCrmLink: boolean;
  onCancel: () => void;
  onSaved: () => void;
}) {
  const t = useTranslations(clientsDict);
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  const [name, setName] = useState(client.name);
  const [clientType, setClientType] = useState(client.client_type);
  const [businessLine, setBusinessLine] = useState(client.business_line ?? "");
  const [legalName, setLegalName] = useState(client.legal_name ?? "");
  const [cui, setCui] = useState(client.cui ?? "");
  const [notes, setNotes] = useState(client.notes ?? "");
  const [externalCrmRef, setExternalCrmRef] = useState(client.external_crm_ref ?? "");

  function doSave() {
    setError(null);
    startTransition(async () => {
      const result = await updateClient(
        client.id,
        name,
        clientType,
        businessLine,
        legalName,
        cui,
        notes,
        externalCrmRef,
      );
      if (!result.ok) setError(result.error);
      else onSaved();
    });
  }

  return (
    <Section title={t("edit_client_title")}>
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
          placeholder={t("edit_name_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        />
        <select
          value={clientType}
          onChange={(e) => setClientType(e.target.value)}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        >
          {CLIENT_TYPES.map((ty) => (
            <option key={ty} value={ty}>
              {t(CLIENT_TYPE_KEYS[ty])}
            </option>
          ))}
        </select>
        <input
          type="text"
          value={businessLine}
          onChange={(e) => setBusinessLine(e.target.value)}
          placeholder={t("business_line_placeholder")}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2"
        />
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
        <textarea
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
          placeholder={t("notes_placeholder")}
          rows={2}
          className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2 md:col-span-2"
        />

        {canEditCrmLink ? (
          <input
            type="text"
            value={externalCrmRef}
            onChange={(e) => setExternalCrmRef(e.target.value)}
            placeholder={t("external_crm_ref_placeholder")}
            className="font-body text-ink focus:border-brand-pink focus:ring-brand-pink/20 rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none focus:ring-2 md:col-span-2"
          />
        ) : (
          <div className="font-body text-muted rounded-lg border border-dashed border-gray-300 px-3 py-2.5 text-sm md:col-span-2">
            {t("crm_ref_locked_prefix")}
            <span className="text-ink">{client.external_crm_ref || "—"}</span>
            {t("crm_ref_locked_suffix")}
          </div>
        )}
      </div>

      <div className="mt-3 flex gap-2">
        <button
          type="button"
          disabled={isPending || !name.trim() || !clientType}
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
