#!/usr/bin/env python3
"""mutate_instrument.py — MAKE THE INSTRUMENT FAIL ON PURPOSE.

bd `test_C_libtooling-rpkr` (the BANK axis) and bd `test_C_libtooling-gfsk` (the
header contract), session 2026-09-15, Track I.

⚠ WHY THIS FILE IS THE DELIVERABLE AND THE GREEN SELFTEST IS NOT. `CLAUDE.md`
L10: *an instrument's failure mode is to report a PASS, so the only instrument
worth citing is one that has been made to fail on purpose* — and the ⚠ block
under it records SIX measured instances that landed in ONE session, every one
found by the agent that owned the instrument and none by a green suite. A
27-case selftest going to 51 green cases proves nothing on its own: it is
equally consistent with 24 new cases that assert nothing.

So each mutation below REMOVES ONE FIX from `tools/loop_twin_matrix.py` (or from
the selftest's own scaffolding) inside a COPY of `tools/`, runs
`loop_twin_matrix_quarantine_test.py` there, and records which cases go red.
A mutation that nothing catches is a HOLE and is reported as `MISSED`.

    python3 mutate_instrument.py            # run every mutation
    python3 mutate_instrument.py --list

⚠ THE HARNESS'S OWN HOLES, CLOSED HERE RATHER THAN REDISCOVERED. Three of the
six instances in L10's block were harnesses that reported a pass on no input, or
ran a WEAKER command than the gate they claimed to measure. So:

  * a run with ZERO mutations exits non-zero (`n/a`, `checked 0` and `0
    mutations` are holes, not passes);
  * a mutation whose textual anchor is not found in the copy exits non-zero
    rather than scoring `MISSED` — an anchor that has drifted measures the
    harness, not the fix;
  * the UNMUTATED copy is run FIRST as a positive control, and if it is not
    green the whole run is refused: a selftest that is already red catches every
    mutation for the wrong reason;
  * every mutation must change the file — a no-op replacement is refused.
"""

import argparse
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", "..",
                                    ".."))
TOOLS = os.path.join(ROOT, "tools")

