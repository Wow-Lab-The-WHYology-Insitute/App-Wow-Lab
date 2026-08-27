"use client";

import { useRef, useState, useTransition } from "react";
import { useTranslations } from "@/lib/i18n";
import { profileDict } from "./i18n";
import { updateOwnProfile, uploadOwnAvatar } from "./actions";

function initialsFrom(label: string) {
  return (
    label
      .split(/\s+/)
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part[0]?.toUpperCase())
      .join("") || "?"
  );
}

export function ProfileSection({
  email,
  initialFirstName,
  initialLastName,
  initialPhone,
  initialAvatarUrl,
}: {
  email: string;
  initialFirstName: string | null;
  initialLastName: string | null;
  initialPhone: string | null;
  initialAvatarUrl: string | null;
}) {
  const t = useTranslations(profileDict);
  const [firstName, setFirstName] = useState(initialFirstName ?? "");
  const [lastName, setLastName] = useState(initialLastName ?? "");
  const [phone, setPhone] = useState(initialPhone ?? "");
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);
  const [isPending, startTransition] = useTransition();

  // Local object URL shown immediately on file select, before the upload
  // round-trip completes — swapped for the real signed URL once the page
  // revalidates (initialAvatarUrl updates), but stays visible in the
  // meantime so the control never looks like it silently did nothing.
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);
  const [avatarError, setAvatarError] = useState<string | null>(null);
  const [isUploading, startUploadTransition] = useTransition();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const displayedAvatarUrl = avatarPreview ?? initialAvatarUrl;
  const nameForInitials = [firstName, lastName].filter(Boolean).join(" ") || email;

  function handleSave() {
    setError(null);
    setSaved(false);
    startTransition(async () => {
      const result = await updateOwnProfile(firstName, lastName, phone);
      if (!result.ok) setError(result.error);
      else setSaved(true);
    });
  }

  function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setAvatarError(null);

    const allowed = ["image/jpeg", "image/png", "image/webp"];
    if (!allowed.includes(file.type)) {
      setAvatarError(t("avatar_type_error"));
      e.target.value = "";
      return;
    }
    if (file.size > 2 * 1024 * 1024) {
      setAvatarError(t("avatar_size_error"));
      e.target.value = "";
      return;
    }

    setAvatarPreview(URL.createObjectURL(file));

    const formData = new FormData();
    formData.append("avatar", file);
    startUploadTransition(async () => {
      const result = await uploadOwnAvatar(formData);
      if (!result.ok) {
        setAvatarError(result.error);
        setAvatarPreview(null);
      }
      e.target.value = "";
    });
  }

  return (
    <section className="rounded-2xl border border-black/5 bg-white p-6 shadow-sm">
      <h2 className="font-body text-muted mb-4 text-xs font-bold tracking-wide uppercase">
        {t("your_profile_heading")}
      </h2>

      <div className="flex flex-col gap-4 sm:flex-row sm:items-start">
        <div className="flex shrink-0 flex-col items-center gap-2">
          <button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            className="group relative h-20 w-20 shrink-0 overflow-hidden rounded-full outline-none focus-visible:ring-2 focus-visible:ring-brand-pink/40"
          >
            {displayedAvatarUrl ? (
              // eslint-disable-next-line @next/next/no-img-element -- dynamic, short-lived signed URL (or a local object URL mid-upload), not a static asset next/image can usefully optimize
              <img src={displayedAvatarUrl} alt="" className="h-full w-full object-cover" />
            ) : (
              <span className="bg-ink/10 text-ink flex h-full w-full items-center justify-center text-lg font-bold">
                {initialsFrom(nameForInitials)}
              </span>
            )}
            <span className="absolute inset-0 flex items-center justify-center bg-black/40 text-[10px] font-bold text-white opacity-0 transition-opacity group-hover:opacity-100">
              {isUploading ? "…" : t("change_overlay")}
            </span>
          </button>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/jpeg,image/png,image/webp"
            onChange={handleFileSelect}
            className="hidden"
          />
          <button
            type="button"
            onClick={() => fileInputRef.current?.click()}
            disabled={isUploading}
            className="text-brand-pink font-body text-xs font-semibold underline disabled:opacity-50"
          >
            {isUploading ? t("uploading_ellipsis") : t("change_photo")}
          </button>
          {avatarError && (
            <p className="font-body text-brand-pink max-w-[10rem] text-center text-xs">
              {avatarError}
            </p>
          )}
        </div>

        <div className="flex flex-1 flex-col gap-3">
          <div className="flex flex-col gap-3 sm:flex-row">
            <input
              type="text"
              value={firstName}
              onChange={(e) => {
                setFirstName(e.target.value);
                setSaved(false);
              }}
              placeholder={t("first_name_placeholder")}
              className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 sm:flex-1"
            />
            <input
              type="text"
              value={lastName}
              onChange={(e) => {
                setLastName(e.target.value);
                setSaved(false);
              }}
              placeholder={t("last_name_placeholder")}
              className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20 sm:flex-1"
            />
          </div>
          <input
            type="tel"
            value={phone}
            onChange={(e) => {
              setPhone(e.target.value);
              setSaved(false);
            }}
            placeholder={t("phone_placeholder")}
            className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
          />
          {error && (
            <p className="font-body text-ink rounded-lg bg-brand-pink/10 px-4 py-3 text-sm">
              {error}
            </p>
          )}
          <div className="flex items-center gap-3">
            <button
              type="button"
              disabled={isPending}
              onClick={handleSave}
              className="font-body w-fit rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-5 py-2.5 text-xs font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
            >
              {t("save")}
            </button>
            {saved && !isPending && (
              <span className="font-body text-muted text-xs">{t("saved")}</span>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
