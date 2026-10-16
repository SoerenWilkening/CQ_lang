; spec_reject_lift_tail_unhoisted_continuation.ll — DECLINE, loud (bd
; test_C_libtooling-r2j3.37, the batch-055 INTERIM): `for (i < 2) t = f(t, a);`
; with `f(t,a) = t ^ a`. After the loop pre-passes unroll it, the FIRST call's
; result is read only by the SECOND call (a lifted reader, which the in-place
; round's `survives` counts as a temporary), so the backstop asks E3 ACROSS calls
; (`kept`: a tagged call reading the result in a chain slot whose own result is
; kept). Without that clause this compiled silently, the original `t` rail left
; beside the final value (measured before the clause existed, interim build).
;
; Source: g2.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq specialization: a lifted call overwrites a dead quantum argument, which is not lowered in place across the call
source_filename = "g2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef zeroext i1 @f(i1 noundef zeroext %0, i1 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = xor i1 %0, %1
  ret i1 %3
}

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 4) i32 @main() local_unnamed_addr #1 {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #3
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.000000e-01) #3
  br label %10

3:                                                ; preds = %10
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef 0x3FE6666666666666) #3
  %5 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #4
  %6 = zext i1 %5 to i32
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %13) #4
  %8 = select i1 %7, i32 2, i32 0
  %9 = or disjoint i32 %8, %6
  ret i32 %9

10:                                               ; preds = %0, %10
  %11 = phi i32 [ 0, %0 ], [ %14, %10 ]
  %12 = phi i1 [ %2, %0 ], [ %13, %10 ]
  %13 = tail call zeroext i1 @f(i1 noundef zeroext %12, i1 noundef zeroext %1)
  %14 = add nuw nsw i32 %11, 1
  %15 = icmp eq i32 %11, 0
  br i1 %15, label %10, label %3, !llvm.loop !6
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

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
