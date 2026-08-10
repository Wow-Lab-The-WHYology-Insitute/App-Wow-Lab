"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type ActionResult =
  | { ok: true; id: string }
  | { ok: false; error: string };

// Unlike app/(app)/admin/users/actions.ts, this never touches
// lib/supabase-admin.ts (service_role). The C1 RLS policy on clients
// (supabase/migrations/202608100003) already gates INSERT on
// clients.create — this action runs the insert through the caller's own
// session client and lets that policy be the actual authority. If someone
// reaches this action without the capability, RLS rejects the insert (no
// grant match on WITH CHECK) and Postgres/PostgREST surface that as an
// error here — the UI-level capability check that hides the "+ New
// Client" button is a convenience, not the enforcement.
export async function addClient(
  orgId: string,
  name: string,
  clientType: string,
  businessLine: string,
): Promise<ActionResult> {
  if (!name.trim() || !clientType) {
    return { ok: false, error: "Name and client type are required." };
  }

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("clients")
    .insert({
      organization_id: orgId,
      name: name.trim(),
      client_type: clientType,
      business_line: businessLine.trim() || null,
      status: "prospect",
    })
    .select("id")
    .single();

  if (error || !data) {
    return { ok: false, error: error?.message ?? "Could not create client." };
  }

  revalidatePath("/clients");
  return { ok: true, id: data.id };
}
