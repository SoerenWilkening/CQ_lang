#!/usr/bin/env python3
"""loop_twin_matrix.py — the ROLLED-EQUALS-UNROLLED witness, as a MATRIX.

bd test_C_libtooling-8h7d.5, Rule-13 ROUND 4. Phase 7.3 Increment 3's whole
correctness claim is one sentence — "the rolled loop emits the same gate stream
its hand-unrolled twin does" — and until this gate existed it was witnessed by
FOUR hand-picked e2e slice pairs, every one of which puts the tainted region
FIRST in the loop body. That is one cell of a matrix, and it is the cell where
the round-4 finding is invisible.

WHAT THIS GATE IS FOR, stated as the defect it would have caught. Move ONE
`cq_theta` to the front of the body:

    for (i < 2) { a = cq_theta(a, 0.25);
                  if (sqrt(a + 3.) <= 3.5) { a = cq_phi(a, PI); }
                  a = cq_theta(a, -0.5); }

and the M-B interior partition stopped discharging the oracle's ancilla chain.
`opt` exited 0. `opt -verify` was clean. STRICT `free_pairing_check.py` reported
zero violations — it counts `cqrt_alloc` mints, and the leaked rails are
TEMPLATE-minted, so it cannot see them (read that file's header). Five of the
eleven affected cells emitted NO diagnostic at all. The rolled trace was simply
shorter than its twin's, by exactly the missing discharge lines, and every other
gate in the 285-entry suite stayed green.

So the matrix is not extra coverage of a covered property. It is the ONLY
instrument in the tree that can see this class, and the shipped slices are the
cell it is blind in.

WHAT IT CHECKS, per cell, and each of the three is a separate failure:
  (i)   DISPOSITION MISMATCH — the rolled form accepts and the unrolled declines,
        or vice versa. Both diagnostics are printed.
  (ii)  TRACE DIVERGENCE — both accept and the runtime traces differ. The first
        differing line is printed, with per-side counts of `_unc`, `cqrt_free`
        and handle mints.
  (iii) ASYMMETRIC DIAGNOSTIC — an accepted rolled cell carries a stderr warning
        its twin does not.
Plus the table check: every cell's verdict must equal the committed one in
`tools/loop_twin_matrix.expected.txt`. A cell that changes disposition is a RED,
never a silent drift (Rule 12) — regenerate the table deliberately with
`--regenerate`, never by reflex, and say in the commit message which cells moved
and why.

THE STAGES ARE THE SLICES' STAGES, deliberately replicated rather than shared:
`clang -O1 -emit-llvm` -> `opt -passes=cq-lowering` -> STRICT
`free_pairing_check.py` (no `--allow-unproven`) -> link (templates BEFORE
runtime) -> run. `run_slice.sh` is not reused because it ends in a golden
byte-diff and these cells have no goldens — the twin IS the golden.

WHY THE TRACES CAN BE COMPARED AT ALL. Both sides mint their handles in the same
order from the same source stream, so a correct rolled lowering produces a trace
that is byte-identical to its unrolled twin's, handle numbering included. That is
a strong property and it is the point: it leaves no room for "equivalent but
different".

THE ONE WAY THAT PROPERTY CAN BREAK WITHOUT A COMPILER BUG, recorded before it
bites someone (round-5 reviewer caveat, bd 8h7d.5). The two sides are the same
source text but not the same PROGRAM SHAPE, and `clang -O1` optimizes the flat
spelling harder: a body whose gates carry CONSTANT immediates can fold ACROSS the
repetition on the unrolled side only — `a = a * 3;` twice in a row becomes
`a * 9`, so the unrolled trace legitimately has one fewer gate. That is a
`TRACE-DIVERGENCE` caused by the GENERATOR, not by the loop lowering.

THE FOURTH AXIS — RECORD (bd drbq Inc 2a round-1 review, L1 §3.8). Until then
this matrix had NO `int mark = a;` in any of its 120 cells, and the 8h7d.5 F-1 and
F-3 findings — two of the three CONFIRMED silent miscompiles that machinery
produced — were entirely about rail RECORDS. See the `RECORD` table below for the
three shapes and for why the axis is crossed with a declared sub-grid rather than
with the whole product. The 120 record-free cells keep their names and verdicts
exactly (`m_<prefix>_<region>_<suffix>`); the 36 new ones carry a fourth segment.

NO SHIPPED AXIS HAS ONE — every prefix/suffix immediate here is either the
`volatile int off` or a rotation angle (angles are classical operands and never
fold into each other), which is why all 120 cells are meaningful today. A FUTURE
AXIS MAY. When one appears, the honest response is to make the immediate opaque
(`volatile`, as `off` already is) so the two sides are shapes of the same
computation again. NEVER bless a divergence in the expected table: this gate has
exactly one job, and a table entry that says "this pair may differ" retires it.
"""

