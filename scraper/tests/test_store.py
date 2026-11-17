from dataclasses import replace

import pytest

from ufc_scraper.parsers.event_page import parse_event_page
from ufc_scraper.parsers.fighter_page import parse_fighter_page
from ufc_scraper.store import MissingReferenceData, Store

EVENT_URL = "http://www.ufcstats.com/event-details/a1b2c3d4e5f60718"
FIGHTER_URL = "http://www.ufcstats.com/fighter-details/f001"


@pytest.fixture
def event(fixture_html):
    return parse_event_page(fixture_html("event_details.html"), EVENT_URL)


def count(db, table):
    return db.execute(f"SELECT count(*) FROM {table}").fetchone()[0]


def test_saves_event_bouts_fighters_and_appearances(db, event):
    store = Store(db)

    store.save_event(event)

    assert count(db, "events") == 1
    assert count(db, "bouts") == 5
    assert count(db, "fighters") == 10
    assert count(db, "appearances") == 10
    assert (store.counts.events, store.counts.bouts, store.counts.fighters) == (1, 5, 10)


def test_saving_the_same_event_twice_does_not_duplicate_rows(db, event):
    store = Store(db)

    store.save_event(event)
    store.save_event(event)

    assert count(db, "bouts") == 5
    assert count(db, "appearances") == 10


def test_stores_normalized_finish_and_raw_method(db, event):
    Store(db).save_event(event)

    rows = dict(db.execute("SELECT ufcstats_id, finish || '|' || finish_detail FROM bouts"))

    assert rows["aa01"] == "ko_tko|KO/TKO Punch"
    assert rows["aa02"] == "decision|U-DEC"
    assert rows["aa04"] == "no_contest|Overturned"
    assert rows["aa05"] == "submission|SUB Rear Naked Choke"


def test_links_bouts_to_seeded_weight_classes(db, event):
    Store(db).save_event(event)

    name = db.execute(
        "SELECT w.name FROM bouts b JOIN weight_classes w ON w.id = b.weight_class_id "
        "WHERE b.ufcstats_id = 'aa02'"
    ).fetchone()[0]

    assert name == "Women's Strawweight"


def test_updates_an_outcome_that_changed(db, event):
    store = Store(db)
    store.save_event(event)
    first = event.bouts[0]
    overturned = replace(
        first,
        method_label="Overturned",
        fighters=tuple(replace(f, outcome="no_contest") for f in first.fighters),
    )

    store.save_event(replace(event, bouts=(overturned,)))

    outcomes = [
        row[0]
        for row in db.execute(
            "SELECT a.outcome FROM appearances a JOIN bouts b ON b.id = a.bout_id "
            "WHERE b.ufcstats_id = 'aa01'"
        )
    ]
    assert outcomes == ["no_contest", "no_contest"]


def test_fighter_profile_fills_in_the_placeholder_from_the_event(db, event, fixture_html):
    store = Store(db)
    store.save_event(event)

    store.save_fighter(parse_fighter_page(fixture_html("fighter_details.html"), FIGHTER_URL))

    row = db.execute(
        "SELECT wins, reach_cm, sig_strike_accuracy FROM fighters WHERE ufcstats_id = 'f001'"
    ).fetchone()
    assert (row[0], row[1], float(row[2])) == (26, 201, 0.62)
    assert count(db, "fighters") == 10


def test_a_missing_weight_class_explains_how_to_fix_it(db, event):
    db.execute("DELETE FROM weight_classes WHERE name = 'Catch Weight'")

    with pytest.raises(MissingReferenceData, match="db:seed"):
        Store(db).save_event(event)


def test_a_failed_event_leaves_no_partial_rows(db, event):
    db.execute("DELETE FROM weight_classes WHERE name = 'Catch Weight'")

    with pytest.raises(MissingReferenceData):
        Store(db).save_event(event)

    assert count(db, "bouts") == 0


def lock(db, ufcstats_id, name):
    db.execute(
        "INSERT INTO fighters (ufcstats_id, name, locked, created_at, updated_at) "
        "VALUES (%s, %s, true, now(), now())",
        (ufcstats_id, name),
    )


def test_a_locked_fighter_keeps_its_corrections(db, fixture_html):
    lock(db, "f001", "Rico Vance (corrected)")

    Store(db).save_fighter(parse_fighter_page(fixture_html("fighter_details.html"), FIGHTER_URL))

    row = db.execute("SELECT name, wins FROM fighters WHERE ufcstats_id = 'f001'").fetchone()
    assert row == ("Rico Vance (corrected)", 0)


def test_events_still_load_bouts_for_locked_fighters(db, event):
    lock(db, "f001", "Rico Vance (corrected)")

    Store(db).save_event(event)

    name = db.execute("SELECT name FROM fighters WHERE ufcstats_id = 'f001'").fetchone()[0]
    assert name == "Rico Vance (corrected)"
    assert count(db, "appearances") == 10
