import { act, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, expect, test, vi } from 'vitest'
import { subscribe } from '../api/cable.js'
import { api } from '../api/client.js'
import { stubDefaults } from '../test/apiMock.js'
import { renderRoute } from '../test/renderRoute.jsx'

vi.mock('../api/client.js', async () => (await import('../test/apiMock.js')).apiMock())
vi.mock('../api/cable.js', () => ({ subscribe: vi.fn() }))

const players = [{ seat: 1, display_name: 'Host' }]
const waiting = (yourSeat) => ({ id: 'm1', status: 'waiting', your_seat: yourSeat, current_seat: null, players, pool: null, boards: [], result: null })

let nudge
beforeEach(() => {
  vi.resetAllMocks()
  stubDefaults(api)
  vi.mocked(subscribe).mockImplementation((channel, params, onMessage) => {
    nudge = onMessage
    return () => {}
  })
})

test('challenging a friend creates a match and opens its page', async () => {
  vi.mocked(api.createMatch).mockResolvedValue({ id: 'm1' })
  const { router } = renderRoute('/')

  await userEvent.click(await screen.findByRole('button', { name: 'Challenge a friend' }))

  expect(router.state.location.pathname).toBe('/matches/m1')
})

test('the host sees the invite link while waiting', async () => {
  vi.mocked(api.getMatch).mockResolvedValue(waiting(1))
  renderRoute('/matches/m1')

  expect(await screen.findByRole('status')).toHaveTextContent('Waiting for an opponent')
  expect(screen.getByRole('button', { name: 'Copy invite link' })).toBeInTheDocument()
  expect(subscribe).toHaveBeenCalledWith('MatchChannel', { id: 'm1' }, expect.any(Function))
})

test('a visitor with the link can join', async () => {
  vi.mocked(api.getMatch).mockResolvedValue(waiting(null))
  vi.mocked(api.joinMatch).mockResolvedValue({ ...waiting(2), status: 'drafting', players: [...players, { seat: 2, display_name: 'Guest' }] })
  renderRoute('/matches/m1')

  expect(await screen.findByText(/challenged you to a draft/)).toHaveTextContent('Host challenged you')
  await userEvent.click(screen.getByRole('button', { name: 'Join the match' }))

  expect(api.joinMatch).toHaveBeenCalledWith('m1')
  expect(await screen.findByText('Host vs. Guest')).toBeInTheDocument()
})

test("the host's page moves on when the opponent joins", async () => {
  vi.mocked(api.getMatch)
    .mockResolvedValueOnce(waiting(1))
    .mockResolvedValueOnce({ ...waiting(1), status: 'drafting', players: [...players, { seat: 2, display_name: 'Guest' }] })
  renderRoute('/matches/m1')
  await screen.findByRole('status')

  await act(async () => nudge({ match_id: 'm1' }))

  expect(await screen.findByText('Host vs. Guest')).toBeInTheDocument()
})
