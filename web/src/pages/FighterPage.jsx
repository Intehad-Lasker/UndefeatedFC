import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router'
import { api } from '../api/client.js'
import FighterCard from '../components/FighterCard.jsx'

const OUTCOME = { win: 'W', loss: 'L', draw: 'D', no_contest: 'NC' }
const FINISH = { ko_tko: 'KO/TKO', submission: 'Submission', decision: 'Decision', disqualification: 'DQ', no_contest: 'No contest', other: 'Other' }

export default function FighterPage() {
  const { fighterId } = useParams()
  const [state, setState] = useState({ id: null, fighter: null, error: null })

  useEffect(() => {
    let active = true
    api
      .getFighter(fighterId)
      .then((fighter) => active && setState({ id: fighterId, fighter, error: null }))
      .catch((error) => active && setState({ id: fighterId, fighter: null, error: error.message }))
    return () => {
      active = false
    }
  }, [fighterId])

  if (state.id !== fighterId) return <p className="loading">Loading fighter…</p>
  if (state.error) {
    return (
      <p role="alert" className="error">
        {state.error}
      </p>
    )
  }

  const { fighter } = state
  return (
    <section className="fighter">
      <Link to="/fighters">← Search</Link>
      <h1>{fighter.name}</h1>
      <FighterCard fighter={fighter} />

      <h2>Draftable in</h2>
      <ul className="fighter__pools" aria-label="Draftable in">
        {fighter.pools.map((pool) => (
          <li key={`${pool.weight_class}-${pool.era}`}>
            {pool.weight_class} · {pool.era}
          </li>
        ))}
      </ul>

      <h2>Recent bouts</h2>
      <table className="fighter__bouts">
        <thead>
          <tr>
            <th scope="col">Result</th>
            <th scope="col">Opponent</th>
            <th scope="col">Method</th>
            <th scope="col">Event</th>
            <th scope="col">Date</th>
          </tr>
        </thead>
        <tbody>
          {fighter.recent_bouts.map((bout) => (
            <tr key={`${bout.event}-${bout.opponent?.id}`}>
              <td>{OUTCOME[bout.outcome]}</td>
              <td>{bout.opponent ? <Link to={`/fighters/${bout.opponent.id}`}>{bout.opponent.name}</Link> : '—'}</td>
              <td>
                {FINISH[bout.finish]}
                {bout.ending_round && bout.finish !== 'decision' ? ` (R${bout.ending_round})` : ''}
              </td>
              <td>{bout.event}</td>
              <td>{bout.held_on}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  )
}
