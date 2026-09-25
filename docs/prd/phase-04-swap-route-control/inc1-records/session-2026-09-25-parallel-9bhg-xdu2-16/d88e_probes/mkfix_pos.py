#!/usr/bin/env python3
"""mkfix_pos.py — the bd d88e ACCEPT fixtures (the re-ask must NOT fire)."""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
P = os.path.join(HERE, "p")
TEST = ("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/"
        "agent-acf961e52a2f9e440/ir-pass/test")


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
    with open(os.path.join(P, probe + ".s1.ll")) as f:
        text = f.read()
    if len(text) < 200 or "define" not in text:
        sys.exit("refusing tiny/empty body for " + probe)
    return text


def write(name, text):
    dst = os.path.join(TEST, name)
    with open(dst, "w") as f:
        f.write(text)
    print("wrote", dst, len(text.splitlines()), "lines")


RECIPE = """\
;
; Regenerate: clang -O1 -emit-llvm -S the two TUs as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
"""

SPEC_Q = """\
; lowering_classical_mux_phi_onereg_spec_quantum_base.ll — ACCEPT (bd
; test_C_libtooling-d88e, the SPEC-QUANTUM positive control).
;
; The d88e decline family's exact caller (`lowering_reject_classical_mux_phi_spec_
; scrubbed_base.ll`) with the library `h` returning its QUANTUM argument. The
; clone's verdict is QUANTUM, `specialize()` scrubs nothing, and `t` really IS a
; register: the one-register lift of `phi(t, cq_theta(t, .2))` was a true
; renaming, so the re-ask after `specialize()` (`declineFalsifiedMergePhiLifts`)
; finds its recorded premise intact at FINAL taint and says nothing. The stream
; is byte-identical to main `def1b088` (cq-opt `b1603d23`): the arm's Ry fires IN
; PLACE on the clone's returned handle and the user's measurement reads that same
; handle — no fresh rail in the arm, one `cqrt_measure`.
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return a + k; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
{CALLER}{RECIPE}\
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \\
; RUN:   | %filecheck %s
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef [[Q]], i32 noundef %5)
; CHECK-NEXT: [[C:%[0-9]+]] = icmp sgt i32 %5, 3
; CHECK-NEXT: br i1 [[C]], label %[[ARM:[0-9]+]], label %[[JOIN:[0-9]+]]
; CHECK:      [[ARM]]:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[T]], double 2.000000e-01)
; CHECK-NEXT: br label %[[JOIN]]
; CHECK:      [[JOIN]]:
; CHECK-NEXT: [[M:%[a-z0-9.]+]] = call i32 @cqrt_measure_i32(i32 [[T]])
; CHECK-NEXT: ret i32 [[M]]
; CHECK-NEXT: }
; CHECK-LABEL: define internal i32 @__cq_q_h_01(

"""

SPEC_Q_SWITCH = """\
; lowering_classical_mux_phi_onereg_spec_quantum_base_switch_nway.ll — ACCEPT (bd
; test_C_libtooling-d88e, the SPEC-QUANTUM positive control at N=3).
;
; The N=3 `switch` twin of `lowering_reject_classical_mux_phi_spec_scrubbed_base_
; switch_nway_all_arms.ll` with the library `h` returning its QUANTUM argument:
; every edge (default included) rotates, the 3-incoming lift is a true renaming,
; and the re-ask after `specialize()` keeps it. Stream byte-identical to main
; `def1b088` (cq-opt `b1603d23`): each edge's Ry chain fires IN PLACE on the
; clone's returned handle, one measurement of that handle, no phi left.
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return a + k; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
{CALLER}{RECIPE}\
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \\
; RUN:   | %filecheck %s
; CHECK-LABEL: define i32 @main(
; CHECK:      [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(
; CHECK-NOT:  cqrt_alloc
; CHECK:      call void @cqrt_ry_i32(i32 [[T]], double 2.000000e-01)
; CHECK-NOT:  cqrt_alloc
; CHECK:      call void @cqrt_ry_i32(i32 [[T]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[T]], double 1.000000e-01)
; CHECK-NOT:  cqrt_alloc
; CHECK:      call void @cqrt_ry_i32(i32 [[T]], double 6.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[T]], double 3.000000e-01)
; CHECK-NOT:  {{phi|cqrt_alloc}}
; CHECK:      [[M:%[a-z0-9.]+]] = call i32 @cqrt_measure_i32(i32 [[T]])
; CHECK-NEXT: ret i32 [[M]]
; CHECK-NEXT: }

"""

