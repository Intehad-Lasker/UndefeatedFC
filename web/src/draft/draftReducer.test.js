import { describe, expect, test } from 'vitest'
import { draftReducer, initialState, openSlots, phaseFor, selectedFighter } from './draftReducer.js'

const slot = (key, fighter = null) => ({ key, label: key, fighter, rating: fighter ? 80 : null })
const fresh = { status: 'in_progress', open_round: null, slots: [slot('striking'), slot('power')] }
const spun = { ...fresh, open_round: { number: 1, pool: [{ id: 7, name: 'Ace Ardent' }, { id: 9, name: 'Bea Garrow' }] } }
const picked = { ...fresh, slots: [slot('striking'), slot('power', { id: 7 })] }
const finished = { ...picked, status: 'completed', result: { record: '15-0' } }

const run = (...actions) => actions.reduce(draftReducer, initialState)

describe('phaseFor', () => {
  test('maps a draft to the phase it should open in', () => {
    expect(phaseFor(fresh)).toBe('ready')
    expect(phaseFor(spun)).toBe('picking')
    expect(phaseFor(finished)).toBe('complete')
  })
})

describe('draftReducer', () => {
  test('a full round: spin, reveal, select, pick', () => {
    const states = [
      { type: 'loaded', draft: fresh },
      { type: 'spin_started' },
      { type: 'spin_succeeded', draft: spun },
      { type: 'reveal_finished' },
      { type: 'fighter_selected', fighterId: 7 },
      { type: 'pick_started' },
      { type: 'pick_succeeded', draft: picked, slot: 'power' },
    ].reduce((list, action) => [...list, draftReducer(list.at(-1), action)], [initialState])

    expect(states.map((s) => s.phase)).toEqual([
      'loading', 'ready', 'spinning', 'revealing', 'picking', 'picking', 'submitting', 'ready',
    ])
    expect(states.at(-1).lastPick).toEqual({ fighterId: 7, slot: 'power' })
    expect(states.at(-1).selectedFighterId).toBeNull()
  })

  test('the last pick completes the draft', () => {
    const state = run(
      { type: 'loaded', draft: spun },
      { type: 'fighter_selected', fighterId: 9 },
      { type: 'pick_started' },
      { type: 'pick_succeeded', draft: finished, slot: 'striking' },
    )

    expect(state.phase).toBe('complete')
  })

  test('ignores a spin unless ready, and a pick until a fighter is selected', () => {
    const picking = run({ type: 'loaded', draft: spun })

    expect(draftReducer(picking, { type: 'spin_started' })).toBe(picking)
    expect(draftReducer(picking, { type: 'pick_started' })).toBe(picking)
  })

  test('cannot select a fighter while the wheels are still revealing', () => {
    const revealing = run({ type: 'loaded', draft: fresh }, { type: 'spin_started' }, { type: 'spin_succeeded', draft: spun })

    expect(draftReducer(revealing, { type: 'fighter_selected', fighterId: 7 })).toBe(revealing)
  })

  test('a failed request returns to a stable phase and shows the message', () => {
    const state = run(
      { type: 'loaded', draft: spun },
      { type: 'fighter_selected', fighterId: 7 },
      { type: 'pick_started' },
      { type: 'request_failed', message: 'That fighter did not fight at Lightweight.' },
    )

    expect(state.phase).toBe('picking')
    expect(state.error).toBe('That fighter did not fight at Lightweight.')
  })

  test('a failed first load is an error phase', () => {
    expect(run({ type: 'request_failed', message: 'That draft does not exist.' }).phase).toBe('error')
  })

  test('rejects unknown actions loudly', () => {
    expect(() => draftReducer(initialState, { type: 'teleport' })).toThrow('Unknown draft action: teleport')
  })
})

describe('selectors', () => {
  test('openSlots lists unfilled slots', () => {
    expect(openSlots(run({ type: 'loaded', draft: picked })).map((s) => s.key)).toEqual(['striking'])
  })

  test('selectedFighter finds the chosen pool fighter', () => {
    const state = run({ type: 'loaded', draft: spun }, { type: 'fighter_selected', fighterId: 9 })

    expect(selectedFighter(state).name).toBe('Bea Garrow')
  })
})
