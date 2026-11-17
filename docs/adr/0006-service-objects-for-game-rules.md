# 0006. Service objects for rules that span models

- Status: Accepted
- Date: 2026-11-17

## Context

Spinning, picking and scoring each touch several models (drafts, rounds,
fighters, ratings), must run inside one transaction with a row lock, and have
rules worth testing on their own. Rails offers several places to put that
logic: controllers, model callbacks, model methods, or plain Ruby objects.

## Decision

- **Single-model knowledge stays on the model.** Scopes (`Fighter.in_pool`),
  validations, and state readers (`Draft#open_slots`) live in `app/models`.
- **Multi-model operations are service objects** in `app/services`, one verb
  each: `Drafts::Spinner`, `Drafts::PickRecorder`, `Drafts::Scorer`, plus
  `FightSimulator` and `Ratings::Refresher`. Each has one public `call`.
- **No callbacks for game rules.** A pick does not trigger scoring through an
  `after_update` hook; `PickRecorder` calls `Scorer` explicitly. Reading
  `PickRecorder#call` top to bottom shows everything a pick does.
- **Collaborators are injected with sensible defaults** (`rng:`,
  `pool_sizes:`, `simulator:`, `skills:`), so tests pass deterministic stand-ins
  and production code passes nothing.
- **Rule failures raise `Drafts::RuleViolation`** with a message written for
  players. Controllers map it to one error response.

## Alternatives considered

- **Fat models.** `Draft#pick!` would work, but the pick rules need fighters,
  ratings and pools, so `Draft` would grow to know about all of them.
- **Callbacks.** Concise, but hidden: scoring would happen as a side effect of
  saving a round, and tests of rounds would trigger fight simulations.
- **Logic in controllers.** Untestable without HTTP and impossible to reuse
  from jobs, the console or a future head-to-head mode.

## Consequences

- Each rule has a fast, focused test file; controllers stay a few lines long.
- One more directory to learn, and a naming convention to keep (noun + `call`).
- The same services serve the API, the console, seeds and future features.
