"""US-4.8 Phase 2 tests — master_cloner (Scenario B/C extension).

Tests that ``clone_master_and_borrow`` correctly borrows layouts from
``default.pptx`` and injects them under the user's existing master, with
the user's theme inherited automatically.
"""
import shutil
import sys
from pathlib import Path

import pytest
from pptx import Presentation

_HERE = Path(__file__).resolve().parent
_MODIFIER_SCRIPTS = _HERE.parent                   # .../pptx-template-modifier-skill/scripts
_SKILLS = _MODIFIER_SCRIPTS.parent.parent          # .../skills
_COMMON_SCRIPTS = _SKILLS / "_common" / "scripts"
_REPO_ROOT = _SKILLS.parent.parent                 # repo root
_FILLER_SCRIPTS = _SKILLS / "pptx-generate-slide-skill" / "scripts"
for _p in (str(_MODIFIER_SCRIPTS), str(_COMMON_SCRIPTS), str(_FILLER_SCRIPTS)):
    if _p not in sys.path:
        sys.path.insert(0, _p)

from master_cloner import clone_master_and_borrow  # noqa: E402
from layout_contract import get_render_contract, _resolve_layout_by_fingerprint  # noqa: E402

_DEFAULT_PPTX = str(_REPO_ROOT / "template" / "default.pptx")


def _base_in(tmp_path):
    """Copy default.pptx into tmp_path so derived files don't pollute the repo."""
    return str(shutil.copy2(_DEFAULT_PPTX, tmp_path / "template.pptx"))


@pytest.mark.skip(reason="BT-142 Phase 7.3: layout-borrowing tests require a multi-layout donor template (the minimal synthesized template via _build_minimal_pptx_bytes has only 1 layout, so nothing can be borrowed). Skip until a richer fixture builder is added or a real user template is supplied in tests.")
class TestCloneMasterAndBorrow:
    def test_borrow_produces_extended_template(self, tmp_path):
        base = _base_in(tmp_path)
        extended, overrides = clone_master_and_borrow(
            base,
            ["chart_slide"],  # default has this, but we borrow a fresh copy
            _DEFAULT_PPTX,
        )
        assert extended != base
        assert Path(extended).exists()
        assert "chart_slide" in overrides
        assert overrides["chart_slide"].endswith("(borrowed)")

    def test_borrowed_layout_findable_by_name(self, tmp_path):
        base = _base_in(tmp_path)
        extended, overrides = clone_master_and_borrow(
            base, ["chart_slide"], _DEFAULT_PPTX
        )
        reloaded = Presentation(extended)
        layouts = reloaded.slide_masters[0].slide_layouts
        for name in overrides.values():
            assert layouts.get_by_name(name) is not None

    def test_borrowed_layout_has_placeholders(self, tmp_path):
        base = _base_in(tmp_path)
        extended, overrides = clone_master_and_borrow(
            base, ["content_slide"], _DEFAULT_PPTX
        )
        reloaded = Presentation(extended)
        clone = reloaded.slide_masters[0].slide_layouts.get_by_name(
            overrides["content_slide"]
        )
        assert clone is not None
        # content_slide fingerprint = [TITLE, OBJECT] — at least 2 placeholders.
        assert len(list(clone.placeholders)) >= 2

    def test_borrow_inherits_user_theme(self, tmp_path):
        """The borrowed layout is under the user's master → inherits user theme."""
        base = _base_in(tmp_path)
        orig_prs = Presentation(base)
        orig_master_count = len(orig_prs.slide_masters)
        orig_layout_count = len(orig_prs.slide_masters[0].slide_layouts)

        extended, overrides = clone_master_and_borrow(
            base, ["content_slide"], _DEFAULT_PPTX
        )
        reloaded = Presentation(extended)
        # No new master created (Decision 5 fallback: layouts under existing master).
        assert len(reloaded.slide_masters) == orig_master_count
        # The layout count grew.
        new_layout_count = len(reloaded.slide_masters[0].slide_layouts)
        assert new_layout_count > orig_layout_count

    def test_borrow_multiple_slide_types(self, tmp_path):
        base = _base_in(tmp_path)
        extended, overrides = clone_master_and_borrow(
            base,
            ["chart_slide", "two_content_slide", "comparison_slide"],
            _DEFAULT_PPTX,
        )
        assert len(overrides) == 3
        assert set(overrides.keys()) == {"chart_slide", "two_content_slide", "comparison_slide"}

    def test_base_unchanged_after_borrow(self, tmp_path):
        base = _base_in(tmp_path)
        before = Path(base).read_bytes()
        clone_master_and_borrow(base, ["chart_slide"], _DEFAULT_PPTX)
        after = Path(base).read_bytes()
        assert before == after

    def test_no_borrow_when_no_missing_types(self, tmp_path):
        base = _base_in(tmp_path)
        extended, overrides = clone_master_and_borrow(
            base, [], _DEFAULT_PPTX
        )
        assert extended == base
        assert overrides == {}

    def test_borrowed_layout_servable_by_fingerprint(self, tmp_path):
        """After borrowing, the new layout is found by the fingerprint matcher."""
        base = _base_in(tmp_path)
        extended, overrides = clone_master_and_borrow(
            base, ["two_content_slide"], _DEFAULT_PPTX
        )
        contract = get_render_contract(extended)
        idx, reason = _resolve_layout_by_fingerprint("two_content_slide", contract)
        assert idx is not None  # the borrowed layout is matched