# (id, file, what it breaks, anchor, replacement, the case ids that MUST go red)
MUTATIONS = [
    # ── bd rpkr — the BANK axis's non-vacuity floor ────────────────────────
    ("M1-floor-removed", "loop_twin_matrix.py",
     "delete the floor check from verdict(): a bank pair whose two traces both "
     "lost the user's measurements goes back to ACCEPT-IDENTICAL",
     "        floor = BANK_FLOOR.get(name)",
     "        floor = None  # MUTANT M1",
     ["NEG-15", "NEG-16", "NEG-17", "NEG-18"]),
    ("M2-floor-rolled-only", "loop_twin_matrix.py",
     "ask the floor of the ROLLED side only — the natural half-measure, and it "
     "is defeated by a thin UNROLLED twin",
     '            thin = [(w, trace_floor(s), s) for w, s\n'
     '                    in (("rolled", rolled), ("unrolled", unrolled))',
     '            thin = [(w, trace_floor(s), s) for w, s\n'
     '                    in (("rolled", rolled),)  # MUTANT M2',
     ["NEG-19"]),
    ("M3-floor-empty", "loop_twin_matrix.py",
     "BANK_FLOOR silently becomes empty — every bank cell unguarded, which is "
     "the `checked 0` hole wearing this instrument's clothes",
     "BANK_FLOOR = {cell_name(c): _bank_floor(c) for c in bank_cells()}",
     "BANK_FLOOR = {}  # MUTANT M3",
     # Caught at IMPORT, by `_floor_is_a_lower_bound` — a stronger catch than a
     # case, because the module cannot load at all. The needle is the exception,
     # not a case id, and that is recorded rather than tidied away.
     ["KeyError: 'm_none_kprep_none_none_kflat'"]),
    ("M4-floor-of-one", "loop_twin_matrix.py",
     "lower every floor to 1 — satisfiable by a trace that has already dropped "
     "both bank measurements",
     "    return (1 + TRIPS * banks, 1 + TRIPS * banks)",
     "    return (1, 1)  # MUTANT M4",
     # Also caught at IMPORT: the floor is DERIVED from the generated source's
     # `cq_measure` call-site count, and a floor below it cannot see a dropped
     # measurement. That derivation is the reason the numbers are not guesses.
     ["floor 1 < 3 cq_measure call sites"]),
    ("M5-bank-axis-dropped", "loop_twin_matrix.py",
     "drop the bank cells from the matrix — the axis exists in the file and "
     "never runs, which is exactly what `no existing cell can see a rail bank` "
     "meant before this increment",
     "    cells = base + rec + ry + f + b + k",
     "    cells = base + rec + ry + f + b  # MUTANT M5",
     ["are defined but NOT in cells_of_matrix()"]),

    # ── bd gfsk — the header contract ──────────────────────────────────────
    ("M6-regenerate-eats-prose", "loop_twin_matrix.py",
     "THE ORIGINAL DEFECT, restored: --regenerate writes the CONSTANT over the "
     "file, deleting every hand-added line, and reports success",
     "        header, note, refusal = resolve_header(cfg.expected, EXPECTED_HEADER)",
     "        header, note, refusal = EXPECTED_HEADER, 'preserved 0', None  # MUTANT M6",
     ["POS-4"]),
    ("M7-refresh-eats-prose", "loop_twin_matrix.py",
     "the same defect in the OTHER write mode: --refresh-quarantine rewrites "
     "the quarantine from its constant",
     "    header, note, refusal = resolve_header(path, QUARANTINE_HEADER)",
     "    header, note, refusal = QUARANTINE_HEADER, 'preserved 0', None  # MUTANT M7",
     ["POS-5"]),
    ("M8-no-marker-is-seeded", "loop_twin_matrix.py",
     "an unmarked file is SEEDED from the constant instead of refused — the "
     "comfortable-looking choice, and the one that destroys the evidence",
     '    if not found:\n        return None, None, (',
     '    if not found:\n        return default_header + HEADER_END_MARKER, "seeded", None  # MUTANT M8\n    if False:\n        return None, None, (',
     ["NEG-10", "NEG-11"]),
    ("M9-no-readback", "loop_twin_matrix.py",
     "delete the post-write read-back: the writer reports its own success "
     "without checking it, which is L10's failure mode verbatim",
     "    back, found = split_header(path)\n"
     "    if not found or back != header:",
     "    back, found = split_header(path)\n"
     "    if False:  # MUTANT M9",
     ["write_preserving_header, made to fail"]),
    ("M10-plain-run-skips-marker", "loop_twin_matrix.py",
     "stop checking the marker on a PLAIN run — the gate stays green while the "
     "next --regenerate is already armed to refuse (or, before the fix, to eat)",
     '        if _h is not None and not _found:',
     '        if False:  # MUTANT M10',
     ["NEG-12", "NEG-13"]),
    ("M11-committed-tables-unmarked", "loop_twin_matrix.expected.txt",
     "strip the marker from a COMMITTED table — the state every table in this "
     "tree was in until 2026-09-15",
     None, None,
     ["the four COMMITTED tables carry the marker"]),

    # ── the harness's own scaffolding ──────────────────────────────────────
    ("M12-empty-matrix-passes", "loop_twin_matrix.py",
     "let an EMPTY matrix report a tidy pass — the `0 mutations, MISSED 0` hole",
     '    if not cells:\n        print("REFUSED: cells_of_matrix() produced NO cells.',
     '    if False:\n        print("REFUSED: cells_of_matrix() produced NO cells.',
     ["an EMPTY matrix exits 2"]),
    ("M13-stub-disarms-the-floor", "loop_twin_matrix_quarantine_test.py",
     "⚠ MEASURED FOR REAL DURING THIS INCREMENT, not invented: `install()` "
     "replaces `cell_name` with an identity stub, so without the restore the "
     "floor cases look up `BANK_FLOOR['none']`, get None, and FOUR of them go "
     "green against a fence that was never consulted",
     "    M.cell_name = _REAL_CELL_NAME\n    name = M.cell_name(cell)",
     "    name = M.cell_name(cell)  # MUTANT M13",
     ["NEG-15", "NEG-17"]),
]


