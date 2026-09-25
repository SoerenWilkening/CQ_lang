#!/usr/bin/env python3
"""mkfix.py — assemble the bd d88e lit fixtures: header text + the llvm-linked
stage-1 body of a probe (scratchpad p/<probe>.s1.ll). Refuses an empty body
(the 0-byte-module ACCEPT trap, CLAUDE.md L10)."""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(HERE, "p")
TEST = ("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/"
        "agent-acf961e52a2f9e440/ir-pass/test")

LIB_C = "int h(int a, int k) { return k + 1; }"
LIB_Q = "int h(int a, int k) { return a + k; }"

COMMON_DECLINE = """\
;
; A TWO-TU module: the caller TU (`-include CQ.h`) llvm-linked with a plain-C
; library TU, exactly as tests/e2e/run_slice_multi.sh builds one. `t = h(q, m)`
; reads the tainted `q`, so `propagate` taints `t` CONSERVATIVELY and every stage
; before `specialize()` sees it as a quantum REGISTER. `declineClassicalMuxes`'
; one-register lift (`liftOneRegisterMergePhi`) therefore proved the
; classical-condition merge phi {PHI} a pure renaming of ONE
; register, RAUW'd it to its wire base `t` and erased it. `specialize()` then
; clones `h`, proves the clone returns the CLASSICAL `k + 1`, and
; `scrubForwardCone` untaints `t`: the lift's premise is false after the fact.
; Before this fence the rotation lowered as a SOURCE on a fresh rail that nothing
; reads and the user's `cq_measure` read the classical `t` down the bd 21mg
; classical-measure path — NO measurement, `opt` exit 0, stage-2b STRICT clean
; (measured on main `def1b088`, cq-opt `b1603d23`: 0 `cqrt_measure` in the lowered
; module, 1 in the source). bd `test_C_libtooling-l3oi`'s fence could not see it:
; no EMITTED gate reads `t` — the consumers were reached through a RAUW.
;
; THE CORRECT DISPOSITION IS THE HAND-INLINED TWIN'S (`int t = m + 1;`, the same
; caller with `h`'s classical return written directly), and the twin DECLINES at
; `declineClassicalMuxes` with exactly the string below (measured on the same
; oracle): the phi muxes the classical `t` and a quantum register under a
; classical condition, a real data mux and not a renaming. The lift now RECORDS
; its taint-dependent premise (`taint.LiftedMergePhis`) and
; `declineFalsifiedMergePhiLifts` RE-ASKS it at FINAL taint right after
; `specialize()` in both entry points (CLAUDE.md L1: record, then re-ask).
{EXTRA};
; Library TU (plain C, no CQ.h):
;   {LIB}
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   {DECL}
{CALLER};
; Regenerate: clang -O1 -emit-llvm -S the two TUs as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \\
; RUN:   | %filecheck %s
; CHECK: in function {FN}: cq taint escape: tainted value muxed by a classical-condition phi

"""


def caller_lines(probe):
    out = []
    with open(os.path.join(P, probe + ".c")) as f:
        for line in f:
            line = line.rstrip("\n")
            if not line or line.startswith("#include") or line in ("int h(int a, int k);", "double hf(double a, double k);"):
                continue
            out.append(";   " + line + "\n")
    return "".join(out)


def body(probe):
    path = os.path.join(P, probe + ".s1.ll")
    with open(path) as f:
        text = f.read()
    if len(text) < 200 or "define" not in text:
        sys.exit("refusing tiny/empty body for " + probe)
    return text


def write(name, text):
    dst = os.path.join(TEST, name)
    with open(dst, "w") as f:
        f.write(text)
    print("wrote", dst, len(text.splitlines()), "lines")


