"""Command-line entry point: `ufc-scraper run` or `python -m ufc_scraper run`."""

import argparse
import os
import sys
from datetime import date
from pathlib import Path

import psycopg

from ufc_scraper.cache import CachedFetcher
from ufc_scraper.fetcher import DEFAULT_USER_AGENT, Fetcher, FetchError
from ufc_scraper.normalize import UnknownWeightClass
from ufc_scraper.pipeline import EVENTS_URL, Pipeline
from ufc_scraper.runs import RecordedRun
from ufc_scraper.store import MissingReferenceData, Store

# Failures with a clear cause get a one-line message instead of a traceback.
EXPECTED_ERRORS = (FetchError, MissingReferenceData, UnknownWeightClass)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="ufc-scraper", description="Load UFCStats data into the UndefeatedFC database."
    )
    commands = parser.add_subparsers(dest="command", required=True)

    run = commands.add_parser("run", help="scrape UFCStats and load it into Postgres")
    run.add_argument(
        "--database-url",
        default=os.environ.get("DATABASE_URL"),
        help="Postgres URL (default: $DATABASE_URL)",
    )
    run.add_argument("--since", type=date.fromisoformat, help="only events on or after YYYY-MM-DD")
    run.add_argument("--limit", type=int, help="only the N most recent events")
    run.add_argument(
        "--cache-dir",
        type=Path,
        default=Path(".cache/ufcstats"),
        help="where fetched pages are kept (default: .cache/ufcstats)",
    )
    run.add_argument(
        "--delay", type=float, default=1.0, help="seconds between requests (default: 1.0)"
    )
    run.add_argument("--user-agent", default=DEFAULT_USER_AGENT)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if not args.database_url:
        parser.error("set DATABASE_URL or pass --database-url")

    source = CachedFetcher(
        Fetcher(min_interval=args.delay, user_agent=args.user_agent),
        args.cache_dir,
        refresh=lambda url: url == EVENTS_URL,
    )

    # Autocommit: each event is its own transaction inside Store, and the
    # ingestion run row is visible to Rails while the run is in progress.
    try:
        with psycopg.connect(args.database_url, autocommit=True) as connection:
            store = Store(connection)
            with RecordedRun(connection, store.counts):
                pipeline = Pipeline(source, store, today=date.today())
                pipeline.run(since=args.since, limit=args.limit)
    except EXPECTED_ERRORS as error:
        print(f"ufc-scraper: {error}", file=sys.stderr)
        return 1

    counts = store.counts
    print(f"Loaded {counts.events} events, {counts.bouts} bouts, {counts.fighters} fighters.")
    return 0
