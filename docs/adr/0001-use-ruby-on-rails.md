# 0001. Use Ruby on Rails for the web app and API

- Status: Accepted
- Date: 2026-11-17

## Context

UndefeatedFC is a data-heavy web app. It stores relational fight data (fighters,
events, bouts), enforces game rules (one fighter per slot, picks only from the
current pool), and over the roadmap needs background jobs (rating refreshes, a
daily challenge), caching (pools, leaderboards), real-time updates (live
leaderboard, head-to-head drafts), accounts, and an internal admin. It is built
and maintained by one developer, so fewer moving parts matter more than raw speed.

## Decision

Use Rails 8 as a full app (not `--api`): Active Record for data and rules,
Active Job with Solid Queue for jobs, Solid Cache for caching, Action Cable with
Solid Cable for WebSockets, the built-in authentication generator for accounts,
and Hotwire views for internal admin pages. The player-facing UI is a React app
that talks to a versioned JSON API (`/api/v1`).

## Alternatives considered

- **Django.** Closest match: ORM, migrations and a built-in admin. Background
  jobs and WebSockets need Celery, Channels and Redis on top.
- **Express or NestJS with Prisma.** Same language as the frontend, but jobs,
  caching, WebSockets, auth and migrations are each a separate library to choose,
  wire up and keep current.
- **Next.js.** Strong for server-rendered React; the backend pieces above are
  still add-ons.
- **Phoenix (Elixir).** Better at very large numbers of live connections. Smaller
  ecosystem, and this app does not need that scale.

## Consequences

- One framework and one database cover every feature on the roadmap. No Redis.
- Conventions make the codebase predictable: a reviewer knows where models,
  jobs and channels live.
- Ruby is slower than Go or Node for CPU-heavy work. Here most time is spent in
  Postgres, and the fight simulation is a handful of arithmetic operations.
- Rails "magic" can hide control flow. Game rules live in plain service objects
  rather than model callbacks so the flow stays explicit.
