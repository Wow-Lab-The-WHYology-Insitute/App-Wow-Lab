import type { Metadata } from "next";
import { Cabin, Tilt_Neon } from "next/font/google";
import "./globals.css";

const cabin = Cabin({
  subsets: ["latin"],
  weight: ["400", "500", "700"],
  variable: "--font-cabin",
});

const tiltNeon = Tilt_Neon({
  subsets: ["latin"],
  weight: ["400"],
  variable: "--font-tilt-neon",
});

export const metadata: Metadata = {
  title: "WOW LAB OS",
  description: "WOW LAB OS internal platform",
  icons: {
    icon: "/wow-lab-fav.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    // Font variable classes live on <html>, not <body>: Tailwind's @theme
    // block declares --font-display/--font-body on :root (= <html>),
    // referencing var(--font-tilt-neon)/var(--font-cabin) — a CSS custom
    // property can only resolve a var() reference to another custom
    // property defined on the SAME element or an ancestor, never a
    // descendant. With the variable classes on <body> (a descendant of
    // :root), --font-tilt-neon/--font-cabin didn't exist yet at the point
    // :root's declarations were evaluated, so --font-display/--font-body
    // silently resolved to invalid and every page fell back to the system
    // font stack — confirmed live (computed font-family had no Cabin/Tilt
    // Neon in it, document.fonts showed both as "unloaded") before this
    // fix, standard next/font + Tailwind v4 @theme fix afterward.
    <html lang="en" className={`${cabin.variable} ${tiltNeon.variable}`}>
      <body className="antialiased">{children}</body>
    </html>
  );
}
