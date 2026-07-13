import Link from "next/link";
import { createClient } from "@/lib/supabase/server";

export default async function Home() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  return (
    <main className="mx-auto flex min-h-screen max-w-xl flex-col items-start justify-center gap-4 p-8">
      <h1 className="text-2xl font-semibold">WOW LAB OS</h1>
      <p className="text-gray-600">
        Signed in as <span className="font-mono">{user?.email}</span>.
      </p>
      <p className="text-sm text-gray-500">
        This is a bare S0/S1 placeholder — the real app shell (navigation, brand)
        lands in S3.
      </p>
      <Link href="/admin/users" className="text-blue-600 underline">
        Users &amp; roles (admin)
      </Link>
    </main>
  );
}
