from datetime import date

from ufc_scraper.pipeline import EVENTS_URL, Pipeline
from ufc_scraper.store import Store

NEW_EVENT = "http://www.ufcstats.com/event-details/a1b2c3d4e5f60718"
OLD_EVENT = "http://www.ufcstats.com/event-details/0918273645abcdef"


class SavedPages:
    """Serves fixture HTML by URL and records what was requested."""

    def __init__(self, fixture_html):
        event = fixture_html("event_details.html")
        self.pages = {
            EVENTS_URL: fixture_html("events_completed.html"),
            NEW_EVENT: event,
            # The older card reuses the layout with its own bout ids.
            OLD_EVENT: event.replace("fight-details/aa0", "fight-details/bb0"),
        }
        self.fighter_html = fixture_html("fighter_details.html")
        self.requested = []

    def get(self, url):
        self.requested.append(url)
        if "/fighter-details/" in url:
            return self.fighter_html
        return self.pages[url]


def run(db, pages, **options):
    store = Store(db)
    Pipeline(pages, store, today=date(2026, 1, 1), log=lambda _: None).run(**options)
    return store


def count(db, table):
    return db.execute(f"SELECT count(*) FROM {table}").fetchone()[0]


def test_loads_every_completed_event_and_its_fighters(db, fixture_html):
    store = run(db, SavedPages(fixture_html))

    assert count(db, "events") == 2
    assert count(db, "bouts") == 10
    assert store.counts.fighters == 10
    assert db.execute("SELECT count(*) FROM fighters WHERE wins = 26").fetchone()[0] == 10


def test_loads_events_oldest_first(db, fixture_html):
    pages = SavedPages(fixture_html)

    run(db, pages)

    event_urls = [url for url in pages.requested if "/event-details/" in url]
    assert event_urls == [OLD_EVENT, NEW_EVENT]


def test_fetches_each_fighter_profile_once(db, fixture_html):
    pages = SavedPages(fixture_html)

    run(db, pages)

    fighter_urls = [url for url in pages.requested if "/fighter-details/" in url]
    assert len(fighter_urls) == len(set(fighter_urls)) == 10


def test_since_skips_older_events(db, fixture_html):
    run(db, SavedPages(fixture_html), since=date(2020, 1, 1))

    assert [row[0] for row in db.execute("SELECT held_on FROM events")] == [date(2024, 4, 13)]


def test_limit_keeps_the_most_recent_events(db, fixture_html):
    run(db, SavedPages(fixture_html), limit=1)

    assert [row[0] for row in db.execute("SELECT name FROM events")] == [
        "UFC 999: Example vs. Sample"
    ]
