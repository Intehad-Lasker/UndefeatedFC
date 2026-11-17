import { screen, within } from '@testing-library/react'
import { beforeEach, expect, test, vi } from 'vitest'
import { api } from '../api/client.js'
import { stubDefaults } from '../test/apiMock.js'
import { renderRoute } from '../test/renderRoute.jsx'

vi.mock('../api/client.js', async () => (await import('../test/apiMock.js')).apiMock())

const player = { id: 1, email_address: 'one@example.com', display_name: 'FirstPlayer' }

beforeEach(() => {
  vi.resetAllMocks()
})

test('lists the player drafts with their results', async () => {
  stubDefaults(api, { user: player })
  vi.mocked(api.myDrafts).mockResolvedValue({
    drafts: [
      { id: 'a', status: 'in_progress', picks_made: 2, overall: null, record: null, undefeated: false, created_at: '2026-11-17T10:00:00Z' },
      { id: 'b', status: 'completed', picks_made: 6, overall: 91, record: '15-0', undefeated: true, created_at: '2026-11-16T10:00:00Z' },
    ],
  })
  renderRoute('/me/drafts')

  const list = await screen.findByRole('list', { name: 'Your drafts' })
  const links = await within(list).findAllByRole('link')
  expect(links.map((link) => link.getAttribute('href'))).toEqual(['/drafts/a', '/drafts/b'])
  expect(links[0]).toHaveTextContent('In progress · 2 of 6 picks')
  expect(links[1]).toHaveTextContent('15-0 · Undefeated')
  expect(links[1]).toHaveTextContent('91')
})

test('the header links signed-in players to their drafts', async () => {
  stubDefaults(api, { user: player })
  vi.mocked(api.myDrafts).mockResolvedValue({ drafts: [] })
  renderRoute('/')

  expect(await screen.findByRole('link', { name: 'My drafts' })).toHaveAttribute('href', '/me/drafts')
})

test('guests are asked to sign in and nothing is requested', async () => {
  stubDefaults(api)
  renderRoute('/me/drafts')

  expect(await screen.findByText(/to keep your drafts across devices/)).toBeInTheDocument()
  const hrefs = screen.getAllByRole('link', { name: 'Sign in' }).map((link) => link.getAttribute('href'))
  expect(hrefs).toContain('/sign-in?next=/me/drafts')
  expect(api.myDrafts).not.toHaveBeenCalled()
})

test('an empty history suggests starting a draft', async () => {
  stubDefaults(api, { user: player })
  vi.mocked(api.myDrafts).mockResolvedValue({ drafts: [] })
  renderRoute('/me/drafts')

  expect(await screen.findByText(/No drafts yet/)).toBeInTheDocument()
})
