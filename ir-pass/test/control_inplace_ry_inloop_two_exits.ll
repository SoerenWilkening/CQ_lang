; control_inplace_ry_inloop_two_exits.ll — ACCEPT (ROLLED, in-loop): a
; control-in-place Ry arm in a loop with TWO EXITS, where the P1 deferred gate
; sits on the EARLY-RETURN path.
;
;     for (i = 0; i < 3; ++i) {
;         if (q == 5) cq_theta(&r, 0.9);       <-- the in-place Ry arm
;         q = cq_phi(q, 0.2);
;         if (k == i) { cq_theta(&q, 0.3);     <-- the DEFERRED gate (P1)
;                       return cq_measure(q) + cq_measure(r); }
;     }
;     return cq_measure(q) + cq_measure(r);
;
; WHY THIS FILE EXISTS (bd test_C_libtooling-drbq Inc 3, round-1 lens L8, Q3).
; The question L8 put to the flat P1 proof was whether
; `condWireDisposition`'s `provablyBefore(BI, G)` can be TRUE around a BACK EDGE
; where it should not be. It can be true — and both in-loop positions it is true
; for are sound. This is the second and sharper one: `G` is DOMINATED by `BI` and
; cannot reach it, because the block it lives in RETURNS. So the flat proof
; succeeds INSIDE a loop, and on the trace where `G` fires, that iteration's whole
; region stream (mint, controlled rotation, strip, free) has already run and the
; function leaves — no later mint reads the moved wire. Measured: ORACLE DECLINE
; -> HEAD ACCEPT, linked and run, 2 region activations then the gate at `k = 1`,
; strict stage 2b clean.
;
; ⚠ §13.1's ACCEPT SHAPE DOES NOT CONSTRAIN EXIT COUNT, AND THAT IS DELIBERATE
; RATHER THAN AN OVERSIGHT — it is `flatRegionRollableInLoop`'s (A)-(D) that
; decide, and none of the four mentions exits: (A) a natural `LoopInfo` loop,
; (B) arm and merge at the SAME depth, (C) a single LATCH, (D) no second cycle
; through the region entry. A second EXIT adds no back edge, no latch and no
; cycle, so it changes none of them. The composition is nonetheless one that no
; shipped fixture or slice had — a rolled loop with two exits AND a frozen
; controlled-Ry register — which is why the lens asked for it pinned even though
; it could not break it.
;
; WHY THE EMITTED STREAM IS RIGHT, read off the CHECKs below. The region lowers
; ONCE (rolled: exactly one mint/rotate/strip/free quadruple in the body block),
; the deferred `cqrt_ry_i32` on the CONDITION handle sits in the early-exit block
; ALONE, and the rotated register `%h1` is FROZEN — never `_unc`'d, never freed —
; on both exit paths, which is Inc 1's structural freeze doing its job across a
; back edge (a controlled gate's adjoint would need its control, and the flag is
; stripped and freed inside the iteration).
;
; THE BODY BELOW IS VERBATIM `clang -O1` OUTPUT (`review3/L8/p19*.c`), function
; renamed to `@example`, because the shape is entirely about what the optimizer
; does to a two-exit loop: `%9`/`%26` are the rotated-`i1` exit predicate SimplifyCFG
; introduces, and hand-transcribing them would have tested a different program.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; ONE copy of the region stream — the loop is ROLLED, not unrolled:
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R:[a-zA-Z0-9_.]+]], double 9.0
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the source's own diagonal reflection stays uncontrolled and in the body:
; the DEFERRED P1 gate is in the EARLY-EXIT block, on its own, after the branch:
; CHECK: call void @cqrt_ry_i32(i32 %[[Q]], double 3.0
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
;
; the FREEZE, across both exits: the rotated register is never uncomputed and
; never freed, only measured.
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: @cq_theta_
; NOROUTE-NOT: cqrt_ry_i32_controlled_inv
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @example(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br label %8

4:                                                ; preds = %16
  %5 = add nuw nsw i32 %10, 1
  %6 = icmp ugt i32 %10, 1
  %7 = icmp eq i32 %5, 3
  br i1 %7, label %25, label %8, !llvm.loop !6

8:                                                ; preds = %1, %4
  %9 = phi i1 [ false, %1 ], [ %6, %4 ]
  %10 = phi i32 [ 0, %1 ], [ %5, %4 ]
  %11 = phi i32 [ %3, %1 ], [ %17, %4 ]
  %12 = phi i32 [ %2, %1 ], [ %12, %4 ]
  %13 = icmp eq i32 %12, 5
  br i1 %13, label %14, label %16

14:                                               ; preds = %8
  %15 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 9.000000e-01) #2
  br label %16

16:                                               ; preds = %14, %8
  %17 = phi i32 [ %15, %14 ], [ %11, %8 ]
  %19 = icmp eq i32 %10, %0
  br i1 %19, label %20, label %4

20:                                               ; preds = %16
  %21 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 3.000000e-01) #2
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #2
  %23 = tail call i32 @cq_measure_si32(i32 noundef %17) #2
  %24 = add nsw i32 %23, %22
  br label %25

25:                                               ; preds = %4, %20
  %26 = phi i1 [ %9, %20 ], [ %6, %4 ]
  %27 = phi i32 [ %24, %20 ], [ undef, %4 ]
  %28 = phi i32 [ %21, %20 ], [ %12, %4 ]
  br i1 %26, label %29, label %33

29:                                               ; preds = %25
  %30 = tail call i32 @cq_measure_si32(i32 noundef %28) #2
  %31 = tail call i32 @cq_measure_si32(i32 noundef %17) #2
  %32 = add nsw i32 %31, %30
  br label %33

33:                                               ; preds = %25, %29
  %34 = phi i32 [ %32, %29 ], [ %27, %25 ]
  ret i32 %34
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1


declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @example(i32 noundef 1)
  ret i32 0
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
