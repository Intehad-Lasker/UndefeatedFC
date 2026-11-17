from datetime import date

import pytest

from ufc_scraper.parsers.event_page import parse_event_page

URL = "http://www.ufcstats.com/event-details/a1b2c3d4e5f60718"


@pytest.fixture
def event(fixture_html):
    return parse_event_page(fixture_html("event_details.html"), URL)


def test_reads_event_header(event):
    assert event.ufcstats_id == "a1b2c3d4e5f60718"
    assert event.name == "UFC 999: Example vs. Sample"
    assert event.held_on == date(2024, 4, 13)
    assert event.location == "Las Vegas, Nevada, USA"


def test_reads_every_bout(event):
    assert [bout.ufcstats_id for bout in event.bouts] == ["aa01", "aa02", "aa03", "aa04", "aa05"]


def test_first_listed_fighter_is_the_winner(event):
    winner, loser = event.bouts[0].fighters

    assert (winner.name, winner.outcome) == ("Rico Vance", "win")
    assert (loser.name, loser.outcome) == ("Tomas Ferreira", "loss")
    assert winner.ufcstats_id == "f001"


def test_reads_draws_and_no_contests_for_both_fighters(event):
    assert [f.outcome for f in event.bouts[2].fighters] == ["draw", "draw"]
    assert [f.outcome for f in event.bouts[3].fighters] == ["no_contest", "no_contest"]


def test_reads_per_fighter_stats(event):
    winner, loser = event.bouts[1].fighters

    assert (winner.sig_strikes_landed, loser.sig_strikes_landed) == (88, 61)
    assert winner.takedowns_landed == 3
    assert winner.submission_attempts == 1
    assert event.bouts[0].fighters[0].knockdowns == 1


def test_reads_method_round_and_time(event):
    bout = event.bouts[4]

    assert bout.method_label == "SUB"
    assert bout.method_detail == "Rear Naked Choke"
    assert bout.ending_round == 2
    assert bout.ending_time_seconds == 150


def test_decisions_have_no_method_detail(event):
    assert event.bouts[1].method_detail is None


def test_reads_weight_class_and_title_belt(event):
    assert event.bouts[0].weight_class_label == "Light Heavyweight"
    assert event.bouts[0].title_bout is True
    assert event.bouts[1].weight_class_label == "Women's Strawweight"
    assert event.bouts[1].title_bout is False


def test_skips_bouts_without_a_result(fixture_html):
    html = fixture_html("event_details.html").replace(
        '<i class="b-flag__text">win</i>', '<i class="b-flag__text"></i>'
    )

    bouts = parse_event_page(html, URL).bouts

    assert [bout.ufcstats_id for bout in bouts] == ["aa03", "aa04"]
