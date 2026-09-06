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
plus the all-good CONTROL, which must PASS. Twelve runs.

Three of the twelve assert on FILE BYTES, not just on the exit code: a refusal
that still wrote the file is exactly the defect F-R2-1 was, and it printed a
non-zero exit the whole time it was doing it.

HOW IT AVOIDS COSTING ANYTHING. `main()` gets its cell results from `run_cell`,
so the stub below replaces `_run_cell_star`, `build_side` and the process pool
with synthetic traces: **no clang, no opt, no plugin, no subprocess** — the whole
file runs in well under a second. It therefore tests the quarantine's SEMANTICS
and deliberately not its measurements; the real 273-cell run is what measures.
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
    with open(q, "w") as f:
        f.write(qtext)
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
    good_q = block("m_a", *A) + block("m_b", *B)
    moved_q = block("m_a", "deadbeefdeadbeef", A[1], A[2]) + block("m_b", *B)
    good_e = "m_c ACCEPT-IDENTICAL\nm_d ACCEPT-IDENTICAL\n"

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

    print("loop_twin_matrix_quarantine_test: %d case(s), %d failure(s)"
          % (total, failures))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
