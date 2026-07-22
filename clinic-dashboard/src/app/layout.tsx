import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "nabda | Clinic Dashboard",
  description: "لوحة تحكم العيادة لمنصة nabda",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ar" dir="rtl">
      <body>{children}</body>
    </html>
  );
}
