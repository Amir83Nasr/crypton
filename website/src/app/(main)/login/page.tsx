import { LoginForm } from '@/components/forms/'
import TitleBar from '@/components/titlebar'
import { Button } from '@/components/ui/button'
import Link from 'next/link'

export default function Login() {
  return (
    <main className="container">
      <TitleBar>ورود به پنل کاربری</TitleBar>

      <LoginForm />

      <Button variant={'ghost'} className="rounded-full">
        <Link href={'/signup'}>حساب نداری؟ ثبت ‌نام کن</Link>
      </Button>
    </main>
  )
}
