"""Tests for BT-142 Phase 3.5b placeholder_backfill.

Uses lightweight shape fakes (same pattern as test_container_check) because
python-pptx's `placeholder_format` is read-only — adding a real placeholder
requires raw OOXML manipulation. The backfill logic is what we care about
here; integration tests with real placeholders are covered by Phase 6.12.
"""

from __future__ import annotations

import sys
import pathlib

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))

from placeholder_backfill import backfill_slide, backfill_deck, BackfillReport


class _FakeRun:
    def __init__(self):
        self.text = ""


class _FakeParagraph:
    def __init__(self):
        self.runs = []

    def add_run(self):
        r = _FakeRun()
        self.runs.append(r)
        return r


class _FakeTextFrame:
    def __init__(self):
        self.text = ""
        self.paragraphs = [_FakeParagraph()]  # python-pptx always has ≥1

    def clear(self):
        self.text = ""
        self.paragraphs = [_FakeParagraph()]

    def add_paragraph(self):
        p = _FakeParagraph()
        self.paragraphs.append(p)
        return p


class _FakePhFmt:
    def __init__(self, idx, type_=None):
        self.idx = idx
        self.type = type_


class _FakeShape:
    def __init__(self, idx, text="", type_=None):
        self.name = f"PH {idx}"
        self.placeholder_format = _FakePhFmt(idx, type_)
        self.is_placeholder = True
        self._text = text
        self.has_text_frame = True
        self.text_frame = _FakeTextFrame()
        self.text_frame.text = text
        self.left = self.top = self.width = self.height = 0

    @property
    def text(self):
        return self._text


class _FakeShapes:
    def __init__(self, shapes):
        self._shapes = shapes

    def __iter__(self):
        return iter(self._shapes)

    def add_picture(self, *args, **kw):
        return _FakeShape(99, type_=18)


class _FakeSlide:
    def __init__(self, placeholders):
        self.shapes = _FakeShapes(placeholders)
        self.placeholders = placeholders


def test_backfill_body_slot_fills_empty_placeholder():
    slide = _FakeSlide([_FakeShape(idx=1, text=""), _FakeShape(idx=2, text="")])
    report = backfill_slide(slide, {
        "body_slots": [
            {"placeholder_idx": 1, "text": "Member A — CEO"},
            {"placeholder_idx": 2, "text": "Member B — CTO"},
        ]
    })
    assert "body[1]" in report.filled
    assert "body[2]" in report.filled
    assert len(report.errors) == 0


def test_backfill_skips_already_filled():
    slide = _FakeSlide([_FakeShape(idx=1, text="Existing content")])
    report = backfill_slide(slide, {
        "body_slots": [{"placeholder_idx": 1, "text": "Should not overwrite"}]
    })
    assert any("body[1]" in s for s in report.skipped)
    assert not any("body[1]" in f for f in report.filled)


def test_backfill_missing_placeholder_reports_error():
    slide = _FakeSlide([])  # no placeholders
    report = backfill_slide(slide, {
        "body_slots": [{"placeholder_idx": 99, "text": "x"}]
    })
    assert len(report.errors) >= 1
    assert any("99" in err for err in report.errors)


def test_backfill_handles_empty_slide_data():
    slide = _FakeSlide([_FakeShape(idx=1, text="")])
    report = backfill_slide(slide, {})
    assert report.filled == []
    assert report.errors == []


def test_backfill_deck_aligns_by_index():
    slide1 = _FakeSlide([_FakeShape(idx=1, text="")])
    slide2 = _FakeSlide([_FakeShape(idx=1, text="")])
    reports = backfill_deck(
        type("P", (), {"slides": [slide1, slide2]})(),
        [{"body_slots": [{"placeholder_idx": 1, "text": "x"}]},
         {"body_slots": [{"placeholder_idx": 1, "text": "y"}]}],
    )
    assert set(reports.keys()) == {0, 1}
    assert reports[0].filled == ["body[1]"]
    assert reports[1].filled == ["body[1]"]


def test_backfill_deck_handles_size_mismatch():
    slide1 = _FakeSlide([_FakeShape(idx=1, text="")])
    slide2 = _FakeSlide([_FakeShape(idx=1, text="")])
    reports = backfill_deck(
        type("P", (), {"slides": [slide1, slide2]})(),
        [{}],  # only 1 entry for 2 slides
    )
    assert len(reports[1].errors) >= 1


def test_backfill_report_to_dict_round_trip():
    r = BackfillReport(filled=["body[1]"], skipped=["body[2]"], errors=["err"])
    d = r.to_dict()
    assert d["filled"] == ["body[1]"]
    assert d["skipped"] == ["body[2]"]
    assert d["errors"] == ["err"]
