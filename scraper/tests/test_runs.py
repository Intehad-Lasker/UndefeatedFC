import pytest

from ufc_scraper.runs import RecordedRun
from ufc_scraper.store import LoadCounts


def fetch_run(db, run_id):
    return db.execute(
        "SELECT status, events_count, bouts_count, fighters_count, error_message, "
        "finished_at >= started_at FROM ingestion_runs WHERE id = %s",
        (run_id,),
    ).fetchone()


def test_marks_the_run_running_while_it_is_in_progress(db):
    with RecordedRun(db, LoadCounts()) as run:
        status = db.execute("SELECT status FROM ingestion_runs WHERE id = %s", (run.id,)).fetchone()

    assert status == ("running",)


def test_records_counts_when_the_run_succeeds(db):
    counts = LoadCounts()

    with RecordedRun(db, counts) as run:
        counts.events = 2
        counts.bouts = 11
        counts.fighter_ids.update({"a", "b", "c"})

    assert fetch_run(db, run.id) == ("succeeded", 2, 11, 3, None, True)


def test_records_the_error_and_reraises_when_the_run_fails(db):
    with (
        pytest.raises(RuntimeError, match="ufcstats is down"),
        RecordedRun(db, LoadCounts()) as run,
    ):
        raise RuntimeError("ufcstats is down")

    status, *_, error, _ = fetch_run(db, run.id)
    assert (status, error) == ("failed", "ufcstats is down")


def test_an_interrupted_run_is_marked_failed(db):
    with pytest.raises(KeyboardInterrupt), RecordedRun(db, LoadCounts()) as run:
        raise KeyboardInterrupt

    status, *_, error, _ = fetch_run(db, run.id)
    assert (status, error) == ("failed", "KeyboardInterrupt")
