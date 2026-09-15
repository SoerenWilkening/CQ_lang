#!/usr/bin/env python3
"""railbank_register_twin_gate_test.py — MUTANT VALIDATION of the twin gate.

CLAUDE.md L10, restated: *"an instrument's failure mode is to REPORT A PASS, so
the only instrument worth citing is one that has been MADE TO FAIL ON PURPOSE."*
Nine instrument self-failures were measured in the 2026-09-14/-15 sessions alone
— a harness reading `$?` after an assignment and reporting 7/7 green INCLUDING
its mutants; a sweep reporting "0 movers" while all 2050 rows were exit 127; an
injection matrix printing `0 mutations, MISSED 0` when invoked with no argument.
So this file exists before the gate is cited, not after.

Two layers, because each catches what the other cannot:

  A. the PURE DECISION LAYER (`verdict_pair`) driven with synthetic rows. Every
     cell of the (bank_rc x reg_rc x traces-equal) table is asserted, including
     the two that must FAIL the gate and the two that must not.
  B. the WHOLE DRIVER run on REAL, DELIBERATELY BROKEN corpora built from the
     shipped pairs, asserting the process EXIT CODE. A checker whose verdict
     function is right and whose exit code is not is a checker that reports a
     pass.

Layer B needs a built `cq-opt`; pass `--build`. With no `--build` it runs layer A
only and SAYS SO in its output (a partial run must never read as a full one).
"""
import os, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import railbank_register_twin_gate as G  # noqa: E402

FAILURES = []


def check(name, got, want):
    if got != want:
        FAILURES.append("%s: got %r, want %r" % (name, got, want))
        print("  MUTANT NOT CAUGHT  %-46s got=%r want=%r" % (name, got, want))
    else:
        print("  caught             %-46s %r" % (name, got))


def layer_a():
    print("LAYER A — the pure decision layer (12 cases)")
    # THE ONE THAT MATTERS: the register spelling has no valid circuit and says
    # so; the bank emitted one.  This is review finding F-1.
    check("A1 bank ACCEPT / reg DECLINE           (F-1)", G.verdict_pair(0, 1, "t", ""), G.VIOLATION)
    check("A2 both DECLINE                        (safe)", G.verdict_pair(1, 1, "", ""), G.OK_BOTH_DECLINE)
    check("A3 both ACCEPT, identical traces       (P2 ok)", G.verdict_pair(0, 0, "t", "t"), G.OK_IDENTICAL)
    check("A4 both ACCEPT, traces differ          (P2)", G.verdict_pair(0, 0, "t", "u"), G.MISMATCH)
    check("A5 bank DECLINE / reg ACCEPT     (over-decline)", G.verdict_pair(1, 0, "", "t"), G.OVERDECLINE)
    # A non-zero rc other than 1 is still a decline: `cq-opt` may exit 2 or be
    # killed.  A checker that tested `rc == 1` would score a CRASH as an accept.
    check("A6 reg rc=2 (crash/other) counts as DECLINE", G.verdict_pair(0, 2, "t", ""), G.VIOLATION)
    check("A7 bank rc=-9 (killed) counts as DECLINE", G.verdict_pair(-9, 1, "", ""), G.OK_BOTH_DECLINE)
    # Empty traces on BOTH sides must not read as "identical" success if the
    # modules accepted — they can only both be empty if both linked and printed
    # nothing, which is a real (if unusual) equality.  Pinned so a future edit
    # that starts returning "" on link failure is visible.
    check("A8 both ACCEPT, both traces empty", G.verdict_pair(0, 0, "", ""), G.OK_IDENTICAL)
    check("A9 link-failure marker differs from a trace", G.verdict_pair(0, 0, "<<LINK-FAILED>> x", "t"), G.MISMATCH)
    # The FAIL set is itself a mutable decision; pin it.
    check("A10 VIOLATION is in the FAIL set", G.VIOLATION in G.FAIL_VERDICTS, True)
    check("A11 TRACE-MISMATCH is in the FAIL set", G.MISMATCH in G.FAIL_VERDICTS, True)
    check("A12 OVER-DECLINE is NOT in the FAIL set", G.OVERDECLINE in G.FAIL_VERDICTS, False)