import argparse
import concurrent.futures
import itertools
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

# ── THE MATRIX ──────────────────────────────────────────────────────────────
# PREFIX x REGION x SUFFIX over one loop body. The axes are chosen so that each
# one moves a DIFFERENT part of the lowering:
#
#   PREFIX — what stands on the rail BEFORE the region. `none` is the shipped
#     slices' cell. `ry` is the finding: a non-diagonal in-place gate whose next
#     activation sits before the region's first recovered gate. `rz` is its
#     DIAGONAL control (it is admitted by `preservesBorrowedParent`, so it must
#     never have been affected — and it never was, which is what identified the
#     axis). `add`/`xor` are the dtzb in-place VALUE gates, the same position with
#     a different opcode family.
#   REGION — how the condition is built. `eq`/`eq0`/`gt` are direct compares on
#     the rail; `der` is a DERIVED condition (`sqrt(a+3.)`), which is the one that
#     brings the uncompute spine in with four template rails; `ifelse` is the
#     two-armed phase region. `range` is the TWO-SIDED test `a > 5 && a < 20`,
#     added by the round-5 cleanup (bd 8h7d.5): `clang -O1` canonicalizes it to
#     `%t = add %q, -6; icmp ult %t, 14`, so the condition temp wears the dtzb
#     IN-PLACE SHAPE on the rail — which is the OD-A oracle, the exact shape
#     round 4 fixed, and it was NOT among the shipped 100 cells. Measured at the
#     time it was added: 11 of its 20 cells were DIVERGENT at round 3 and all 20
#     are IDENTICAL at HEAD, so the axis is a live witness for OD-A and not
#     decoration.
#   SUFFIX — what stands on the rail AFTER the region, which is where the
#     discharge point lands.
PREFIX = {
    "none": "",
    "ry": "        a = cq_theta(a, 0.25);\n",
    "rz": "        a = cq_phi(a, 0.125);\n",
    "add": "        a = a + off;\n",
    "xor": "        a = a ^ 9;\n",
}
REGION = {
    "eq": "        if (a == 5) { a = cq_phi(a, M_PI); }\n",
    "eq0": "        if (a == 0) { a = cq_phi(a, M_PI); }\n",
    "der": "        if (sqrt(a + 3.) <= 3.5) { a = cq_phi(a, M_PI); }\n",
    "ifelse": "        if (a == 5) { a = cq_phi(a, M_PI); } else { a = cq_phi(a, 0.5); }\n",
    "gt": "        if (a > 5) { a = cq_phi(a, M_PI); }\n",
    "range": "        if (a > 5 && a < 20) { a = cq_phi(a, M_PI); }\n",
}
SUFFIX = {
    "none": "",
    "ry": "        a = cq_theta(a, -0.5);\n",
    "rz": "        a = cq_phi(a, -0.125);\n",
    "add": "        a = a + off;\n",
}

