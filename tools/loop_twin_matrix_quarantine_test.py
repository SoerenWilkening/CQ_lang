#!/usr/bin/env python3
"""loop_twin_matrix_quarantine_test.py — the QUARANTINE's own mutant validation.

bd test_C_libtooling-drbq Increment 3, round-1 Rule-13 review (lens L7).

WHY THIS EXISTS, in the form of the argument this project already made twice.
`tools/free_pairing_check_test.py`'s header says a checker nobody has tried to
fool is a checker nobody should trust, and `fixture_guard_liveness.py`'s says the
same of a FileCheck negative. `tools/loop_twin_matrix.py`'s quarantine is a THIRD
instance of that shape and a more dangerous one: it is the only mechanism in the
tree that lets a KNOWN rolled-vs-flat trace divergence pass a gate whose entire
purpose is to fail on trace divergence. If its semantics silently degenerate to
"skip these 15 cells", the gate reports green while witnessing nothing about them
— and nobody would notice, because the green looks exactly the same.

So every claim the quarantine makes is tested here as a claim, one run each:

  NEG-1  a pinned SIGNATURE that changed          -> FAIL
  NEG-2  a quarantined cell that STOPPED diverging -> FAIL ("quarantine stale")
  NEG-3  a divergent cell that is NOT quarantined  -> FAIL (unchanged behaviour)
  NEG-4  a cell present in BOTH files              -> FAIL
  NEG-5  a quarantine entry naming a cell that does not exist -> FAIL
  NEG-6  a BOUNDARY CONTROL that stopped being identical      -> FAIL
  NEG-7  `--regenerate` over an un-quarantined divergence -> FAIL, and the
         expected table is BYTE-UNCHANGED (round-2 review F-R2-1: it used to
         write `TRACE-DIVERGENCE` into a file whose own header forbids that
         verdict, and only THEN print "REGENERATION REFUSED")
  NEG-8  `--regenerate` while a BOUNDARY CONTROL has moved -> FAIL, table
         BYTE-UNCHANGED (F-R2-2: both write modes returned before the controls
         ever ran, so this exited 0)
  NEG-9  `--refresh-quarantine` while a BOUNDARY CONTROL has moved -> FAIL, the
         quarantine BYTE-UNCHANGED (F-R2-2, and the sharper half: re-pinning is
         the one operation that most needs the class story to be measured)
  POS-2  `--refresh-quarantine` RE-PINS a moved digest and can neither ADD nor
         REMOVE a cell — the cell set before == after, and the two agreeing
         cells are not swept in
  POS-3  `--regenerate` on a clean run still WRITES, with the quarantined cells
         omitted — so "refuse to write" cannot degenerate into "never write"

and, since 2026-09-15, the HEADER CONTRACT (bd test_C_libtooling-gfsk — the
defect where `--regenerate` deleted 54 lines of Rule-13 RULING prose from the
expected table and printed a success message):

  NEG-10 `--regenerate` over a table with NO END-OF-HEADER marker -> FAIL, table
         BYTE-UNCHANGED (the script may not guess which half is yours)
  NEG-11 the same for `--refresh-quarantine` -> FAIL, quarantine BYTE-UNCHANGED
  NEG-12 a PLAIN run over an unmarked expected table -> FAIL (rule 6: the marker
         is checked at the gate, not first noticed when it eats something)
  NEG-13 the same for the quarantine
  POS-4  `--regenerate` PRESERVES hand-added prose above the marker BYTE-FOR-BYTE
  POS-5  the same for `--refresh-quarantine`
  POS-6  `--regenerate` over a table that DOES NOT EXIST seeds the constant, and
         the seed carries the marker — a contract whose own seed violated it
         would be unusable from the first write

and bd test_C_libtooling-rpkr's NON-VACUITY FLOOR for the BANK axis, whose whole
point is that its negatives have IDENTICAL traces on both sides:

  POS-7  a bank trace AT the floor passes (or every negative below is satisfied
         by a check that always fires)
  NEG-15 both sides lost the bank measurements -> FAIL `VACUOUS-ACCEPT`
  NEG-16 only the ROLLED side is thin -> FAIL
  NEG-17 the MINT half of the floor -> FAIL
  NEG-18 `--regenerate` over a VACUOUS ACCEPT -> FAIL, table BYTE-UNCHANGED
  POS-8  a NON-bank cell with the same thin trace is NOT flagged — the floor is
         scoped, or it would have reddened 338 committed cells

plus the all-good CONTROL, which must PASS, four standalone guards
(`write_preserving_header` made to fail twice, the four COMMITTED tables carry
the marker, `BANK_FLOOR` covers the whole axis non-emptily, an EMPTY matrix
exits 2), and the surface guards. 51 cases.

Six of them assert on FILE BYTES, not just on the exit code: a refusal that
still wrote the file is exactly the defect F-R2-1 was, and it printed a non-zero
exit the whole time it was doing it.

HOW IT AVOIDS COSTING ANYTHING. `main()` gets its cell results from `run_cell`,
so the stub below replaces `_run_cell_star`, `build_side` and the process pool
with synthetic traces: **no clang, no opt, no plugin, no subprocess** — the whole
file runs in well under a second. It therefore tests the quarantine's SEMANTICS
and deliberately not its measurements; the real 359-cell run is what measures.
"""

