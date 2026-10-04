; control_inplace_ry_inloop_twofn_mixed_clauses.ll — ACCEPT (bd
; `test_C_libtooling-wx8g`, review round 1): TWO FUNCTIONS IN ONE MODULE GRANTED
; BY TWO DIFFERENT R7-LOOP CLAUSES, and both must keep lowering.
;
;     int f_c(void) { for (k<2) { bool t = 0; cq_theta(&t,.5); int r = 7; cq_theta(&r,.25);
;                                 if (t) cq_theta(&r,.2); … } }   // clause (c)
;     int f_b(void) { int r = 7; cq_theta(&r,.25); bool b = 0; cq_theta(&b,.5);
;                     for (k<2) { if (b) cq_theta(&r,.2); } … }   // clause (b')
;
; THE POSITIVE CONTROL FOR BOTH ROUND-1 FIXES, and it is a control precisely
; because both fixes move in the DECLINE direction and a fence that declines
; everything is not a fence:
;   * F-W1-1 scoped `declineUnmarkedRolledIterLocal`'s per-loop dedup sets INSIDE
;     the per-function body and keyed them on the loop HEADER. This module is the
;     mixed two-function pair that must still ACCEPT — the same axis as
;     `control_inplace_ry_reject_inloop_iterlocal_twofn.ll`, opposite verdict.
;   * F-W1-2 made the record fire at EVERY R7-loop grant, so `f_b`'s (b') grant
;     is now recorded and re-asked where before it was invisible. It passes
;     because its body has no spine-discharge candidate at all: a bare `_Bool`
;     condition mints nothing and derives nothing, so there is no per-trip
;     `cq_template_*` rail for the whole-DAG spine to place an `_unc` for.
;
; MEASURED: ORACLE `f7b65d8c…` DECLINES the whole module (the l4x4.b in-loop rail
; carve-out this increment retires); on the fixed binary it lowers to 22 trace
; lines, BYTE-IDENTICAL to its hand-unrolled twin
; (`trackW/probes/w_l_twofn_mixed_clauses{,_unrolled}.c`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOMINT < %t.cqd0.ll
;
; `f_c` — every mint INSIDE the surviving loop block (clause (c)):
; CHECK-LABEL: define i32 @f_c
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; CHECK-NEXT: %h1 = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 2.000000e-01)
;
; `f_b` — both mints in the ENTRY block, ONCE (clause (b'), the loop-CARRIED
; rail), and the controlled Ry alone in the loop body:
; CHECK-LABEL: define i32 @f_b
; CHECK: %h1 = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01)
; CHECK-NEXT: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; CHECK: call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 2.000000e-01)
;
; ⚠ COUNTS IN THEIR OWN WHOLE-FILE PREFIX (Rule 12 hygiene (a)). FOUR, not two:
; `-O1` inlines both kernels into `@main`, so the module carries a third and a
; fourth controlled Ry — which is itself the two-function axis under a different
; name, and is why a count is pinned at module scope rather than per function.
; COUNT-COUNT-4: call void @cqrt_ry_i32_controlled(
; COUNT-NOT: call void @cqrt_ry_i32_controlled(
;
; ⚠ A PURE NEGATIVE PREFIX. A rail condition mints nothing, so neither clause
; puts a template rail, an X bracket or a free anywhere in the module — and THAT
; ABSENCE is what makes conjunct 2 skip both loops.
; NOMINT-NOT: cq_template_
; NOMINT-NOT: call void @cqrt_free(
; NOMINT-NOT: call void @cqrt_x(
; NOMINT-NOT: cqrt_cswap
;
; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/probes/w_l_twofn_mixed_clauses.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/probes/w_l_twofn_mixed_clauses.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f_c() local_unnamed_addr #0 {
  br label %2

1:                                                ; preds = %9
  ret i32 %15

2:                                                ; preds = %0, %9
  %3 = phi i32 [ 0, %0 ], [ %15, %9 ]
  %4 = phi i32 [ 0, %0 ], [ %16, %9 ]
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %6 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br i1 %5, label %7, label %9

7:                                                ; preds = %2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.000000e-01) #2
  br label %9

9:                                                ; preds = %7, %2
  %10 = phi i32 [ %8, %7 ], [ %6, %2 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #2
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #2
  %13 = zext i1 %12 to i32
  %14 = add i32 %11, %3
  %15 = add i32 %14, %13
  %16 = add nuw nsw i32 %4, 1
  %17 = icmp eq i32 %4, 0
  br i1 %17, label %2, label %1, !llvm.loop !6
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f_b() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  br label %8

3:                                                ; preds = %13
  %4 = tail call i32 @cq_measure_si32(i32 noundef %14) #2
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #2
  %6 = zext i1 %5 to i32
  %7 = add nsw i32 %4, %6
  ret i32 %7

8:                                                ; preds = %0, %13
  %9 = phi i32 [ 0, %0 ], [ %15, %13 ]
  %10 = phi i32 [ %1, %0 ], [ %14, %13 ]
  br i1 %2, label %11, label %13

11:                                               ; preds = %8
  %12 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 2.000000e-01) #2
  br label %13

13:                                               ; preds = %8, %11
  %14 = phi i32 [ %12, %11 ], [ %10, %8 ]
  %15 = add nuw nsw i32 %9, 1
  %16 = icmp eq i32 %9, 0
  br i1 %16, label %8, label %3, !llvm.loop !9
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  br label %1

1:                                                ; preds = %8, %0
  %2 = phi i32 [ 0, %0 ], [ %14, %8 ]
  %3 = phi i32 [ 0, %0 ], [ %15, %8 ]
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %5 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br i1 %4, label %6, label %8

6:                                                ; preds = %1
  %7 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 2.000000e-01) #2
  br label %8

8:                                                ; preds = %6, %1
  %9 = phi i32 [ %7, %6 ], [ %5, %1 ]
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #2
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #2
  %12 = zext i1 %11 to i32
  %13 = add i32 %10, %2
  %14 = add i32 %13, %12
  %15 = add nuw nsw i32 %3, 1
  %16 = icmp eq i32 %3, 0
  br i1 %16, label %1, label %17, !llvm.loop !6

17:                                               ; preds = %8
  %18 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  %19 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  br label %20

20:                                               ; preds = %25, %17
  %21 = phi i32 [ 0, %17 ], [ %27, %25 ]
  %22 = phi i32 [ %18, %17 ], [ %26, %25 ]
  br i1 %19, label %23, label %25

23:                                               ; preds = %20
  %24 = tail call i32 @cq_theta_si32(i32 noundef %22, double noundef 2.000000e-01) #2
  br label %25

25:                                               ; preds = %23, %20
  %26 = phi i32 [ %24, %23 ], [ %22, %20 ]
  %27 = add nuw nsw i32 %21, 1
  %28 = icmp eq i32 %21, 0
  br i1 %28, label %20, label %29, !llvm.loop !9

29:                                               ; preds = %25
  %30 = tail call i32 @cq_measure_si32(i32 noundef %26) #2
  %31 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %19) #2
  %32 = zext i1 %31 to i32
  %33 = add i32 %30, %14
  %34 = add i32 %33, %32
  ret i32 %34
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !7, !8}
