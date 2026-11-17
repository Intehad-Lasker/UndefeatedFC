# 0009. A React app for players, served by Rails from the same origin

- Status: Accepted
- Date: 2026-11-17

## Context

The draft screen is highly interactive: two animated reels, a sortable and
filterable pool, a slot board that changes as you select, a reveal animation
and a results card, all driven by a handful of API calls. Rails could render it
with Hotwire, or a separate frontend could consume the JSON API.

## Decision

- **Players get a React app** (`web/`, Vite, plain JavaScript). Internal admin
  pages will stay server-rendered Rails views (a later ADR).
- **One origin in every environment.** In production Vite builds into
  `public/app`; `SpaController` returns `index.html` for page routes and the API
  stays under `/api/v1`. In development Vite proxies `/api` to Rails. Cookies,
  SameSite and CSRF therefore behave identically everywhere, and there is no
  CORS configuration.
- **State is a pure reducer** (`draftReducer`) with the server as the source of
  truth; a hook (`useDraft`) turns API responses into reducer actions. No global
  state library.
- **One API client** owns fetch, JSON, the CSRF header and error mapping.
- **Configuration comes from `/api/v1/meta`**, so skills, weight classes and
  eras are never duplicated in JavaScript.

## Alternatives considered

- **Hotwire for everything.** Less code and one language. The reels, pool
  sorting and reveal flow would need a fair amount of Stimulus, and the resume
  goal was a React client on a Rails API.
- **A separately deployed frontend (Vercel + API host).** Independent deploys,
  but two origins means CORS, cross-site cookies and token handling.
- **Redux or React Query.** Useful at a larger scale; one page with one state
  machine does not need them.
- **TypeScript.** Would catch API shape mismatches; a reasonable next step.

## Consequences

- One Docker image serves both the app and the API; CI builds it on every PR.
- Node is needed to build the frontend, and Rails has a catch-all route that
  must skip `/api`, `/rails`, `/admin` and `/cable`.
- Components are tested with Vitest and Testing Library against the real route
  table, with the API client mocked.
