from datetime import date

from ufc_scraper.parsers.events_list import parse_events_list


def test_parses_each_completed_event(fixture_html):
    events = parse_events_list(fixture_html("events_completed.html"), today=date(2026, 1, 1))

    assert [event.name for event in events] == [
        "UFC 999: Example vs. Sample",
        "UFC Fight Night: Test vs. Fixture",
    ]


def test_reads_id_date_location_and_url(fixture_html):
    event = parse_events_list(fixture_html("events_completed.html"), today=date(2026, 1, 1))[0]

    assert event.ufcstats_id == "a1b2c3d4e5f60718"
    assert event.held_on == date(2024, 4, 13)
    assert event.location == "Las Vegas, Nevada, USA"
    assert event.url == "http://www.ufcstats.com/event-details/a1b2c3d4e5f60718"


def test_skips_the_upcoming_event(fixture_html):
    events = parse_events_list(fixture_html("events_completed.html"), today=date(2026, 1, 1))

    assert "UFC Fight Night: Upcoming Card" not in [event.name for event in events]


def test_returns_nothing_for_an_empty_page():
    assert parse_events_list("<html></html>", today=date(2026, 1, 1)) == []
