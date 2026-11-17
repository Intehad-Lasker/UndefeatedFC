# 0004. Load data with a Python scraper that writes to the Rails schema

- Status: Accepted
- Date: 2026-11-17

## Context

Fighter, event and bout data comes from UFCStats, which has no API. Loading it
means fetching thousands of pages politely, parsing HTML, and writing the results
into Postgres. This runs as a batch job (weekly, or on demand), never inside a
web request.

## Decision

Write the scraper in Python (`scraper/`) and have it write directly to the
tables the Rails migrations create.

- **Rails owns the schema.** Migrations are the only place tables change; the
  scraper never runs DDL. CI loads `db/schema.rb` with Rails and runs the
  scraper's tests against it, so a migration that breaks the scraper fails CI.
- **The database is the whole contract.** The scraper writes fighters, events,
  bouts and appearances with upserts keyed on `ufcstats_id`, and records each
  run in `ingestion_runs`. Rails watches that table to know when to recompute
  ratings. Neither side calls the other.
- **Layers inside the scraper are swappable.** `Fetcher` (rate limit, retries),
  `CachedFetcher` (disk) and test doubles all satisfy one `PageSource`
  protocol; parsers are pure functions; `Store` is the only code that touches
  SQL.

## Alternatives considered

- **Ruby with Nokogiri as a Rake task.** One language and Active Record models
  for free. A perfectly good option; Python was chosen because its scraping
  tooling (requests, BeautifulSoup) is the most common choice and because the
  ingestion job is fully decoupled from the web app anyway.
- **Scraper writes JSON files, Rails imports them.** Keeps all writes in Rails
  but adds a file format to version and an extra step to every load.
- **A third-party dataset (CSV dumps).** Faster to start, but goes stale and
  leaves no way to refresh weekly.

## Consequences

- Contributors need Python as well as Ruby to work on ingestion.
- Constraints must live in the database (CHECK, UNIQUE, exclusion), not only in
  model validations, because the scraper writes around Active Record.
- The scraper can be run, retried or rewritten without touching the web app.
