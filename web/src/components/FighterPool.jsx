import { useMemo, useState } from 'react'
import FighterCard, { STAT_COLUMNS } from './FighterCard.jsx'

const SORTS = [
  { key: 'name', label: 'Name', compare: (a, b) => a.name.localeCompare(b.name) },
  { key: 'ufc_wins', label: 'UFC wins', compare: (a, b) => (b.ufc_record?.wins ?? 0) - (a.ufc_record?.wins ?? 0) },
  ...STAT_COLUMNS.map((column) => ({
    key: column.key,
    label: column.label,
    compare: (a, b) => b.stats[column.key] - a.stats[column.key],
  })),
]

export default function FighterPool({ pool, selectedId, onSelect, disabled }) {
  const [query, setQuery] = useState('')
  const [sortKey, setSortKey] = useState('name')

  const fighters = useMemo(() => {
    const needle = query.trim().toLowerCase()
    const sort = SORTS.find((option) => option.key === sortKey)
    return pool
      .filter((fighter) => `${fighter.name} ${fighter.nickname ?? ''}`.toLowerCase().includes(needle))
      .toSorted(sort.compare)
  }, [pool, query, sortKey])

  return (
    <div className="pool">
      <div className="pool__controls">
        <label>
          Filter
          <input type="search" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Name or nickname" />
        </label>
        <label>
          Sort by
          <select value={sortKey} onChange={(event) => setSortKey(event.target.value)}>
            {SORTS.map((option) => (
              <option key={option.key} value={option.key}>
                {option.label}
              </option>
            ))}
          </select>
        </label>
      </div>
      <ul className="pool__list" aria-label="Fighters in this pool">
        {fighters.map((fighter) => (
          <li key={fighter.id}>
            <button
              type="button"
              className="pool__fighter"
              aria-pressed={fighter.id === selectedId}
              onClick={() => onSelect(fighter.id)}
              disabled={disabled}
            >
              <FighterCard fighter={fighter} />
            </button>
          </li>
        ))}
      </ul>
      {fighters.length === 0 && <p className="pool__empty">No fighters match “{query}”.</p>}
    </div>
  )
}
