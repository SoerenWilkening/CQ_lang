; control_phase_kickback_mixed_claim_across_loops_leak_control.ll —
; ACCEPT-AND-LEAKS. bd test_C_libtooling-3qlq Inc 1, the THIRD C-1 review round,
; finding **F-C1B-2**: `taint.ClaimedRailRoots` was MODULE-WIDE and keyed on the
; ROOT VALUE, while the property `invariantRegisterRoots` clause (0) skips on is
; PER-LOOP.
;
;     int ext_f(int a);                             /* separate TU: return a + 100; */
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
;       for(int i=0;i<3;i++){ r=cq_theta(r,0.1); }  /* LOOP A — tryCaseA CLAIMS r     */
;       int y=5; if (q>5) y=ext_f(7);               /* 6.5 arm -> %out (ROUND 2)      */
;       int acc=0;
;       for(int i=0;i<3;i++){ if((y>>i)&1) cq_phi(0.25);
;                             int s=cq_theta(r,0.2); acc+=cq_measure(s); }  /* LOOP B */
;       return cq_measure(y)+acc; }
;
; Clause (0) means *"THIS loop's collapse already proved THIS rail, so do not judge
; it again"*. Keyed on the root alone, LOOP A's claim satisfied it for LOOP B —
; where clause (iii)'s own question (is there an in-loop in-place gate on this
; root?) was then never asked, and loop B's body was MARKED on a rail loop B never
; proved. Instrumented ground truth on the round-2 binary:
;
;     [DBG] R2=0 localRoots=0 claimed=1          <- the claim comes from LOOP A
;     [DBG] IRR TRUE roots=2 marked=0
;     [DBG] markIfRailLocal MARKED 1 blocks      <- loop B marked
;
; and on this HEAD, with the key `(root, the CLAIMING loop's header)`:
;
;     [DBG] R2=0 localRoots=0 claimedTOTAL=1 claimedHERE=0
;     [DBG] IRR FALSE rollback=0                 <- judged, and refused
;
; ⭐ THE OBSERVABLE. The round-2 binary emitted 3 `cq_template_and_i32_hl` mints
; and 3 `_unc` discharges (51 trace lines); 542d588, the round-1 fix and this HEAD
; emit 3 mints / **0** discharges (45 lines, BYTE-IDENTICAL across the three). So
; the per-loop key is not a new over-decline — it REVERTS a widening the second
; round introduced by accident. The lens that found F-C1B-2 graded it LATENT
; because the four spellings it built all decline at a later fence; this fifth one
; does not, which is why the finding has a fixture at all.
;
; The hand-unrolled twin of this source DECLINES on every binary in the epic
; (`cq loop lowering: loop-carried rail has multiple in-place consumers`, the
; Rule-8 fan-out guard), so there is no twin witness in either direction — the
; witness is the three-binary byte diff plus the instrumented marking.
;
; ⚠ A HEADER-BLOCK KEY CAN ONLY EVER REFUSE, which is what makes it admissible
; inside a Rule-13 fence. If the pointer ever failed to survive the round-2
; flatten, the claim would not match, clause (0) would judge the candidate,
; clause (iii) would refuse it, and the module would keep today's leak. It DOES
; survive, MEASURED for BOTH writers (`tryCaseA` at round 1 read at round 2 —
; `p/r33_onward_inv_only.c`, `claimedHERE=1`; `collapseRailPhisIn` step (4) —
; `p/r40_onward_r1open.c`, `claimedHERE=1` at both offers), and every shipped
; customer keeps its 3/3 rolled-vs-unrolled identity.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll

; The two root mints. NOTE the printed BLOCK ORDER below is entry, then the 6.5
; region's block, then LOOP A's body, then LOOP B's — `-O1` rotates both loops, so
; these CHECKs follow file order, not source order.
; CHECK: call void @cqrt_ry_i32(i32 %{{.*}}, double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)

; The 6.5 arm's out-rail, minted between the two loops.
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)

; LOOP A: the carried rail collapsed to its root — one `cqrt_ry` per trip on `%r`.
; CHECK: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)

; LOOP B: the bit rail off `%out`, the flag, the kickback, the strip and the flag
; free — and NO discharge of the bit rail. That is the leak this file pins.
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)

; ⭐ THE ASSERTION: ZERO `and` discharges anywhere. It was ONE on the round-2 binary.
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; One kickback gate, in loop B's body.
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; `#cqrt_rz_i1 == #!cq.branchphase` — an unmarked kickback gate is one the
; uncompute spine would adjoint, cancelling the user's phase exactly (F-L7-1).
; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT: !cq.branchphase

; The `cqrt_free` census — a dropped or an extra free is a Rule-6 defect the
; positive CHECKs cannot see.
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; The `cqrt_x` census: the kickback's polarity bracket(s) and the arm brackets.
; An UNPAIRED one is a wrong-branch phase.
; XCNT-COUNT-4: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; WHOLE-FILE PURE-NEGATIVE.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: @cqrt_rz_{{[a-z0-9]+}}_controlled(

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #3
  br label %6

4:                                                ; preds = %6
  %5 = icmp sgt i32 %2, 5
  br i1 %5, label %12, label %14

6:                                                ; preds = %6, %1
  %7 = phi i32 [ %3, %1 ], [ %9, %6 ]
  %8 = phi i32 [ 0, %1 ], [ %10, %6 ]
  %9 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 1.000000e-01) #3
  %10 = add nuw nsw i32 %8, 1
  %11 = icmp eq i32 %10, 3
  br i1 %11, label %4, label %6, !llvm.loop !6

12:                                               ; preds = %4
  %13 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %14

14:                                               ; preds = %12, %4
  %15 = phi i32 [ %13, %12 ], [ 5, %4 ]
  br label %19

16:                                               ; preds = %26
  %17 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  %18 = add nsw i32 %17, %29
  ret i32 %18

19:                                               ; preds = %26, %14
  %20 = phi i32 [ 0, %14 ], [ %30, %26 ]
  %21 = phi i32 [ 0, %14 ], [ %29, %26 ]
  %22 = shl nuw nsw i32 1, %20
  %23 = and i32 %22, %15
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %26, label %25

25:                                               ; preds = %19
  tail call void @cq_phi(double noundef 2.500000e-01) #3
  br label %26

26:                                               ; preds = %25, %19
  %27 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 2.000000e-01) #3
  %28 = tail call i32 @cq_measure_si32(i32 noundef %27) #3
  %29 = add nsw i32 %28, %21
  %30 = add nuw nsw i32 %20, 1
  %31 = icmp eq i32 %30, 3
  br i1 %31, label %16, label %19, !llvm.loop !9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable

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
!9 = distinct !{!9, !7, !8}
