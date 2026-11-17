import { screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, expect, test, vi } from 'vitest'
import { api } from '../api/client.js'
import { stubDefaults } from '../test/apiMock.js'
import { renderRoute } from '../test/renderRoute.jsx'

vi.mock('../api/client.js', async () => (await import('../test/apiMock.js')).apiMock())

beforeEach(() => {
  vi.resetAllMocks()
  stubDefaults(api)
})

test('explains the game and offers to start a draft', () => {
  renderRoute('/')

  expect(screen.getByRole('heading', { name: 'Build an undefeated fighter.' })).toBeInTheDocument()
  expect(screen.getByRole('button', { name: 'Start a draft' })).toBeEnabled()
})

test('starting a draft opens it', async () => {
  vi.mocked(api.createDraft).mockResolvedValue({ id: 'draft-123' })
  const { router } = renderRoute('/')

  await userEvent.click(screen.getByRole('button', { name: 'Start a draft' }))

  expect(router.state.location.pathname).toBe('/drafts/draft-123')
})

test('shows the server message when a draft cannot be started', async () => {
  vi.mocked(api.createDraft).mockRejectedValue(new Error("You're starting drafts too quickly."))
  renderRoute('/')

  await userEvent.click(screen.getByRole('button', { name: 'Start a draft' }))

  expect(await screen.findByRole('alert')).toHaveTextContent("You're starting drafts too quickly.")
  expect(screen.getByRole('button', { name: 'Start a draft' })).toBeEnabled()
})

test('unknown pages show a way back', () => {
  renderRoute('/nowhere')

  expect(screen.getByRole('heading', { name: 'Nothing here' })).toBeInTheDocument()
  expect(screen.getByRole('link', { name: 'Back to the game' })).toHaveAttribute('href', '/')
})
