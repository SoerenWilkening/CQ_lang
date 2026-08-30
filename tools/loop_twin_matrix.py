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
#     two-armed phase region.
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
}
SUFFIX = {
    "none": "",
    "ry": "        a = cq_theta(a, -0.5);\n",
    "rz": "        a = cq_phi(a, -0.125);\n",
    "add": "        a = a + off;\n",
}

HDR = "#include <math.h>\nvolatile int off = 3;\n"

# TWO TRIPS, and two is not arbitrary: it is the smallest count at which the back
# edge is taken, so the "next activation" the window lemma reasons about actually
# exists in the trace, and it is small enough that a divergence is readable.
TRIPS = 2


def sources(prefix, region, suffix):
    """(rolled, unrolled) C for one cell."""
    body = PREFIX[prefix] + REGION[region] + SUFFIX[suffix]
    rolled = (
        HDR
        + "int slice(void){\n    int a = 0;\n    a = cq_theta(a, 0.5);\n"
        + "    for (int i = 0; i < %d; ++i) {\n" % TRIPS
        + body
        + "    }\n    return cq_measure(a);\n}\n"
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
        + "int slice(void){\n    int a = 0;\n    a = cq_theta(a, 0.5);\n"
        + flat * TRIPS
        + "    return cq_measure(a);\n}\n"
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
    # Called IN PROCESS, not as a subprocess: 200 python interpreter starts cost
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


def run_cell(cfg, cell):
    prefix, region, suffix = cell
    name = "m_%s_%s_%s" % cell
    rolled_src, unrolled_src = sources(prefix, region, suffix)
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

    cells = list(itertools.product(PREFIX, REGION, SUFFIX))
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
# ONE LINE PER CELL, `m_<prefix>_<region>_<suffix>` then its verdict. The gate
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
#                           needs a written reason — today's two are `clang -O1`
#                           canonicalization artifacts of the UNROLLED spelling
#                           (`a = a ^ 9;` twice in a row folds into the region and
#                           produces a mixed phase/value arm that does not exist
#                           in the rolled form), not a compiler asymmetry.
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