import contextlib
import io
import os
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import loop_twin_matrix as M  # noqa: E402

CELLS = ["m_a", "m_b", "m_c", "m_d"]

# ⚠ `install()` REPLACES `M.cell_name` with an identity stub, and every case
# after it inherits that. The bd rpkr floor cases need the REAL grammar (their
# cells are real five-segment bank cells whose names are the `BANK_FLOOR` keys),
# so the genuine function is captured HERE, before any stubbing, and restored by
# `install_bank`. Measured the hard way: without this, `cell_name(BANK_CELL)`
# returned `"none"`, `BANK_FLOOR.get("none")` was `None`, and FOUR floor cases
# went green against a floor that was never consulted — a stub silently
# disarming the very fence the cases exist to prove.
_REAL_CELL_NAME = M.cell_name
_REAL_CELLS_OF_MATRIX = M.cells_of_matrix

# m_a and m_b diverge (the quarantine candidates); m_c and m_d agree.
BASE = {
    "m_a": ("g1\ng2\nROLLED-A\n", "g1\ng2\nUNROLLED-A\n"),
    "m_b": ("h1\nROLLED-B\n", "h1\nUNROLLED-B\n"),
    "m_c": ("same\n", "same\n"),
    "m_d": ("same2\n", "same2\n"),
}


def _side(trace):
    s = M.Side()
    s.exit, s.trace, s.warns, s.diag = 0, trace, 0, ""
    return s


class _FakePool:
    """Stand in for ProcessPoolExecutor: no pickling, no subprocesses."""

    def __init__(self, *a, **k):
        pass

    def __enter__(self):
        return self

    def __exit__(self, *a):
        return False

    def map(self, fn, args):
        return [fn(a) for a in args]


def _star(arg):
    _cfg, cell = arg
    r, u = BASE[cell[0]]
    return cell[0], _side(r), _side(u)


def install(control_diverges=False):
    M.cells_of_matrix = lambda: [(n, "", "", "", "") for n in CELLS]
    M.cell_name = lambda c: c[0]
    M._run_cell_star = _star
    M.concurrent.futures.ProcessPoolExecutor = _FakePool
    # Two positional args since bd 3qlq Inc 1 (`control_sources(name, surface)`).
    # It was one, and the mismatch made THIS FILE — the quarantine's own mutant
    # validation, and a ctest entry — die with a TypeError before a single case
    # ran. Measured at ffa95cc: `RC=1, TypeError: install.<locals>.<lambda>()
    # takes 1 positional argument but 2 were given`. A selftest that cannot start
    # is a selftest that validates nothing, and it reported that as an ERROR only
    # because it happened to crash rather than to pass.
    M.control_sources = lambda name, surface="register": ("", "")
    # The stub's control traces are synthetic ("ctl\n" on both sides), so on the
    # `void` surface they cannot reproduce the REAL pinned pair
    # (q_armoncond DECLINE-BOTH-DIFFERENT). Pin them to what the stub actually
    # produces: this file validates the quarantine's SEMANTICS and deliberately
    # not its measurements (see the module docstring), and the real pins are
    # measured by the 274-cell run.
    M.SURFACE_CONTROL_VERDICTS = dict(M.SURFACE_CONTROL_VERDICTS)
    M.SURFACE_CONTROL_VERDICTS["void"] = {"q_noregion": "ACCEPT-IDENTICAL",
                                          "q_armoncond": "ACCEPT-IDENTICAL"}
    if control_diverges:
        M.build_side = lambda cfg, work, name, src: _side(
            "ctl\n" if name.endswith("_u") else "ctl-DIFFERENT\n")
    else:
        M.build_side = lambda cfg, work, name, src: _side("ctl\n")


# The two stand-in headers. WRITTEN HERE rather than read from include/, so the
# twelve semantic cases stay dependency-free and cannot be reddened by an
# unrelated header edit. The SHIPPED header is asserted separately, once, by
# `case_real_header` — which is the assertion round-1 finding F-L5-7(b) says was
# missing (the guard had only ever been exercised against a stand-in).
HEADERS = {
    "void": "void                cq_phi     (double angle);\n",
    "register": "int cq_phi_i32(int q, double angle);\n"
                "#define cq_phi(q, a) cq_phi_i32((q), (a))\n",
}


