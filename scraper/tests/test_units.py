import pytest

from ufc_scraper import units


@pytest.mark.parametrize(("text", "cm"), [("6' 4\"", 193), ("5' 11\"", 180), ("--", None)])
def test_height_to_cm(text, cm):
    assert units.height_to_cm(text) == cm


@pytest.mark.parametrize(("text", "cm"), [('79"', 201), ('72.0"', 183), ("--", None)])
def test_inches_to_cm(text, cm):
    assert units.inches_to_cm(text) == cm


@pytest.mark.parametrize(
    ("text", "value"), [("62%", 0.62), ("100%", 1.0), ("0%", 0.0), ("--", 0.0)]
)
def test_percent(text, value):
    assert units.percent(text) == value


def test_number_treats_missing_as_zero():
    assert units.number("5.12") == 5.12
    assert units.number("--") == 0.0


def test_text_or_none():
    assert units.text_or_none(" Orthodox ") == "Orthodox"
    assert units.text_or_none("--") is None
