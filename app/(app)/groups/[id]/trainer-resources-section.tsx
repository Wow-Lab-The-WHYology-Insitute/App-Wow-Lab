"use client";

import { useTranslations } from "@/lib/i18n";
import { groupsDict } from "../i18n";

// Anca's two links (2026-09) -- both hardcoded, deliberately. Two
// org-wide, unchanging URLs; a table would need RLS and an admin screen
// to actually deliver "add a third without a deploy" (nobody but Mihai
// could write to it otherwise, same constraint as editing this file),
// which is not what "smallest useful version" asked for -- same bar this
// domain has held elsewhere (declined a table for per-child attendance,
// 202608130001's own comment). Revisit as a table only if Anca starts
// wanting to manage these herself.
//
// The feedback form's own relevance (mandatory for one-off workshops,
// optional for recurring ones, per Anca) is NOT used to hide the link --
// only to change the caption under it. delivery_format is Mihai's own
// unconfirmed working categorization (WOWLAB_SAD_Domeniul_Operational_
// Groups_Sessions.md: "decizie de lucru, risc acceptat"), and hiding a
// feedback mechanism behind a classification nobody has confirmed risks
// a trainer who genuinely needs it finding nothing there at all. Showing
// it always, captioned correctly, costs a recurring-group trainer one
// extra line of text they can ignore -- the asymmetry favors always
// showing it.
const FEEDBACK_FORM_URL =
  "https://docs.google.com/forms/d/e/1FAIpQLSci_C5t8LqsLMddloMDSLgdO9wJSw5LMakwUcEO3dbtLkXXgQ/viewform";
const RESPONSIBILITIES_DOC_URL = "https://docs.google.com/document/d/1io8GJYq4wBvHvPcblAcqOTOcxNZsOcrC-JfpQ3bLzmQ/edit";

export function TrainerResourcesSection({ deliveryFormat }: { deliveryFormat: string }) {
  const t = useTranslations(groupsDict);
  const isOneOff = deliveryFormat !== "recurring";

  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        {t("resources_heading")}
      </h2>
      <ul className="flex flex-col gap-4">
        <ResourceLink
          href={FEEDBACK_FORM_URL}
          label={t("resources_feedback_form_label")}
          caption={isOneOff ? t("resources_feedback_form_required") : t("resources_feedback_form_optional")}
          openLabel={t("resources_open_action")}
        />
        <ResourceLink
          href={RESPONSIBILITIES_DOC_URL}
          label={t("resources_responsibilities_label")}
          caption={t("resources_responsibilities_caption")}
          openLabel={t("resources_open_action")}
        />
      </ul>
    </section>
  );
}

function ResourceLink({
  href,
  label,
  caption,
  openLabel,
}: {
  href: string;
  label: string;
  caption: string;
  openLabel: string;
}) {
  return (
    <li className="flex items-center justify-between gap-3">
      <div>
        <p className="font-body text-ink text-sm font-semibold">{label}</p>
        <p className="font-body text-muted text-xs">{caption}</p>
      </div>
      <a
        href={href}
        target="_blank"
        rel="noreferrer"
        className="text-brand-pink shrink-0 text-xs font-semibold underline"
      >
        {openLabel}
      </a>
    </li>
  );
}
