import { afterEach, beforeEach, expect, test, vi } from 'vitest'
import { ApiError, api, resetClientForTests } from './client.js'

function reply(status, body, headers = {}) {
  return Promise.resolve(
    new Response(body === undefined ? null : JSON.stringify(body), {
      status,
      headers: { 'Content-Type': 'application/json', ...headers },
    }),
  )
}

let fetchMock

beforeEach(() => {
  resetClientForTests()
  fetchMock = vi.fn()
  vi.stubGlobal('fetch', fetchMock)
})

afterEach(() => {
  vi.unstubAllGlobals()
  document.cookie = 'CSRF-TOKEN=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/'
})

test('GET requests hit the versioned API and return parsed JSON', async () => {
  fetchMock.mockReturnValueOnce(reply(200, { skills: [] }))

  expect(await api.meta()).toEqual({ skills: [] })
  expect(fetchMock).toHaveBeenCalledWith('/api/v1/meta', expect.objectContaining({ method: 'GET' }))
})

test('writes echo the CSRF token from the last response', async () => {
  fetchMock
    .mockReturnValueOnce(reply(200, {}, { 'X-CSRF-Token': 'token-1' }))
    .mockReturnValueOnce(reply(201, { id: 'abc' }))

  await api.meta()
  await api.createDraft()

  const [, options] = fetchMock.mock.calls[1]
  expect(options.headers['X-CSRF-Token']).toBe('token-1')
})

test('a first write fetches a CSRF token before posting', async () => {
  fetchMock
    .mockReturnValueOnce(reply(200, {}, { 'X-CSRF-Token': 'fresh' }))
    .mockReturnValueOnce(reply(201, { id: 'abc' }))

  await api.createDraft()

  expect(fetchMock.mock.calls.map(([url]) => url)).toEqual(['/api/v1/meta', '/api/v1/drafts'])
  expect(fetchMock.mock.calls[1][1].headers['X-CSRF-Token']).toBe('fresh')
})

test('picks send the fighter and slot as JSON', async () => {
  fetchMock
    .mockReturnValueOnce(reply(200, {}, { 'X-CSRF-Token': 't' }))
    .mockReturnValueOnce(reply(201, {}))

  await api.pick('draft-1', 87, 'power')

  const [url, options] = fetchMock.mock.calls[1]
  expect(url).toBe('/api/v1/drafts/draft-1/picks')
  expect(JSON.parse(options.body)).toEqual({ pick: { fighter_id: 87, slot: 'power' } })
  expect(options.headers['Content-Type']).toBe('application/json')
})

test('search queries are URL-encoded', async () => {
  fetchMock.mockReturnValueOnce(reply(200, { fighters: [] }))

  await api.searchFighters("o'malley & co")

  expect(fetchMock.mock.calls[0][0]).toBe("/api/v1/fighters?q=o'malley%20%26%20co")
})

test('error responses become ApiError with the server message', async () => {
  fetchMock.mockReturnValueOnce(
    reply(422, { error: { code: 'rule_violation', message: 'Pick a fighter before spinning again.' } }),
  )

  const error = await api.getDraft('x').catch((e) => e)

  expect(error).toBeInstanceOf(ApiError)
  expect(error).toMatchObject({ status: 422, code: 'rule_violation', message: 'Pick a fighter before spinning again.' })
})

test('errors without a JSON body still get a readable message', async () => {
  fetchMock.mockReturnValueOnce(Promise.resolve(new Response('Bad gateway', { status: 502 })))

  const error = await api.meta().catch((e) => e)

  expect(error).toMatchObject({ status: 502, code: 'http_error', message: 'Something went wrong (HTTP 502).' })
})

test('prefers the CSRF-TOKEN cookie, which always matches the current session cookie', async () => {
  document.cookie = 'CSRF-TOKEN=from%2Bcookie; path=/'
  fetchMock
    .mockReturnValueOnce(reply(200, {}, { 'X-CSRF-Token': 'from-header' }))
    .mockReturnValueOnce(reply(201, { id: 'abc' }))

  await api.meta()
  await api.createDraft()

  expect(fetchMock.mock.calls[1][1].headers['X-CSRF-Token']).toBe('from+cookie')
})

test('validation errors carry per-field messages', async () => {
  fetchMock
    .mockReturnValueOnce(reply(200, {}, { 'X-CSRF-Token': 't' }))
    .mockReturnValueOnce(
      reply(422, { error: { code: 'validation_failed', message: 'Display name has already been taken', fields: { display_name: ['taken'] } } }),
    )

  const error = await api.signUp({ display_name: 'x' }).catch((e) => e)

  expect(error.fields).toEqual({ display_name: ['taken'] })
})

test('sign out sends a DELETE with the CSRF token', async () => {
  fetchMock
    .mockReturnValueOnce(reply(200, {}, { 'X-CSRF-Token': 'del' }))
    .mockReturnValueOnce(Promise.resolve(new Response(null, { status: 204 })))

  await api.signOut()

  const [url, options] = fetchMock.mock.calls[1]
  expect([url, options.method, options.headers['X-CSRF-Token']]).toEqual(['/api/v1/session', 'DELETE', 'del'])
})
