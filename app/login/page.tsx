import Image from "next/image";
import { LoginForm } from "./login-form";

export default function LoginPage() {
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
        <div className="mt-8">
          <LoginForm />
        </div>
      </div>
    </main>
  );
}
