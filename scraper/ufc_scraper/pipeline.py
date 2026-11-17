"""Ties fetching, parsing and loading together for one scraper run."""

from collections.abc import Callable
from datetime import date

from ufc_scraper.fetcher import PageSource
from ufc_scraper.parsers.event_page import parse_event_page
from ufc_scraper.parsers.events_list import parse_events_list
from ufc_scraper.parsers.fighter_page import parse_fighter_page
from ufc_scraper.store import Store

EVENTS_URL = "http://www.ufcstats.com/statistics/events/completed?page=all"
FIGHTER_URL = "http://www.ufcstats.com/fighter-details/{}"


class Pipeline:
    """Loads events oldest-first, then the profile of every fighter on those cards.

    It depends only on a PageSource and a Store, so tests swap in saved pages
    and the CLI swaps in a cached, rate-limited fetcher.
    """

    def __init__(
        self,
        source: PageSource,
        store: Store,
        *,
        today: date,
        log: Callable[[str], None] = print,
    ) -> None:
        self._source = source
        self._store = store
        self._today = today
        self._log = log

    def run(self, *, since: date | None = None, limit: int | None = None) -> None:
        events = parse_events_list(self._source.get(EVENTS_URL), today=self._today)
        events = sorted(
            (event for event in events if since is None or event.held_on >= since),
            key=lambda event: event.held_on,
        )
        if limit is not None:
            events = events[-limit:]  # the most recent `limit` cards

        for number, summary in enumerate(events, start=1):
            self._log(f"[{number}/{len(events)}] {summary.held_on} {summary.name}")
            self._store.save_event(parse_event_page(self._source.get(summary.url), summary.url))

        fighter_ids = sorted(self._store.counts.fighter_ids)
        for number, fighter_id in enumerate(fighter_ids, start=1):
            if number % 50 == 0 or number == len(fighter_ids):
                self._log(f"fighters {number}/{len(fighter_ids)}")
            url = FIGHTER_URL.format(fighter_id)
            self._store.save_fighter(parse_fighter_page(self._source.get(url), url))
