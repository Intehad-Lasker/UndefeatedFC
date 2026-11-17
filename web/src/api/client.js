// The only module that talks to the Rails API. It sends and parses JSON, keeps
// the latest CSRF token from response headers and echoes it on writes, and
// turns error responses into ApiError carrying the server's message.

const BASE = '/api/v1'
let csrfToken = null

export class ApiError extends Error {
  constructor(status, code, message) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.code = code
  }
}

async function send(method, path, body) {
  const headers = { Accept: 'application/json' }
  if (body !== undefined) headers['Content-Type'] = 'application/json'
  if (method !== 'GET' && csrfToken) headers['X-CSRF-Token'] = csrfToken

  const response = await fetch(`${BASE}${path}`, {
    method,
    headers,
    credentials: 'same-origin',
    body: body === undefined ? undefined : JSON.stringify(body),
  })

  const token = response.headers.get('X-CSRF-Token')
  if (token) csrfToken = token

  const data = response.status === 204 || response.status === 304 ? null : await response.json().catch(() => null)
  if (!response.ok) {
    const error = data?.error
    throw new ApiError(
      response.status,
      error?.code ?? 'http_error',
      error?.message ?? `Something went wrong (HTTP ${response.status}).`,
    )
  }
  return data
}

function get(path) {
  return send('GET', path)
}

// Writes need a CSRF token; fetch one first if this tab has not made a request yet.
async function post(path, body) {
  if (!csrfToken) await get('/meta')
  return send('POST', path, body)
}

export const api = {
  meta: () => get('/meta'),
  createDraft: () => post('/drafts'),
  getDraft: (id) => get(`/drafts/${id}`),
  spin: (draftId) => post(`/drafts/${draftId}/rounds`),
  pick: (draftId, fighterId, slot) => post(`/drafts/${draftId}/picks`, { pick: { fighter_id: fighterId, slot } }),
  searchFighters: (query) => get(`/fighters?q=${encodeURIComponent(query)}`),
  getFighter: (id) => get(`/fighters/${id}`),
}

// Test hook: forget the token between tests.
export function resetClientForTests() {
  csrfToken = null
}
