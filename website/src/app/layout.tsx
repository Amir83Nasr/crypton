import type { Metadata } from 'next'
import './globals.css'

import Image from 'next/image'
import cryto from '@/assets/images/black crytpo.jpg'

export const metadata: Metadata = {
  title: 'Crypton',
  description: 'a crypto currency app',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="fa" dir="rtl">
      <body className={`antialiased`}>
        <main className="flex h-screen w-screen flex-row gap-64 p-64">
          <div className="w-364 max-sm:w-full">{children}</div>

          <div className="w-full max-sm:hidden">
            <Image
              src={cryto}
              alt="crypto currency"
              height={772}
              width={884}
              className="rounded-40 size-full object-cover mix-blend-luminosity"
            />
          </div>
        </main>
      </body>
    </html>
  )
}
