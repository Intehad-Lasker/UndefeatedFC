import { useState } from 'react'
import { useMeta } from '../api/useMeta.js'
import FighterPool from '../components/FighterPool.jsx'
import PickTray from '../components/PickTray.jsx'
import SlotBoard from '../components/SlotBoard.jsx'

// The live draft between two players, reusing the solo draft's components:
// the round's pool, both boards, and (on your turn) pick buttons.
export default function MatchRoom({ match, onPick }) {
  const meta = useMeta()
  const [selectedId, setSelectedId] = useState(null)
  const [submitting, setSubmitting] = useState(false)
  const nameOf = (seat) => match.players.find((player) => player.seat === seat)?.display_name ?? `Player ${seat}`
  // While a pick is in flight the board is locked, so a quick second click
  // can't act on the turn that is already being submitted.
  const yourTurn = match.status === 'drafting' && match.your_seat === match.current_seat && !submitting
  const selected = yourTurn ? match.pool?.fighters.find((fighter) => fighter.id === selectedId) ?? null : null
  const yourSeat = match.your_seat ?? 1
  const seats = [yourSeat, yourSeat === 1 ? 2 : 1]
  const board = (seat) => match.boards.find((b) => b.seat === seat)

  async function pick(slot) {
    setSubmitting(true)
    try {
      await onPick(selected.id, slot)
    } finally {
      setSelectedId(null)
      setSubmitting(false)
    }
  }

  return (
    <div className="room">
      {match.status === 'drafting' && (
        <p className="room__turn" role="status">
          Round {match.round} of 6 · {yourTurn ? 'Your turn' : `${nameOf(match.current_seat)}'s turn`}
        </p>
      )}

      <div className="room__boards">
        {seats.map((seat) => (
          <div key={seat} className="room__board">
            <h2>{match.your_seat === seat ? `You (${nameOf(seat)})` : nameOf(seat)}</h2>
            <SlotBoard
              slots={board(seat).slots}
              skills={meta?.skills}
              selectedFighter={seat === match.your_seat ? selected : null}
              onPick={pick}
              disabled={!yourTurn}
            />
          </div>
        ))}
      </div>

      {match.pool && (
        <section className="room__pool" aria-label="Round pool">
          <h2>
            {match.pool.weight_class.name} · {match.pool.era.label}
          </h2>
          <FighterPool pool={match.pool.fighters} selectedId={selectedId} onSelect={setSelectedId} disabled={!yourTurn} />
        </section>
      )}

      {yourTurn && (
        <PickTray
          fighter={selected}
          openSlots={board(match.your_seat).slots.filter((slot) => !slot.fighter)}
          onPick={pick}
        />
      )}

      {match.result && (
        <section className="result" aria-label="Match result">
          <p className="result__badge">{match.result.winner_seat === match.your_seat ? 'You win' : `${nameOf(match.result.winner_seat)} wins`}</p>
          <p className="result__record">{match.result.score}</p>
          <p className="result__overall">
            Overall {nameOf(1)} <strong>{match.result.overalls['1']}</strong> · {nameOf(2)}{' '}
            <strong>{match.result.overalls['2']}</strong>
          </p>
          <ol className="result__fights" aria-label="Rounds">
            {match.result.rounds.map((round) => (
              <li key={round.number} className="fight fight--won">
                <span className="fight__number">Round {round.number}</span>
                <span className="fight__opponent">{nameOf(round.winner_seat)}</span>
                <span className="fight__odds">{Math.round(round.seat_one_chance * 100)}% for {nameOf(1)}</span>
                <span className="fight__outcome">✓</span>
              </li>
            ))}
          </ol>
        </section>
      )}
    </div>
  )
}
