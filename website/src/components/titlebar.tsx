import React from 'react'

export default function TitleBar({ children }: { children: React.ReactNode }) {
  return (
    <main>
      <h1 className="headline text-center">{children}</h1>
    </main>
  )
}
