; control_phase_kickback_mixed_onward_r1open_inloop.ll — ACCEPT. bd
; test_C_libtooling-3qlq Inc 1, the SECOND C-1 review round, finding
; **F-C1-2(2b)** (CONFIRMED MISCOMPILE). The SAME loop holds a ROUND-1 kickback
; region AND a ROUND-2 ONWARD one, and that combination is what made the round-2
; loop-rail pass structurally unreachable.
;
;     int ext_f(int a);                                  /* separate TU */
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
;       int y=5; if (q>5) y=ext_f(7);                    /* 6.5 arm -> %out */
;       for(int i=0;i<3;i++){ if(r==3) cq_phi(0.2);      /* ROUND-1 region  */
;                             if((y>>i)&1) cq_phi(0.25); /* ROUND-2 region  */
;                             r=cq_theta(r,0.1); }
;       return cq_measure(r)+cq_measure(y); }
;
; `clang -O1`, `llvm-link`ed with `int ext_f(int a){return a+100;}`, `@main`
; dropped. `!llvm.loop` VERBATIM.
;
; WHAT WENT WRONG — A KEY, NOT A CLAUSE. `repropagateControlMerges` re-offers a
; loop to `collapseFlattenedLoopRails` only when the ROUND-2 flatten "opened"
; something in it, and that test was MEMBERSHIP in a SET of `Pred` blocks. Round
; 1's `r==3` region flattens into `Pred`; round 2's `(y>>i)&1` region flattens
; into THAT SAME (now larger) block; membership does not move, so the loop is
; NEVER RE-OFFERED. Meanwhile the ROUND-1 call had reached `markIfRailLocal` and
; bailed `!AnyLocal` — correctly, because at round 1 the values the onward region
; derives are not yet tainted and there was genuinely nothing local to mark. So
; the marking happened at NEITHER round. MEASURED with an instrumented build:
; exactly ONE `[DBG] loop hdr=` line, `round2=0`.
;
; MEASURED on 542d588 AND on the round-1 C-1 fix: THREE `cq_template_and_i32_hl`
; mints, **ZERO** `_unc`, `opt` exit 0, verify-clean, STRICT stage 2b clean.
;
; THE FIX. `taint.InLoopFlattenedPreds` is a COUNT per block, and the round-2
; delta is the count having MOVED. The re-offer is the GRANT half of Q-R2-1 and
; is measured, not assumed: on a loop round 1 fully collapsed, `collapseRailPhisIn`
; finds no tainted header phi and returns `NotClaimed` WITHOUT mutating, and
; `markIfRailLocal` only ever inserts blocks — asked at round 2 with a strict
; SUPERSET of round-1 taint, i.e. with more evidence, never less.
;
; ⚠ NO e2e TWIN EXISTS FOR THIS SHAPE, and that is a measurement rather than an
; omission: the hand-unrolled spelling DECLINES `cq controlled lowering: control
; flow under quantum control` on 542d588, on the round-1 fix and on this HEAD
; (the clearance's §5 item 5 / OQ-C1-3 class, bd 3qlq.9). This file therefore
; carries the LIFO per-trip pairing assertion itself, in place of a byte-identity
; gate. Its sibling `control_phase_kickback_mixed_onward_inloop.ll` (the same
; shape WITHOUT the round-1 region) does have one.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

; The two root mints and the 6.5 arm's `%out`.
; CHECK: %[[Q:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)

; ⭐ THE ROLLED BODY, BOTH REGIONS, IN ORDER AND LIFO PER TRIP. The ROUND-1 region
; on the carried register comes first (no `cqrt_x` — `-O1` gives it the true
; polarity), then the ROUND-2 onward region on `%out`'s bits, whose `and` rail is
; discharged and freed INSIDE the body. That discharge is the finding.
; CHECK: %[[F1:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[R]], i32 3)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F1]], double 2.000000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[R]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: %[[F2:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F2]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A]], i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)

; ⭐ ONE `and` discharge in the rolled body. ZERO on both earlier binaries.
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; TWO kickback gates: one per region.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; FOUR frees: the 6.5 arm's flag, and per trip the round-1 flag, the bit rail and
; the round-2 flag.
; FCNT-COUNT-4: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; MDCNT-COUNT-2: !cq.branchphase
; MDCNT-NOT: !cq.branchphase

; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(
; NOROUTE-NOT: fneg

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #3
  %4 = icmp sgt i32 %2, 5
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %7

7:                                                ; preds = %5, %1
  %8 = phi i32 [ %6, %5 ], [ 5, %1 ]
  br label %13

9:                                                ; preds = %23
  %10 = tail call i32 @cq_measure_si32(i32 noundef %24) #3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %12 = add nsw i32 %11, %10
  ret i32 %12

13:                                               ; preds = %23, %7
  %14 = phi i32 [ 0, %7 ], [ %25, %23 ]
  %15 = phi i32 [ %3, %7 ], [ %24, %23 ]
  %16 = icmp eq i32 %15, 3
  br i1 %16, label %17, label %18

17:                                               ; preds = %13
  tail call void @cq_phi(double noundef 2.000000e-01) #3
  br label %18

18:                                               ; preds = %17, %13
  %19 = shl nuw nsw i32 1, %14
  %20 = and i32 %19, %8
  %21 = icmp eq i32 %20, 0
  br i1 %21, label %23, label %22

22:                                               ; preds = %18
  tail call void @cq_phi(double noundef 2.500000e-01) #3
  br label %23

23:                                               ; preds = %22, %18
  %24 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 1.000000e-01) #3
  %25 = add nuw nsw i32 %14, 1
  %26 = icmp eq i32 %25, 3
  br i1 %26, label %9, label %13, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1


; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