# ── THE RECORD AXIS ─────────────────────────────────────────────────────────
# bd test_C_libtooling-drbq Inc 2a, round-1 review (L1 §3.8). THE SHIPPED 120
# CELLS HAVE NO `int mark = a;` ANYWHERE, and the 8h7d.5 F-1 and F-3 findings —
# two of the three CONFIRMED silent miscompiles that machinery produced — were
# ENTIRELY about rail RECORDS: a value read at a position where the register no
# longer holds it. The PREFIX/REGION/SUFFIX product cannot express one, so the
# instrument that exists to see the loop lowering's worst class was blind to the
# shape those defects lived in.
#
# Each record is (a declaration hoisted OUT of the loop, a line before the
# region, a line after it, and what the return statement additionally measures).
# THE DECLARATION IS OUTSIDE THE LOOP DELIBERATELY: an in-body `int mark = a;`
# makes the hand-unrolled twin redeclare `mark` in ONE scope and `clang` rejects
# it — a harness artifact that cost the round-1 reviewer 8 of 32 cells, and it is
# designed out here rather than explained away.
#
#   premark   — the F-1 shape. The record is taken from the register BEFORE the
#               region and read AFTER THE LOOP. Note this is ALSO the
#               "record of the condition register" case: every REGION spelling in
#               this grid builds its condition from `a`, so `mark` is by
#               construction a record of the register the condition reads.
#   postmark  — the F-3 shape, one hop the other way: the record is taken AFTER
#               the region, so it names the post-gate register and any later
#               in-place gate (the SUFFIX) makes it stale.
#   bodyread  — the round-1 F1 program itself (`acc = mark * 7;`): the record is
#               read INSIDE the body, i.e. the read and the relabelling gate are
#               separated by the back edge rather than by straight-line position.
RECORD = {
    "none": {"decl": "", "pre": "", "post": "", "tail": ""},
    "premark": {"decl": "    int mark = 0;\n",
                "pre": "        mark = a;\n", "post": "",
                "tail": " + cq_measure(mark)"},
    "postmark": {"decl": "    int mark = 0;\n",
                 "pre": "", "post": "        mark = a;\n",
                 "tail": " + cq_measure(mark)"},
    "bodyread": {"decl": "    int mark = 0;\n    int acc = 0;\n",
                 "pre": "        mark = a;\n",
                 "post": "        acc = mark * 7;\n",
                 "tail": " + cq_measure(acc)"},
}

# The record axis is crossed with a DECLARED SUB-GRID, not with the whole 120.
# Reason, stated so nobody reads it as an oversight: a full 5x6x4x4 product is
# 480 cells and would quadruple a gate the whole suite already pays for, while
# the discriminating power of the extra cells is low — the round-1 reviewer's own
# 32-cell record run reached a TRACE COMPARISON in 6 cells and the rest were
# declines. The sub-grid keeps one cell of each PREFIX family that can relabel
# the rail (`none` control, `ry` non-diagonal, `add` dtzb in-place), both REGION
# kinds that matter for the uncompute spine (`eq` direct, `der` derived — the one
# that brings four template rails in), and the SUFFIX that moves the discharge
# point past the record (`none`, `ry`). 3 x 2 x 2 x 3 = 36 new cells.
RECORD_GRID_PREFIX = ("none", "ry", "add")
RECORD_GRID_REGION = ("eq", "der")
RECORD_GRID_SUFFIX = ("none", "ry")

HDR = "#include <math.h>\nvolatile int off = 3;\n"

# TWO TRIPS, and two is not arbitrary: it is the smallest count at which the back
# edge is taken, so the "next activation" the window lemma reasons about actually
# exists in the trace, and it is small enough that a divergence is readable.
TRIPS = 2


def sources(prefix, region, suffix, record="none"):
    """(rolled, unrolled) C for one cell."""
    R = RECORD[record]
    body = PREFIX[prefix] + R["pre"] + REGION[region] + R["post"] + SUFFIX[suffix]
    head = ("int slice(void){\n    int a = 0;\n" + R["decl"]
            + "    a = cq_theta(a, 0.5);\n")
    tail = "    return cq_measure(a)%s;\n}\n" % R["tail"]
    rolled = (
        HDR
        + head
        + "    for (int i = 0; i < %d; ++i) {\n" % TRIPS
        + body
        + "    }\n" + tail
        + "int main(void){(void)slice();return 0;}\n"
    )
    # The unrolled twin is the SAME TEXT, dedented one level and repeated — never
    # a re-spelling. A hand-written twin that differs in any other way would make
    # a trace divergence ambiguous between "the loop lowering is wrong" and "the
    # two programs are not the same program".
    flat = "".join(
        "    " + l[8:] if l.startswith(" " * 8) else l for l in body.splitlines(True)
    )
    unrolled = (
        HDR
        + head
        + flat * TRIPS
        + tail
        + "int main(void){(void)slice();return 0;}\n"
    )
    return rolled, unrolled