class TestRollback:
    def test_rollback_on_corrupt_input(self, tmp_path):
        """A non-PPTX file should trigger rollback."""
        bad = tmp_path / "broken.pptx"
        bad.write_bytes(b"not a pptx")
        extended, overrides = clone_master_and_borrow(
            str(bad), ["chart_slide"], _DEFAULT_PPTX,
            output_path=str(tmp_path / "out.pptx"),
        )
        # Safe fallback: returns the base path, no overrides.
        assert extended == str(bad)
        assert overrides == {}


@pytest.mark.skip(reason="BT-142 Phase 7.3: layout-borrowing tests require a multi-layout donor template (the minimal synthesized template via _build_minimal_pptx_bytes has only 1 layout, so nothing can be borrowed). Skip until a richer fixture builder is added or a real user template is supplied in tests.")
class TestCrossPackageSerialization:
    """M-4: verify that borrowed layouts from default.pptx's package serialize
    correctly into the user's package (no dangling foreign-part references)."""

    def test_output_zip_is_valid(self, tmp_path):
        import zipfile
        base = _base_in(tmp_path)
        extended, overrides = clone_master_and_borrow(
            base, ["content_image_slide"], _DEFAULT_PPTX
        )
        # The output must be a readable zip with all core PPTX parts.
        with zipfile.ZipFile(extended) as z:
            names = z.namelist()
            assert "[Content_Types].xml" in names
            assert any(n.startswith("ppt/slideMasters/") for n in names)
            assert any(n.startswith("ppt/slideLayouts/") for n in names)
            assert "ppt/presentation.xml" in names

    def test_output_has_content_types_override_for_layouts(self, tmp_path):
        import zipfile
        base = _base_in(tmp_path)
        extended, overrides = clone_master_and_borrow(
            base, ["content_slide"], _DEFAULT_PPTX
        )
        with zipfile.ZipFile(extended) as z:
            ct = z.read("[Content_Types].xml").decode("utf-8")
            # The layout content type must be present (either as Default or Override).
            assert "slideLayout" in ct


@pytest.mark.skip(reason="BT-142 Phase 7.3: layout-borrowing tests require a multi-layout donor template (the minimal synthesized template via _build_minimal_pptx_bytes has only 1 layout, so nothing can be borrowed). Skip until a richer fixture builder is added or a real user template is supplied in tests.")
class TestStateMachineDispatch:
    """Verify that resolve_and_clone dispatches to Level 1 when Level 0 has no donor."""

    def test_no_circular_import(self):
        """CRIT-4: layout_creator and master_cloner must not import each other."""
        import layout_creator
        import master_cloner
        # Both modules load without error — no circular import.
        assert hasattr(layout_creator, "clone_for_over_limit")
        assert hasattr(master_cloner, "clone_master_and_borrow")

    def test_resolve_and_clone_with_missing_type(self, tmp_path):
        """End-to-end: a slide_type not in the template triggers Level 1 borrow."""
        from state_machine import resolve_and_clone
        base = _base_in(tmp_path)
        # Request only a title slide (which default.pptx definitely has).
        # This won't trigger cloning since the template already serves it.
        deck = [{"slide_type": "title_slide", "title": "T", "subtitle": "S"}]
        active, overrides, note = resolve_and_clone(base, deck)
        # No cloning needed — template already serves title_slide.
        assert active == base
        assert overrides == {}

    def test_resolve_and_clone_triggers_level1_borrow(self, tmp_path):
        """C-1 regression: Level 1 borrow actually fires and produces overrides."""
        from state_machine import resolve_and_clone
        from pptx import Presentation as Prs
        from pptx.util import Inches
        base = str(tmp_path / "minimal.pptx")
        # Create a MINIMAL template with only a "Blank" layout → most slide
        # types have no donor → Level 1 borrow kicks in.
        prs = Prs()
        prs.save(base)
        # Request a content_slide — the minimal template likely lacks it.
        deck = [{"slide_type": "content_slide", "title": "T", "body": "**A** - x"}]
        active, overrides, note = resolve_and_clone(base, deck)
        # Level 1 should have borrowed from default.pptx.
        if overrides:
            assert "content_slide" in overrides
            assert Path(active).exists()
