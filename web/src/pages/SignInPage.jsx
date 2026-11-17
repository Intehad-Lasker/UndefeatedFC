import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router'
import { useSession } from '../auth/SessionContext.jsx'

export default function SignInPage() {
  const { signIn } = useSession()
  const navigate = useNavigate()
  const [params] = useSearchParams()
  const [error, setError] = useState(null)
  const [submitting, setSubmitting] = useState(false)

  async function submit(event) {
    event.preventDefault()
    const form = new FormData(event.currentTarget)
    setSubmitting(true)
    setError(null)
    try {
      await signIn(form.get('email_address'), form.get('password'))
      navigate(params.get('next') ?? '/')
    } catch (err) {
      setError(err.message)
      setSubmitting(false)
    }
  }

  return (
    <section className="auth">
      <h1>Sign in</h1>
      <p>Your drafts follow you to any device, and guest drafts on this browser move to your account.</p>
      <form className="auth__form" onSubmit={submit}>
        <label>
          Email address
          <input name="email_address" type="email" autoComplete="email" required />
        </label>
        <label>
          Password
          <input name="password" type="password" autoComplete="current-password" required />
        </label>
        {error && (
          <p role="alert" className="error">
            {error}
          </p>
        )}
        <button type="submit" className="button button--primary" disabled={submitting}>
          {submitting ? 'Signing in…' : 'Sign in'}
        </button>
      </form>
      <p className="auth__links">
        <Link to="/forgot-password">Forgot your password?</Link> · New here? <Link to="/sign-up">Create an account</Link>
      </p>
    </section>
  )
}
