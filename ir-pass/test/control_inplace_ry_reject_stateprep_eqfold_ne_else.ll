; control_inplace_ry_reject_stateprep_eqfold_ne_else.ll — DECLINE (F2). PRD
; §14.3 row F2-7, probe `p08k` — the row that shipped with NO FIXTURE and was
; named nowhere (round-1 Rule-13 review, lens L5 F-L5-3 = lens L7 F-L7-6, a real
; Rule-12 gap).
;
;     int r = 5;  if (q != 5) { } else { r = cq_theta(q, 0.9); }
;
; `clang -O1` canonicalizes the `!=` into `icmp eq %q, 5` with the ARM as the
; TRUE successor and folds the arm's `cq_theta(%q, .9)` to `cq_theta(i32 5, .9)`.
;
; ⚠ WHAT IT ADDS OVER `..._eqfold_coincidence.ll`, stated precisely because the
; two are nearly the same module (MEASURED 2026-09-05, `-O1` slice-body diff):
; they differ in EXACTLY ONE THING — the merge φ's INCOMING ORDER. This file's φ
; lists the PRED edge first (`phi i32 [ 5, %entry ], [ %rt, %arm ]`), the other's
; lists the ARM edge first. F1's second sub-clause reads the pred incoming by
; `getBasicBlockIndex(Region.Pred)`, i.e. BY BLOCK and not by operand position,
; and this file is what pins that. It is not a duplicate and it is not a third
; polarity: `..._eqfold_coincidence.ll` (arm on the TRUE successor) and
; `..._eqfold_coincidence_ne.ll` (arm on the FALSE successor) already witness
; polarity-freeness.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 5, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ 5, %entry ], [ %rt, %arm ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %s  = add i32 %mr, %mq
  ret i32 %s
}
