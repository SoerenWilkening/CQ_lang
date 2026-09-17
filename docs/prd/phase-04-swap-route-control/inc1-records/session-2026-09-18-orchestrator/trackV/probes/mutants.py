#!/usr/bin/env python3
"""mutants.py — MAKE THE NESTED-LOOP AXIS FAIL ON PURPOSE.

`CLAUDE.md` L10: *an instrument's failure mode is to report a PASS, so the only
instrument worth citing is one that has been made to fail on purpose.* This is
that, for bd `test_C_libtooling-vsr6`.

Each mutant is a literal source edit to a COPY of `tools/loop_twin_matrix.py`
(and, where the mutation is in the selftest's own subject, nothing else is
touched). The copy plus the unmodified selftest are run in an isolated
directory; a mutant is CAUGHT if the selftest exits non-zero, MISSED if it exits
0. MISSED is the number that matters and it is reported whether it is zero or
not.

⚠ THREE PROPERTIES THIS HARNESS HAS BECAUSE THE ONES BEFORE IT DID NOT
(`CLAUDE.md` L10's six measured instances):

  * a mutant whose textual edit does not APPLY is reported as `NOT-APPLIED` and
    counts as a HOLE, never as a pass — an injection matrix that silently
    substitutes nothing measures itself;
  * a run with ZERO mutants exits non-zero, because `0 mutations, MISSED 0` is
    the shape of a harness with no subject;
  * it runs the selftest by the SAME command the ctest entry runs
    (`python3 tools/loop_twin_matrix_quarantine_test.py`, no flags), so it cannot
    measure a weaker check than the gate does.

    python3 mutants.py <REPO>
"""
import os
import shutil
import subprocess
import sys
import tempfile

# (id, what it breaks, file, old, new)
MUTANTS = [
    ("M1", "nest_cells() returns nothing — the axis is defined and never runs",
     "loop_twin_matrix.py",
     "    out = []\n    # N1 — the CORE product.",
     "    return []\n    out = []\n    # N1 — the CORE product."),
    ("M2", "sub-grid N4 (depth 3) is dropped from the axis",
     "loop_twin_matrix.py",
     '    out += [("none", "l2d3d", "none", "none", "l2im")]\n',
     "\n"),
    ("M3", "the INNER LOOP is inlined — `l2im` stops being a loop at all",
     "loop_twin_matrix.py",
     '    "l2im": {"pre": "", "post":\n'
     '             "        for (int j = 0; j < 2; ++j) {\\n"',
     '    "l2im": {"pre": "", "post":\n'
     '             "        {\\n"'),
    ("M4", "the ENCLOSING loop is dropped for the inverted sub-grid",
     "loop_twin_matrix.py",
     '    "l2inv": ("    for (int io = 0; io < 2; ++io) {\\n"\n'
     '              "        int w = cq_theta(7, 0.3);\\n",',
     '    "l2inv": ("        int w = cq_theta(7, 0.3);\\n",'),
    ("M5", "the SIBLING loop is dropped for sub-grid N3",
     "loop_twin_matrix.py",
     'N_PRELOOP = {"l2sib": _N_SIBLING, "l2sibd": _N_SIBLING}',
     'N_PRELOOP = {}'),
    ("M6", "the enclosure OPENS on the rolled side only — the twin is a "
     "different program",
     "loop_twin_matrix.py",
     '        + preloop\n'
     '        + eopen\n'
     '        + ("    int i = 0;\\n" if index else "")',
     '        + preloop\n'
     '        + ("    int i = 0;\\n" if index else "")'),
    ("M7", "the axis is not wired into cells_of_matrix()",
     "loop_twin_matrix.py",
     "    cells = base + rec + ry + f + b + k + n",
     "    cells = base + rec + ry + f + b + k"),
    ("M8", "the post-loop interference column collapses onto its sibling",
     "loop_twin_matrix.py",
     '     for r in ("l2nd", "l2bd", "l2cd", "l2sibd", "l2d3d")})',
     '     for r in ()})'),
    ("M9", "the enclosure CLOSES on the unrolled side only",
     "loop_twin_matrix.py",
     '        + "    }\\n" + eclose + postloop + tail',
     '        + "    }\\n" + postloop + tail'),
    ("M10", "the `l2iu` inner loop reads its OWN mint, so the UNMARKED column "
     "becomes a second copy of the MARKED one",
     "loop_twin_matrix.py",
     '    "l2iu": {"pre": "", "post":\n'
     '             "        for (int j = 0; j < 2; ++j)\\n"\n'
     '             "            s += cq_measure((a >> (j + 8)) & 1);\\n"},',
     '    "l2iu": {"pre": "", "post":\n'
     '             "        for (int j = 0; j < 2; ++j) {\\n"\n'
     '             "            int u = cq_theta(6, 0.4);\\n"\n'
     '             "            s += cq_measure((u >> j) & 1);\\n"\n'
     '             "        }\\n"},'),
    ("M11", "a boundary control loses its pin — built, compared, never checked",
     "loop_twin_matrix.py",
     '        "q_nestinline": "ACCEPT-IDENTICAL",\n',
     "\n"),
    # ⚠ M12 IS A *CONSISTENT* RENAME, ON PURPOSE. An inconsistent one trips the
    # sub-grid size assert or the inner-axis check first, so it would be CAUGHT
    # by a guard that is not the one under test and `case_quarantined_cells_exist`
    # would stay unpinned — the bd `e1gr` shape (two clauses mutually redundant
    # over the corpus, neither individually measured). Renaming the region in
    # BOTH places leaves the matrix internally perfect — 23 cells, every size
    # asserted, every twin correct — and leaves exactly one thing wrong: the
    # committed quarantine now names cells that do not exist.
    ("M12", "the axis is renamed CONSISTENTLY, so the committed quarantine "
     "names cells the matrix no longer produces",
     "loop_twin_matrix.py",
     ['    "l2b": _N_BIT, "l2bd": _N_BIT,',
      'N_CORE_REGION = ("l2n", "l2nd", "l2b", "l2bd", "l2c", "l2cd")'],
     ['    "l2bb": _N_BIT, "l2bbd": _N_BIT,',
      'N_CORE_REGION = ("l2n", "l2nd", "l2bb", "l2bbd", "l2c", "l2cd")']),
    # ⚠ M13 EXISTS BECAUSE M12 WAS CAUGHT BY THE WRONG GUARD. A consistent
    # rename has knock-on effects (`POSTLOOP_FOR_REGION` keeps the old key, so
    # the interference column collapses) and the axis guard fires first, leaving
    # `case_quarantined_cells_exist` unpinned — which is bd `e1gr`'s shape: two
    # checks mutually redundant over the corpus, neither individually measured.
    # This mutant touches ONLY the committed quarantine, which nothing else in
    # the selftest reads for its cell names.
    ("M13", "a committed quarantine block names a cell the matrix does not "
     "produce — ONLY the quarantine guard can see this",
     "loop_twin_matrix.quarantine.txt",
     "cell     m_none_l2b_none_none_l2im",
     "cell     m_none_l2b_none_none_l2ZZ"),
]


