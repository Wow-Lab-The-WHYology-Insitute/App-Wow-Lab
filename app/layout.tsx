import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "WOW LAB OS",
  description: "WOW LAB OS internal platform",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
