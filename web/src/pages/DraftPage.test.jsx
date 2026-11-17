import { screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, expect, test, vi } from 'vitest'
import { api } from '../api/client.js'
import { resetMetaForTests } from '../api/useMeta.js'
import { draftPicking, draftReady, fighter, meta } from '../test/fixtures.js'
import { renderRoute } from '../test/renderRoute.jsx'

vi.mock('../api/client.js', () => ({ api: { meta: vi.fn(), getDraft: vi.fn(), spin: vi.fn(), pick: vi.fn() } }))

beforeEach(() => {
  vi.resetAllMocks()
  resetMetaForTests()
  vi.mocked(api.meta).mockResolvedValue(meta)
})

test('a new draft offers the first spin', async () => {
  vi.mocked(api.getDraft).mockResolvedValue(draftReady)
  renderRoute('/drafts/d1')

  expect(await screen.findByRole('heading', { name: 'Round 1 of 2' })).toBeInTheDocument()
  expect(screen.getByRole('button', { name: 'Spin' })).toBeEnabled()
  expect(api.getDraft).toHaveBeenCalledWith('d1')
})

test('spinning lands the wheels on the pool the server chose', async () => {
  vi.mocked(api.getDraft).mockResolvedValue(draftReady)
  vi.mocked(api.spin).mockResolvedValue(draftPicking)
  renderRoute('/drafts/d1')

  await userEvent.click(await screen.findByRole('button', { name: 'Spin' }))

  const weightClass = screen.getByLabelText('Weight class')
  const era = screen.getByLabelText('Era')
  expect(await screen.findByText('2 fighters fought at Welterweight in the Modern (2016-2020) era.')).toBeInTheDocument()
  expect(weightClass.querySelector('output')).toHaveTextContent('Welterweight')
  expect(era.querySelector('output')).toHaveTextContent('Modern')
  expect(screen.queryByRole('button', { name: 'Spin' })).not.toBeInTheDocument()
})

test('shows the server message when a spin is refused', async () => {
  vi.mocked(api.getDraft).mockResolvedValue(draftReady)
  vi.mocked(api.spin).mockRejectedValue(new Error('There are no pools left to spin.'))
  renderRoute('/drafts/d1')

  await userEvent.click(await screen.findByRole('button', { name: 'Spin' }))

  expect(await screen.findByRole('alert')).toHaveTextContent('There are no pools left to spin.')
})

test("someone else's draft is read-only", async () => {
  vi.mocked(api.getDraft).mockResolvedValue({ ...draftReady, owned: false })
  renderRoute('/drafts/d1')

  expect(await screen.findByText("You're viewing someone else's draft.")).toBeInTheDocument()
  expect(screen.queryByRole('button', { name: 'Spin' })).not.toBeInTheDocument()
})

test('an unknown draft shows the error', async () => {
  vi.mocked(api.getDraft).mockRejectedValue(new Error('That draft does not exist.'))
  renderRoute('/drafts/nope')

  expect(await screen.findByRole('alert')).toHaveTextContent('That draft does not exist.')
})

test('the open round shows its pool and lets the owner select a fighter', async () => {
  vi.mocked(api.getDraft).mockResolvedValue(draftPicking)
  renderRoute('/drafts/d1')

  const ace = await screen.findByRole('button', { name: /Ace Ardent/ })
  await userEvent.click(ace)

  expect(ace).toHaveAttribute('aria-pressed', 'true')
})

test('picking a fighter into a slot reveals their rating and readies the next spin', async () => {
  const afterPick = {
    ...draftReady,
    rounds: [{ ...draftPicking.open_round, picked: true, slot: 'power', rating: 88, fighter: fighter(7, 'Ace Ardent') }],
    slots: [draftReady.slots[0], { ...draftReady.slots[1], round_number: 1, rating: 88, fighter: fighter(7, 'Ace Ardent') }],
  }
  vi.mocked(api.getDraft).mockResolvedValue(draftPicking)
  vi.mocked(api.pick).mockResolvedValue(afterPick)
  renderRoute('/drafts/d1')

  await userEvent.click(await screen.findByRole('button', { name: /Ace Ardent/ }))
  await userEvent.click(screen.getAllByRole('button', { name: 'Put Ace Ardent here' })[1])

  expect(api.pick).toHaveBeenCalledWith('d1', 7, 'power')
  expect(await screen.findByLabelText('Power rating')).toHaveTextContent('88')
  expect(screen.getByRole('button', { name: 'Spin' })).toBeEnabled()
})

test('a refused pick keeps the pool open and shows why', async () => {
  vi.mocked(api.getDraft).mockResolvedValue(draftPicking)
  vi.mocked(api.pick).mockRejectedValue(new Error('Your Power slot is already filled.'))
  renderRoute('/drafts/d1')

  await userEvent.click(await screen.findByRole('button', { name: /Bea Garrow/ }))
  await userEvent.click(screen.getAllByRole('button', { name: 'Put Bea Garrow here' })[1])

  expect(await screen.findByRole('alert')).toHaveTextContent('Your Power slot is already filled.')
  const pool = screen.getByRole('list', { name: 'Fighters in this pool' })
  expect(within(pool).getByRole('button', { name: /Bea Garrow/ })).toHaveAttribute('aria-pressed', 'true')
})
