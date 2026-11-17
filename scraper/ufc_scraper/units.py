"""Converts UFCStats display values ("6' 4\"", "62%", "--") into stored values."""

import re

MISSING = {"", "--"}
CM_PER_INCH = 2.54


def height_to_cm(text: str) -> int | None:
    """'6\\' 4"' -> 193."""
    match = re.fullmatch(r"(\d+)'\s*(\d+)\"?", text.strip())
    if match is None:
        return None
    feet, inches = map(int, match.groups())
    return round((feet * 12 + inches) * CM_PER_INCH)


def inches_to_cm(text: str) -> int | None:
    """'79"' or '79.0"' -> 201."""
    match = re.fullmatch(r"(\d+(?:\.\d+)?)\"?", text.strip())
    return round(float(match.group(1)) * CM_PER_INCH) if match else None


def percent(text: str) -> float:
    """'62%' -> 0.62. Missing values count as 0, as UFCStats shows for new fighters."""
    value = text.strip().rstrip("%")
    return 0.0 if value in MISSING else round(float(value) / 100, 3)


def number(text: str) -> float:
    """'5.12' -> 5.12, missing -> 0.0."""
    value = text.strip()
    return 0.0 if value in MISSING else float(value)


def text_or_none(text: str) -> str | None:
    value = text.strip()
    return None if value in MISSING else value
