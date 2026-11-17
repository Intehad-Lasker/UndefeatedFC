// What a player sees about a fighter while drafting: record and career stats.
// Ratings are not part of the payload until the fighter is picked.

const percent = (value) => `${Math.round(value * 100)}%`
const decimal = (value) => value.toFixed(2)

export const STAT_COLUMNS = [
  { key: 'sig_strikes_landed_per_min', label: 'Str/min', format: decimal },
  { key: 'sig_strike_accuracy', label: 'Str acc', format: percent },
  { key: 'sig_strike_defense', label: 'Str def', format: percent },
  { key: 'takedowns_per_15_min', label: 'TD/15', format: decimal },
  { key: 'takedown_defense', label: 'TD def', format: percent },
  { key: 'submission_attempts_per_15_min', label: 'Sub/15', format: decimal },
]

export default function FighterCard({ fighter }) {
  const ufc = fighter.ufc_record
  return (
    <div className="fighter-card">
      <div className="fighter-card__name">
        <strong>{fighter.name}</strong>
        {fighter.nickname && <span className="fighter-card__nickname">“{fighter.nickname}”</span>}
      </div>
      <div className="fighter-card__record">
        {fighter.record}
        {ufc && (
          <span>
            {' '}
            · UFC {ufc.wins}-{ufc.losses} ({ufc.ko_wins} KO, {ufc.submission_wins} SUB)
          </span>
        )}
      </div>
      <dl className="fighter-card__stats">
        {STAT_COLUMNS.map((column) => (
          <div key={column.key}>
            <dt>{column.label}</dt>
            <dd>{column.format(fighter.stats[column.key])}</dd>
          </div>
        ))}
      </dl>
    </div>
  )
}