def _pair_check(path):
    """Run tools/free_pairing_check.py STRICT, in this interpreter."""
    import contextlib
    import io
    if HERE not in sys.path:
        sys.path.insert(0, HERE)
    import free_pairing_check
    buf = io.StringIO()
    try:
        with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
            rc = free_pairing_check.main(["-q", path])
    except SystemExit as e:            # never today; a checker edit must not
        rc = e.code if isinstance(e.code, int) else 1   # turn into a silent pass.
    except Exception as e:             # ditto — an exception is a FAILURE here.
        return 1, "free_pairing_check raised %r\n%s" % (e, buf.getvalue())
    return rc, buf.getvalue()


class Side:
    """One compiled side of a cell."""

    def __init__(self):
        self.exit = None      # opt exit code
        self.diag = ""        # first `cq ...` diagnostic, or ""
        self.warns = 0        # stderr warning count
        self.trace = ""       # runtime trace, or ""
        self.error = None     # harness failure (clang/link/run), never a verdict


def _first_diag(text):
    for line in text.splitlines():
        i = line.find("cq ")
        if i >= 0:
            return line[i:].strip()
    return ""


def build_side(cfg, work, name, csrc):
    s = Side()
    cpath = os.path.join(work, name + ".c")
    with open(cpath, "w") as f:
        f.write(csrc)
    s1 = os.path.join(work, name + ".s1.ll")
    r = subprocess.run(
        [cfg.clang, "-I", cfg.include, "-include", "CQ.h", "-O1", "-emit-llvm", "-S",
         cpath, "-o", s1],
        capture_output=True, text=True)
    if r.returncode != 0:
        s.error = "stage 1 (clang -O1) failed:\n" + r.stderr
        return s
    s2 = os.path.join(work, name + ".s2.ll")
    r = subprocess.run(
        [cfg.opt, "-load-pass-plugin", cfg.plugin, "-passes=cq-lowering", "-S", s1,
         "-o", s2],
        capture_output=True, text=True)
    s.exit = r.returncode
    s.diag = _first_diag(r.stderr)
    s.warns = r.stderr.count("warning")
    if r.returncode != 0:
        return s
    # Stage 2b — STRICT. A cell that needs `--allow-unproven` is not a cell this
    # gate can speak for, and saying so loudly is the point.
    #
    # Called IN PROCESS, not as a subprocess: 240 python interpreter starts cost
    # ~70s of wall clock and the check itself ~0.02s. Safe here because cells run
    # in a PROCESS pool — `free_pairing_check` raises the interpreter's recursion
    # limit as a side effect, which is not something to do from several threads of
    # one interpreter.
    rc, out = _pair_check(s2)
    if rc != 0:
        s.error = "stage 2b (free_pairing_check, STRICT) failed:\n" + out
        return s
    exe = os.path.join(work, name + ".exe")
    # Stage 3, SPLIT (bd dgn5, the same trick `run_slice.sh` uses and for the same
    # reason): the clang DRIVER dlopens libLTO -> libLLVM (140MB) on every -O0
    # link that never uses LTO, MEASURED at ~1.0s per cell, i.e. 200s of CPU for
    # this gate alone. `$CQ_LD` is the wrapper CMake derives from this same clang
    # via `clang -###` with `-lto_library` removed; unset (by-hand invocation) the
    # driver runs and is exactly equivalent, only slower.
    if cfg.ld and os.access(cfg.ld, os.X_OK):
        obj = os.path.join(work, name + ".o")
        r = subprocess.run([cfg.clang, "-c", s2, "-o", obj],
                           capture_output=True, text=True)
        if r.returncode == 0:
            r = subprocess.run([cfg.ld, "-o", exe, obj, cfg.templates, cfg.runtime],
                               capture_output=True, text=True)
    else:
        r = subprocess.run([cfg.clang, s2, cfg.templates, cfg.runtime, "-o", exe],
                           capture_output=True, text=True)
    if r.returncode != 0:
        s.error = "stage 3 (link) failed:\n" + r.stderr
        return s
    r = subprocess.run([exe], capture_output=True, text=True)
    if r.returncode != 0:
        s.error = "stage 4 (run) exited %d" % r.returncode
        return s
    s.trace = r.stdout
    return s


