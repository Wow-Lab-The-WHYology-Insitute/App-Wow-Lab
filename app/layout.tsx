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
    <html lang="en">
      <body
        className={`${cabin.variable} ${tiltNeon.variable} antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
