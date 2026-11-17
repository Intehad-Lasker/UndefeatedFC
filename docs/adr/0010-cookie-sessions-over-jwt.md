# 0010. Cookie sessions over JWT for player accounts

- Status: Accepted
- Date: 2026-11-17

## Context

Players can play as guests, but accounts let drafts follow them across devices
and (next) put their name on leaderboards. The React app and the API share one
origin (ADR 0009). We need sign-up, sign-in, sign-out and password resets.

## Decision

- **Use Rails 8's authentication generator.** Users with `has_secure_password`,
  a `sessions` table, a signed, HTTP-only, SameSite=Lax session cookie, and
  password resets with signed, expiring tokens. The generated HTML pages are
  kept: the reset email links to them, and admins will sign in through them.
- **One session for both sides.** `Api::V1::BaseController` includes the same
  `Authentication` concern, allows guests by default, and answers
  `require_authentication` with a JSON 401 instead of a redirect.
- **CSRF stays on.** Every API response sets a JS-readable `CSRF-TOKEN` cookie
  (and an `X-CSRF-Token` header for other clients). The React app reads the
  cookie when it writes.
- **Guest drafts are claimed** when a browser signs in, by moving drafts with
  that browser's player id onto the account.

## Alternatives considered

- **JWTs in localStorage.** Common for SPAs, but any XSS can read the token,
  logging out needs a denylist, and tokens can't be revoked server-side. With
  one origin there is no cross-domain problem for JWTs to solve.
- **JWTs in cookies.** Avoids XSS theft, but then CSRF protection is needed
  anyway and revocation is still hard. A sessions table gives both for free.
- **Devise.** Mature and featureful, but far more than this app needs; the
  generator's ~200 lines are code we own and can read.
- **OAuth / social login.** Nice to have; adds providers and secrets before the
  basics exist.

## Consequences

- Sessions can be listed and revoked (a password reset deletes them all).
- Every write must carry the CSRF token. Reading it from a cookie fixed a real
  race: a new browser's first two requests each created a session, and the
  client sometimes kept the token belonging to the session cookie the browser
  had discarded, so the first write got a 403. The cookie arrives with its
  matching session cookie in the same response, so the pair can't disagree.
- Third-party API clients would need a token scheme later; none exist today.