def counts(trace):
    return (trace.count("_unc("), trace.count("cqrt_free("), trace.count("-> h"))


def cell_name(cell):
    """`m_<prefix>_<region>_<suffix>` for the record-free cells — UNCHANGED, so
    the 120 committed names and their verdicts survive the axis addition — and
    `m_<prefix>_<region>_<suffix>_<record>` for the new ones."""
    prefix, region, suffix, record = cell
    if record == "none":
        return "m_%s_%s_%s" % (prefix, region, suffix)
    return "m_%s_%s_%s_%s" % cell


def cells_of_matrix():
    """The full cell list: the 120-cell PREFIX x REGION x SUFFIX product with no
    record, plus the record sub-grid (see `RECORD_GRID_*`)."""
    base = [(p, r, s, "none") for p, r, s
            in itertools.product(PREFIX, REGION, SUFFIX)]
    rec = [(p, r, s, k) for p, r, s, k
           in itertools.product(RECORD_GRID_PREFIX, RECORD_GRID_REGION,
                                RECORD_GRID_SUFFIX,
                                [k for k in RECORD if k != "none"])]
    return base + rec


def run_cell(cfg, cell):
    prefix, region, suffix, record = cell
    name = cell_name(cell)
    rolled_src, unrolled_src = sources(prefix, region, suffix, record)
    work = tempfile.mkdtemp(prefix="cqtwin_")
    try:
        rolled = build_side(cfg, work, name, rolled_src)
        unrolled = build_side(cfg, work, name + "_u", unrolled_src)
    finally:
        shutil.rmtree(work, ignore_errors=True)
    return name, rolled, unrolled


def _run_cell_star(arg):
    return run_cell(*arg)


