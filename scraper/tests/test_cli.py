import pytest

from ufc_scraper.cli import build_parser, main


def test_run_requires_a_database_url(monkeypatch, capsys):
    monkeypatch.delenv("DATABASE_URL", raising=False)

    with pytest.raises(SystemExit) as exit_info:
        main(["run"])

    assert exit_info.value.code == 2
    assert "DATABASE_URL" in capsys.readouterr().err


def test_parses_options():
    args = build_parser().parse_args(
        ["run", "--database-url", "postgresql:///x", "--since", "2020-01-01", "--limit", "5"]
    )

    assert args.since.isoformat() == "2020-01-01"
    assert args.limit == 5
    assert args.delay == 1.0


def test_rejects_a_badly_formatted_date():
    with pytest.raises(SystemExit):
        build_parser().parse_args(["run", "--since", "Jan 2020"])


def test_expected_failures_print_one_line_and_exit_1(db, monkeypatch, capsys):
    import os

    import psycopg

    from ufc_scraper.fetcher import FetchError
    from ufc_scraper.pipeline import Pipeline

    def fail(self, **options):
        raise FetchError("giving up on http://www.ufcstats.com after 4 attempts")

    monkeypatch.setattr(Pipeline, "run", fail)
    url = os.environ["TEST_DATABASE_URL"]

    try:
        assert main(["run", "--database-url", url]) == 1
        assert "ufc-scraper: giving up" in capsys.readouterr().err
    finally:
        # main() commits its run row on its own connection, so remove it on another.
        with psycopg.connect(url, autocommit=True) as cleanup:
            cleanup.execute("DELETE FROM ingestion_runs")