def run(qtext, etext, extra=(), surface="register"):
    d = tempfile.mkdtemp(prefix="qtest_")
    q, e = os.path.join(d, "q.txt"), os.path.join(d, "e.txt")
    # `None` means DO NOT CREATE THE FILE — the bd gfsk contract's rule 4 (a
    # missing table is seeded from the constant) has to be tested against a file
    # that genuinely is not there, not against an empty one.
    if qtext is not None:
        with open(q, "w") as f:
            f.write(qtext)
    if etext is not None:
        with open(e, "w") as f:
            f.write(etext)
    inc = os.path.join(d, "include")
    os.makedirs(inc, exist_ok=True)
    with open(os.path.join(inc, "CQ.h"), "w") as f:
        f.write(HEADERS[surface])
    argv = ["loop_twin_matrix", "--clang", "c", "--opt", "o", "--plugin", "p",
            "--include", inc, "--runtime", "r", "--templates", "t", "--jobs", "1",
            "--phi-surface", surface,
            "--quarantine", q, "--expected", e] + list(extra)
    old, buf = sys.argv, io.StringIO()
    sys.argv = argv
    try:
        with contextlib.redirect_stdout(buf):
            rc = M.main()
    finally:
        sys.argv = old
    return rc, buf.getvalue(), q, e


def block(name, digest, rolled, unrolled):
    return ("cell     %s\nclass    A\nbd       bd-test\nowner     test\n"
            "digest   %s\nrolled   %s\nunrolled %s\n\n"
            % (name, digest, rolled, unrolled))


# ── THE HEADER CONTRACT'S FIXTURES (bd test_C_libtooling-gfsk) ──────────────
# `SENTINEL` is the 54-line `b6ap` ruling paragraph in miniature: one line of
# HAND-ADDED prose sitting above the marker. Every header-contract case below
# asks the same question of it that the defect answered wrongly — *is it still
# there afterwards, byte for byte?* — and the two write modes are tested
# separately, because the defect lived in two functions and was fixed in two.
SENTINEL = ("# ⚠ HAND-ADDED RULING PROSE. bd test_C_libtooling-gfsk deleted 54\n"
            "# lines of exactly this and printed a success message.\n")
EHDR = "# synthetic expected table\n" + SENTINEL + M.HEADER_END_MARKER
QHDR = "# synthetic quarantine\n" + SENTINEL + M.HEADER_END_MARKER


def _prose_survived(which):
    """POS-4 / POS-5: the write mode ran, and every line ABOVE the marker came
    back BYTE-IDENTICAL. Asserted on the bytes rather than on the presence of
    the sentinel, because "the sentinel is somewhere in the file" is satisfied
    by a script that moved it, reflowed it, or wrote it twice."""
    def check(qpath, epath, before, out):
        path = qpath if which == "q" else epath
        want, found_before = M.split_header(_write_tmp(before[which]))
        got, found = M.split_header(path)
        bad = []
        if not found:
            bad.append("%s lost its END-OF-HEADER marker" % path)
        elif got != want:
            bad.append("%s header CHANGED across the write:\n  was %r\n  now %r"
                       % (path, want, got))
        if M.HEADER_END_MARKER.splitlines()[0] not in open(path).read():
            bad.append("the marker text is gone from %s" % path)
        if "preserved" not in out:
            bad.append("the run did not SAY it preserved anything — a silent "
                       "preservation is one refactor away from a silent deletion")
        return bad
    return check


def _write_tmp(text):
    fd, p = tempfile.mkstemp(prefix="qtest_ref_")
    with os.fdopen(fd, "w") as f:
        f.write(text)
    return p


def _seeded_missing(qpath, epath, before, out):
    """POS-6: `--regenerate` over a table that does NOT EXIST seeds the script's
    constant, and the seed CARRIES THE MARKER — otherwise the very next
    regeneration would refuse, and a contract whose own seed violates it is a
    contract nobody can start using."""
    txt = open(epath).read()
    bad = []
    if M.HEADER_END_MARKER not in txt:
        bad.append("the seeded header has no END-OF-HEADER marker, so the next "
                   "--regenerate would REFUSE")
    if "seeded" not in out:
        bad.append("the run did not say it seeded the header")
    rows = [l for l in txt.splitlines() if l.strip() and not l.startswith("#")]
    if sorted(l.split()[0] for l in rows) != ["m_c", "m_d"]:
        bad.append("seeded file has rows %s" % rows)
    return bad


def _unchanged(which):
    """A checker asserting that one of the two files is BYTE-IDENTICAL to what
    the case wrote. This is the assertion F-R2-1 needed and did not have: the
    exit code was already 1 while the forbidden verdict was on disk."""
    def check(qpath, epath, before, out):
        path = qpath if which == "q" else epath
        if open(path).read() != before[which]:
            return ["%s was REWRITTEN by a run that refused" % path]
        return []
    return check


def _refresh_repins(A, B):
    """POS-2: `--refresh-quarantine` re-pins the moved digest and neither adds
    nor removes a cell."""
    def check(qpath, epath, before, out):
        bad = []
        got = M.load_quarantine(qpath)
        if sorted(got) != ["m_a", "m_b"]:
            bad.append("cell set changed: %s (m_c/m_d must NOT be swept in, and "
                       "nothing may be dropped)" % sorted(got))
        else:
            if got["m_a"]["digest"] != A[0]:
                bad.append("m_a digest not re-pinned (%s != %s)"
                           % (got["m_a"]["digest"], A[0]))
            if got["m_b"]["digest"] != B[0]:
                bad.append("m_b digest moved (%s != %s)"
                           % (got["m_b"]["digest"], B[0]))
        return bad
    return check


