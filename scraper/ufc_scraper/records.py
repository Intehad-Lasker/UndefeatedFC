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
