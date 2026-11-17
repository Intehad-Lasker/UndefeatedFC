"""Parses an event page, e.g. http://www.ufcstats.com/event-details/<id>."""

from bs4 import BeautifulSoup, Tag

from ufc_scraper.parsers.text import clean, parse_date, ufcstats_id
from ufc_scraper.records import BoutRecord, EventDetail, FighterResult

# Columns of the fight table, left to right.
RESULT, FIGHTERS, KNOCKDOWNS, STRIKES, TAKEDOWNS, SUBMISSIONS, WEIGHT_CLASS, METHOD, ROUND, TIME = (
    range(10)
)

# What the W/L flags in the first column mean for (first fighter, second fighter).
OUTCOMES = {
    ("win",): ("win", "loss"),
    ("draw", "draw"): ("draw", "draw"),
    ("nc", "nc"): ("no_contest", "no_contest"),
}


def parse_event_page(html: str, url: str) -> EventDetail:
    soup = BeautifulSoup(html, "html.parser")
    details = _labelled_items(soup)

    return EventDetail(
        ufcstats_id=ufcstats_id(url),
        name=clean(soup.select_one("span.b-content__title-highlight").get_text()),
        held_on=parse_date(details["date"]),
        location=details.get("location") or None,
        bouts=tuple(
            bout
            for row in soup.select("tr.b-fight-details__table-row[data-link]")
            if (bout := _parse_bout(row)) is not None
        ),
    )


def _labelled_items(soup: BeautifulSoup) -> dict[str, str]:
    """Reads "Date: April 13, 2024" style list items into {"date": "April 13, 2024"}."""
    items = {}
    for item in soup.select("li.b-list__box-list-item"):
        label = item.select_one("i.b-list__box-item-title")
        if label is None:
            continue
        key = clean(label.get_text()).rstrip(":").lower()
        items[key] = clean(item.get_text().replace(label.get_text(), "", 1))
    return items


def _parse_bout(row: Tag) -> BoutRecord | None:
    cells = row.find_all("td", recursive=False)
    flags = tuple(clean(flag.get_text()).lower() for flag in cells[RESULT].select(".b-flag__text"))
    outcomes = OUTCOMES.get(flags)
    if outcomes is None:
        return None  # result not published yet

    links = cells[FIGHTERS].select('a[href*="/fighter-details/"]')
    fighters = tuple(
        FighterResult(
            ufcstats_id=ufcstats_id(link["href"]),
            name=clean(link.get_text()),
            outcome=outcome,
            knockdowns=_count(cells[KNOCKDOWNS], index),
            sig_strikes_landed=_count(cells[STRIKES], index),
            takedowns_landed=_count(cells[TAKEDOWNS], index),
            submission_attempts=_count(cells[SUBMISSIONS], index),
        )
        for index, (link, outcome) in enumerate(zip(links, outcomes, strict=True))
    )

    method_lines = _lines(cells[METHOD])
    return BoutRecord(
        ufcstats_id=ufcstats_id(row["data-link"]),
        weight_class_label=_lines(cells[WEIGHT_CLASS])[0],
        method_label=method_lines[0],
        method_detail=method_lines[1] if len(method_lines) > 1 else None,
        ending_round=_int_or_none(_lines(cells[ROUND])[0]),
        ending_time_seconds=_seconds(_lines(cells[TIME])[0]),
        title_bout=cells[WEIGHT_CLASS].select_one('img[src*="belt"]') is not None,
        fighters=fighters,
    )


def _lines(cell: Tag) -> list[str]:
    return [text for p in cell.select("p") if (text := clean(p.get_text()))]


def _count(cell: Tag, index: int) -> int:
    """The value for the first (index 0) or second (index 1) fighter; 0 if missing."""
    values = _lines(cell)
    if index >= len(values):
        return 0
    return _int_or_none(values[index]) or 0


def _int_or_none(text: str) -> int | None:
    return int(text) if text.isdigit() else None


def _seconds(text: str) -> int | None:
    minutes, _, seconds = text.partition(":")
    if not (minutes.isdigit() and seconds.isdigit()):
        return None
    return int(minutes) * 60 + int(seconds)
