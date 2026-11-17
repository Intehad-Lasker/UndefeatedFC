import { screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, expect, test, vi } from 'vitest'
import { api } from '../api/client.js'
import { stubDefaults } from '../test/apiMock.js'
import { renderRoute } from '../test/renderRoute.jsx'

vi.mock('../api/client.js', async () => (await import('../test/apiMock.js')).apiMock())

beforeEach(() => {
  vi.resetAllMocks()
})

const card = async () => screen.findByRole('complementary', { name: 'Daily challenge' })

test('offers today’s challenge when the player has not tried it', async () => {
  stubDefaults(api)
  vi.mocked(api.startDailyChallenge).mockResolvedValue({ id: 'dc1' })
  const { router } = renderRoute('/')

  const daily = await card()
  expect(daily).toHaveTextContent('Daily challenge · Tuesday, November 17')
  await userEvent.click(within(daily).getByRole('button', { name: "Play today's challenge" }))

  expect(router.state.location.pathname).toBe('/drafts/dc1')
})

test('an unfinished attempt can be continued', async () => {
  stubDefaults(api, { dailyChallenge: { day: '2026-11-17', attempt: { id: 'dc1', status: 'in_progress' } } })
  renderRoute('/')

  expect(within(await card()).getByRole('link', { name: 'Continue your attempt' })).toHaveAttribute('href', '/drafts/dc1')
})

test('a finished attempt shows its record instead of another try', async () => {
  stubDefaults(api, {
    dailyChallenge: { day: '2026-11-17', attempt: { id: 'dc1', status: 'completed', record: '15-0', undefeated: true } },
  })
  renderRoute('/')

  const daily = await card()
  expect(daily).toHaveTextContent('You went 15-0, undefeated!')
  expect(within(daily).queryByRole('button')).not.toBeInTheDocument()
})
