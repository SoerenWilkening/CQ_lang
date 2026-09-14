; control_inplace_ry_inloop_iterlocal_no_root.ll — ACCEPT (bd
; `test_C_libtooling-wx8g`): a clause-(c) loop with NO LOOP-INVARIANT TAINTED
; REGISTER AT ALL — the `_Bool` condition is minted inside the body too, so every
; quantum value in the loop is iteration-local.
;
;     for (k < 2) { bool t = cq_theta(0, .5); int r = cq_theta(7, .25);
;                   if (t) r = cq_theta(r, .2); s += cq_measure(r)+cq_measure(t); }
;
; IT IS HERE TO PIN A PRECONDITION, NOT A LOWERING. `LoopLowering::
; invariantRegisterRoots` returns false for this loop at its "no invariant
; register read" early-out, so `markIfRailLocal` is NEVER CALLED and
; `taint.IterationLocalBlocks` stays empty for it. The round-2 re-ask
; (`declineUnmarkedRolledIterLocal`) would therefore decline — and MUST NOT,
; because this body holds nothing the whole-DAG spine would place an `_unc` for:
; only rotations, two measurements and the merge phi the emitter dissolves. The
; precondition `bodyHasSpineDischargeCandidate` is what separates "unmarked and
; it does not matter" from "unmarked and the per-trip rails will leak".
;
; ⚠ ITS DISCRIMINATING SIBLING IS A DECLINE:
; `control_inplace_ry_reject_inloop_iterlocal_no_root_derived.ll` is this same
; shape with a DERIVED condition, so the body DOES mint a `cq_template_and_*`
; rail per trip — and with no marking the spine never discharges it. One added
; `&` between the two files, two dispositions. Do not "simplify" either by
; deleting the other.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOMINT < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @slice
; Everything is INSIDE the loop body — both mints, the controlled Ry, and both
; measurements — so K activations mint 2K rails, exactly as K copies would:
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; CHECK-NEXT: %h1 = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %h, i32 %h1, double 2.000000e-01)
; CHECK-NEXT: %m = call i32 @cqrt_measure_i32(i32 %h1)
; CHECK-NEXT: %m2 = call i1 @cqrt_measure_i1(i32 %h)
;
; ⚠ COUNTS IN THEIR OWN WHOLE-FILE PREFIX (Rule 12 hygiene (a)).
; COUNT-COUNT-2: call void @cqrt_ry_i32_controlled(
; COUNT-NOT: call void @cqrt_ry_i32_controlled(
;
; ⚠ A PURE NEGATIVE PREFIX. Nothing is minted for the condition and nothing is
; freed — this is the shape whose body has NO spine-discharge candidate, and the
; absence of `cq_template_` below is exactly that fact.
; NOMINT-NOT: cq_template_
; NOMINT-NOT: call void @cqrt_free(
; NOMINT-NOT: call void @cqrt_x(
; NOMINT-NOT: cqrt_cswap
;
; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/probes/w_i_no_invariant_root.c'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/probes/w_i_no_invariant_root.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
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
  ret i32 %14
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
