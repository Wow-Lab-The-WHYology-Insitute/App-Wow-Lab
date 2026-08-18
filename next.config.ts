import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // /whoami renamed to /profile — a permanent (308) redirect here, resolved
  // by Next.js before middleware/routing, so any bookmarked or previously-
  // shared /whoami link keeps working. Middleware's own auth gate still
  // applies to the resulting /profile request as normal (redirects run
  // ahead of middleware in the pipeline, so an unauthenticated visitor to
  // /whoami correctly ends up at /login?next=/profile, not a dead end).
  async redirects() {
    return [
      {
        source: "/whoami",
        destination: "/profile",
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