def main():
    repo = sys.argv[1]
    if not MUTANTS:
        print("REFUSED: zero mutants. `0 mutations, MISSED 0` is the shape of a "
              "harness with no subject, not a pass.")
        return 2
    caught = missed = notapplied = 0
    for mid, what, fname, old, new in MUTANTS:
        d = tempfile.mkdtemp(prefix="cqmut_")
        try:
            tools = os.path.join(d, "tools")
            os.makedirs(tools)
            for f in ("loop_twin_matrix.py",
                      "loop_twin_matrix_quarantine_test.py",
                      "loop_twin_matrix.expected.txt",
                      "loop_twin_matrix.quarantine.txt",
                      "loop_twin_matrix.expected.register.txt",
                      "loop_twin_matrix.quarantine.register.txt",
                      "free_pairing_check.py"):
                shutil.copy2(os.path.join(repo, "tools", f),
                             os.path.join(tools, f))
            os.makedirs(os.path.join(d, "include"))
            shutil.copy2(os.path.join(repo, "include", "CQ.h"),
                         os.path.join(d, "include", "CQ.h"))
            path = os.path.join(tools, fname)
            text = open(path).read()
            # A mutant is one or SEVERAL textual edits (M12 needs two to stay
            # internally consistent); a single pair is the one-element case.
            pairs = list(zip(old, new)) if isinstance(old, list) else [(old, new)]
            counts = [text.count(o) for o, _ in pairs]
            if any(c != 1 for c in counts):
                print("%-4s NOT-APPLIED (anchor occurrence counts %s) — %s"
                      % (mid, counts, what))
                notapplied += 1
                continue
            for o, nn in pairs:
                text = text.replace(o, nn)
            open(path, "w").write(text)
            r = subprocess.run(
                [sys.executable,
                 os.path.join(tools, "loop_twin_matrix_quarantine_test.py")],
                capture_output=True, text=True)
            if r.returncode != 0:
                caught += 1
                first = next((l for l in (r.stdout + r.stderr).splitlines()
                              if "FAILED" in l or "Error" in l
                              or "error" in l), "")
                print("%-4s CAUGHT  — %s\n         %s"
                      % (mid, what, first[:150]))
            else:
                missed += 1
                print("%-4s MISSED  — %s" % (mid, what))
        finally:
            shutil.rmtree(d, ignore_errors=True)
    print("\nmutants: %d applied, %d CAUGHT, %d MISSED, %d NOT-APPLIED"
          % (caught + missed, caught, missed, notapplied))
    return 1 if (missed or notapplied) else 0


if __name__ == "__main__":
    sys.exit(main())
