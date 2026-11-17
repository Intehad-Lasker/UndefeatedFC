// UI state for the draft page. The server owns the draft itself; this reducer
// only tracks what the screen is doing with it:
//
//   loading -> ready -> spinning -> revealing -> picking -> submitting -> ready ...
//                                                                     \-> complete
//
// Keeping it a pure function means every transition is testable without React.

export const initialState = {
  phase: 'loading',
  draft: null,
  selectedFighterId: null,
  lastPick: null,
  error: null,
}

// The phase a freshly loaded draft should be in.
export function phaseFor(draft) {
  if (draft.status === 'completed') return 'complete'
  if (draft.open_round) return 'picking'
  return 'ready'
}

export function draftReducer(state, action) {
  switch (action.type) {
    case 'loaded':
      return { ...state, draft: action.draft, phase: phaseFor(action.draft), error: null }

    case 'spin_started':
      return state.phase === 'ready' ? { ...state, phase: 'spinning', error: null } : state

    case 'spin_succeeded':
      return { ...state, draft: action.draft, phase: 'revealing', selectedFighterId: null }

    case 'reveal_finished':
      return state.phase === 'revealing' ? { ...state, phase: 'picking' } : state

    case 'fighter_selected':
      return state.phase === 'picking' ? { ...state, selectedFighterId: action.fighterId, error: null } : state

    case 'pick_started':
      return state.phase === 'picking' && state.selectedFighterId ? { ...state, phase: 'submitting', error: null } : state

    case 'pick_succeeded':
      return {
        ...state,
        draft: action.draft,
        phase: phaseFor(action.draft),
        selectedFighterId: null,
        lastPick: { fighterId: state.selectedFighterId, slot: action.slot },
      }

    case 'request_failed':
      return {
        ...state,
        phase: state.draft ? phaseFor(state.draft) : 'error',
        error: action.message,
      }

    default:
      throw new Error(`Unknown draft action: ${action.type}`)
  }
}

// Selectors read derived values off the state so components don't recompute them.
export function openSlots(state) {
  return state.draft?.slots.filter((slot) => slot.fighter === null) ?? []
}

export function selectedFighter(state) {
  const pool = state.draft?.open_round?.pool ?? []
  return pool.find((fighter) => fighter.id === state.selectedFighterId) ?? null
}
