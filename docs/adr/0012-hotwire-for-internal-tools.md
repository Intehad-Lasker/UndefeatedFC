# 0012. Server-rendered Rails with Hotwire for internal tools

- Status: Accepted
- Date: 2026-11-17

## Context

Real scraped data needs care: a misspelled nickname, a division that should
not be spinnable, era boundaries to adjust, failed scraper runs to inspect, and
background jobs to watch. A handful of trusted people need these tools; players
never see them.

## Decision

Build `/admin` as ordinary Rails controllers and ERB views, enhanced with
Hotwire, separate from the player-facing React app (ADR 0009).

- **Same sign-in, stricter gate.** `Admin::BaseController` uses the generated
  session pages and returns 403 unless `users.admin` is true
  (`bin/rails admin:grant[email]`).
- **Turbo Frames for inline editing.** Each fighter row is a frame; Edit swaps
  in a form and Save swaps the row back with no page reload and no custom
  JavaScript.
- **Corrections survive re-scrapes.** Editing marks a fighter `locked`, and the
  scraper's upserts skip locked rows (`ON CONFLICT ... DO UPDATE ... WHERE NOT
  locked`).
- **Mission Control for jobs.** The official Solid Queue dashboard is mounted
  at `/admin/jobs`, inheriting `Admin::BaseController` rather than using HTTP
  basic auth.

## Alternatives considered

- **Build admin screens in React.** A second set of API endpoints, forms and
  state for a few internal users.
- **ActiveAdmin / Avo / Administrate.** Fast to start, but generic screens, a
  large dependency, and the custom parts (locking, refresh button) fight the
  framework.
- **Rails console only.** Fine for engineers; error-prone for routine fixes
  and leaves no audit trail of what changed.

## Consequences

- The admin is a few hundred lines of plain Rails with integration tests.
- Two UI stacks in one repo: React for players, ERB and Turbo for staff. Each
  is the cheapest tool for its audience.
- Mission Control works where Solid Queue runs jobs (production); development
  runs jobs in-process and hides the link.
