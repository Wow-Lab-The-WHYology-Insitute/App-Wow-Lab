import Image from "next/image";
import { LoginForm } from "./login-form";

// /auth/callback (app/auth/callback/route.ts) redirects here with
// ?error=auth-callback-failed on any failure -- missing token_hash/type,
// or a real verifyOtp error (expired link, already-used link, etc.) both
// converge on this exact same single value; grepped every redirect("/login")
// call site in the app (this one, app/(app)/layout.tsx's auth gate,
// app/(app)/actions.ts's sign-out) and confirmed no other error value is
// ever emitted anywhere. One banner covers every failure mode that
// exists today, not just the common one.
type SearchParams = { [key: string]: string | string[] | undefined };

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}) {
  const params = await searchParams;
  const hasCallbackError = params.error === "auth-callback-failed";

  return (
    <main className="flex min-h-screen items-center justify-center bg-[linear-gradient(135deg,#EC008C_0%,#FAA21B_100%)] p-6">
      <div className="w-full max-w-[420px] rounded-2xl bg-white p-10 shadow-xl">
        <div className="flex flex-col items-center text-center">
          <Image
            src="/logo-wowlab.png"
            alt="WOW LAB"
            width={220}
            height={73}
            priority
            className="h-12 w-auto"
          />
          <h1 className="font-display mt-6 text-2xl text-brand-pink">
            WOW LAB OS
          </h1>
          <p className="font-body text-muted mt-2 text-sm">
            Invite-only. Enter your email to get a sign-in link.
          </p>
        </div>
        {hasCallbackError && (
          <p className="font-body text-ink mt-6 rounded-lg bg-brand-pink/10 px-3 py-2 text-center text-sm">
            That link didn&apos;t work — it may have expired or already been
            used. Enter your email below to request a new one.
          </p>
        )}
        <div className="mt-8">
          <LoginForm />
        </div>
      </div>
    </main>
  );
}