def _regen_wrote(qpath, epath, before, out):
    """POS-3: the clean `--regenerate` must actually WRITE — a refusal that
    became unconditional would pass every negative above."""
    txt = open(epath).read()
    # ROWS only. `EXPECTED_HEADER` names `TRACE-DIVERGENCE` in prose precisely to
    # forbid it, so the needle has to be read off the data lines, not the file.
    rows = [l for l in txt.splitlines() if l.strip() and not l.startswith("#")]
    bad = []
    if txt == before["e"]:
        bad.append("%s unchanged: --regenerate wrote nothing on a clean run"
                   % epath)
    if any("TRACE-DIVERGENCE" in l for l in rows):
        bad.append("the regenerated table has a TRACE-DIVERGENCE row")
    names = [l.split()[0] for l in rows]
    if sorted(names) != ["m_c", "m_d"]:
        bad.append("regenerated rows are %s, expected the two non-quarantined "
                   "cells" % sorted(names))
    return bad


# The one report string that differs by surface: the `register` surface asserts
# the STRONGER "both controls are ACCEPT-IDENTICAL" rule, the `void` surface a
# PINNED verdict (see `SURFACE_CONTROL_VERDICTS` — the register-surface isolation
# is not expressible with a branch phase). Same defect, same exit code, different
# sentence, so the needle is per surface rather than relaxed to a common prefix.
CTL_MOVED = {"register": "BOUNDARY CONTROL is no longer",
             "void": "BOUNDARY CONTROL moved"}


def case_readback_selfcheck():
    """The header contract's rule 5, as a UNIT: `write_preserving_header` reads
    the file back and proves the header survived, and a failure is a LOUD
    non-zero rather than a printed note beside a success.

    ⚠ This is the case that makes the contract worth citing. bd
    test_C_libtooling-gfsk was not a wrong answer — it was a RIGHT-LOOKING
    success message over a destroyed file, which is `CLAUDE.md` L10's *an
    instrument's failure mode is to report a pass*. So the write path is made to
    fail on purpose twice: once with a header that cannot survive (no marker),
    and once with a read-back that comes back DIFFERENT.
    """
    bad = []
    d = tempfile.mkdtemp(prefix="qtest_rb_")
    p = os.path.join(d, "t.txt")
    hdr = "# prose a human wrote\n" + M.HEADER_END_MARKER
    body = "m_x ACCEPT-IDENTICAL\n"

    # (a) POSITIVE CONTROL. An honest write must go through, or every negative
    # below is satisfied by a function that always raises.
    try:
        M.write_preserving_header(p, hdr, body)
    except SystemExit as e:
        bad.append("an HONEST write raised: %s" % e)
    if open(p).read() != hdr + body:
        bad.append("the honest write did not produce header+body byte-for-byte")

    # (b) MUTANT 1 — a header with no marker cannot survive its own read-back.
    try:
        M.write_preserving_header(p, "# no marker here\n", body)
        bad.append("MUTANT 1 NOT CAUGHT: a header without the marker was "
                   "written and reported as fine")
    except SystemExit as e:
        if "the marker is gone" not in str(e):
            bad.append("MUTANT 1 caught with the wrong message: %s" % e)

    # (c) MUTANT 2 — the bytes on disk are NOT what we meant to preserve. This
    # is the gfsk defect itself, simulated at the one place that can see it.
    orig = M.split_header
    M.split_header = lambda path: ("# SOMETHING ELSE\n" + M.HEADER_END_MARKER,
                                   True)
    try:
        M.write_preserving_header(p, hdr, body)
        bad.append("MUTANT 2 NOT CAUGHT: a write whose header did not survive "
                   "returned normally — this is bd test_C_libtooling-gfsk")
    except SystemExit as e:
        if "did not survive the write" not in str(e):
            bad.append("MUTANT 2 caught with the wrong message: %s" % e)
    finally:
        M.split_header = orig

    # (d) `resolve_header` is a DISCRIMINATOR, not a function that always
    # refuses: a marked file is preserved, an absent one is seeded, an unmarked
    # one is refused. All three, so "refuse everything" cannot pass.
    marked = os.path.join(d, "marked.txt")
    open(marked, "w").write(hdr + body)
    h, note, ref = M.resolve_header(marked, "# CONST\n")
    if ref or h != hdr or "preserved" not in (note or ""):
        bad.append("resolve_header did not PRESERVE a marked file (%r, %r)"
                   % (h, ref))
    h, note, ref = M.resolve_header(os.path.join(d, "absent.txt"), "# CONST\n")
    if ref or not h or M.HEADER_END_MARKER not in h or "seeded" not in (note or ""):
        bad.append("resolve_header did not SEED an absent file")
    open(os.path.join(d, "bare.txt"), "w").write("# prose\n" + body)
    h, note, ref = M.resolve_header(os.path.join(d, "bare.txt"), "# CONST\n")
    if h is not None or not ref or "no END-OF-HEADER marker" not in ref:
        bad.append("resolve_header did not REFUSE an unmarked file")
    return bad