DECLINES = [
    # (fixture, probe, title, phi, fn, extra)
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base.ll", "l01C",
     "the bead's own reproducer (`main`, one `if`)",
     "`phi(t, cq_theta(t, .2))`", "main i32 (i32, ptr)", ""),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_nonmain.ll", "l08C",
     "a non-`main` function returning `cq_measure(r)` (its return is untainted)",
     "`phi(t, cq_theta(t, .2))`", "f i32 (i32)", ""),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_switch.ll", "l13C",
     "a classical `switch` (`-O1` folds its two rotating cases into ONE "
     "`cq_theta` over a `phi double` ANGLE, so the lift itself is 2-way; the "
     "true N=3 lift is `..._switch_nway_all_arms.ll`)",
     "`phi(t, cq_theta(t, phi(.4, .2)))`", "main i32 (i32, ptr)", ""),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_two_lifts.ll", "l18C",
     "TWO sequential lifts on the same scrubbed base",
     "(each of two)", "main i32 (i32, ptr)", ""),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_arm_chain.ll", "l22C",
     "a TWO-GATE chain in one arm (the chain peels through a chained theta)",
     "`phi(t, cq_theta(cq_theta(t, .2), .3))`", "main i32 (i32, ptr)", ""),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_ifelse_all_arms.ll", "b01C",
     "if/else with a rotation on EVERY edge (no incoming IS the base, so the "
     "re-ask's ALL-TAINTED conjunct holds and the BASE-EQUALITY conjunct is the "
     "one that fires)",
     "`phi(cq_theta(t, .2), cq_theta(cq_theta(t, .7), .1))`", "main i32 (i32, ptr)", ""),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_switch_nway_all_arms.ll", "b02C",
     "the N-way `switch` with a rotation on EVERY edge, default included (the "
     "base-equality conjunct at N=3)",
     "`phi(cq_theta(t, .2), cq_theta(cq_theta(t, .4), .1), cq_theta(cq_theta(t, .6), .3))`",
     "main i32 (i32, ptr)", ""),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_fp.ll", "f01C",
     "the f64 register (a `double` spec site whose clone returns the classical "
     "`k + 1.0`; `t` is a `cq_theta_f64` register at round 1)",
     "`phi(t, cq_theta(t, .2))` (f64)", "main i32 (i32, ptr)",
     """\
;
; (Here the library function is `hf` and its classical return is `k + 1.0`; the
; hand-inlined twin is `double t = m + 1.0;`, measured to decline with the same
; string. Its SPEC-QUANTUM sibling, whose site `specialize()` REBUILDS to an `i32`
; handle, is `lowering_classical_mux_phi_onereg_spec_quantum_base_fp_rebuilt.ll`.)
""",
     "double hf(double a, double k) { return k + 1.0; }"),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_pure_consumer.ll", "g01C",
     "a PURE op consumes the lifted phi (`r + 1`), the SLOT pin for the bd 2qyz "
     "post-lift stale re-sweep",
     "`phi(t, cq_theta(t, .2))`", "main i32 (i32, ptr)",
     """\
;
; ⚠ THIS FIXTURE PINS THE bd 2qyz RE-SWEEP'S SLOT. After the false lift, `r + 1`
; reads `t`, whose wire the arm's `cq_theta(t, .2)` rotated IN PLACE on round-1
; taint, so `declineLiftedStaleRecordOps` found a stale record. It used to run
; right after the lift, i.e. BEFORE `specialize()`, and it declined FIRST with
; `cq opcode lowering: operand predates a non-diagonal gate`: a staleness the
; false RAUW manufactured, and not the twin's string (the oracle, and this
; change's first build, both print that). bd d88e moved the re-sweep below
; `specialize()` and the lift's re-ask, so the re-ask speaks first, with the
; twin's string. The TRUE-lift twin of this module (library `h` returning its
; quantum argument) still declines at the re-sweep:
; `lowering_reject_classical_mux_phi_lift_stale_spec_quantum_base.ll`.
"""),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_l3oi_owner.ll", "h03C",
     "the SLOT pin against the bd l3oi fence: a false lift on `t` beside a branch on "
     "a SECOND spec-classical result `t2` that a control emitter read as a handle",
     "`phi(t, cq_theta(t, .2))`", "main i32 (i32, ptr)",
     """\
;
; ⚠ THIS FIXTURE PINS THE SLOT RELATIVE TO bd l3oi. The module carries TWO scrub
; consequences: the false lift on `t`, and a 4.4 select whose condition `t2 > 3`
; round-1 control emission turned into a compare TEMPLATE reading `t2` as a handle
; (l3oi's class). The oracle declined at l3oi's `classical call result used as a
; quantum register`; the hand-inlined twin (`int t = m + 1; int t2 = m + 3;`) has no
; emitted gate on `t2` and declines at the classical-mux guard with the string
; below. The re-ask sits BEFORE `declineScrubbedHandleReads`, so the first owner is
; the twin's; swapping the two slots turns this red. (The spec-QUANTUM twin of this
; module ACCEPTS on both binaries with two measurements.)
"""),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_store.ll", "l07C",
     "the measurement stored through a pointer from a non-`main` function",
     "`phi(t, cq_theta(t, .2))`", "f i32 (i32, ptr)", ""),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_owner.ll", "l25C",
     "the SLOT pin: two lifts whose post-lift IR ALSO trips the bd 3d8q "
     "stale-reader BACKSTOP",
     "(each of two)", "main i32 (i32, ptr)",
     """\
;
; ⚠ THIS FIXTURE PINS THE SLOT, NOT ONLY THE VERDICT. The oracle declined this
; module too, but with the stale-reader backstop's string (`rotation/measure
; operand predates a non-diagonal gate`): after the two false lifts both
; `cq_theta(t, .2)` and `cq_theta(t, .4)` read `t` IN PLACE and the backstop saw
; a stale reader that exists only because of the lifts' RAUW. The twin declines
; at `declineClassicalMuxes` with the classical-phi string. The re-ask sits
; immediately after `specialize()` and BEFORE the backstop, so the first owner to
; speak is the one whose premise was falsified. Moving it below the backstop
; turns this fixture red.
"""),
]


def main():
    for row in DECLINES:
        fx, probe, title, phi, fn, extra = row[:6]
        lib = row[6] if len(row) > 6 else LIB_C
        head = "; %s — DECLINE (bd test_C_libtooling-d88e, P1 silent miscompile, found by\n" % fx
        head += "; bd 9bhg's Rule-13 round r1A, F-9A-1): %s.\n" % title
        decl = "double hf(double a, double k);" if lib.startswith("double") else "int h(int a, int k);"
        text = head + COMMON_DECLINE.format(PHI=phi, EXTRA=extra, LIB=lib, DECL=decl,
                                            CALLER=caller_lines(probe), FN=fn)
        write(fx, text + body(probe))


if __name__ == "__main__":
    main()
