"use client";

import { useActionState } from "react";
import { sendMagicLink, type SendMagicLinkState } from "./actions";

const initialState: SendMagicLinkState = { status: "idle" };

export function LoginForm() {
  const [state, formAction, isPending] = useActionState(
    sendMagicLink,
    initialState,
  );

  if (state.status === "sent") {
    return (
      <p className="text-sm text-gray-700">
        Check your email for a sign-in link.
      </p>
    );
  }

  return (
    <form action={formAction} className="flex flex-col gap-3">
      <label htmlFor="email" className="text-sm font-medium">
        Email
      </label>
      <input
        id="email"
        name="email"
        type="email"
        required
        autoComplete="email"
        className="rounded border border-gray-300 px-3 py-2"
        placeholder="you@wowlab.ro"
      />
      {state.status === "error" && (
        <p className="text-sm text-red-600">{state.message}</p>
      )}
      <button
        type="submit"
        disabled={isPending}
        className="rounded bg-black px-3 py-2 text-white disabled:opacity-50"
      >
        {isPending ? "Sending…" : "Send magic link"}
      </button>
    </form>
  );
}
