# UndefeatedFC

A UFC fighter-draft game. Each round you spin a weight class and an era, draft one
fighter from that pool into a skill slot (Striking, Power, Wrestling, Submissions,
Defense, Chin), and after six rounds your build fights a simulated 15-fight title run.
The goal is to go 15-0.

## Stack

| Part | Tech |
|---|---|
| Web app and JSON API | Ruby on Rails 8.1, Ruby 3.3 |
| Database | PostgreSQL 16 |
| Background jobs, cache, WebSockets | Solid Queue, Solid Cache, Solid Cable (all on Postgres) |
| Player-facing UI | React (Vite) |
| Data ingestion | Python scraper for UFCStats |

## Getting started

### Prerequisites

- Ruby 3.3.6 (see `.ruby-version`)
- Node 22 (for the React app in `web/`)
- PostgreSQL 16, either installed locally or through Docker

### Database

Use a local Postgres through its Unix socket, or start the bundled container:

```bash
docker compose up -d
export DB_HOST=localhost DB_USER=postgres DB_PASSWORD=postgres
```

### Setup and run

```bash
bin/setup
```

`bin/setup` installs gems, prepares the database and starts the server at
http://localhost:3000. Use `bin/setup --skip-server` to only prepare.

### Play locally

Run Rails and the Vite dev server side by side, then open http://localhost:5173:

```bash
bin/rails server
cd web && npm install && npm run dev
```

Vite proxies `/api` to Rails, so the browser sees a single origin, as it does in
production, where Rails serves the built app (`cd web && npm run build`).

In development, `bin/rails db:seed` also creates invented fighters and bouts so
the game is playable before the scraper has run. To load real data instead, start
from an empty fighters table and follow [scraper/README.md](scraper/README.md). See
[docs/data-model.md](docs/data-model.md) for the schema.

## Admin

`/admin` is for staff: fix fighter details inline (corrections are locked
against re-scrapes), choose which divisions can be spun, adjust eras, review
scraper runs, recalculate ratings, and (in production) watch jobs in Mission
Control. Promote an account with:

```bash
bin/rails admin:grant[you@example.com]
```

## API

The game is served as a JSON API under `/api/v1`: meta, drafts, spins, picks
and fighter search. See [docs/api.md](docs/api.md).

## Tests and checks

```bash
bin/rails test        # unit, model and request tests
bin/rubocop           # style
bin/brakeman          # security static analysis
bin/ci                # everything CI runs, locally
cd web && npm test    # React components and the draft reducer
```

CI runs the same checks on every pull request (`.github/workflows/ci.yml`).

## Repository layout

```
app/, config/, db/, test/   Rails application
web/                        React app for players (see web/README.md)
scraper/                    Python package that loads UFCStats data (see scraper/README.md)
docs/                       roadmap, data model, API reference and architecture decision records (ADRs)
```