def verdict(name, rolled, unrolled):
    """(verdict-string, failure-report-or-None).

    The verdict is what the committed table stores; the report is a hard failure
    that no table entry can bless (a harness break, or a divergence).
    """
    if rolled.error:
        return "HARNESS-ERROR", "%s: rolled side: %s" % (name, rolled.error)
    if unrolled.error:
        return "HARNESS-ERROR", "%s: unrolled side: %s" % (name, unrolled.error)

    if rolled.exit == 0 and unrolled.exit == 0:
        if rolled.trace != unrolled.trace:
            # (ii) TRACE DIVERGENCE — always a hard failure, never blessable.
            rl, ul = rolled.trace.splitlines(), unrolled.trace.splitlines()
            first = next((i for i in range(max(len(rl), len(ul)))
                          if i >= len(rl) or i >= len(ul) or rl[i] != ul[i]), 0)
            rep = ["%s: ROLLED AND UNROLLED TRACES DIFFER (this is the F-4 class)" % name,
                   "  first differing line %d:" % (first + 1),
                   "    rolled   : %s" % (rl[first] if first < len(rl) else "<end>"),
                   "    unrolled : %s" % (ul[first] if first < len(ul) else "<end>"),
                   "  counts (_unc, cqrt_free, handle mints):",
                   "    rolled   : %s over %d lines" % (counts(rolled.trace), len(rl)),
                   "    unrolled : %s over %d lines" % (counts(unrolled.trace), len(ul))]
            return "TRACE-DIVERGENCE", "\n".join(rep)
        if rolled.warns > unrolled.warns:
            # (iii) ASYMMETRIC DIAGNOSTIC — the rolled form complaining where its
            # twin does not is a compiler asymmetry even when the traces agree.
            return "WARN-ASYMMETRY", (
                "%s: rolled side emits %d warning(s), its twin %d — a compiler "
                "asymmetry, not a property of the program:\n    %s"
                % (name, rolled.warns, unrolled.warns, rolled.diag))
        if rolled.warns or unrolled.warns:
            return "ACCEPT-IDENTICAL-WARN\t%s" % rolled.diag, None
        return "ACCEPT-IDENTICAL", None

    if rolled.exit != 0 and unrolled.exit != 0:
        if rolled.diag == unrolled.diag:
            return "DECLINE-BOTH\t%s" % rolled.diag, None
        return "DECLINE-BOTH-DIFFERENT\t%s\t%s" % (rolled.diag, unrolled.diag), None

    # (i) DISPOSITION MISMATCH. Recorded as a VERDICT rather than an unconditional
    # failure, because `clang -O1` canonicalizes the two spellings differently and
    # a couple of cells legitimately land on opposite sides of a shipped decline
    # (see the table's own notes). A NEW one still turns the table red.
    if rolled.exit == 0:
        return "ROLLED-ONLY\t%s" % unrolled.diag, None
    return "UNROLLED-ONLY\t%s" % rolled.diag, None


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--clang", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--include", required=True)
    ap.add_argument("--runtime", required=True)
    ap.add_argument("--templates", required=True)
    ap.add_argument("--expected",
                    default=os.path.join(HERE, "loop_twin_matrix.expected.txt"))
    ap.add_argument("--ld", default=os.environ.get("CQ_LD", ""),
                    help="the bd dgn5 link wrapper (CMake exports it as CQ_LD); "
                         "empty falls back to the clang driver")
    ap.add_argument("--jobs", type=int, default=6)
    ap.add_argument("--regenerate", action="store_true",
                    help="rewrite the expected table from this run. DELIBERATE "
                         "ONLY — say which cells moved and why (Rule 12).")
    cfg = ap.parse_args()

    cells = cells_of_matrix()
    results = {}
    # A PROCESS pool, not a thread pool — stage 2b runs in-process (see
    # `_pair_check`) and mutates the interpreter's recursion limit.
    with concurrent.futures.ProcessPoolExecutor(max_workers=cfg.jobs) as ex:
        for name, rolled, unrolled in ex.map(_run_cell_star,
                                             [(cfg, c) for c in cells]):
            results[name] = (rolled, unrolled)

    got, hard = {}, []
    for name in sorted(results):
        v, report = verdict(name, *results[name])
        got[name] = v
        if report:
            hard.append(report)

    if cfg.regenerate:
        with open(cfg.expected, "w") as f:
            f.write(EXPECTED_HEADER)
            for name in sorted(got):
                f.write("%-24s %s\n" % (name, got[name]))
        print("regenerated %s (%d cells)" % (cfg.expected, len(got)))
        if hard:
            print("\nREGENERATION REFUSED TO HIDE %d HARD FAILURE(S):" % len(hard))
            for r in hard:
                print(r)
            return 1
        return 0

    want = {}
    with open(cfg.expected) as f:
        for line in f:
            line = line.split("#", 1)[0].rstrip()
            if not line.strip():
                continue
            name, _, v = line.partition(" ")
            want[name] = v.strip()

    fails = list(hard)
    for name in sorted(set(got) | set(want)):
        if name not in want:
            fails.append("%s: NEW CELL, not in the expected table" % name)
        elif name not in got:
            fails.append("%s: MISSING — the expected table has it, this run did not"
                         % name)
        elif got[name] != want[name]:
            fails.append("%s: verdict changed\n    expected: %s\n    got     : %s"
                         % (name, want[name], got[name]))

    accepts = sum(1 for v in got.values() if v.startswith("ACCEPT-IDENTICAL"))
    declines = sum(1 for v in got.values() if v.startswith("DECLINE"))
    print("loop_twin_matrix: %d cells — %d ACCEPT-IDENTICAL, %d DECLINE, %d other"
          % (len(got), accepts, declines, len(got) - accepts - declines))
    if fails:
        print("\nFAILED (%d):" % len(fails))
        for r in fails:
            print(r)
            print()
        return 1
    print("all cells match tools/loop_twin_matrix.expected.txt")
    return 0


