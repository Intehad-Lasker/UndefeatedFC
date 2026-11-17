import { act, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, expect, test, vi } from 'vitest'
import { subscribe } from '../api/cable.js'
import { api } from '../api/client.js'
import { stubDefaults } from '../test/apiMock.js'
import { renderRoute } from '../test/renderRoute.jsx'

vi.mock('../api/client.js', async () => (await import('../test/apiMock.js')).apiMock())
vi.mock('../api/cable.js', () => ({ subscribe: vi.fn() }))

const entry = (rank, name, record, overall) => ({
  rank, draft_id: `d-${name}`, display_name: name, record, overall, undefeated: record === '15-0',
})

let pushUpdate
const unsubscribe = vi.fn()

beforeEach(() => {
  vi.resetAllMocks()
  stubDefaults(api)
  vi.mocked(subscribe).mockImplementation((channel, params, onMessage) => {
    pushUpdate = onMessage
    return unsubscribe
  })
})

const rows = () => within(screen.getByRole('table')).getAllByRole('row').slice(1).map((row) => row.textContent)

test("shows today's standings and subscribes to updates", async () => {
  vi.mocked(api.leaderboard).mockResolvedValue({ day: '2026-11-17', entries: [entry(1, 'Ace', '15-0', 92), entry(2, 'Bea', '12-3', 84)] })
  renderRoute('/leaderboard')

  await screen.findByRole('table')
  expect(rows()).toEqual(['1Ace15-092', '2Bea12-384'])
  expect(api.leaderboard).toHaveBeenCalledWith('daily')
  expect(subscribe).toHaveBeenCalledWith('LeaderboardChannel', { board: 'daily' }, expect.any(Function))
})

test('a live update refetches the board', async () => {
  vi.mocked(api.leaderboard)
    .mockResolvedValueOnce({ day: '2026-11-17', entries: [entry(1, 'Bea', '12-3', 84)] })
    .mockResolvedValueOnce({ day: '2026-11-17', entries: [entry(1, 'Cal', '14-1', 90), entry(2, 'Bea', '12-3', 84)] })
  renderRoute('/leaderboard')
  await screen.findByRole('table')

  await act(async () => pushUpdate({ board: 'daily' }))

  expect(await screen.findByText('Cal')).toBeInTheDocument()
  expect(api.leaderboard).toHaveBeenCalledTimes(2)
})

test('switching to all-time loads that board and drops the old subscription', async () => {
  vi.mocked(api.leaderboard).mockResolvedValue({ day: null, entries: [] })
  const { router } = renderRoute('/leaderboard')
  await screen.findByText('No finished runs yet. Be the first.')

  await userEvent.click(screen.getByRole('tab', { name: 'All-time' }))

  expect(router.state.location.search).toBe('?board=all_time')
  expect(api.leaderboard).toHaveBeenLastCalledWith('all_time')
  expect(unsubscribe).toHaveBeenCalled()
  expect(screen.getByRole('tab', { name: 'All-time' })).toHaveAttribute('aria-selected', 'true')
})
