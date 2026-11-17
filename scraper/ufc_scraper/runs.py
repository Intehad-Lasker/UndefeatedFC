"""Records each scraper run in the ingestion_runs table that Rails watches."""

from types import TracebackType

import psycopg

from ufc_scraper.store import LoadCounts

MAX_ERROR_LENGTH = 2000


class RecordedRun:
    """Context manager around one scraper run.

    On entry it inserts a `running` row. On a clean exit it marks the row
    `succeeded` with the load counts; if anything raises (including Ctrl-C) it
    marks it `failed` with the error and lets the exception continue. Rails only
    reacts to succeeded runs, so a half-finished load never triggers a refresh.
    """

    def __init__(
        self, connection: psycopg.Connection, counts: LoadCounts, source: str = "ufcstats"
    ):
        self._conn = connection
        self._counts = counts
        self._source = source
        self.id: int | None = None

    def __enter__(self) -> "RecordedRun":
        self.id = self._conn.execute(
            """
            INSERT INTO ingestion_runs (source, status, started_at, created_at, updated_at)
            VALUES (%s, 'running', now(), now(), now())
            RETURNING id
            """,
            (self._source,),
        ).fetchone()[0]
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc: BaseException | None,
        traceback: TracebackType | None,
    ) -> bool:
        if exc is None:
            status, error = "succeeded", None
        else:
            status, error = "failed", (str(exc) or exc_type.__name__)[:MAX_ERROR_LENGTH]

        self._conn.execute(
            """
            UPDATE ingestion_runs
               SET status = %s, error_message = %s, finished_at = clock_timestamp(),
                   events_count = %s, bouts_count = %s, fighters_count = %s,
                   updated_at = clock_timestamp()
             WHERE id = %s
            """,
            (
                status,
                error,
                self._counts.events,
                self._counts.bouts,
                self._counts.fighters,
                self.id,
            ),
        )
        return False  # never swallow the exception
