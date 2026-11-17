"""Maps the labels UFCStats prints onto the names the database uses.

Weight classes must match rows seeded by Rails (db/seeds/reference_data.rb) and
finishes must match the bouts.finish CHECK constraint.
"""

from ufc_scraper.parsers.text import clean

MEN_DIVISIONS = (
    "Flyweight",
    "Bantamweight",
    "Featherweight",
    "Lightweight",
    "Welterweight",
    "Middleweight",
    "Light Heavyweight",
    "Heavyweight",
)
WOMEN_DIVISIONS = ("Strawweight", "Flyweight", "Bantamweight", "Featherweight")
WEIGHT_CLASSES = (
    *MEN_DIVISIONS,
    *(f"Women's {name}" for name in WOMEN_DIVISIONS),
    "Open Weight",
    "Catch Weight",
)

FINISHES = ("ko_tko", "submission", "decision", "disqualification", "no_contest", "other")


class UnknownWeightClass(ValueError):
    """Raised for a label no rule recognises, so new formats are noticed, not guessed."""


def normalize_weight_class(label: str) -> str:
    """'UFC Interim Lightweight Title Bout' -> 'Lightweight'."""
    text = clean(label).lower()

    if "catch weight" in text or "catchweight" in text:
        return "Catch Weight"
    if "open weight" in text or "openweight" in text:
        return "Open Weight"

    # Longest names first so "light heavyweight" is not read as "heavyweight".
    candidates = WOMEN_DIVISIONS if "women" in text else MEN_DIVISIONS
    for name in sorted(candidates, key=len, reverse=True):
        if name.lower() in text:
            return f"Women's {name}" if "women" in text else name

    # Early UFC tournaments ("UFC 2 Tournament Title Bout") had no weight limits.
    if "tournament" in text:
        return "Open Weight"

    raise UnknownWeightClass(f"cannot map weight class {label!r}")


def normalize_finish(label: str) -> str:
    """'S-DEC' -> 'decision', "TKO - Doctor's Stoppage" -> 'ko_tko'."""
    text = clean(label).upper()

    if text.startswith(("KO", "TKO")):
        return "ko_tko"
    if text.startswith("SUB"):
        return "submission"
    if text.endswith("DEC") or text.startswith("DECISION"):
        return "decision"
    if text.startswith("DQ"):
        return "disqualification"
    if text in {"CNC", "OVERTURNED", "NC"} or "NO CONTEST" in text:
        return "no_contest"
    return "other"