def case_committed_tables_are_marked():
    """Rule 6 of the contract, asked of the FILES THIS TREE SHIPS rather than of
    a stand-in — the same lesson `case_real_header` exists for. All four tables
    named in `SURFACE_TABLES` must carry the marker, or the write modes refuse
    and the plain gate reds."""
    bad = []
    for surface, (e, q) in sorted(M.SURFACE_TABLES.items()):
        for name in (e, q):
            p = os.path.join(os.path.dirname(HERE), "tools", name)
            if not os.path.exists(p):
                bad.append("%s does not exist" % p)
                continue
            h, found = M.split_header(p)
            if not found:
                bad.append("%s has NO END-OF-HEADER marker — --regenerate / "
                           "--refresh-quarantine would refuse it" % name)
            elif h.count("\n") < 10:
                bad.append("%s's header is %d line(s); the marker was probably "
                           "inserted at the top rather than at the boundary"
                           % (name, h.count("\n")))
    return bad


# ── THE BANK AXIS'S NON-VACUITY FLOOR (bd test_C_libtooling-rpkr) ───────────
# Traces are synthetic, exactly as everything else in this file is: the floor is
# a SEMANTIC claim about what a verdict may conclude, and the real 359-cell run
# is what measures. `FAT` meets the floor for `m_none_kprep_none_none_kflat`
# (3 measures, 3 mints); `THIN_M` is the actual defect — the two BANK cell
# measurements vanished because `cq_measure` of an untainted load emits no trace
# line — and `THIN_H` is the mint side of the same question.
_FAT = ("cqrt_alloc_i32(0) -> h0\ncqrt_alloc_i1(0) -> h1\n"
        "cqrt_alloc_i1(0) -> h2\ncqrt_measure_i32(h0) -> 0\n"
        "cqrt_measure_i1(h1) -> 0\ncqrt_measure_i1(h2) -> 0\n")
_THIN_M = ("cqrt_alloc_i32(0) -> h0\ncqrt_alloc_i1(0) -> h1\n"
           "cqrt_alloc_i1(0) -> h2\ncqrt_measure_i32(h0) -> 0\n")
_THIN_H = ("cqrt_alloc_i32(0) -> h0\ncqrt_measure_i32(h0) -> 0\n"
           "cqrt_measure_i1(h0) -> 0\ncqrt_measure_i1(h0) -> 0\n")

BANK_CELL = ("none", "kprep", "none", "none", "kflat")
BANK_NAME = M.cell_name(BANK_CELL)
PLAIN_CELL = ("none", "eq", "none", "none", "none")
PLAIN_NAME = M.cell_name(PLAIN_CELL)


def install_bank(rolled, unrolled, cell=BANK_CELL):
    """One cell, two synthetic traces, no clang and no opt — the same stubbing
    discipline as `install`."""
    M.cell_name = _REAL_CELL_NAME
    name = M.cell_name(cell)
    M.cells_of_matrix = lambda: [cell]
    M._run_cell_star = lambda arg: (name, _side(rolled), _side(unrolled))
    M.concurrent.futures.ProcessPoolExecutor = _FakePool
    M.control_sources = lambda n, surface="register": ("", "")
    M.SURFACE_CONTROL_VERDICTS = dict(M.SURFACE_CONTROL_VERDICTS)
    for s in ("void", "register"):
        M.SURFACE_CONTROL_VERDICTS[s] = {"q_noregion": "ACCEPT-IDENTICAL",
                                         "q_armoncond": "ACCEPT-IDENTICAL"}
    M.build_side = lambda cfg, work, n, src: _side("ctl\n")
    return name


