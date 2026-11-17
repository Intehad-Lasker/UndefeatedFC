import os
from pathlib import Path

import psycopg
import pytest

from ufc_scraper.normalize import WEIGHT_CLASSES

FIXTURES = Path(__file__).parent / "fixtures"


@pytest.fixture
def fixture_html():
    def read(name: str) -> str:
        return (FIXTURES / name).read_text(encoding="utf-8")

    return read


@pytest.fixture
def db():
    """A connection to a database with the Rails schema loaded. Every test runs
    inside a transaction that is rolled back, so tests never see each other's rows.

    Create it with:
      RAILS_ENV=test DATABASE_URL=postgres://.../undefeated_fc_scraper_test \
        bin/rails db:create db:schema:load
    """
    url = os.environ.get("TEST_DATABASE_URL")
    if not url:
        pytest.skip("set TEST_DATABASE_URL to run database tests")

    with psycopg.connect(url) as connection:
        for position, name in enumerate(WEIGHT_CLASSES, start=1):
            connection.execute(
                """
                INSERT INTO weight_classes (name, position, spinnable, created_at, updated_at)
                VALUES (%s, %s, true, now(), now()) ON CONFLICT (name) DO NOTHING
                """,
                (name, position),
            )
        yield connection
        connection.rollback()
