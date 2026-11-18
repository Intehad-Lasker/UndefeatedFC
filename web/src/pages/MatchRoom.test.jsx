import { act, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, expect, test, vi } from 'vitest'
import { api } from '../api/client.js'
import { resetMetaForTests } from '../api/useMeta.js'
import { stubDefaults } from '../test/apiMock.js'
import { fighter, meta } from '../test/fixtures.js'
import { renderRoute } from '../test/renderRoute.jsx'

vi.mock('../api/client.js', async () => (await import('../test/apiMock.js')).apiMock())
vi.mock('../api/cable.js', () => ({ subscribe: vi.fn(() => () => {}) }))

const slots = (filled = {}) =>
  meta.skills.map((skill) => ({ key: skill.key, label: skill.label, rating: filled[skill.key]?.rating ?? null, fighter: filled[skill.key]?.fighter ?? null }))

const drafting = (overrides = {}) => ({
  id: 'm1', status: 'drafting', your_seat: 1, current_seat: 1, round: 1,
  players: [{ seat: 1, display_name: 'Host' }, { seat: 2, display_name: 'Guest' }],
  pool: { weight_class: { id: 1, name: 'Lightweight' }, era: { id: 10, name: 'Modern', label: 'Modern (2016-2020)' }, fighters: [fighter(7, 'Ace Ardent'), fighter(9, 'Bea Garrow')] },
  boards: [{ seat: 1, slots: slots() }, { seat: 2, slots: slots() }],
  result: null,
  ...overrides,
})

beforeEach(() => {
  vi.resetAllMocks()
  resetMetaForTests()
  stubDefaults(api)
  vi.mocked(api.meta).mockResolvedValue(meta)
})

test('on your turn you pick from the round pool into your board', async () => {
  vi.mocked(api.getMatch).mockResolvedValue(drafting())
  vi.mocked(api.matchPick).mockResolvedValue(drafting({ current_seat: 2, boards: [{ seat: 1, slots: slots({ power: { rating: 81, fighter: fighter(7, 'Ace Ardent') } }) }, { seat: 2, slots: slots() }] }))
  renderRoute('/matches/m1')

  expect(await screen.findByRole('status')).toHaveTextContent('Round 1 of 6 · Your turn')
  expect(screen.getByRole('heading', { name: 'Lightweight · Modern (2016-2020)' })).toBeInTheDocument()
  await userEvent.click(within(screen.getByRole('region', { name: 'Round pool' })).getByRole('button', { name: /Ace Ardent/ }))
  await userEvent.click(screen.getAllByRole('button', { name: 'Put Ace Ardent here' })[1])

  expect(api.matchPick).toHaveBeenCalledWith('m1', 7, 'power')
  expect(await screen.findByRole('status')).toHaveTextContent("Guest's turn")
})

test("on the opponent's turn the pool is locked", async () => {
  vi.mocked(api.getMatch).mockResolvedValue(drafting({ current_seat: 2 }))
  renderRoute('/matches/m1')

  expect(await screen.findByRole('status')).toHaveTextContent("Guest's turn")
  const pool = screen.getByRole('region', { name: 'Round pool' })
  expect(within(pool).getByRole('button', { name: /Ace Ardent/ })).toBeDisabled()
  expect(screen.queryByRole('button', { name: /^Put / })).not.toBeInTheDocument()
})

test('a finished match shows who won and how each round went', async () => {
  vi.mocked(api.getMatch).mockResolvedValue(
    drafting({
      status: 'completed', current_seat: null, round: null, pool: null,
      result: { winner_seat: 1, score: '3-1', overalls: { 1: 84, 2: 79 }, rounds: [1, 2, 3, 4].map((n) => ({ number: n, winner_seat: n === 2 ? 2 : 1, seat_one_chance: 0.7 })) },
    }),
  )
  renderRoute('/matches/m1')

  const result = await screen.findByRole('region', { name: 'Match result' })
  expect(result).toHaveTextContent('You win')
  expect(result).toHaveTextContent('3-1')
  expect(within(result).getAllByRole('listitem')).toHaveLength(4)
})

test('the board locks while a pick is being submitted', async () => {
  let finishPick
  vi.mocked(api.getMatch).mockResolvedValue(drafting())
  vi.mocked(api.matchPick).mockImplementation(() => new Promise((resolve) => (finishPick = resolve)))
  renderRoute('/matches/m1')

  const pool = await screen.findByRole('region', { name: 'Round pool' })
  await userEvent.click(within(pool).getByRole('button', { name: /Ace Ardent/ }))
  await userEvent.click(screen.getAllByRole('button', { name: 'Put Ace Ardent here' })[0])

  expect(within(pool).getByRole('button', { name: /Bea Garrow/ })).toBeDisabled()
  expect(screen.queryByRole('button', { name: /^Put / })).not.toBeInTheDocument()
  await act(async () => finishPick(drafting({ current_seat: 2 })))
  expect(await screen.findByRole('status')).toHaveTextContent("Guest's turn")
})
