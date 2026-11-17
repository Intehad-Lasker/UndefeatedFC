# ufc-scraper

Loads fight data from [UFCStats](http://www.ufcstats.com) into the UndefeatedFC
Postgres database. The Rails app owns the schema, so run its migrations and seeds
first (`bin/rails db:prepare db:seed` from the repository root).

## Setup

```bash
cd scraper
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

## Usage

```bash
export DATABASE_URL=postgresql:///undefeated_fc_development
ufc-scraper run --limit 5            # the five most recent cards
ufc-scraper run --since 2016-01-01   # everything from 2016 on
ufc-scraper run                      # the full history (slow: one request per second)
```

- Pages are cached in `.cache/ufcstats`, so a re-run only downloads what is new.
  The events list is always re-fetched.
- Every write is an upsert, so an interrupted run can simply be started again.
- Each run is recorded in the `ingestion_runs` table as `succeeded` or `failed`.
  Rails recomputes fighter ratings after a successful run.

## How it fits together

```
Fetcher (rate limit, retries) -> CachedFetcher (disk) -> parsers (HTML -> dataclasses)
  -> normalize (labels -> database names) -> Store (upserts) -> Postgres
```

Parsers are pure functions tested against saved pages in `tests/fixtures`. The
fixtures mirror UFCStats' markup; if the site changes, save a fresh page there
and update the parser.

## Checks

```bash
ruff check .
ruff format --check .
pytest
```

Database tests need a database with the Rails schema. From the repository root:

```bash
RAILS_ENV=test DATABASE_URL=postgresql:///undefeated_fc_scraper_test bin/rails db:create db:schema:load
TEST_DATABASE_URL=postgresql:///undefeated_fc_scraper_test pytest
```

Without `TEST_DATABASE_URL` those tests are skipped.
