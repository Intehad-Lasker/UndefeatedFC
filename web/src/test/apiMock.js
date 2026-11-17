import { vi } from 'vitest'

// One mock of the API client for every page test. Use it from vi.mock:
//   vi.mock('../api/client.js', async () => (await import('../test/apiMock.js')).apiMock())
export const API_METHODS = [
  'meta', 'createDraft', 'getDraft', 'spin', 'pick', 'searchFighters', 'getFighter',
  'currentSession', 'signIn', 'signUp', 'signOut', 'requestPasswordReset', 'myDrafts',
  'dailyChallenge', 'startDailyChallenge',
]

export function apiMock() {
  return { api: Object.fromEntries(API_METHODS.map((method) => [method, vi.fn()])) }
}

// Calls every page makes on load: nobody signed in, plus the given overrides.
export function stubDefaults(api, { user = null, dailyChallenge = { day: '2026-11-17', attempt: null } } = {}) {
  vi.mocked(api.currentSession).mockResolvedValue({ user })
  vi.mocked(api.dailyChallenge).mockResolvedValue(dailyChallenge)
}
