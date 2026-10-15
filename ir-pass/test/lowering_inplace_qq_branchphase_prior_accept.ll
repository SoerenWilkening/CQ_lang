; lowering_inplace_qq_branchphase_prior_accept.ll — ACCEPT (bd r2j3.33 / dm7f.51
; step 1, R11 round 2 finding F2; repro review_s1R2/p1.c).
;
; Source (clang -O1 -include CQ.h):
;   _Bool c = 0, a = 0; cq_theta(&c,.5); cq_theta(&a,.4);
;   if (c) cq_phi(.3); c ^= a; cq_theta(&c,.7); ... measure c, a
;
; The bare-`_Bool` rail condition puts the kickback `cqrt_rz_i1(h_c, .3)` (a
; recorded branch-phase gate) directly on `c`'s rail, a PRIOR reader of the dead
; `c`. 634f64b4's G7 arm (c′) treated it as a gate with an unknown write set and
; failed loudly (an over-decline: 435b3bc1 lowered this). A diagonal branch-phase
; gate writes no basis label anywhere (`isBranchPhaseGate`, by membership): empty
; write set, settled. Analytic: the emitted P(.3) on c=1, then CNOT(a -> c), then
; Ry(.7) on c is the textbook circuit of the source, nothing else stands.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[A]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[C]], double 3.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[A]], i32 %[[C]]), !cq.inplace.qq
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[C]], double 0x3FE6666666666666)
; CHECK-NOT:  cq_template_xor_

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 3) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01)
  br i1 %1, label %3, label %4

3:                                                ; preds = %0
  tail call void @cq_phi(double noundef 3.000000e-01)
  br label %4

4:                                                ; preds = %3, %0
  %5 = xor i1 %1, %2
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %5, double noundef 0x3FE6666666666666)
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6)
  %8 = zext i1 %7 to i32
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2)
  %10 = zext i1 %9 to i32
  %11 = add nuw nsw i32 %10, %8
  ret i32 %11
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare void @cq_phi(double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr

