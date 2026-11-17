# 0011. Solid Queue, Solid Cache and Solid Cable instead of Redis

- Status: Accepted
- Date: 2026-11-17

## Context

The app now needs three kinds of infrastructure besides the database:

- **Background jobs:** rating refreshes after each scrape, the nightly daily
  challenge, leaderboard broadcasts.
- **A cache:** leaderboard rankings, plus the store behind rate limits.
- **WebSocket fan-out:** live leaderboard updates over Action Cable.

The classic Rails answer is Redis (with Sidekiq), which means a second
datastore to run, back up, secure and monitor.

## Decision

Use Rails 8's database-backed defaults, all on PostgreSQL:

| Need | Library | Where it shows up |
|---|---|---|
| Jobs and schedules | Solid Queue | `RatingsRefreshJob`, `ProcessIngestionRunsJob` (every 10 min), `CreateDailyChallengeJob` (23:50 daily), `LeaderboardBroadcastJob`; `limits_concurrency` stops overlapping refreshes |
| Cache | Solid Cache | Leaderboard rankings keyed on the board's version; `rate_limit` counters |
| WebSockets | Solid Cable | `LeaderboardChannel` |

Production gives each its own database (queue, cache, cable) in the same
Postgres server, as `config/database.yml` sets up.

Two details keep this correct:

- **Broadcast after commit.** The scorer enqueues the broadcast inside
  `ActiveRecord.after_all_transactions_commit`, so a pick that rolls back is
  never announced.
- **The message is only a nudge.** The channel says *which* board changed;
  clients refetch it from the cached endpoint, so rankings have one source of
  truth and a missed message costs nothing.

## Alternatives considered

- **Redis + Sidekiq + Redis-backed cache and cable.** Faster at very high
  volume and battle-tested. It is another service with its own memory limits
  and persistence settings, for load this app does not have.
- **Postgres LISTEN/NOTIFY for cable.** Built into the database, but payloads
  are capped at 8 KB and there is no message history.
- **Cron + rake tasks for schedules.** Needs host-level cron and gives no
  retries, concurrency control or visibility.

## Consequences

- One datastore to operate; backups and monitoring cover everything.
- Solid Cable polls (every 100 ms here), so real-time latency is slightly
  higher than Redis pub/sub, unnoticeable for a leaderboard.
- If load grows, any one piece can move to Redis by changing an adapter in
  config; the application code does not change.