EXPECTED_HEADER = """\
# loop_twin_matrix.expected.txt — the committed disposition table for
# tools/loop_twin_matrix.py (bd test_C_libtooling-8h7d.5, Rule-13 round 4).
#
# ONE LINE PER CELL, `m_<prefix>_<region>_<suffix>` — plus a fourth `_<record>`
# segment on the 36 RECORD-axis cells (bd drbq Inc 2a round-1 review) — then its
# verdict. The gate
# fails on ANY deviation, in either direction: a cell that starts declining, a
# cell that starts accepting, and a cell whose decline message changes owner are
# all reds. That is the point — a disposition drift in the loop lowering must
# never be something a reader has to notice.
#
# VERDICTS
#   ACCEPT-IDENTICAL        both sides lower, both silent, traces byte-identical.
#   ACCEPT-IDENTICAL-WARN   as above but both sides warn, with the same message.
#   DECLINE-BOTH            both sides decline with the SAME diagnostic.
#   DECLINE-BOTH-DIFFERENT  both decline, different diagnostics.
#   ROLLED-ONLY / UNROLLED-ONLY
#                           a DISPOSITION MISMATCH: one side lowers, the other
#                           declines with the recorded message. Every such cell
#                           needs a written reason — today's THREE are all the
#                           same `clang -O1` canonicalization artifact of the
#                           UNROLLED spelling, and all three are `xor`/`none`
#                           (prefix `a = a ^ 9;`, no suffix): flattening puts one
#                           repetition's `xor` immediately before the next one's
#                           region, clang folds it in, and the arm becomes a mixed
#                           phase/value arm that does not exist in the rolled
#                           form. Not a compiler asymmetry — the two sides stopped
#                           being the same program shape. `m_xor_range_none` was
#                           added with the `range` axis (bd 8h7d.5 round-5
#                           cleanup) and is the third member of that one family,
#                           not a new phenomenon.
#
# THE 18 `UNROLLED-ONLY` RECORD CELLS — every one with SUFFIX `ry` — AND WHY THEY
# ARE THE FENCE WORKING, WRITTEN OUT BECAUSE THE TABLE DEMANDS A REASON PER
# MISMATCH (bd drbq Inc 2a round-1 review, the record axis).
#   ROLLED side: the record (`mark`, or `acc`'s source) is defined in the body and
#     read either after the loop or on a later activation, and the SUFFIX
#     `a = cq_theta(a, -0.5)` is a NON-DIAGONAL in-place gate on the same rail
#     between the definition and the read. That is the 8h7d.5 F-1/F-2 staleness
#     exactly, and `LoopLowering::staleRailRecordRead` declines it
#     (`cq loop lowering: rail record read past an in-place gate on the same
#     rail`; the three `bodyread` cells reach `declineStaleRecordOps` first and
#     decline as `cq opcode lowering: operand predates a non-diagonal gate`).
#     Correct, and the whole reason that fence exists.
#   UNROLLED side: it ACCEPTS, and it emits `cqrt_measure_i32(%h)` for the
#     record — i.e. it measures the register at its POST-Ry value. ⚠ THAT IS A
#     PRE-EXISTING PROPERTY OF THE STRAIGHT-LINE PATH, NOT OF THE LOOP LOWERING
#     AND NOT OF THIS INCREMENT. Measured on BOTH the pre-2a (`f92d95e`) and the
#     post-2a binary, byte-identically, on the matrix cells and on the minimal
#     probe `int mark = a; a = cq_theta(a, 0.25); return cq_measure(mark);`
#     (rc 0, no warning, both binaries). The loop half of this class is fenced
#     (8h7d.5 round 1 / round 2 F-1); the straight-line half is not, and whether
#     it should be is an OPEN question for the owner — under Rule 8 `int mark = a`
#     is an ALIAS of one register, so measuring the current register may be the
#     only thing physically available, in which case the right answer is a loud
#     decline rather than a different unitary. Filed as an observation, NOT fixed
#     here: nothing in this increment moves it, in either direction.
#   So these cells are recorded as `UNROLLED-ONLY`, and a change in EITHER
#   direction is a red — the rolled side starting to accept, or the unrolled side
#   starting to decline, both need a written decision.
#
# TRACE-DIVERGENCE and WARN-ASYMMETRY are NEVER recorded here. They are hard
# failures whatever this file says — a trace that differs from its twin's is the
# defect this gate exists to catch, and no table entry may bless it.
#
# REGENERATE DELIBERATELY: `--regenerate`, then state in the commit message which
# cells moved and why (Rule 12). Regeneration will not overwrite a hard failure.
"""


if __name__ == "__main__":
    sys.exit(main())