def case_bank_floor():
    """The floor, in both directions and scoped.

    ⚠ The point of the NEGATIVES is that both traces are IDENTICAL. Every other
    comparison in `loop_twin_matrix.py` is a difference, and a measurement that
    was never emitted is emitted by neither side — so `ACCEPT-IDENTICAL` is
    exactly what a silently-dropped `cq_measure` looks like. That is
    `CLAUDE.md` L10's `m_none_pbitd_none_premark_rypost` lesson arriving from
    the other side: *a cell whose two halves agree because BOTH are wrong is
    precisely what ACCEPT-IDENTICAL cannot see; only a fence can.*
    """
    out = []
    ok_e = EHDR + "%s ACCEPT-IDENTICAL\n" % BANK_NAME
    q0 = QHDR + "\n"

    # POS — at the floor, the verdict is the ordinary one.
    install_bank(_FAT, _FAT)
    rc, rep, _, _ = run(q0, ok_e)
    bad = []
    if rc != 0:
        bad.append("rc %d, expected 0 — a trace AT the floor must pass" % rc)
    if "VACUOUS" in rep:
        bad.append("a trace at the floor was called vacuous")
    out.append(("POS-7    a bank trace AT the floor passes", bad, rep))

    # NEG — the measurements vanished from BOTH sides identically.
    for label, r, u in (("NEG-15   both sides lost the bank measurements",
                         _THIN_M, _THIN_M),
                        ("NEG-16   only the ROLLED side is thin",
                         _THIN_M, _FAT),
                        ("NEG-19   only the UNROLLED side is thin",
                         _FAT, _THIN_M),
                        ("NEG-17   the MINT side of the floor", _THIN_H, _THIN_H)):
        install_bank(r, u)
        rc, rep, _, _ = run(q0, ok_e)
        bad = []
        if rc != 1:
            bad.append("rc %d, expected 1" % rc)
        if "VACUOUS ACCEPT" not in rep:
            bad.append("no VACUOUS ACCEPT in the report")
        out.append((label, bad, rep))

    # NEG — `--regenerate` may not write a vacuous accept into the table.
    install_bank(_THIN_M, _THIN_M)
    rc, rep, _, epath = run(q0, ok_e, ("--regenerate",))
    bad = []
    if rc != 1:
        bad.append("rc %d, expected 1" % rc)
    if "REGENERATION REFUSED" not in rep:
        bad.append("--regenerate did not refuse")
    if open(epath).read() != ok_e:
        bad.append("the expected table was REWRITTEN by a refusing run")
    out.append(("NEG-18   --regenerate over a VACUOUS ACCEPT", bad, rep))

    # POS — the floor is SCOPED. A non-bank cell with the same thin trace is not
    # flagged, or the floor would have reddened 338 committed cells and the
    # green above would mean nothing.
    install_bank(_THIN_M, _THIN_M, cell=PLAIN_CELL)
    rc, rep, _, _ = run(q0, EHDR + "%s ACCEPT-IDENTICAL\n" % PLAIN_NAME)
    bad = []
    if rc != 0:
        bad.append("rc %d — the floor leaked onto a NON-bank cell" % rc)
    if "VACUOUS" in rep:
        bad.append("a non-bank cell was called vacuous")
    out.append(("POS-8    the floor does NOT touch a non-bank cell", bad, rep))
    return out


def case_floor_covers_the_axis():
    """⚠ THE `checked 0` HOLE, IN THIS INSTRUMENT'S OWN SHAPE. Every case above
    installs its own cell, so all of them stay green if `BANK_FLOOR` silently
    becomes empty — and then the real 359-cell run guards nothing. So the map is
    asserted against the axis it is derived from, non-emptily."""
    bad = []
    M.cell_name = _REAL_CELL_NAME
    cells = M.bank_cells()
    if len(cells) != 21:
        bad.append("bank_cells() returned %d cells, expected 21" % len(cells))
    names = {M.cell_name(c) for c in cells}
    if not M.BANK_FLOOR:
        bad.append("BANK_FLOOR is EMPTY — every bank cell is unguarded and the "
                   "floor cases above prove nothing about the real run")
    if set(M.BANK_FLOOR) != names:
        bad.append("BANK_FLOOR covers %d name(s), the axis has %d"
                   % (len(M.BANK_FLOOR), len(names)))
    for n, f in sorted(M.BANK_FLOOR.items()):
        if f[0] < 2 or f[1] < 2:
            bad.append("%s's floor %s is too low to see a dropped measurement"
                       % (n, f))
    # ⚠ AND THE AXIS MUST BE WIRED IN, NOT MERELY DEFINED. Every case in this
    # file installs its own cell list, so `bank_cells()` can be complete, the
    # floor can be perfect, and `cells_of_matrix()` can still never include one
    # — which is bd rpkr's own sentence, *no existing cell can see a rail bank*,
    # recreated by a one-token edit. Found MISSING by mutation M5 and closed
    # here; the real cell list is captured BEFORE any stubbing.
    wired = {M.cell_name(c) for c in _REAL_CELLS_OF_MATRIX()}
    absent = sorted(names - wired)
    if absent:
        bad.append("%d bank cell(s) are defined but NOT in cells_of_matrix() — "
                   "the axis would never run: %s"
                   % (len(absent), absent[:3]))
    return bad


def case_no_cells_is_not_a_pass():
    """A harness that reports a PASS on NO INPUT is a HOLE, not a pass — the
    lesson of the injection matrix that printed `0 mutations, MISSED 0` when
    invoked with no fixture, and of the 0-byte `.ll` that ACCEPTS through the
    passthrough early-out."""
    install()
    M.cells_of_matrix = lambda: []
    rc, rep, _, _ = run(QHDR + "\n", EHDR)
    bad = []
    if rc != 2:
        bad.append("rc %d, expected 2 — an empty matrix must not exit 0" % rc)
    if "produced NO cells" not in rep:
        bad.append("the report does not say the matrix had no subject")
    return bad


