import { useState } from 'react'
import { Link, useNavigate } from 'react-router'
import FieldError from '../auth/FieldError.jsx'
import { useSession } from '../auth/SessionContext.jsx'

export default function SignUpPage() {
  const { signUp } = useSession()
  const navigate = useNavigate()
  const [error, setError] = useState(null)
  const [submitting, setSubmitting] = useState(false)

  async function submit(event) {
    event.preventDefault()
    const form = new FormData(event.currentTarget)
    setSubmitting(true)
    setError(null)
    try {
      await signUp({
        email_address: form.get('email_address'),
        display_name: form.get('display_name'),
        password: form.get('password'),
      })
      navigate('/')
    } catch (err) {
      setError(err)
      setSubmitting(false)
    }
  }

  return (
    <section className="auth">
      <h1>Create an account</h1>
      <form className="auth__form" onSubmit={submit} noValidate>
        <label>
          Display name
          <input name="display_name" autoComplete="nickname" required />
          <span className="hint">3–20 letters, numbers or underscores. Shown on leaderboards.</span>
          <FieldError messages={error?.fields?.display_name} />
        </label>
        <label>
          Email address
          <input name="email_address" type="email" autoComplete="email" required />
          <FieldError messages={error?.fields?.email_address} />
        </label>
        <label>
          Password
          <input name="password" type="password" autoComplete="new-password" required />
          <span className="hint">At least 10 characters.</span>
          <FieldError messages={error?.fields?.password} />
        </label>
        {error && !error.fields && (
          <p role="alert" className="error">
            {error.message}
          </p>
        )}
        <button type="submit" className="button button--primary" disabled={submitting}>
          {submitting ? 'Creating…' : 'Create account'}
        </button>
      </form>
      <p className="auth__links">
        Already have one? <Link to="/sign-in">Sign in</Link>
      </p>
    </section>
  )
}