def apply_mutation(tools, m):
    _id, fname, _what, anchor, repl, _expect = m
    path = os.path.join(tools, fname)
    text = open(path).read()
    if anchor is None:                      # M11: strip the marker
        import loop_twin_matrix as _M
        if _M.HEADER_END_MARKER not in text:
            raise SystemExit("%s: %s already has no marker — the mutation "
                             "measures nothing" % (_id, fname))
        new = text.replace(_M.HEADER_END_MARKER, "")
    else:
        if text.count(anchor) != 1:
            raise SystemExit(
                "%s: its anchor occurs %d time(s) in %s, not exactly once. An "
                "anchor that has DRIFTED measures the harness, not the fix — "
                "fix the anchor, never score this MISSED."
                % (_id, text.count(anchor), fname))
        new = text.replace(anchor, repl)
    if new == text:
        raise SystemExit("%s: the replacement changed nothing" % _id)
    open(path, "w").write(new)


def mirror(work, name):
    """A COPY OF THE TREE, not of `tools/` alone. `case_real_header` and
    `case_committed_tables_are_marked` both resolve paths RELATIVE TO THE
    REPO ROOT, and a harness that gives them a truncated tree measures its own
    plumbing: they would fail under every mutation and every one would score
    CAUGHT. That is the *45 MISSED against fixtures that catch everything*
    failure in the opposite direction, and it was hit on the first run here."""
    d = os.path.join(work, name)
    os.makedirs(d)
    shutil.copytree(TOOLS, os.path.join(d, "tools"))
    shutil.copytree(os.path.join(ROOT, "include"), os.path.join(d, "include"))
    return os.path.join(d, "tools")


def run_selftest(tools):
    r = subprocess.run([sys.executable,
                        os.path.join(tools, "loop_twin_matrix_quarantine_test.py")],
                       capture_output=True, text=True, cwd=tools)
    return r.returncode, r.stdout + r.stderr


def reds(out):
    return [l for l in out.splitlines() if "FAILED" in l]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    a = ap.parse_args()
    if a.list:
        for m in MUTATIONS:
            print("%-30s %s" % (m[0], m[2]))
        return 0
    if not MUTATIONS:
        print("REFUSED: 0 mutations. A mutation harness with nothing to mutate "
              "reports a pass about nothing (exit 2, never 0).")
        return 2

    work = tempfile.mkdtemp(prefix="mutate_inst_")
    base = mirror(work, "base")
    # THE POSITIVE CONTROL, first. A selftest that is ALREADY red catches every
    # mutation for the wrong reason, and the run would read as a perfect score.
    rc, out = run_selftest(base)
    if rc != 0:
        print("REFUSED: the UNMUTATED copy of tools/ is not green (rc %d). "
              "Every mutation below would be 'caught' by a pre-existing red.\n%s"
              % (rc, out))
        return 2
    print("control: unmutated selftest is GREEN (%s)"
          % out.strip().splitlines()[-1])

    caught = missed = 0
    for m in MUTATIONS:
        mid, fname, what, _a, _r, expect = m
        d = mirror(work, mid)
        apply_mutation(d, m)
        rc, out = run_selftest(d)
        hit = [e for e in expect
               if any(e in l for l in reds(out)) or (rc != 0 and e in out)]
        # A mutation is CAUGHT only if it goes non-zero AND the cases that name
        # it are the ones that went red. "something else failed" is not a catch.
        ok = rc != 0 and len(hit) == len(expect)
        if ok:
            caught += 1
        else:
            missed += 1
        print("%-30s %-7s rc=%d  expect %s -> red %s"
              % (mid, "CAUGHT" if ok else "MISSED", rc, expect, hit))
        if not ok:
            print("      what it broke: %s" % what)
            for l in reds(out)[:6]:
                print("      red: %s" % l.strip())
            if not reds(out):
                print("      (no case went red at all — this is a HOLE)")
    print("\nmutate_instrument: %d mutation(s), %d CAUGHT, %d MISSED"
          % (len(MUTATIONS), caught, missed))
    return 1 if missed else 0


if __name__ == "__main__":
    sys.path.insert(0, TOOLS)
    sys.exit(main())
