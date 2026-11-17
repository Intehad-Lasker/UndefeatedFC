from datetime import date

import pytest

from ufc_scraper.parsers.text import clean, parse_date, ufcstats_id


def test_clean_collapses_whitespace():
    assert clean("\n   UFC 999:   Example \n") == "UFC 999: Example"
    assert clean(None) == ""


def test_ufcstats_id_is_the_last_path_segment():
    assert ufcstats_id("http://www.ufcstats.com/event-details/a1b2c3d4") == "a1b2c3d4"
    assert ufcstats_id("http://www.ufcstats.com/fighter-details/ff00/") == "ff00"


@pytest.mark.parametrize("text", ["April 13, 2024", "Apr 13, 2024", "  April 13, 2024 \n"])
def test_parse_date_accepts_long_and_short_months(text):
    assert parse_date(text) == date(2024, 4, 13)


def test_parse_date_rejects_unknown_formats():
    with pytest.raises(ValueError, match="unrecognised date"):
        parse_date("2024-04-13")