def run_driver(build, pairs):
    r = subprocess.run([sys.executable, os.path.join(HERE, "railbank_register_twin_gate.py"),
                        "--build", build, "--pairs", pairs], capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def layer_b(build, shipped):
    print("LAYER B — the whole driver, real corpora (5 cases; exit codes)")
    tmp = tempfile.mkdtemp(prefix="rbtwin-selftest.")
    try:
        # B1 — the shipped corpus must PASS on the binary under test.  If this
        # is red, every other row below is meaningless.
        rc, out = run_driver(build, shipped)
        check("B1 shipped corpus exits 0", rc, 0)
        if rc != 0:
            print(out)

        # B2 — an EMPTY corpus must FAIL.  "0 pairs checked" is an ABSENCE, and
        # the measured precedent is an injection matrix that printed
        # `0 mutations, MISSED 0` and exited 0.
        empty = os.path.join(tmp, "empty"); os.mkdir(empty)
        rc, out = run_driver(build, empty)
        check("B2 empty corpus exits non-zero", rc != 0, True)

        # B3 — a FABRICATED VIOLATION.  Pair a bank program that accepts with a
        # register program that declines.  They are not a true twin, which is
        # precisely the point: the driver must report VIOLATION on the PATTERN,
        # because that pattern is what F-1 looked like.
        viol = os.path.join(tmp, "viol"); os.mkdir(viol)
        shutil.copy(os.path.join(shipped, "p03_percell_theta_bool.bank.c"),
                    os.path.join(viol, "m_fabricated.bank.c"))
        shutil.copy(os.path.join(shipped, "p01_stale_invariant_park.reg.c"),
                    os.path.join(viol, "m_fabricated.reg.c"))
        rc, out = run_driver(build, viol)
        check("B3 fabricated bank-accept/reg-decline exits non-zero", rc != 0, True)
        check("B3 and it is named a VIOLATION", "VIOLATION" in out, True)

        # B4 — a FABRICATED TRACE MISMATCH.  Two programs that both accept and
        # emit different streams.
        mis = os.path.join(tmp, "mis"); os.mkdir(mis)
        shutil.copy(os.path.join(shipped, "p03_percell_theta_bool.bank.c"),
                    os.path.join(mis, "m_mismatch.bank.c"))
        shutil.copy(os.path.join(shipped, "p07_sibling_register_rotated.reg.c"),
                    os.path.join(mis, "m_mismatch.reg.c"))
        rc, out = run_driver(build, mis)
        check("B4 fabricated trace mismatch exits non-zero", rc != 0, True)

        # B5 — a VACUOUS half.  A `.c` with no `cq_*` call compiles to a module
        # the pass ACCEPTS through the passthrough early-out (bd memory
        # `empty-module-accepts-vacuity-trap`), so without the guard this pair
        # would score `ok-identical` and the corpus would look one row bigger
        # than it is.
        vac = os.path.join(tmp, "vac"); os.mkdir(vac)
        shutil.copy(os.path.join(shipped, "p03_percell_theta_bool.bank.c"),
                    os.path.join(vac, "m_vacuous.bank.c"))
        open(os.path.join(vac, "m_vacuous.reg.c"), "w").write("int main(void){return 0;}\n")
        rc, out = run_driver(build, vac)
        check("B5 vacuous half exits non-zero", rc != 0, True)
        check("B5 and it is named VACUOUS", "VACUOUS" in out, True)

        # B6 — a MISSING twin must fail, not be skipped.
        miss = os.path.join(tmp, "miss"); os.mkdir(miss)
        shutil.copy(os.path.join(shipped, "p03_percell_theta_bool.bank.c"),
                    os.path.join(miss, "m_missing.bank.c"))
        rc, out = run_driver(build, miss)
        check("B6 missing register twin exits non-zero", rc != 0, True)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    build = None
    for i, a in enumerate(sys.argv):
        if a == "--build":
            build = sys.argv[i + 1]
    shipped = os.path.join(HERE, "railbank_twin_pairs")
    layer_a()
    if build:
        layer_b(build, shipped)
    else:
        print("LAYER B — SKIPPED (no --build).  THIS RUN IS PARTIAL: the exit-code "
              "behaviour of the driver was NOT exercised.")
    print("railbank_register_twin_gate_test: %d mutant(s) NOT caught" % len(FAILURES))
    for f in FAILURES:
        print("   " + f)
    return 1 if FAILURES else 0


if __name__ == "__main__":
    sys.exit(main())