def case_real_header():
    """The guard, asked about the SHIPPED include/CQ.h — round-1 finding
    F-L5-7(b).

    The guard used to be the literal substring `"void cq_phi(double" not in
    text`, and include/CQ.h spells the declaration column-aligned
    (`void                cq_phi     (double angle);`), so `--phi-surface void`
    REFUSED the one header it was written to require and said that header was a
    `register`-surface one. It had only ever been exercised against an unaligned
    stand-in. This asserts it against the real file, which is the whole lesson:
    a guard tested only against the artifact it was written beside is untested.
    """
    bad = []
    real = os.path.join(os.path.dirname(HERE), "include", "CQ.h")
    if not os.path.exists(real):
        return ["include/CQ.h not found at %s" % real]
    got = M.phi_surface_of_header(open(real).read())
    if got != "void":
        bad.append("the SHIPPED include/CQ.h classifies as %r, expected 'void' "
                   "— the void gate would refuse the tree it runs in" % got)
    # And the other direction, so the classifier is a DISCRIMINATOR and not a
    # function that answers "void" to everything.
    for surface, text in sorted(HEADERS.items()):
        g = M.phi_surface_of_header(text)
        if g != surface:
            bad.append("stand-in %s header classifies as %r" % (surface, g))
    if M.phi_surface_of_header("int x;\n") != "unknown":
        bad.append("a header declaring no cq_phi at all is not 'unknown'")
    if M.phi_surface_of_header(HEADERS["void"] + HEADERS["register"]) != "hybrid":
        bad.append("a header declaring BOTH surfaces is not 'hybrid'")
    # Comments are prose, not declarations: the shipped header's own commentary
    # names the retired `cq_phi_<sfx>(x, angle)` family it replaces.
    if M.phi_surface_of_header(
            "/* the retired cq_phi_i32(x, angle) family */\n"
            + HEADERS["void"]) != "void":
        bad.append("a `register` mention inside a COMMENT changed the verdict")
    return bad


