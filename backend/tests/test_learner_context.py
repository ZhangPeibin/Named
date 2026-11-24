from learner.context import (
    _dedupe_lines,
    _fit_lines,
    _line_key,
    _render_sections,
)


def test_line_key_ignores_bullets_sources_and_kind_prefixes() -> None:
    assert _line_key("- interest: gardening (source: onboarding)") == "gardening"
    assert _line_key("interest: Gardening") == "gardening"
    assert _line_key("- profile: native language Chinese") == "native language chinese"


def test_dedupe_keeps_first_occurrence_across_sections() -> None:
    seen: set[str] = set()
    about = _dedupe_lines(["- interest: gardening (source: user_edit)"], seen)
    learned = _dedupe_lines(["- interest: gardening"], seen)

    assert about == ["- interest: gardening (source: user_edit)"]
    assert learned == []


def test_fit_lines_truncates_at_the_budget() -> None:
    lines = ["- first line", "- second line is longer", "- third line"]

    fitted = _fit_lines(lines, len("- first line") + 1 + 1 + 5)

    assert fitted == ["- first line", "- sec"]


def test_render_sections_orders_and_skips_empty_sections() -> None:
    text = _render_sections(
        [
            ("About:", ["- one"]),
            ("Learned:", []),
            ("Errors:", ["- two"]),
        ],
        budget=100,
    )

    assert text == "About:\n- one\nErrors:\n- two"


def test_render_sections_stops_before_a_header_without_room() -> None:
    text = _render_sections(
        [
            ("About:", ["- one"]),
            ("Errors:", ["- two"]),
        ],
        budget=13,
    )

    assert text == "About:\n- one"
