; control_phase_kickback_mixed_claim_across_loops_accept_control.ll — ACCEPT. bd
; test_C_libtooling-3qlq Inc 1, the THIRD C-1 review round — **the discriminating
; control for F-C1B-2's per-loop key.**
;
;     int ext_f(int a);                             /* separate TU: return a + 100; */
;     int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
;       for(int i=0;i<3;i++){ r=cq_theta(r,0.1); }  /* LOOP A — tryCaseA CLAIMS r  */
;       int y=5; if (q>5) y=ext_f(7);
;       for(int i=0;i<3;i++){ if((y>>i)&1) cq_phi(0.25); }   /* LOOP B — no gate on r */
;       return cq_measure(y)+cq_measure(r); }
;
; This is `..._claim_across_loops_leak_control.ll` with LOOP B's in-body
; `cq_theta(r,0.2)` REMOVED, and the two dispositions are opposite. Here `r` is
; not read inside loop B at all, so it is not a candidate there and clause (0)
; never needed to skip it; loop B's own invariant register is the 6.5 `%out` rail,
; admitted by clause (ii-b), and the per-trip bit rail is discharged EVERY
; iteration.
;
; It exists because a narrowed key that refused everything would also pass the
; leak control. MEASURED: 46 trace lines, 3 `cq_template_and_i32_hl` mints / 3
; `_unc`, BYTE-IDENTICAL on 542d588, on the round-1 fix, on the round-2 fix AND
; here — the per-loop key changed nothing about it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll

; The 6.5 out-rail, then LOOP B's fully-discharging body.
; CHECK: %[[OUT:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %[[A:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 0)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[A]], i32 %[[OUT]], i32 %{{.*}})
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; ⭐ EXACTLY ONE discharge, in the rolled body — the leak control's mirror.
; UCNT-COUNT-1: call void @cq_template_and_i32_hl_unc(
; UCNT-NOT: call void @cq_template_and_i32_hl_unc(

; The region's own compare flag is freed in the pred; the body frees the bit rail
; and the kickback flag.
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(

; Exactly ONE kickback gate in the module (the rolled body's).
; ACNT-COUNT-1: call void @cqrt_rz_i1(
; ACNT-NOT: call void @cqrt_rz_i1(

; `#cqrt_rz_i1 == #!cq.branchphase` — an unmarked kickback gate is one the
; uncompute spine would adjoint, cancelling the user's phase exactly (F-L7-1).
; MDCNT-COUNT-1: !cq.branchphase
; MDCNT-NOT: !cq.branchphase

; The `cqrt_x` census: the kickback's polarity bracket(s) and the arm brackets.
; An UNPAIRED one is a wrong-branch phase.
; XCNT-COUNT-4: call void @cqrt_x(i32
; XCNT-NOT: call void @cqrt_x(i32

; WHOLE-FILE PURE-NEGATIVE.
; NOROUTE-NOT: @cqrt_cswap
; NOROUTE-NOT: @cq_phi
; NOROUTE-NOT: @cq_theta
; NOROUTE-NOT: no longer provable at lowering
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
  %7 = phi i32 [ 0, %1 ], [ %10, %6 ]
  %8 = phi i32 [ %3, %1 ], [ %9, %6 ]
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 1.000000e-01) #3
  %10 = add nuw nsw i32 %7, 1
  %11 = icmp eq i32 %10, 3
  br i1 %11, label %4, label %6, !llvm.loop !6

12:                                               ; preds = %4
  %13 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %14

14:                                               ; preds = %12, %4
  %15 = phi i32 [ %13, %12 ], [ 5, %4 ]
  br label %20

16:                                               ; preds = %26
  %17 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  %18 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  %19 = add nsw i32 %18, %17
  ret i32 %19

20:                                               ; preds = %26, %14
  %21 = phi i32 [ 0, %14 ], [ %27, %26 ]
  %22 = shl nuw nsw i32 1, %21
  %23 = and i32 %22, %15
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %26, label %25

25:                                               ; preds = %20
  tail call void @cq_phi(double noundef 2.500000e-01) #3
  br label %26

26:                                               ; preds = %25, %20
  %27 = add nuw nsw i32 %21, 1
  %28 = icmp eq i32 %27, 3
  br i1 %28, label %16, label %20, !llvm.loop !9
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
