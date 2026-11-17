"""Small helpers every parser needs."""

from datetime import date, datetime
from urllib.parse import urlparse

from bs4 import BeautifulSoup


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


def labelled_items(soup: BeautifulSoup) -> dict[str, str]:
    """Reads UFCStats' "<i>Label:</i> value" list items into {"label": "value"}.

    Event pages use this markup for Date/Location and fighter pages for height,
    reach and career stats. Keys are lowercased with punctuation and spaces
    removed, so "Str. Acc.:" becomes "stracc".
    """
    items = {}
    for item in soup.select("li.b-list__box-list-item"):
        label = item.select_one("i.b-list__box-item-title")
        if label is None:
            continue
        key = "".join(char for char in label.get_text().lower() if char.isalpha())
        items[key] = clean(item.get_text().replace(label.get_text(), "", 1))
    return items
