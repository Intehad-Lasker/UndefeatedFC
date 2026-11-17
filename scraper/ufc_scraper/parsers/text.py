"""Small helpers every parser needs."""

from datetime import date, datetime
from urllib.parse import urlparse


def clean(text: str | None) -> str:
    """Collapses the whitespace UFCStats pads its cells with."""
    return " ".join((text or "").split())


def ufcstats_id(url: str) -> str:
    """The stable id at the end of a UFCStats URL, e.g. .../event-details/<id>."""
    return urlparse(url).path.rstrip("/").rsplit("/", 1)[-1]


def parse_date(text: str) -> date:
    """Parses both "April 13, 2024" and "Apr 13, 2024"."""
    value = clean(text)
    for pattern in ("%B %d, %Y", "%b %d, %Y"):
        try:
            return datetime.strptime(value, pattern).date()
        except ValueError:
            continue
    raise ValueError(f"unrecognised date: {text!r}")
