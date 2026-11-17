# 0008. Hide ratings until a fighter is picked

- Status: Accepted
- Date: 2026-11-17

## Context

Every fighter has a 0-99 rating per skill. While testing the draft engine, a
script that simply took the highest-rated fighter for any open slot each round
scored an overall of 98, which goes 15-0 roughly half the time. If players can
see ratings, the game reduces to reading numbers.

## Decision

- Pools, search results and fighter profiles show identity, professional
  record, UFC record and career stats, but never ratings.
- A rating is revealed on the draft only once the fighter fills a slot, and it
  is snapshotted at that moment.
- The API enforces this on the server; the frontend has nothing to hide.

## Alternatives considered

- **Show ratings.** Simplest, but removes the decision-making.
- **Show ratings with noise.** Still mostly number-reading, and harder to
  explain.
- **Hide stats too.** Makes it a pure memory game; stats give newer fans a way
  to reason about picks.

## Consequences

- Knowing fighters and reading career stats is the skill the game rewards.
- Blind picking is punished: taking the first fighter in each pool scored 38
  and went 0-15 in a manual run.
- Any new endpoint that returns fighters must keep ratings out; controller
  tests assert it for search results.