def main():
    install()
    A = M.divergence_signature(*BASE["m_a"])
    B = M.divergence_signature(*BASE["m_b"])
    # Both synthetic tables now carry a HEADER with hand-added prose and the
    # END-OF-HEADER marker, because that is what a committed table looks like
    # since bd test_C_libtooling-gfsk. `no_marker_*` are the same files with the
    # marker removed — the shape every table in the tree had until 2026-09-15,
    # and the shape the write modes must now REFUSE rather than overwrite.
    good_q = QHDR + "\n" + block("m_a", *A) + block("m_b", *B)
    moved_q = (QHDR + "\n" + block("m_a", "deadbeefdeadbeef", A[1], A[2])
               + block("m_b", *B))
    good_e = EHDR + "m_c ACCEPT-IDENTICAL\nm_d ACCEPT-IDENTICAL\n"
    no_marker_q = good_q.replace(M.HEADER_END_MARKER, "")
    no_marker_e = good_e.replace(M.HEADER_END_MARKER, "")

    # label, expected rc, quarantine text, expected text, needle, control
    # diverges?, extra argv, extra checker
    cases = [
        ("CONTROL  both quarantined, signatures pinned", 0, good_q, good_e,
         "all cells match", False, (), None),
        ("NEG-1    a pinned SIGNATURE changed", 1, moved_q, good_e,
         "QUARANTINED SIGNATURE CHANGED", False, (), None),
        ("NEG-2    a quarantined cell STOPPED diverging", 1,
         good_q + block("m_c", "0" * 16, "x", "y"), good_e,
         "QUARANTINE STALE", False, (), None),
        ("NEG-3    a divergent cell NOT quarantined", 1,
         block("m_a", *A), good_e, "TRACES DIFFER", False, (), None),
        ("NEG-4    a cell in BOTH files", 1,
         good_q, good_e + "m_a UNROLLED-ONLY\n", "IN BOTH FILES", False,
         (), None),
        ("NEG-5    quarantine names an unknown cell", 1,
         good_q + block("m_zz", "0" * 16, "x", "y"), good_e,
         "not a cell in this run", False, (), None),
        ("NEG-6    a BOUNDARY CONTROL diverged", 1,
         good_q, good_e, CTL_MOVED, True, (), None),
        ("NEG-7    --regenerate over a live divergence", 1,
         block("m_a", *A), good_e, "REGENERATION REFUSED", False,
         ("--regenerate",), _unchanged("e")),
        ("NEG-8    --regenerate with a moved BOUNDARY CONTROL", 1,
         good_q, good_e, CTL_MOVED, True,
         ("--regenerate",), _unchanged("e")),
        ("NEG-9    --refresh-quarantine, moved BOUNDARY CONTROL", 1,
         good_q, good_e, "BOUNDARY CONTROL has moved", True,
         ("--refresh-quarantine",), _unchanged("q")),
        ("POS-2    --refresh-quarantine re-pins, adds/removes nothing", 0,
         moved_q, good_e, "re-pinned 2 quarantined signature(s)", False,
         ("--refresh-quarantine",), _refresh_repins(A, B)),
        ("POS-3    --regenerate on a clean run still writes", 0,
         good_q, good_e, "regenerated", False, ("--regenerate",), _regen_wrote),
        # ── bd test_C_libtooling-gfsk: THE HEADER CONTRACT ──────────────────
        ("NEG-10   --regenerate, expected table has NO marker", 1,
         good_q, no_marker_e, "has no END-OF-HEADER marker", False,
         ("--regenerate",), _unchanged("e")),
        ("NEG-11   --refresh-quarantine, quarantine has NO marker", 1,
         no_marker_q, good_e, "has no END-OF-HEADER marker", False,
         ("--refresh-quarantine",), _unchanged("q")),
        ("NEG-12   a PLAIN run over a table with NO marker", 1,
         good_q, no_marker_e, "NO END-OF-HEADER marker", False, (), None),
        ("NEG-13   a PLAIN run, quarantine has NO marker", 1,
         no_marker_q, good_e, "NO END-OF-HEADER marker", False, (), None),
        ("POS-4    --regenerate PRESERVES hand-added prose", 0,
         good_q, good_e, "preserved", False,
         ("--regenerate",), _prose_survived("e")),
        ("POS-5    --refresh-quarantine PRESERVES prose", 0,
         moved_q, good_e, "preserved", False,
         ("--refresh-quarantine",), _prose_survived("q")),
        ("POS-6    --regenerate SEEDS a table that does not exist", 0,
         good_q, None, "seeded", False, ("--regenerate",), _seeded_missing),
    ]

    failures, total = 0, 0
    # BOTH SURFACES, every case. `void` is the surface the shipped
    # `e2e-loop-twin-matrix` gate runs (bd 3qlq Inc 1), and until it did, this
    # file validated only the retired one — a mutant validation of a code path
    # nothing executes.
    for surface in ("register", "void"):
        for label, want_rc, q, e, needle, ctl, extra, check in cases:
            install(control_diverges=ctl)
            rc, out, qpath, epath = run(q, e, extra, surface=surface)
            want = needle[surface] if isinstance(needle, dict) else needle
            bad = []
            if rc != want_rc:
                bad.append("rc %d, expected %d" % (rc, want_rc))
            if want not in out:
                bad.append("missing %r in the report" % want)
            if check:
                bad += check(qpath, epath, {"q": q, "e": e}, out)
            total += 1
            print("[%-8s] %-46s %s"
                  % (surface, label, "ok" if not bad else
                     "FAILED: " + "; ".join(bad)))
            if bad:
                failures += 1
                print(out)

    # ── the SURFACE GUARD itself, both directions ───────────────────────────
    for surface, other in (("void", "register"), ("register", "void")):
        install()
        bad = []
        # `run()` always writes the header MATCHING the surface it passes, so the
        # mismatch is built by hand: the `other` surface's header, this
        # surface's --phi-surface.
        d = tempfile.mkdtemp(prefix="qtest_hdr_")
        inc = os.path.join(d, "include")
        os.makedirs(inc, exist_ok=True)
        with open(os.path.join(inc, "CQ.h"), "w") as f:
            f.write(HEADERS[other])
        qf, ef = os.path.join(d, "q.txt"), os.path.join(d, "e.txt")
        open(qf, "w").write(good_q)
        open(ef, "w").write(good_e)
        old_argv, buf = sys.argv, io.StringIO()
        sys.argv = ["loop_twin_matrix", "--clang", "c", "--opt", "o",
                    "--plugin", "p", "--include", inc, "--runtime", "r",
                    "--templates", "t", "--jobs", "1", "--phi-surface", surface,
                    "--quarantine", qf, "--expected", ef]
        try:
            with contextlib.redirect_stdout(buf):
                rc2 = M.main()
        finally:
            sys.argv = old_argv
        if rc2 != 2:
            bad.append("rc %d, expected 2" % rc2)
        if "declares the `%s` cq_phi surface" % other not in buf.getvalue():
            bad.append("the refusal does not name the surface it was handed")
        total += 1
        print("[guard   ] %-46s %s"
              % ("--phi-surface %s against a %s header" % (surface, other),
                 "ok" if not bad else "FAILED: " + "; ".join(bad)))
        if bad:
            failures += 1
            print(buf.getvalue())

    bad = case_real_header()
    total += 1
    print("[guard   ] %-46s %s"
          % ("phi_surface_of_header over the SHIPPED include/CQ.h",
             "ok" if not bad else "FAILED: " + "; ".join(bad)))
    if bad:
        failures += 1

    # ── bd gfsk's unit-level mutants and bd rpkr's floor ───────────────────
    for label, fn in (("write_preserving_header, made to fail twice",
                       case_readback_selfcheck),
                      ("the four COMMITTED tables carry the marker",
                       case_committed_tables_are_marked),
                      ("BANK_FLOOR covers the whole bank axis",
                       case_floor_covers_the_axis),
                      ("an EMPTY matrix exits 2, never 0",
                       case_no_cells_is_not_a_pass)):
        bad = fn()
        total += 1
        print("[guard   ] %-46s %s"
              % (label, "ok" if not bad else "FAILED: " + "; ".join(bad)))
        if bad:
            failures += 1

    for label, bad, rep in case_bank_floor():
        total += 1
        print("[floor   ] %-46s %s"
              % (label, "ok" if not bad else "FAILED: " + "; ".join(bad)))
        if bad:
            failures += 1
            print(rep)

    print("loop_twin_matrix_quarantine_test: %d case(s), %d failure(s)"
          % (total, failures))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
