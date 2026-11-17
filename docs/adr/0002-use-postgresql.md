# 0002. Use PostgreSQL

- Status: Accepted
- Date: 2026-11-17

## Context

The data is relational: fighters appear in bouts, bouts belong to events and
weight classes, drafts reference fighters. Two programs write to the database:
the Python scraper (bulk loads) and the Rails app (game state). Game rules need
to hold even under double-clicks and concurrent requests.

## Decision

Use PostgreSQL 16 for all environments, including development (Docker Compose)
and CI (service container).

Postgres features the design relies on:

- **Partial unique indexes**, e.g. "only one unpicked round per draft"
  (`UNIQUE (draft_id) WHERE fighter_id IS NULL`).
- **CHECK constraints** for ranges such as ratings between 0 and 99 and an era's
  start date before its end date.
- **`INSERT ... ON CONFLICT DO UPDATE`** so the scraper can re-run safely.
- **`gen_random_uuid()`** for unguessable draft and match IDs.
- **`pg_trgm`** for fuzzy fighter-name search.
- Proper concurrent writers and row-level locks (`SELECT ... FOR UPDATE`).

## Alternatives considered

- **SQLite (the Rails 8 default).** Excellent for single-process apps, but two
  separate programs writing to one file is the case it is weakest at, and it
  lacks `pg_trgm`.
- **MySQL.** Would work and is proven at large scale. It has no partial
  indexes, and its CHECK constraints and upsert syntax are less expressive.
- **A document store such as MongoDB.** The data is highly relational and the
  game depends on joins and integrity constraints.

## Consequences

- Rules are enforced in the database as well as in Ruby, so races cannot
  corrupt a draft.
- Local development needs a running Postgres server; `compose.yml` makes that
  one command.
- Solid Queue, Solid Cache and Solid Cable all run on Postgres, so there is no
  separate Redis to operate.
