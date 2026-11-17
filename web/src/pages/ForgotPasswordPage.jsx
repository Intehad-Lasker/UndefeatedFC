import { useState } from 'react'
import { api } from '../api/client.js'

export default function ForgotPasswordPage() {
  const [message, setMessage] = useState(null)
  const [error, setError] = useState(null)

  async function submit(event) {
    event.preventDefault()
    setError(null)
    try {
      const response = await api.requestPasswordReset(new FormData(event.currentTarget).get('email_address'))
      setMessage(response.message)
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <section className="auth">
      <h1>Reset your password</h1>
      {message ? (
        <p role="status">{message}</p>
      ) : (
        <form className="auth__form" onSubmit={submit}>
          <label>
            Email address
            <input name="email_address" type="email" autoComplete="email" required />
          </label>
          {error && (
            <p role="alert" className="error">
              {error}
            </p>
          )}
          <button type="submit" className="button button--primary">
            Email me a reset link
          </button>
        </form>
      )}
    </section>
  )
}
