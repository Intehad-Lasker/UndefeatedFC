# 0003. One repository with Rails at the root

- Status: Accepted
- Date: 2026-11-17

## Context

The project has three parts: the Rails app (game rules, JSON API, admin), a
React frontend for players, and a Python scraper that loads fight data. A single
feature often touches more than one part, for example a new skill changes the
ratings code, the API and the UI.

## Decision

Keep everything in one repository:

```
/            Rails app (owns the database schema)
web/         React app built with Vite
scraper/     Python package that loads UFCStats data
docs/        roadmap and ADRs
```

Rails sits at the root because it is the core of the product: it owns the
schema, the rules and the API. The frontend and scraper depend on it, not the
other way around.

## Alternatives considered

- **Three repositories.** Independent release cycles, but a cross-cutting change
  becomes three coordinated pull requests and the schema contract can drift.
- **Rails in an `api/` subfolder.** Symmetrical, but every Rails command needs a
  `cd`, and it suggests Rails is one peer among three rather than the core.

## Consequences

- One pull request can change the schema, the API and the UI together, and CI
  checks all of them.
- CI jobs are split per part so a frontend change does not wait on Python tests.
- Contributors need Ruby, Node and Python installed to work on everything.
