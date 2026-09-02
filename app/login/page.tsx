import { LoginContent } from "./login-content";

// Server Component -- reads searchParams (Next 15: a Promise, awaited
// here, not a hook) and hands the one boolean it produces down to a
// client child. Same split as client-header.tsx/group-header.tsx
// (page.tsx can't call useTranslations()/useLocale() itself, per
// docs/OPEN_ITEMS.md item 14) -- not a new pattern for this page.
//
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

  return <LoginContent hasCallbackError={hasCallbackError} />;
}
