import pytest

from ufc_scraper.normalize import (
    FINISHES,
    WEIGHT_CLASSES,
    UnknownWeightClass,
    normalize_finish,
    normalize_weight_class,
)


@pytest.mark.parametrize(
    ("label", "expected"),
    [
        ("Lightweight", "Lightweight"),
        ("Lightweight Bout", "Lightweight"),
        ("UFC Lightweight Title Bout", "Lightweight"),
        ("UFC Interim Lightweight Title Bout", "Lightweight"),
        ("Light Heavyweight", "Light Heavyweight"),
        ("UFC Heavyweight Title Bout", "Heavyweight"),
        ("Super Heavyweight Bout", "Heavyweight"),
        ("Women's Strawweight", "Women's Strawweight"),
        ("UFC Women's Flyweight Title Bout", "Women's Flyweight"),
        (
            "Ultimate Fighter 28 Women's Featherweight Tournament Title Bout",
            "Women's Featherweight",
        ),
        ("Ultimate Fighter Latin America 3 Lightweight Tournament Title Bout", "Lightweight"),
        ("UFC 2 Tournament Title Bout", "Open Weight"),
        ("Open Weight Bout", "Open Weight"),
        ("Catch Weight Bout", "Catch Weight"),
        ("  catch weight  ", "Catch Weight"),
    ],
)
def test_normalize_weight_class(label, expected):
    assert normalize_weight_class(label) == expected


def test_every_result_is_a_seeded_weight_class():
    assert len(WEIGHT_CLASSES) == 14
    assert normalize_weight_class("Women's Bantamweight Bout") in WEIGHT_CLASSES


def test_unknown_weight_class_is_an_error_not_a_guess():
    with pytest.raises(UnknownWeightClass, match="Cruiserweight"):
        normalize_weight_class("Cruiserweight Bout")


@pytest.mark.parametrize(
    ("label", "expected"),
    [
        ("KO/TKO", "ko_tko"),
        ("TKO - Doctor's Stoppage", "ko_tko"),
        ("SUB", "submission"),
        ("Submission", "submission"),
        ("U-DEC", "decision"),
        ("S-DEC", "decision"),
        ("M-DEC", "decision"),
        ("Decision - Split", "decision"),
        ("DQ", "disqualification"),
        ("CNC", "no_contest"),
        ("Overturned", "no_contest"),
        ("Other", "other"),
    ],
)
def test_normalize_finish(label, expected):
    assert normalize_finish(label) == expected


def test_finishes_match_the_database_constraint():
    assert set(FINISHES) == {
        "ko_tko",
        "submission",
        "decision",
        "disqualification",
        "no_contest",
        "other",
    }
