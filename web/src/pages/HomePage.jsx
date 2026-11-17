import { useState } from 'react'
import { useNavigate } from 'react-router'
import { api } from '../api/client.js'

export default function HomePage() {
  const navigate = useNavigate()
  const [starting, setStarting] = useState(false)
  const [error, setError] = useState(null)

  async function startDraft() {
    setStarting(true)
    setError(null)
    try {
      const draft = await api.createDraft()
      navigate(`/drafts/${draft.id}`)
    } catch (err) {
      setError(err.message)
      setStarting(false)
    }
  }

  return (
    <section className="home">
      <h1>Build an undefeated fighter.</h1>
      <ol className="home__steps">
        <li>
          <strong>Spin</strong> a weight class and an era.
        </li>
        <li>
          <strong>Draft</strong> one fighter from that pool into a skill slot: Striking, Power, Wrestling,
          Submissions, Defense or Chin.
        </li>
        <li>
          <strong>Fight</strong> a 15-bout title run with the six-fighter build. Ratings stay hidden until you pick,
          so know your fighters.
        </li>
      </ol>
      <button type="button" className="button button--primary" onClick={startDraft} disabled={starting}>
        {starting ? 'Starting…' : 'Start a draft'}
      </button>
      {error && (
        <p role="alert" className="error">
          {error}
        </p>
      )}
    </section>
  )
}