ELSEWHERE = """\
; lowering_classical_mux_phi_onereg_spec_scrubbed_elsewhere.ll — ACCEPT (bd
; test_C_libtooling-d88e, the "a scrub happened, but not to the lift's base"
; control).
;
; `specialize()` DOES scrub here — `h`'s clone returns the classical `k + 1`, so
; `t` and `t`'s cone lose their conservative taint — but the lifted phi
; `phi(q, cq_theta(q, .2))` is over `q`, a `cq_theta` result: a never-scrub keep
; root. Its recorded premise holds at FINAL taint and the re-ask
; (`declineFalsifiedMergePhiLifts`) must say nothing. The gate stream is the
; hand-inlined twin's (`int t = m + 1;`, measured on main `def1b088`): Ry(.5) on
; `q`, Ry(.2) on the SAME handle in the arm, one measurement of that handle; the
; only difference is the classical call to the clone, whose result is added to
; the measured value as plain data.
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return k + 1; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
{CALLER}{RECIPE}\
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \\
; RUN:   | %filecheck %s
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef [[Q]], i32 noundef %5)
; CHECK-NOT:  cqrt_alloc
; CHECK:      call void @cqrt_ry_i32(i32 [[Q]], double 2.000000e-01)
; CHECK-NOT:  cqrt_alloc
; CHECK:      [[M:%[a-z0-9.]+]] = call i32 @cqrt_measure_i32(i32 [[Q]])
; CHECK-NEXT: [[S:%[0-9]+]] = add nsw i32 [[M]], [[T]]
; CHECK-NEXT: ret i32 [[S]]

"""

FP_REBUILT = """\
; lowering_classical_mux_phi_onereg_spec_quantum_base_fp_rebuilt.ll — ACCEPT (bd
; test_C_libtooling-d88e, the SPEC-QUANTUM control whose lifted BASE IS ERASED).
;
; The f64 twin of `lowering_classical_mux_phi_onereg_spec_quantum_base.ll`: the
; library `hf` returns its QUANTUM `double` argument, so the clone's verdict is
; QUANTUM and the one-register lift of `phi(t, cq_theta(t, .2))` is a true
; renaming. What this file adds is the ERASE: a tainted fp return is an `i32`
; handle at the call site, so `specialize()`'s `retargetSite` REBUILDS the call
; (`double @hf` -> `i32 @__cq_q_hf_01`), RAUWs the old result onto the new one and
; ERASES the old call — which is the lift's recorded BASE and one of its recorded
; incomings. The record holds `WeakTrackingVH`s, so it FOLLOWS that RAUW and the
; re-ask (`declineFalsifiedMergePhiLifts`) finds the rebuilt, tainted handle and
; says nothing. A plain `WeakVH` (or a raw pointer) would null or dangle there and
; decline a correct module; this file is what turns that mutant red. Stream
; byte-identical to main `def1b088` (cq-opt `b1603d23`).
;
; Library TU (plain C, no CQ.h):
;   double hf(double a, double k) { return a + k; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   double hf(double a, double k);
{CALLER}{RECIPE}\
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \\
; RUN:   | %filecheck %s
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_f64(double %5)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = call i32 @__cq_q_hf_01(i32 [[Q]], double %5)
; CHECK-NOT:  cqrt_alloc
; CHECK:      call void @cqrt_ry_f64(i32 [[T]], double 2.000000e-01)
; CHECK-NOT:  cqrt_alloc
; CHECK:      call double @cqrt_measure_f64(i32 [[T]])

"""


def main():
    for name, tmpl, probe in [
        ("lowering_classical_mux_phi_onereg_spec_quantum_base.ll", SPEC_Q, "l01Q"),
        ("lowering_classical_mux_phi_onereg_spec_quantum_base_switch_nway.ll",
         SPEC_Q_SWITCH, "b02Q"),
        ("lowering_classical_mux_phi_onereg_spec_scrubbed_elsewhere.ll", ELSEWHERE,
         "j01C"),
        ("lowering_classical_mux_phi_onereg_spec_quantum_base_fp_rebuilt.ll", FP_REBUILT,
         "f01Q"),
    ]:
        text = tmpl.replace("{CALLER}", caller_lines(probe)).replace("{RECIPE}", RECIPE)
        write(name, text + body(probe))


if __name__ == "__main__":
    main()
