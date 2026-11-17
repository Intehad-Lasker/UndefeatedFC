"""Parses a fighter page, e.g. http://www.ufcstats.com/fighter-details/<id>."""

import re

from bs4 import BeautifulSoup

from ufc_scraper import units
from ufc_scraper.parsers.text import clean, labelled_items, parse_date, ufcstats_id
from ufc_scraper.records import FighterProfile

RECORD = re.compile(r"(\d+)-(\d+)-(\d+)(?:\s*\((\d+)\s*NC\))?")


def parse_fighter_page(html: str, url: str) -> FighterProfile:
    soup = BeautifulSoup(html, "html.parser")
    items = labelled_items(soup)
    wins, losses, draws, no_contests = _record(soup)
    nickname = soup.select_one("p.b-content__Nickname")
    born = units.text_or_none(items.get("dob", ""))

    return FighterProfile(
        ufcstats_id=ufcstats_id(url),
        name=clean(soup.select_one("span.b-content__title-highlight").get_text()),
        nickname=units.text_or_none(clean(nickname.get_text())) if nickname else None,
        height_cm=units.height_to_cm(items.get("height", "")),
        reach_cm=units.inches_to_cm(items.get("reach", "")),
        stance=units.text_or_none(items.get("stance", "")),
        born_on=parse_date(born) if born else None,
        wins=wins,
        losses=losses,
        draws=draws,
        no_contests=no_contests,
        sig_strikes_landed_per_min=units.number(items.get("slpm", "")),
        sig_strike_accuracy=units.percent(items.get("stracc", "")),
        sig_strikes_absorbed_per_min=units.number(items.get("sapm", "")),
        sig_strike_defense=units.percent(items.get("strdef", "")),
        takedowns_per_15_min=units.number(items.get("tdavg", "")),
        takedown_accuracy=units.percent(items.get("tdacc", "")),
        takedown_defense=units.percent(items.get("tddef", "")),
        submission_attempts_per_15_min=units.number(items.get("subavg", "")),
    )


def _record(soup: BeautifulSoup) -> tuple[int, int, int, int]:
    """'Record: 26-1-0 (1 NC)' -> (26, 1, 0, 1)."""
    title = soup.select_one("span.b-content__title-record")
    match = RECORD.search(title.get_text() if title else "")
    if match is None:
        return 0, 0, 0, 0
    wins, losses, draws, no_contests = match.groups()
    return int(wins), int(losses), int(draws), int(no_contests or 0)
