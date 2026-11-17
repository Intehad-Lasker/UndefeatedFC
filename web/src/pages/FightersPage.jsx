import { useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router'
import { api } from '../api/client.js'
import FighterCard from '../components/FighterCard.jsx'

const DEBOUNCE_MS = 250

// Search lives in the URL (?q=), so results can be bookmarked and the back
// button works. Requests wait for a short pause in typing.
export default function FightersPage() {
  const [params, setParams] = useSearchParams()
  const query = params.get('q') ?? ''
  const [results, setResults] = useState({ query: '', fighters: [], error: null })

  useEffect(() => {
    const term = query.trim()
    if (!term) return undefined

    let active = true
    const timer = setTimeout(() => {
      api
        .searchFighters(term)
        .then(({ fighters }) => active && setResults({ query: term, fighters, error: null }))
        .catch((error) => active && setResults({ query: term, fighters: [], error: error.message }))
    }, DEBOUNCE_MS)

    return () => {
      active = false
      clearTimeout(timer)
    }
  }, [query])

  const term = query.trim()
  const fighters = term ? results.fighters : []

  return (
    <section className="fighters">
      <h1>Fighters</h1>
      <label className="fighters__search">
        Search by name or nickname
        <input
          type="search"
          value={query}
          onChange={(event) => setParams(event.target.value ? { q: event.target.value } : {}, { replace: true })}
          placeholder="e.g. Garrow"
          autoFocus
        />
      </label>
      {results.error && (
        <p role="alert" className="error">
          {results.error}
        </p>
      )}
      {term && results.query === term && fighters.length === 0 && !results.error && (
        <p>No fighters found for “{term}”.</p>
      )}
      <ul className="fighters__results" aria-label="Search results">
        {fighters.map((fighter) => (
          <li key={fighter.id}>
            <Link to={`/fighters/${fighter.id}`} className="fighters__link">
              <FighterCard fighter={fighter} />
            </Link>
          </li>
        ))}
      </ul>
    </section>
  )
}
