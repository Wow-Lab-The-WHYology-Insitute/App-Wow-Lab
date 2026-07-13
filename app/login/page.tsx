import { LoginForm } from "./login-form";

export default function LoginPage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-sm flex-col justify-center gap-6 p-8">
      <div>
        <h1 className="text-xl font-semibold">WOW LAB OS</h1>
        <p className="text-sm text-gray-600">
          Invite-only. Enter your email to get a sign-in link.
        </p>
      </div>
      <LoginForm />
    </main>
  );
}
