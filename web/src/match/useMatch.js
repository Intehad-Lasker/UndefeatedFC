import { useCallback, useEffect, useState } from 'react'
import { subscribe } from '../api/cable.js'
import { api } from '../api/client.js'

// Loads a match and keeps it current: MatchChannel nudges on every join or
// pick, and the hook refetches. Actions return the server's updated match.
export function useMatch(matchId) {
  const [state, setState] = useState({ id: null, match: null, error: null })

  const load = useCallback(
    () =>
      api
        .getMatch(matchId)
        .then((match) => setState({ id: matchId, match, error: null }))
        .catch((error) => setState((current) => ({ ...current, id: matchId, error: error.message }))),
    [matchId],
  )

  useEffect(() => {
    load()
    return subscribe('MatchChannel', { id: matchId }, load)
  }, [matchId, load])

  const run = useCallback(async (request) => {
    try {
      const match = await request()
      setState({ id: matchId, match, error: null })
    } catch (error) {
      setState((current) => ({ ...current, error: error.message }))
    }
  }, [matchId])

  const join = useCallback(() => run(() => api.joinMatch(matchId)), [run, matchId])
  const pick = useCallback((fighterId, slot) => run(() => api.matchPick(matchId, fighterId, slot)), [run, matchId])

  return { ...(state.id === matchId ? state : { match: null, error: null }), join, pick }
}
