import { screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, expect, test, vi } from 'vitest'
import { ApiError, api } from '../api/client.js'
import { stubDefaults } from '../test/apiMock.js'
import { renderRoute } from '../test/renderRoute.jsx'

vi.mock('../api/client.js', async () => {
  const actual = await vi.importActual('../api/client.js')
  return { ...(await import('../test/apiMock.js')).apiMock(), ApiError: actual.ApiError }
})

const player = { id: 1, email_address: 'one@example.com', display_name: 'FirstPlayer' }

beforeEach(() => {
  vi.resetAllMocks()
  stubDefaults(api)
})

test('signing in shows the player in the header and goes home', async () => {
  vi.mocked(api.signIn).mockResolvedValue({ user: player })
  const { router } = renderRoute('/sign-in')

  await userEvent.type(await screen.findByLabelText('Email address'), 'one@example.com')
  await userEvent.type(screen.getByLabelText('Password'), 'password')
  await userEvent.click(screen.getByRole('button', { name: 'Sign in' }))

  expect(await screen.findByText('FirstPlayer')).toBeInTheDocument()
  expect(api.signIn).toHaveBeenCalledWith('one@example.com', 'password')
  expect(router.state.location.pathname).toBe('/')
})

test('a wrong password shows the server message', async () => {
  vi.mocked(api.signIn).mockRejectedValue(new ApiError(401, 'invalid_credentials', "That email address and password don't match."))
  renderRoute('/sign-in')

  await userEvent.type(await screen.findByLabelText('Email address'), 'one@example.com')
  await userEvent.type(screen.getByLabelText('Password'), 'nope')
  await userEvent.click(screen.getByRole('button', { name: 'Sign in' }))

  expect(await screen.findByRole('alert')).toHaveTextContent("That email address and password don't match.")
})

test('sign-up shows errors next to the fields they belong to', async () => {
  vi.mocked(api.signUp).mockRejectedValue(
    new ApiError(422, 'validation_failed', 'Display name has already been taken', {
      display_name: ['Display name has already been taken'],
    }),
  )
  renderRoute('/sign-up')

  await userEvent.type(await screen.findByLabelText(/Display name/), 'FirstPlayer')
  await userEvent.type(screen.getByLabelText('Email address'), 'x@example.com')
  await userEvent.type(screen.getByLabelText(/Password/), 'long enough password')
  await userEvent.click(screen.getByRole('button', { name: 'Create account' }))

  expect(await screen.findByText('Display name has already been taken')).toHaveClass('field-error')
  expect(api.signUp).toHaveBeenCalledWith({ email_address: 'x@example.com', display_name: 'FirstPlayer', password: 'long enough password' })
})

test('a signed-in player can sign out from the header', async () => {
  stubDefaults(api, { user: player })
  vi.mocked(api.signOut).mockResolvedValue(null)
  renderRoute('/')

  await userEvent.click(await screen.findByRole('button', { name: 'Sign out' }))

  expect(await screen.findByRole('link', { name: 'Sign in' })).toBeInTheDocument()
  expect(api.signOut).toHaveBeenCalled()
})

test('asking for a reset link shows the same confirmation for any address', async () => {
  vi.mocked(api.requestPasswordReset).mockResolvedValue({ message: 'If that address has an account, a reset link is on its way.' })
  renderRoute('/forgot-password')

  await userEvent.type(await screen.findByLabelText('Email address'), 'anyone@example.com')
  await userEvent.click(screen.getByRole('button', { name: 'Email me a reset link' }))

  expect(await screen.findByRole('status')).toHaveTextContent('If that address has an account')
})
