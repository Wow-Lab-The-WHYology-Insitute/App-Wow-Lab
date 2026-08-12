"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export type ActionResult = { ok: true } | { ok: false; error: string };

// Self-service only — the existing "authenticated update users" RLS policy
// (id = app.current_user_id()) is the real gate here, not a capability
// check. This never touches service_role, unlike admin/users/actions.ts —
// deliberately a different file, since that one is an admin surface
// (capability-gated, acting on OTHER users) and this one only ever acts on
// the caller's own row.
export async function updateOwnProfile(
  firstName: string,
  lastName: string,
  phone: string,
): Promise<ActionResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: "Not signed in." };

  const { error } = await supabase
    .from("users")
    .update({
      first_name: firstName.trim() || null,
      last_name: lastName.trim() || null,
      phone: phone.trim() || null,
    })
    .eq("id", user.id);

  if (error) return { ok: false, error: error.message };

  revalidatePath("/whoami");
  revalidatePath("/admin/users");
  return { ok: true };
}

const MAX_AVATAR_BYTES = 2 * 1024 * 1024;
const ALLOWED_AVATAR_TYPES = ["image/jpeg", "image/png", "image/webp"];

// Runs through the caller's own session client (lib/supabase/server.ts),
// same as every other action here — so the storage.objects "avatars owner
// insert/update" RLS policy (202608120001, folder-per-user path) is what
// actually authorizes the write, not this action's own logic. Re-checking
// type/size here is belt-and-suspenders for a fast error message; the
// bucket's own allowed_mime_types/file_size_limit (also 202608120001) is
// the real, server-side-enforced backstop even if this check were ever
// bypassed.
export async function uploadOwnAvatar(formData: FormData): Promise<ActionResult> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: "Not signed in." };

  const file = formData.get("avatar");
  if (!(file instanceof File) || file.size === 0) {
    return { ok: false, error: "No file provided." };
  }
  if (!ALLOWED_AVATAR_TYPES.includes(file.type)) {
    return { ok: false, error: "Only JPEG, PNG, or WebP images are allowed." };
  }
  if (file.size > MAX_AVATAR_BYTES) {
    return { ok: false, error: "Image must be 2MB or smaller." };
  }

  // Fixed path per user — re-uploading is a plain overwrite (upsert),
  // never accumulating orphaned old files, and keeps avatar_url stable.
  const path = `${user.id}/avatar`;
  const { error: uploadError } = await supabase.storage
    .from("avatars")
    .upload(path, file, { upsert: true, contentType: file.type });

  if (uploadError) {
    return { ok: false, error: uploadError.message };
  }

  const { error: updateError } = await supabase
    .from("users")
    .update({ avatar_url: path })
    .eq("id", user.id);

  if (updateError) {
    return { ok: false, error: updateError.message };
  }

  revalidatePath("/whoami");
  revalidatePath("/admin/users");
  return { ok: true };
}
