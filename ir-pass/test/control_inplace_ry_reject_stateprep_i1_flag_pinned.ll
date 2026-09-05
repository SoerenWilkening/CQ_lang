; control_inplace_ry_reject_stateprep_i1_flag_pinned.ll — DECLINE, and it is the
; WHOLE `i1` STATE-PREP WIDTH.
;
; ⚠ THIS FILE WAS `control_inplace_ry_stateprep_i1.ll` — AN ACCEPT — UNTIL THE
; ROUND-3 Rule-13 fix, AND THE IR IS UNCHANGED. It is renamed rather than edited
; in place so the flip is visible, exactly as Inc 3 re-homed
; `control_inplace_ry_reject_in_loop.ll`. Nothing about the emitter changed; F2
; became SEMANTIC and started asking about a register the three syntactic
; generations never had in their set: THE BRANCH CONDITION ITSELF.
;
; WHY EVERY `i1` SEED COLLIDES, structurally rather than by coincidence. The
; branch condition is an `i1` TAINTED value, and on the two edges of its own
; branch it is pinned to exactly `true` and `false`. An `i1` seed is one of those
; two constants. So for a `true`-successor arm: seed `true` collides on the ARM
; edge, seed `false` collides on the MERGE edge — and symmetrically for a
; `false`-successor arm. There is no `i1` spelling left in the accept class.
;
; BOTH HALVES ARE GENUINE AMBIGUITIES, and one of them is MEASURED REACHABLE
; from plain C:
;
;   * ARM edge — `..._i1_arm_flag.ll` (source `$S/fix3/q/z02_i1_flag_arm.c`):
;     `_Bool c = (q==5); _Bool r = 1; if (c) r = cq_theta(c, 0.9);` reaches the
;     pass as `cq_theta_i1(i1 true, …)`, i.e. `clang -O1` FOLDED the flag. That
;     is an in-place Ry on the CONDITION register, the shape R4 forbids, and the
;     shipped type gate (compare literal `i32 5`, seed `i1 true`) skipped all of
;     F2 for it.
;   * MERGE edge — THIS file. `%c` is pinned to `false` on the straight-through
;     edge and the seed is `i1 false`, so the source could have been
;     `_Bool r = c; if (c) r = cq_theta(…);` with `-O1` folding the φ's Pred
;     incoming. Inc 4 RAUWs the merge φ to the PREPPED rail, so on the ¬f branch
;     downstream would read a fresh unentangled |0> rail where the source names
;     the flag's rail.
;
; ⚠ HONESTY ABOUT THE MERGE HALF, because the two halves are NOT equally
; reachable. Three plain-C spellings of "the straight-through value IS the flag"
; were written (`q/z01_i1_flag_straight.c`, `q/z03_i1_ifelse_flag.c`) and THIS
; clang folds NONE of them — it keeps `phi i1 [%4,%arm],[%2,%entry]`, whose
; tainted Pred incoming F1 refuses with `state prep merged with a quantum
; register`, and `condDataUseDisposition` refuses it one layer earlier again.
; So the merge half is an over-decline AT THIS CLANG. It is kept because
; (i) "absence of evidence is not a fence" is this review's own standard, and
; (ii) carving the condition out of the test set would re-open the ARM half,
; which IS reachable — measured, not argued.
;
; THE MERGE EDGE IS NOT ITSELF SPECULATIVE. `q/z05_merge_edge_fold.c` and
; `q/z06_merge_edge_fold2.c` are plain-C programs where the straight-through
; incoming IS a live measured register that `-O1` folds to the seed on the merge
; edge (`int t = q&1; int r = t; if (t) r = cq_theta(0,θ);` →
; `phi i32 [%5,%arm],[0,%entry]`). Both decline. That is why F2 asks both edges
; at all.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 false, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ false, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i1 @cq_measure_i1(i1 %rm)
  ret i32 0
}
