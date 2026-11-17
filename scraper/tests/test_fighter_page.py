from datetime import date

import pytest

from ufc_scraper.parsers.fighter_page import parse_fighter_page

URL = "http://www.ufcstats.com/fighter-details/f001"


@pytest.fixture
def fighter(fixture_html):
    return parse_fighter_page(fixture_html("fighter_details.html"), URL)


def test_reads_identity(fighter):
    assert fighter.ufcstats_id == "f001"
    assert fighter.name == "Rico Vance"
    assert fighter.nickname == "The Metronome"


def test_reads_record_including_no_contests(fighter):
    assert (fighter.wins, fighter.losses, fighter.draws, fighter.no_contests) == (26, 1, 0, 1)


def test_converts_physical_attributes(fighter):
    assert fighter.height_cm == 193
    assert fighter.reach_cm == 201
    assert fighter.stance == "Orthodox"
    assert fighter.born_on == date(1987, 7, 7)


def test_reads_career_stats_with_percentages_as_fractions(fighter):
    assert fighter.sig_strikes_landed_per_min == 5.12
    assert fighter.sig_strike_accuracy == 0.62
    assert fighter.sig_strikes_absorbed_per_min == 3.71
    assert fighter.sig_strike_defense == 0.52
    assert fighter.takedowns_per_15_min == 0.21
    assert fighter.takedown_accuracy == 1.0
    assert fighter.takedown_defense == 0.6
    assert fighter.submission_attempts_per_15_min == 0.2


def test_handles_missing_values(fixture_html):
    html = (
        fixture_html("fighter_details.html")
        .replace("Jul 07, 1987", "--")
        .replace('79"', "--")
        .replace("Orthodox", "")
        .replace("The Metronome", "")
        .replace("Record: 26-1-0 (1 NC)", "Record: 3-0-0")
    )

    fighter = parse_fighter_page(html, URL)

    assert fighter.born_on is None
    assert fighter.reach_cm is None
    assert fighter.stance is None
    assert fighter.nickname is None
    assert (fighter.wins, fighter.no_contests) == (3, 0)
