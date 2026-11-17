import { useParams } from 'react-router'
import { useMeta } from '../api/useMeta.js'
import FighterPool from '../components/FighterPool.jsx'
import SlotBoard from '../components/SlotBoard.jsx'
import SpinWheels from '../components/SpinWheels.jsx'
import { selectedFighter } from '../draft/draftReducer.js'
import { useDraft } from '../draft/useDraft.js'

export default function DraftPage() {
  const { draftId } = useParams()
  const meta = useMeta()
  const { state, spin, finishReveal, selectFighter, pick } = useDraft(draftId)
  const { draft, phase, error } = state

  if (phase === 'error') {
    return (
      <p role="alert" className="error">
        {error}
      </p>
    )
  }
  if (!draft || !meta) return <p className="loading">Loading draft…</p>

  const round = draft.open_round ?? draft.rounds.at(-1)
  const picksMade = draft.slots.filter((slot) => slot.fighter).length
  const result = draft.open_round && {
    weightClassId: draft.open_round.weight_class.id,
    eraId: draft.open_round.era.id,
  }

  return (
    <section className="draft">
      <header className="draft__header">
        <h1>{phase === 'complete' ? 'Title run complete' : `Round ${Math.min(picksMade + 1, meta.rules.rounds)} of ${meta.rules.rounds}`}</h1>
        {!draft.owned && <p className="notice">You're viewing someone else's draft.</p>}
      </header>

      <SlotBoard
        slots={draft.slots}
        skills={meta.skills}
        selectedFighter={selectedFighter(state)}
        onPick={pick}
        disabled={!draft.owned || phase !== 'picking'}
        lastPickSlot={state.lastPick?.slot}
      />

      <SpinWheels
        weightClasses={meta.weight_classes}
        eras={meta.eras}
        result={result}
        spinning={phase === 'spinning'}
        revealing={phase === 'revealing'}
        onRevealed={finishReveal}
      />

      {draft.owned && phase === 'ready' && (
        <button type="button" className="button button--primary" onClick={spin}>
          Spin
        </button>
      )}

      {['picking', 'submitting'].includes(phase) && round && (
        <>
          <p className="draft__pool-summary">
            {draft.open_round.pool.length} fighters fought at {round.weight_class.name} in the {round.era.label} era.
          </p>
          <FighterPool
            pool={draft.open_round.pool}
            selectedId={state.selectedFighterId}
            onSelect={selectFighter}
            disabled={!draft.owned || phase === 'submitting'}
          />
        </>
      )}

      {error && (
        <p role="alert" className="error">
          {error}
        </p>
      )}
    </section>
  )
}
