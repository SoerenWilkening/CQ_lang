; control_phase_kickback_reject_compound_cond.ll — DECLINE. Rule-13 round-1
; findings F-L3-7 / F-L5-5 (bd test_C_libtooling-3qlq Inc 1 part A, lenses L3+L5):
; a COMPOUND condition tree is P3/P4 (part B) and must NOT be reported as a
; "bare i1 condition".
;
;     volatile int gc;
;     if (gc) { if (q == 5) cq_phi(PI); }
;
; `clang -O1` folds the nest to `%5 = select i1 %3, i1 %4, i1 false`, where `%3`
; is CLASSICAL (the volatile load) and `%4` is the tainted compare.
;
; WHAT WENT WRONG. `classifyPhaseKickback` step 5 gave EVERY non-`CmpInst`
; condition the message `branch phase on a bare i1 condition`, deliberately. It is
; FALSE about this program — there is no bare `i1` from `cq_theta` anywhere in it,
; the condition is a TREE, and one of its two operands is not even quantum — and
; it is a diagnostic REGRESSION against the pre-3qlq oracle, which said
; `control flow under quantum control` and was right. Two further programs reach
; the same clause and were mislabelled the same way: the folded true nest
; `if (q==5) { if (p==7) cq_phi(θ); }` and the back-edge-only region
; `for(i<3){ if (i) { if (q==5) cq_phi(θ); } … }`.
;
; The split is by SHAPE and the boundary is exactly the two increments: a
; condition TREE (`select i1` / `and`/`or`/`xor` over `i1`) takes the pre-existing
; `control flow`; a tainted `i1` VALUE keeps `branch phase on a bare i1
; condition`, which is Inc 1b's shape and is pinned by
; `control_phase_kickback_reject_bare_i1.ll`. That pair is what lets Inc 1b's
; fixture stay a DISCRIMINATOR: when 1b lands and clears the bare-i1 shape, the
; string must stop firing — under the old spelling it would have gone on firing
; here, with no fixture able to tell.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: control flow under quantum control
; CHECK-NOT: bare i1 condition

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@gc = global i32 0, align 4

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #1
  %2 = load volatile i32, ptr @gc, align 4
  %3 = icmp ne i32 %2, 0
  %4 = icmp eq i32 %1, 5
  %5 = select i1 %3, i1 %4, i1 false
  br i1 %5, label %6, label %7

6:                                                ; preds = %0
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #1
  br label %7

7:                                                ; preds = %6, %0
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1) #1
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
