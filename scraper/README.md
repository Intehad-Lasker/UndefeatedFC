# ufc-scraper

Loads fight data from [UFCStats](http://www.ufcstats.com) into the UndefeatedFC
Postgres database. The Rails app owns the schema; run its migrations first.

## Setup

```bash
cd scraper
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

## Checks

```bash
ruff check .
pytest
```
