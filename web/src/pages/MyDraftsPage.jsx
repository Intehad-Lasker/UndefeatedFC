import { useEffect, useState } from 'react'
import { Link } from 'react-router'
import { api } from '../api/client.js'
import { useSession } from '../auth/SessionContext.jsx'

const dateFormat = new Intl.DateTimeFormat(undefined, { dateStyle: 'medium' })

function summary(draft) {
  if (draft.status === 'completed') return draft.undefeated ? `${draft.record} · Undefeated` : draft.record
  return `In progress · ${draft.picks_made} of 6 picks`
}

export default function MyDraftsPage() {
  const { user, loading } = useSession()
  const [state, setState] = useState({ drafts: null, error: null })

  useEffect(() => {
    if (!user) return undefined
    let active = true
    api
      .myDrafts()
      .then(({ drafts }) => active && setState({ drafts, error: null }))
      .catch((error) => active && setState({ drafts: [], error: error.message }))
    return () => {
      active = false
    }
  }, [user])

  if (loading) return <p className="loading">Loading…</p>
  if (!user) {
    return (
      <section>
        <h1>My drafts</h1>
        <p>
          <Link to="/sign-in?next=/me/drafts">Sign in</Link> to keep your drafts across devices.
        </p>
      </section>
    )
  }

  return (
    <section className="history">
      <h1>My drafts</h1>
      {state.error && (
        <p role="alert" className="error">
          {state.error}
        </p>
      )}
      {state.drafts?.length === 0 && !state.error && (
        <p>
          No drafts yet. <Link to="/">Start one</Link>.
        </p>
      )}
      <ol className="history__list" aria-label="Your drafts">
        {state.drafts?.map((draft) => (
          <li key={draft.id}>
            <Link to={`/drafts/${draft.id}`} className={`history__item${draft.undefeated ? ' history__item--undefeated' : ''}`}>
              <span className="history__date">{dateFormat.format(new Date(draft.created_at))}</span>
              <span className="history__summary">{summary(draft)}</span>
              {draft.overall != null && <span className="history__overall">{draft.overall}</span>}
            </Link>
          </li>
        ))}
      </ol>
    </section>
  )
}
