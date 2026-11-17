"""Writes parsed records into the Rails-owned schema.

Every write is an upsert keyed on ufcstats_id (or bout + fighter for
appearances), so loading the same page twice updates rows instead of
duplicating them, and a crashed run can simply be started again.
"""

from dataclasses import dataclass, field

import psycopg

from ufc_scraper.normalize import normalize_finish, normalize_weight_class
from ufc_scraper.records import BoutRecord, EventDetail, FighterProfile, FighterResult

PROFILE_COLUMNS = (
    "name",
    "nickname",
    "height_cm",
    "reach_cm",
    "stance",
    "born_on",
    "wins",
    "losses",
    "draws",
    "no_contests",
    "sig_strikes_landed_per_min",
    "sig_strike_accuracy",
    "sig_strikes_absorbed_per_min",
    "sig_strike_defense",
    "takedowns_per_15_min",
    "takedown_accuracy",
    "takedown_defense",
    "submission_attempts_per_15_min",
)


class MissingReferenceData(RuntimeError):
    """Raised when a weight class is not in the database (run `bin/rails db:seed`)."""


@dataclass
class LoadCounts:
    events: int = 0
    bouts: int = 0
    fighter_ids: set[str] = field(default_factory=set)

    @property
    def fighters(self) -> int:
        return len(self.fighter_ids)


class Store:
    def __init__(self, connection: psycopg.Connection) -> None:
        self._conn = connection
        self._weight_class_ids: dict[str, int] | None = None
        self.counts = LoadCounts()

    def save_event(self, event: EventDetail) -> None:
        """Saves an event with all its bouts in one transaction."""
        with self._conn.transaction():
            event_id = self._upsert_event(event)
            for bout in event.bouts:
                self._save_bout(event_id, bout)
        self.counts.events += 1

    def save_fighter(self, profile: FighterProfile) -> None:
        """Inserts or refreshes a fighter, except one an admin has locked."""
        columns = ("ufcstats_id", *PROFILE_COLUMNS)
        values = [getattr(profile, column) for column in columns]
        updates = ", ".join(f"{column} = EXCLUDED.{column}" for column in PROFILE_COLUMNS)
        with self._conn.transaction():
            self._conn.execute(
                f"""
                INSERT INTO fighters ({", ".join(columns)}, created_at, updated_at)
                VALUES ({", ".join(["%s"] * len(columns))}, now(), now())
                ON CONFLICT (ufcstats_id) DO UPDATE SET {updates}, updated_at = now()
                WHERE NOT fighters.locked
                """,
                values,
            )
        self.counts.fighter_ids.add(profile.ufcstats_id)

    def _upsert_event(self, event: EventDetail) -> int:
        return self._returning_id(
            """
            INSERT INTO events (ufcstats_id, name, held_on, location, created_at, updated_at)
            VALUES (%s, %s, %s, %s, now(), now())
            ON CONFLICT (ufcstats_id) DO UPDATE
              SET name = EXCLUDED.name, held_on = EXCLUDED.held_on,
                  location = EXCLUDED.location, updated_at = now()
            RETURNING id
            """,
            (event.ufcstats_id, event.name, event.held_on, event.location),
        )

    def _save_bout(self, event_id: int, bout: BoutRecord) -> None:
        weight_class_id = self._weight_class_id(normalize_weight_class(bout.weight_class_label))
        detail = " ".join(part for part in (bout.method_label, bout.method_detail) if part)
        bout_id = self._returning_id(
            """
            INSERT INTO bouts (ufcstats_id, event_id, weight_class_id, finish, finish_detail,
                               ending_round, ending_time_seconds, title_bout,
                               created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, now(), now())
            ON CONFLICT (ufcstats_id) DO UPDATE
              SET event_id = EXCLUDED.event_id, weight_class_id = EXCLUDED.weight_class_id,
                  finish = EXCLUDED.finish, finish_detail = EXCLUDED.finish_detail,
                  ending_round = EXCLUDED.ending_round,
                  ending_time_seconds = EXCLUDED.ending_time_seconds,
                  title_bout = EXCLUDED.title_bout, updated_at = now()
            RETURNING id
            """,
            (
                bout.ufcstats_id,
                event_id,
                weight_class_id,
                normalize_finish(bout.method_label),
                detail or None,
                bout.ending_round,
                bout.ending_time_seconds,
                bout.title_bout,
            ),
        )
        for result in bout.fighters:
            self._save_appearance(bout_id, self._ensure_fighter(result), result)
        self.counts.bouts += 1

    def _ensure_fighter(self, result: FighterResult) -> int:
        """Creates a placeholder fighter from the event page; save_fighter fills in stats.

        The update always runs (keeping a locked fighter's name) so RETURNING
        yields the id either way; a WHERE clause would return no row when locked.
        """
        self.counts.fighter_ids.add(result.ufcstats_id)
        return self._returning_id(
            """
            INSERT INTO fighters (ufcstats_id, name, created_at, updated_at)
            VALUES (%s, %s, now(), now())
            ON CONFLICT (ufcstats_id) DO UPDATE
              SET name = CASE WHEN fighters.locked THEN fighters.name ELSE EXCLUDED.name END
            RETURNING id
            """,
            (result.ufcstats_id, result.name),
        )

    def _save_appearance(self, bout_id: int, fighter_id: int, result: FighterResult) -> None:
        self._conn.execute(
            """
            INSERT INTO appearances (bout_id, fighter_id, outcome, knockdowns, sig_strikes_landed,
                                     takedowns_landed, submission_attempts, created_at, updated_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, now(), now())
            ON CONFLICT (bout_id, fighter_id) DO UPDATE
              SET outcome = EXCLUDED.outcome, knockdowns = EXCLUDED.knockdowns,
                  sig_strikes_landed = EXCLUDED.sig_strikes_landed,
                  takedowns_landed = EXCLUDED.takedowns_landed,
                  submission_attempts = EXCLUDED.submission_attempts, updated_at = now()
            """,
            (
                bout_id,
                fighter_id,
                result.outcome,
                result.knockdowns,
                result.sig_strikes_landed,
                result.takedowns_landed,
                result.submission_attempts,
            ),
        )

    def _weight_class_id(self, name: str) -> int:
        if self._weight_class_ids is None:
            rows = self._conn.execute("SELECT name, id FROM weight_classes").fetchall()
            self._weight_class_ids = dict(rows)
        try:
            return self._weight_class_ids[name]
        except KeyError:
            raise MissingReferenceData(
                f"weight class {name!r} is not in the database; run `bin/rails db:seed` first"
            ) from None

    def _returning_id(self, sql: str, params: tuple) -> int:
        row = self._conn.execute(sql, params).fetchone()
        return row[0]
