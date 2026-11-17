# 0007. Seeded randomness, decided on the server

- Status: Accepted
- Date: 2026-11-17

## Context

Two things in a draft are random: which weight class and era each round lands
on, and the outcome of each simulated fight. If the browser decided either, a
player could pick a favourable pool or replay fights until they went 15-0.
Random results are also hard to test and impossible to reproduce for a bug
report or a shared result.

## Decision

- **The server makes every random choice.** The frontend animates the spin
  wheels, but they land where the API says.
- **Each draft stores a 62-bit seed.** Round N spins with `Random.new(seed + N)`
  and the title run uses `Random.new(seed)`. The same seed and data always give
  the same spins and the same record.
- **Spin eligibility does not depend on picks.** A pool qualifies if it has at
  least 14 fighters (8 choices + 6 possible picks) and has not come up earlier
  in the draft, so a seed alone fixes the sequence of spins. This is what makes
  a shared daily challenge possible later.
- **Generators are injected.** Services accept `rng:` (or a simulator), so
  tests pin outcomes without stubbing `Kernel#rand`.

## Alternatives considered

- **Client-side randomness.** Instant feedback, but trivially cheatable.
- **Unseeded `rand` on the server.** Safe from cheating, but results can't be
  reproduced and tests become probabilistic.
- **Store every spin up front.** Also reproducible, but needs a table of
  pre-rolled spins, and pool eligibility would be frozen at creation time.

## Consequences

- Any finished draft can be replayed exactly from its seed.
- Seeds must stay private while a draft is in progress, or the next spins
  could be predicted. The API never returns them.
- Changing the simulator's constants changes the outcome for existing seeds,
  which is why completed drafts store their fight log rather than re-simulating.
