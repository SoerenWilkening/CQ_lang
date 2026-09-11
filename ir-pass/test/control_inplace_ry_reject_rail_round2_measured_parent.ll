; control_inplace_ry_reject_rail_round2_measured_parent.ll — DECLINE from
; `reverifyRailCondReads`, RUNG (ii) half. The twin of
; `..._round2_sibling_theta.ll`: same two-TU round-2 taint window, same 6.5
; `%out`-derived seed, but the thing that is wrong is a MEASUREMENT rather than a
; sibling gate.
;
;       bool x  = (y != 0);             /* CLASSICAL at round 1  */
;       bool xm = cq_measure(x);        /* collapses x's rail    */
;       bool b  = cq_theta(x, 0.25);    /* CHAINED onto it at FINAL taint */
;       if (b) r = cq_theta(r, 0.9);
;
; At round-1 taint `railWireNamesBackward` stops at `b` (its arg-0 `x` is not yet
; tainted, so `b` reads as a SOURCE theta) and never sees the measurement; at
; final taint `b` is CHAINED onto `x`'s rail and the measurement collapses the
; very register the arm would control on — a post-measure gate, Rule 6's
; loud-reject class. BOTH rungs are re-asked by the tripwire, which is why both
; halves are pinned: a re-verification that asked only the gate question would
; leave this one silent.;
; RED ON `main` 0c7380c AND ON the F2 checkpoint 578dbc4: both decline
; `bare i1 register condition` at `classifyArms`' first gate, so neither binary
; can witness this fence at all. The string below is reachable only because
; l4x4.b widened that gate.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout, so every IR-TEXT negative a
; decline fixture could carry is VACUOUS — `2>&1 | FileCheck` sees the diagnostic
; and nothing else. What pins "no silent lowering" is the `not` INVERSION on the
; RUN line above (the pass must exit non-zero) plus the string below, mirrored
; character-for-character against `ir-pass/src`.
; CHECK: error: {{.*}}cq {{[a-z ]*}}lowering: condition measured before the control route under quantum control

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #3
  %3 = icmp sgt i32 %2, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ 5, %1 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  %9 = icmp eq i32 %0, 0
  br i1 %9, label %11, label %10

10:                                               ; preds = %6
  tail call void @ext_sink(i32 noundef %8) #3
  br label %11

11:                                               ; preds = %10, %6
  %12 = icmp ne i32 %7, 0
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %12) #3
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %12, double noundef 2.500000e-01) #3
  %15 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 2.500000e-01) #3
  br i1 %14, label %16, label %18

16:                                               ; preds = %11
  %17 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 9.000000e-01) #3
  br label %18

18:                                               ; preds = %16, %11
  %19 = phi i32 [ %17, %16 ], [ %15, %11 ]
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  %21 = zext i1 %13 to i32
  %22 = add i32 %8, %21
  %23 = add i32 %22, %20
  ret i32 %23
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @slice(i32 noundef 1)
  ret i32 0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define void @ext_sink(i32 noundef %0) local_unnamed_addr #2 {
  ret void
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
