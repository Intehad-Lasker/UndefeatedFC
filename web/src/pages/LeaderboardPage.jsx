import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router'
import { subscribe } from '../api/cable.js'
import { api } from '../api/client.js'

const BOARDS = [
  { key: 'daily', label: "Today's challenge" },
  { key: 'all_time', label: 'All-time' },
]

// Rankings come from the cached API; the channel only says "this board moved",
// so a live update is just a refetch.
function useLiveBoard(board) {
  const [state, setState] = useState({ board: null, data: null, error: null })

  useEffect(() => {
    let active = true
    const load = () =>
      api
        .leaderboard(board)
        .then((data) => active && setState({ board, data, error: null }))
        .catch((error) => active && setState({ board, data: null, error: error.message }))

    load()
    const unsubscribe = subscribe('LeaderboardChannel', { board }, load)
    return () => {
      active = false
      unsubscribe()
    }
  }, [board])

  return state.board === board ? state : { data: null, error: null }
}

export default function LeaderboardPage() {
  const [params, setParams] = useSearchParams()
  const board = params.get('board') === 'all_time' ? 'all_time' : 'daily'
  const { data, error } = useLiveBoard(board)

  return (
    <section className="leaderboard">
      <h1>Leaderboard</h1>
      <div className="tabs" role="tablist" aria-label="Boards">
        {BOARDS.map((option) => (
          <button
            key={option.key}
            type="button"
            role="tab"
            aria-selected={board === option.key}
            className="tabs__tab"
            onClick={() => setParams(option.key === 'daily' ? {} : { board: option.key })}
          >
            {option.label}
          </button>
        ))}
      </div>
      <p className="notice">
        {board === 'daily' ? `Everyone's attempt at the ${data?.day ?? ''} challenge.` : "Each player's best run."} Updates
        live. Sign in to appear here.
      </p>
      {error && (
        <p role="alert" className="error">
          {error}
        </p>
      )}
      {data && data.entries.length === 0 && <p>No finished runs yet. Be the first.</p>}
      {data && data.entries.length > 0 && (
        <table className="standings">
          <thead>
            <tr>
              <th scope="col">#</th>
              <th scope="col">Player</th>
              <th scope="col">Record</th>
              <th scope="col">Overall</th>
            </tr>
          </thead>
          <tbody>
            {data.entries.map((entry) => (
              <tr key={entry.draft_id} className={entry.undefeated ? 'standings__row--undefeated' : undefined}>
                <td>{entry.rank}</td>
                <td>
                  <Link to={`/drafts/${entry.draft_id}`}>{entry.display_name}</Link>
                </td>
                <td>{entry.record}</td>
                <td>{entry.overall}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  )
}
