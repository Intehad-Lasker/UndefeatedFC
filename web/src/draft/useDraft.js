import { useCallback, useEffect, useReducer } from 'react'
import { api } from '../api/client.js'
import { draftReducer, initialState } from './draftReducer.js'

// Connects the draft reducer to the API: loads the draft, then turns player
// actions into requests and the responses into reducer actions.
export function useDraft(draftId) {
  const [state, dispatch] = useReducer(draftReducer, initialState)

  useEffect(() => {
    let active = true
    api
      .getDraft(draftId)
      .then((draft) => active && dispatch({ type: 'loaded', draft }))
      .catch((error) => active && dispatch({ type: 'request_failed', message: error.message }))
    return () => {
      active = false
    }
  }, [draftId])

  const spin = useCallback(async () => {
    dispatch({ type: 'spin_started' })
    try {
      dispatch({ type: 'spin_succeeded', draft: await api.spin(draftId) })
    } catch (error) {
      dispatch({ type: 'request_failed', message: error.message })
    }
  }, [draftId])

  const finishReveal = useCallback(() => dispatch({ type: 'reveal_finished' }), [])
  const selectFighter = useCallback((fighterId) => dispatch({ type: 'fighter_selected', fighterId }), [])

  const pick = useCallback(
    async (slot) => {
      if (!state.selectedFighterId) return
      dispatch({ type: 'pick_started' })
      try {
        const draft = await api.pick(draftId, state.selectedFighterId, slot)
        dispatch({ type: 'pick_succeeded', draft, slot })
      } catch (error) {
        dispatch({ type: 'request_failed', message: error.message })
      }
    },
    [draftId, state.selectedFighterId],
  )

  return { state, spin, finishReveal, selectFighter, pick }
}
