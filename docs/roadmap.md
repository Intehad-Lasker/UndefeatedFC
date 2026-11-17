# Roadmap

Each milestone ships as one pull request. Tags mark playable releases.

## M0 — Project setup
- [x] Rails 8 app on PostgreSQL
- [x] Local Postgres through Docker Compose
- [x] Strict loading to catch N+1 queries early
- [x] CI: RuboCop, Brakeman, bundler-audit, tests
- [x] README with setup steps
- [x] Architecture decision records for the stack

## M1 — Fight data model
- [x] Weight classes and eras as lookup tables
- [x] Fighters, events, bouts and appearances
- [x] Finish and record queries
- [x] Ingestion run tracking
- [x] Synthetic development data

## M2 — Scraper (Python)
- [x] Rate-limited, cached fetcher
- [x] Parsers for events, bouts and fighter profiles
- [x] Idempotent Postgres loader
- [x] Command-line interface and CI

## M3 — Ratings engine
- [ ] Six skills: Striking, Power, Wrestling, Submissions, Defense, Chin
- [ ] Percentile ratings with small-sample shrinkage
- [ ] Background refresh after each ingestion run

## M4 — Draft engine
- [ ] Fighter pools by weight class and era
- [ ] Server-side seeded spins
- [ ] Pick validation with row locking
- [ ] Fight simulation and scoring

## M5 — JSON API
- [ ] Drafts, spins and picks
- [ ] Fighter search and profiles
- [ ] HTTP caching and rate limiting

## M6 — React app (v0.1.0)
- [ ] Spin wheels, fighter pool, slot board, results
- [ ] Fighter search
- [ ] Served by Rails in production

## M7 — Accounts
- [ ] Sign up, sign in, password reset
- [ ] Draft history

## M8 — Daily Challenge (v0.2.0)
- [ ] Same six spins for every player each day
- [ ] One attempt per player per day

## M9 — Leaderboards
- [ ] Daily and all-time leaderboards, cached
- [ ] Live updates over Action Cable

## M10 — Admin (v0.3.0)
- [ ] Data corrections with Hotwire
- [ ] Ingestion history and rating refresh
- [ ] Job dashboard

## M11 — Head-to-head
- [ ] Invite links and live snake drafts
- [ ] Head-to-head fight simulation

## M12 — Ship (v1.0.0)
- [ ] End-to-end browser test
- [ ] Content security policy
- [ ] Deploy configuration
