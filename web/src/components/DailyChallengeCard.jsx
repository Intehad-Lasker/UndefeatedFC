import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router'
import { api } from '../api/client.js'

const dayFormat = new Intl.DateTimeFormat(undefined, { weekday: 'long', month: 'long', day: 'numeric', timeZone: 'UTC' })

// Today's shared challenge: the same six spins for everyone, one attempt each.
export default function DailyChallengeCard() {
  const navigate = useNavigate()
  const [challenge, setChallenge] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    let active = true
    api
      .dailyChallenge()
      .then((data) => active && setChallenge(data))
      .catch(() => active && setChallenge(null))
    return () => {
      active = false
    }
  }, [])

  if (!challenge) return null

  async function start() {
    setError(null)
    try {
      const draft = await api.startDailyChallenge()
      navigate(`/drafts/${draft.id}`)
    } catch (err) {
      setError(err.message)
    }
  }

  const { attempt } = challenge
  return (
    <aside className="challenge" aria-label="Daily challenge">
      <p className="challenge__eyebrow">Daily challenge · {dayFormat.format(new Date(`${challenge.day}T00:00:00Z`))}</p>
      <p className="challenge__text">Everyone gets the same six spins today. One attempt.</p>
      {!attempt && (
        <button type="button" className="button" onClick={start}>
          Play today's challenge
        </button>
      )}
      {attempt?.status === 'in_progress' && (
        <Link className="button" to={`/drafts/${attempt.id}`}>
          Continue your attempt
        </Link>
      )}
      {attempt?.status === 'completed' && (
        <p className="challenge__done">
          You went <strong>{attempt.record}</strong>
          {attempt.undefeated ? ', undefeated!' : '.'} <Link to={`/drafts/${attempt.id}`}>See your run</Link>
        </p>
      )}
      {error && (
        <p role="alert" className="error">
          {error}
        </p>
      )}
    </aside>
  )
}
