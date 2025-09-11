import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import type React from "react"
import { Suspense } from "react"
const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
})

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
})


export const metadata: Metadata = {
  title: {
    default: "balekai",
    template: "%s | balekai",
  },
  description: "balekai - The task management app that helps you organize and track your projects efficiently",
  generator: "Next.js",
  applicationName: "balekai",
  keywords: ["task management", "productivity", "boards", "organization"],
  authors: [{ name: "balekai" }],
  creator: "balekai",
  publisher: "balekai",
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  metadataBase: new URL("https://balekai.com"),
  openGraph: {
    type: "website",
    locale: "en_US",
    url: "https://balekai.com",
    siteName: "balekai",
    title: "balekai - Task Management App",
    description: "The task management app that helps you organize and track your projects efficiently",
  },
  twitter: {
    card: "summary_large_image",
    title: "balekai - Task Management App",
    description: "The task management app that helps you organize and track your projects efficiently",
    creator: "@balekai",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en">
      <body className={`${geistSans.variable} ${geistMono.variable} antialiased`}>
        <Suspense fallback={<div>Loading...</div>}>{children}</Suspense>
      </body>
    </html>
  )
}
