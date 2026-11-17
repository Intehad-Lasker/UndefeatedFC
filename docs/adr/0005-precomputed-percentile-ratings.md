# 0005. Precompute skill ratings as percentiles

- Status: Accepted
- Date: 2026-11-17

## Context

Each draft slot (Striking, Power, Wrestling, Submissions, Defense, Chin) needs a
0-99 rating per fighter. The inputs are on different scales (strikes per
minute, percentages, finish rates), many fighters have only a handful of UFC
fights, and ratings are read on every spin and every pick but only change when
new fight data arrives (about weekly).

## Decision

1. **One class per skill** (`Skills::Striking`, ...) turns a fighter into a raw
   number where higher is better. `Skills::ALL` is the only list of slots.

   | Skill | Raw score |
   |---|---|
   | Striking | strikes landed/min x (0.5 + accuracy) |
   | Power | KO wins / wins + 0.5 x knockdowns per fight |
   | Wrestling | takedowns/15 min x (0.5 + accuracy) + 3 x takedown defense |
   | Submissions | submission attempts/15 min + 3 x submission wins / wins |
   | Defense | 10 x strike defense - strikes absorbed/min |
   | Chin | 1 - KO losses / UFC fights |

2. **Shrink small samples toward the average** before ranking:
   `(fights x raw + 5 x mean) / (fights + 5)`. A fighter's own numbers dominate
   after a few fights, but one knockout in one fight does not make a 99.
3. **Rank into percentiles** (0 = lowest, 99 = highest, ties share a value).
   Ranking makes every skill comparable regardless of its raw scale, and an
   outlier cannot compress everyone else into a narrow band.
4. **Store the results** in `fighter_ratings` (one row per fighter per skill)
   and recompute them in a background job after each successful scraper run.

## Alternatives considered

- **Compute ratings per request.** Percentiles need every fighter's score, so
  each request would rescore the whole roster. Wasted work for data that
  changes weekly.
- **Min-max scaling to 0-99.** Simple, but one extreme fighter squeezes
  everyone else together.
- **A column per skill on `fighters`.** Fewer rows, but each new skill needs a
  migration. Rows keep the open/closed property of the skill classes.
- **Hand-tuned ratings.** Not reproducible and impossible to keep current.

## Consequences

- Adding a skill is one class, one registry line and a refresh; no migration,
  scorer change or frontend change (the API will expose the registry).
- Ratings are relative: adding many strong fighters lowers everyone else's
  percentile. That is the intended meaning ("better than X% of fighters").
- Ratings use career averages, so a fighter's rating is the same in every era
  they fought in. Per-era ratings from per-fight data are a possible extension.
