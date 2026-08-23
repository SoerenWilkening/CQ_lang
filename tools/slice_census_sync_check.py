#!/usr/bin/env python3
"""slice_census_sync_check.py — the bd `3c6m.63` prevention gate.

WHAT IT ENFORCES.  A committed `tests/e2e/slice_libm_real_<spelling>` golden is
the *verified* half of the published libm scoreboard: `probe.py`'s
`_full_surface_scoreboard()` computes **verified = the glob count of these
files** and prints it beside **injection-covered**, read off
`full_surface/full_census_O1.json`.  Those two numbers are produced by different
mechanisms over the same claim, so they can DESYNCHRONIZE — and when they do the
published pair reads `verified > injection-covered`, which `probe.py`'s own
docstring names as an incoherent result ("48 injection-covered, 68 verified").

This gate asserts the only direction that can go wrong silently:

    *** no `slice_libm_real_<s>` may exist for a spelling whose census cell is
        not injection-covered. ***

WHY IT EXISTS (the incident, bd `test_C_libtooling-3c6m.63`).  The census corpus
built ten openlibm TUs from `ld80/` whose basenames also exist in `src/`, and
openlibm's own build EXCLUDES all ten.  Three census cells were measured
`COMPILES` on a body that ships nowhere.  Correcting the corpus flipped
`nextafterl.f80`, `nexttoward.f64` and `nexttowardf.f32` to `decline` — while
their three `slice_libm_real_*` goldens, which vendor the SAME non-shipped ld80
bodies, kept passing.  Nothing turned red.  The ticket recorded that as a trap
for whoever fixed it; this file is that trap closed.

The failure it catches is a FAITHFULNESS/ACCOUNTING defect, never a miscompile:
the vendored C is real openlibm source and the pass lowers it correctly.  What
breaks is what the slice *counts as* — the `slice_libm_real_` prefix is a claim
that this is the body a user's libm call would reach, and for an excluded ld80
variant that claim is false.  A slice that keeps its proof value without the
claim belongs under a different prefix (the tree uses `slice_libm_ld80_*`), which
is exactly what this gate forces the author to think about.

WHAT IT DOES **NOT** WITNESS (read before quoting it):
  * It does not check that a slice's vendored body actually matches upstream.
    Faithfulness of the *text* is a manual audit (the `libm-real-slice-recipe`)
    and nothing here re-derives it.
  * It does not check the CORPUS.  A corpus that silently switched bodies again
    would move the census, and this gate would then fire on the goldens — one
    step downstream.  `full_surface/build_corpus.py` is the gate at the source.
  * It does not require every covered cell to HAVE a golden.  That direction is
    reported as INFO only: `injection-covered` and `verified` are deliberately
    measured apart, and the docs state that their coinciding today is a
    MEASUREMENT, not an invariant.  Making it an error here would quietly convert
    that stance into a rule.
  * It says nothing about `slice_branchless_*` (the CQ-PROVIDED row, whose gate is
    `probe.cq_provided_cells()`) or about any other slice family.

Usage:  slice_census_sync_check.py [--root <repo-root>] [-q]
Exit 0 = clean, 1 = a golden claims coverage the census does not, 2 = cannot run.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import sys

PREFIX = "slice_libm_real_"
GOLDEN_SUFFIX = ".expected.log"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=None, help="repo root (default: infer)")
    ap.add_argument("-q", "--quiet", action="store_true")
    a = ap.parse_args()

    root = pathlib.Path(a.root).resolve() if a.root \
        else pathlib.Path(__file__).resolve().parents[1]
    e2e = root / "tests" / "e2e"
    libcov = root / "tools" / "library_coverage"
    census = libcov / "full_surface" / "full_census_O1.json"
    if not e2e.is_dir():
        print(f"!! {e2e} not found", file=sys.stderr)
        return 2
    if not census.exists():
        print(f"!! {census} not found — cannot check the goldens against a census "
              f"that is not there.", file=sys.stderr)
        return 2

    # Rule 14: ONE covered-predicate, imported rather than mirrored. A local copy
    # is how `probe.py` and `full_census.py` came to disagree by the `no-body`
    # cell (bd `5ft3`).
    sys.path.insert(0, str(libcov))
    try:
        import probe as P
        is_covered = P.is_covered
    except Exception as e:                                    # pragma: no cover
        print(f"!! could not import probe.py for its is_covered predicate: {e}",
              file=sys.stderr)
        return 2

    cells = json.loads(census.read_text())
    if not cells:
        print("!! census json is empty — a gate that checks nothing passes "
              "vacuously, so this is a failure.", file=sys.stderr)
        return 2

    # A census key is "<spelling>.<width>", and every consumer (probe.py's
    # `mathh_union_scoreboard`, this gate) keys on the spelling alone. Assert the
    # uniqueness that assumption rests on rather than inheriting it.
    by_spelling: dict[str, tuple[str, dict]] = {}
    dupes = []
    for key, rec in cells.items():
        s = key.rsplit(".", 1)[0]
        if s in by_spelling:
            dupes.append(s)
        by_spelling[s] = (key, rec)
    if dupes:
        print(f"!! census spellings are not unique: {sorted(set(dupes))}. Every "
              f"reader of this file keys on the spelling; fix that first.",
              file=sys.stderr)
        return 2

    goldens = sorted(p.name[len(PREFIX):-len(GOLDEN_SUFFIX)]
                     for p in e2e.glob(f"{PREFIX}*{GOLDEN_SUFFIX}"))
    if not goldens:
        print(f"!! no {PREFIX}*{GOLDEN_SUFFIX} found under {e2e} — this gate would "
              f"pass vacuously, which is not a pass.", file=sys.stderr)
        return 2

    unknown, not_covered, cq_provided, no_source = [], [], [], []
    for s in goldens:
        if not (e2e / f"{PREFIX}{s}.c").exists():
            no_source.append(s)
        hit = by_spelling.get(s)
        if hit is None:
            unknown.append(s)
            continue
        key, rec = hit
        if rec.get("provider") == "cq":
            cq_provided.append((s, key))
        elif not is_covered(rec.get("status", "decline")):
            not_covered.append((s, key, rec.get("status"), rec.get("bucket", "")))

    covered = {s for s, (k, r) in by_spelling.items()
               if r.get("provider", "openlibm") != "cq" and is_covered(r.get("status", "decline"))}
    missing_golden = sorted(covered - set(goldens))

    # Printed BEFORE any failure banner, and flushed, so the two do not interleave
    # confusingly when stdout and stderr land in the same terminal.
    if not a.quiet:
        print(f"slice/census sync: {len(goldens)} `{PREFIX}*` goldens, "
              f"{len(covered)} injection-covered cells.", flush=True)

    bad = False
    if not_covered:
        bad = True
        print(f"\n!! {len(not_covered)} `{PREFIX}*` GOLDEN(S) CLAIM COVERAGE THE "
              f"CENSUS DOES NOT (bd 3c6m.63):", file=sys.stderr)
        for s, key, st, bk in not_covered:
            print(f"    {PREFIX}{s}  ->  census {key} = {st} ({bk})", file=sys.stderr)
        print("   `verified` is the glob count of these files and is printed beside "
              "`injection-covered`; leaving them makes verified > covered.\n"
              "   Either the cell should be covered (fix the compiler / the corpus), "
              "or the slice is not a coverage claim —\n"
              "   in which case rename it out of the `slice_libm_real_` namespace "
              "(e.g. `slice_libm_ld80_*`) and say in its header\n"
              "   which body it vendors and why openlibm does not build it.",
              file=sys.stderr)
    if unknown:
        bad = True
        print(f"\n!! {len(unknown)} `{PREFIX}*` golden(s) name a spelling that is not "
              f"a census cell at all: {unknown}", file=sys.stderr)
        print("   The prefix asserts 'the REAL openlibm body for census cell <s>'. "
              "If there is no such cell, use another prefix.", file=sys.stderr)
    if cq_provided:
        bad = True
        print(f"\n!! {len(cq_provided)} `{PREFIX}*` golden(s) name a CQ-PROVIDED cell: "
              f"{[s for s, _ in cq_provided]}", file=sys.stderr)
        print("   Those cells inject CQ's OWN leaf, not upstream's body (Rule 18 "
              "amendment (iii)); their goldens are `slice_branchless_*`.",
              file=sys.stderr)
    if no_source:
        bad = True
        print(f"\n!! {len(no_source)} golden(s) have no `.c` beside them: {no_source}",
              file=sys.stderr)

    if not a.quiet and not bad:
        if missing_golden:
            # INFO, never a failure — see the docstring. This is the "gap" the
            # coverage docs track between `injection-covered` and `verified`.
            print(f"  INFO: {len(missing_golden)} injection-covered cell(s) have no "
                  f"ship-floor golden yet: {missing_golden}")
            print("        (Not an error: covered and verified are measured apart on "
                  "purpose. It IS the published gap.)")
        else:
            print("  gap 0: every injection-covered cell has a committed golden.")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
