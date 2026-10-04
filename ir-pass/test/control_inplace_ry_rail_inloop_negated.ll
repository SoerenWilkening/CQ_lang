; control_inplace_ry_rail_inloop_negated.ll — ACCEPT (bd
; `test_C_libtooling-wx8g`): the NEGATED bare-`_Bool` in-place controlled-Ry arm
; inside a classically-bounded loop, lowered ROLLED.
;
;     bool b = 0; cq_theta(&b, .5); int r = 7; cq_theta(&r, .25);
;     for (k < 2) if (!b) cq_theta(&r, .2);
;
; THE POINT OF THIS FILE IS THE ANTI-CONTROL, PER ACTIVATION. l4x4.b's answer to
; a negated rail arm is Ry ADDITIVITY (`emitInPlaceRotationRegion` §2.3 option A)
; — `ry(h, θ)` unconditionally, then `ry_controlled(h_b, h, −θ)` to cancel it on
; the `b = 1` branch — because the `cqrt_x` bracket the COMPARE path uses is
; FORBIDDEN on a user register (Inc 1b's non-negotiable) and `X·P(θ)·X` is an
; identity about a DIAGONAL gate, which Ry is not.
;
; That pair must appear INSIDE the loop body, once per activation, with the
; UNCONTROLLED gate first: the cancelling gate is the ORIGINAL theta CHAINED onto
; a clone of itself, so `lowerRotations` lowers both through its ordinary
; `Chained` path and M-β's RAUW target is still the last gate in the stream. A
; rolled form that hoisted either half out of the body would apply the rotation
; once and cancel it K times.
;
; MEASURED byte-identical to its hand-unrolled twin at 10 trace lines (probe
; `w_a_neg` / `w_a_neg_unrolled`, `$SES/trackW/probes/`).
;
; ⚠ The angle here is a CONSTANT, which is what makes the `fneg` a sign-bit flip
; and exact. A NON-FINITE constant angle is refused before any mutation (l4x4.b
; round-1 finding F-1) and an `undef`/`poison` one by `valueCarriesUndef`; both
; refusals are ABOVE R7 and are unchanged by this increment.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOBRACKET < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @slice
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: %h1 = call i32 @cqrt_alloc_i32(i32 7)
; The ADDITIVITY PAIR, in the loop body, unconditional gate FIRST:
; CHECK: phi i32 [ 0, %0 ], [
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h1, double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double -2.000000e-01)
;
; ⚠ COUNTS IN THEIR OWN WHOLE-FILE PREFIX (Rule 12 hygiene (a)). Two functions,
; one pair each — never three gates, which is what a hoisted half would give.
; COUNT-COUNT-2: call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double -2.000000e-01)
; COUNT-NOT: call void @cqrt_ry_i32_controlled(
;
; ⚠ A PURE NEGATIVE PREFIX: NEVER a `cqrt_x` on a user register, and no flag
; mint, strip, free or route anywhere — a rail condition mints nothing.
; NOBRACKET-NOT: call void @cqrt_x(
; NOBRACKET-NOT: call void @cqrt_free(
; NOBRACKET-NOT: cq_template_
; NOBRACKET-NOT: cqrt_cswap
;
; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/probes/w_a_neg.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/probes/w_a_neg.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br label %8

3:                                                ; preds = %13
  %4 = tail call i32 @cq_measure_si32(i32 noundef %14) #2
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2
  %6 = zext i1 %5 to i32
  %7 = add nsw i32 %4, %6
  ret i32 %7

8:                                                ; preds = %0, %13
  %9 = phi i32 [ 0, %0 ], [ %15, %13 ]
  %10 = phi i32 [ %2, %0 ], [ %14, %13 ]
  br i1 %1, label %13, label %11

11:                                               ; preds = %8
  %12 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 2.000000e-01) #2
  br label %13

13:                                               ; preds = %8, %11
  %14 = phi i32 [ %10, %8 ], [ %12, %11 ]
  %15 = add nuw nsw i32 %9, 1
  %16 = icmp eq i32 %9, 0
  br i1 %16, label %8, label %3, !llvm.loop !6
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #2
  br label %3

3:                                                ; preds = %8, %0
  %4 = phi i32 [ 0, %0 ], [ %10, %8 ]
  %5 = phi i32 [ %2, %0 ], [ %9, %8 ]
  br i1 %1, label %8, label %6

6:                                                ; preds = %3
  %7 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 2.000000e-01) #2
  br label %8

8:                                                ; preds = %6, %3
  %9 = phi i32 [ %5, %3 ], [ %7, %6 ]
  %10 = add nuw nsw i32 %4, 1
  %11 = icmp eq i32 %4, 0
  br i1 %11, label %3, label %12, !llvm.loop !6

12:                                               ; preds = %8
  %13 = tail call i32 @cq_measure_si32(i32 noundef %9) #2
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) #2
  %15 = zext i1 %14 to i32
  %16 = add nsw i32 %13, %15
  ret i32 %16
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
