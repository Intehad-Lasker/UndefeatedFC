"""Scrapes UFCStats and loads fighters, events and bouts into Postgres.

The Rails app owns the database schema; this package only reads and writes the
tables it is given (see docs/adr/0004-python-scraper.md).
"""

__version__ = "0.1.0"
