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

In development, `bin/rails db:seed` also creates invented fighters and bouts so
the game is playable before the scraper has run. See
[docs/data-model.md](docs/data-model.md) for the schema.

## Tests and checks

```bash
bin/rails test        # unit, model and request tests
bin/rubocop           # style
bin/brakeman          # security static analysis
bin/ci                # everything CI runs, locally
```

CI runs the same checks on every pull request (`.github/workflows/ci.yml`).

## Repository layout

```
app/, config/, db/, test/   Rails application
docs/                       roadmap, data model and architecture decision records (ADRs)
```
