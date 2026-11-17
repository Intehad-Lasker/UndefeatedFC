"""Plain data objects passed from the parsers to the loader."""

from dataclasses import dataclass
from datetime import date


@dataclass(frozen=True)
class EventSummary:
    ufcstats_id: str
    name: str
    held_on: date
    location: str | None
    url: str


@dataclass(frozen=True)
class FighterResult:
    """One fighter's side of a bout as shown on an event page."""

    ufcstats_id: str
    name: str
    outcome: str  # win, loss, draw or no_contest
    knockdowns: int
    sig_strikes_landed: int
    takedowns_landed: int
    submission_attempts: int


@dataclass(frozen=True)
class BoutRecord:
    ufcstats_id: str
    weight_class_label: str  # as printed, e.g. "Women's Strawweight"
    method_label: str  # as printed, e.g. "U-DEC" or "KO/TKO"
    method_detail: str | None  # second line, e.g. "Punch"
    ending_round: int | None
    ending_time_seconds: int | None
    title_bout: bool
    fighters: tuple[FighterResult, FighterResult]


@dataclass(frozen=True)
class EventDetail:
    ufcstats_id: str
    name: str
    held_on: date
    location: str | None
    bouts: tuple[BoutRecord, ...]


@dataclass(frozen=True)
class FighterProfile:
    ufcstats_id: str
    name: str
    nickname: str | None
    height_cm: int | None
    reach_cm: int | None
    stance: str | None
    born_on: date | None
    wins: int
    losses: int
    draws: int
    no_contests: int
    sig_strikes_landed_per_min: float
    sig_strike_accuracy: float
    sig_strikes_absorbed_per_min: float
    sig_strike_defense: float
    takedowns_per_15_min: float
    takedown_accuracy: float
    takedown_defense: float
    submission_attempts_per_15_min: float
