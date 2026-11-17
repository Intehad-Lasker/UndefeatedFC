import { screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, expect, test, vi } from 'vitest'
import { api } from '../api/client.js'
import { fighter } from '../test/fixtures.js'
import { stubDefaults } from '../test/apiMock.js'
import { renderRoute } from '../test/renderRoute.jsx'

vi.mock('../api/client.js', async () => (await import('../test/apiMock.js')).apiMock())

beforeEach(() => {
  vi.resetAllMocks()
  stubDefaults(api)
})

test('searching shows matching fighters linked to their profiles', async () => {
  vi.mocked(api.searchFighters).mockResolvedValue({ fighters: [fighter(5, 'Ace Garrow'), fighter(6, 'Bea Garrow')] })
  const { router } = renderRoute('/fighters')

  await userEvent.type(screen.getByLabelText('Search by name or nickname'), 'garow')

  const results = await screen.findByRole('list', { name: 'Search results' })
  expect(await within(results).findAllByRole('link')).toHaveLength(2)
  expect(api.searchFighters).toHaveBeenLastCalledWith('garow')
  expect(router.state.location.search).toBe('?q=garow')
})

test('waits for a pause in typing before searching', async () => {
  vi.mocked(api.searchFighters).mockResolvedValue({ fighters: [] })
  renderRoute('/fighters')

  await userEvent.type(screen.getByLabelText('Search by name or nickname'), 'abc')
  await screen.findByText('No fighters found for “abc”.')

  expect(api.searchFighters).toHaveBeenCalledTimes(1)
})

test('a search in the URL runs on load', async () => {
  vi.mocked(api.searchFighters).mockResolvedValue({ fighters: [fighter(5, 'Ace Garrow')] })
  renderRoute('/fighters?q=ace')

  expect(await screen.findByRole('link', { name: /Ace Garrow/ })).toHaveAttribute('href', '/fighters/5')
})

test('a profile shows draftable pools and recent bouts', async () => {
  vi.mocked(api.getFighter).mockResolvedValue({
    ...fighter(5, 'Ace Garrow'),
    born_on: '1991-02-03',
    pools: [{ weight_class: 'Lightweight', era: 'Modern' }],
    recent_bouts: [
      { event: 'UFC Example', held_on: '2019-05-04', weight_class: 'Lightweight', outcome: 'win', finish: 'ko_tko', ending_round: 2, opponent: { id: 8, name: 'Hugo Rask' } },
    ],
  })
  renderRoute('/fighters/5')

  expect(await screen.findByRole('heading', { name: 'Ace Garrow', level: 1 })).toBeInTheDocument()
  expect(within(screen.getByRole('list', { name: 'Draftable in' })).getByText('Lightweight · Modern')).toBeInTheDocument()
  const row = screen.getByRole('row', { name: /Hugo Rask/ })
  expect(row).toHaveTextContent('W')
  expect(row).toHaveTextContent('KO/TKO (R2)')
  expect(within(row).getByRole('link', { name: 'Hugo Rask' })).toHaveAttribute('href', '/fighters/8')
})

test('an unknown fighter shows the error', async () => {
  vi.mocked(api.getFighter).mockRejectedValue(new Error('That fighter does not exist.'))
  renderRoute('/fighters/0')

  expect(await screen.findByRole('alert')).toHaveTextContent('That fighter does not exist.')
})
