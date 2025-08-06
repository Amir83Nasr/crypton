import { SignupForm } from '@/components/forms'
import TitleBar from '@/components/titlebar'
import { Button } from '@/components/ui/button'
import Link from 'next/link'

export default function Signup() {
  return (
    <main className="container">
      <TitleBar>ثبت نام در پنل کاربری</TitleBar>

      <SignupForm />

      <Button variant={'ghost'} className="rounded-full" asChild>
        <Link href={'/login'}>حساب نداری؟ ثبت ‌نام کن</Link>
      </Button>
    </main>
  )
}
