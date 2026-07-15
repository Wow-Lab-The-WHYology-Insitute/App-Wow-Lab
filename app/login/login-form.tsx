"use client";

import { useActionState } from "react";
import { sendMagicLink, type SendMagicLinkState } from "./actions";

const initialState: SendMagicLinkState = { status: "idle" };

const SUPPORT_EMAIL = "info@wowlab.ro";

function renderWithMailtoLink(message: string) {
  const parts = message.split(SUPPORT_EMAIL);
  if (parts.length === 1) {
    return message;
  }
  return parts.flatMap((part, i) =>
    i === 0
      ? [part]
      : [
          <a key={i} href={`mailto:${SUPPORT_EMAIL}`} className="underline">
            {SUPPORT_EMAIL}
          </a>,
          part,
        ],
  );
}

export function LoginForm() {
  const [state, formAction, isPending] = useActionState(
    sendMagicLink,
    initialState,
  );

  if (state.status === "sent") {
    return (
      <p className="font-body text-ink rounded-xl bg-brand-pink/10 px-4 py-3 text-center text-sm">
        Check your email for a sign-in link.
      </p>
    );
  }

  return (
    <form action={formAction} className="flex flex-col gap-4">
      <div className="flex flex-col gap-1.5">
        <label
          htmlFor="email"
          className="font-body text-ink text-sm font-medium"
        >
          Email
        </label>
        <input
          id="email"
          name="email"
          type="email"
          required
          autoComplete="email"
          placeholder="you@wowlab.ro"
          className="font-body text-ink rounded-lg border border-gray-300 px-3 py-2.5 text-sm outline-none transition-colors focus:border-brand-pink focus:ring-2 focus:ring-brand-pink/20"
        />
      </div>

      {state.status === "error" && (
        <p className="font-body text-ink rounded-lg bg-brand-pink/10 px-3 py-2 text-sm">
          {renderWithMailtoLink(state.message ?? "")}
        </p>
      )}

      <button
        type="submit"
        disabled={isPending}
        className="font-body mt-1 rounded-full bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] px-6 py-3.5 text-sm font-bold tracking-wide text-white uppercase transition-opacity disabled:opacity-50"
      >
        {isPending ? "Sending…" : "Send magic link"}
      </button>
    </form>
  );
}
