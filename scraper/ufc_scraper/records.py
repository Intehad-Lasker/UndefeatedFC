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
