"""Parses http://www.ufcstats.com/statistics/events/completed?page=all."""

from datetime import date

from bs4 import BeautifulSoup

from ufc_scraper.parsers.text import clean, parse_date, ufcstats_id
from ufc_scraper.records import EventSummary


def parse_events_list(html: str, *, today: date) -> list[EventSummary]:
    """Returns every completed event, skipping the upcoming card listed at the top."""
    soup = BeautifulSoup(html, "html.parser")
    events = []

    for row in soup.select("tr.b-statistics__table-row"):
        link = row.select_one('a[href*="/event-details/"]')
        date_span = row.select_one("span.b-statistics__date")
        if link is None or date_span is None:
            continue

        held_on = parse_date(date_span.get_text())
        if held_on > today:
            continue

        cells = row.find_all("td")
        location = clean(cells[1].get_text()) if len(cells) > 1 else ""
        events.append(
            EventSummary(
                ufcstats_id=ufcstats_id(link["href"]),
                name=clean(link.get_text()),
                held_on=held_on,
                location=location or None,
                url=link["href"],
            )
        )

    return events
