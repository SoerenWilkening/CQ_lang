; /* tests/spine probe (CR rules 5, 20): under a quantum predicate every bus access is _controlled, a constant global's
;  * too (`_hl_controlled`); the copy's _unc takes the same control; a kept store keeps its control rail. */
; ModuleID = 'bus_arm_access.c'
source_filename = "bus_arm_access.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 5, align 4
@h = local_unnamed_addr global i32 6, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @arm_access(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #2
  %7 = icmp sgt i32 %5, 0
  br i1 %7, label %8, label %11

8:                                                ; preds = %4
  %9 = load i32, ptr @g, align 4, !tbaa !6
  %10 = add nsw i32 %9, 9
  store i32 %6, ptr @h, align 4, !tbaa !6
  br label %14

11:                                               ; preds = %4
  %12 = load i32, ptr @h, align 4, !tbaa !6
  %13 = add nsw i32 %12, -7
  store i32 3, ptr @g, align 4, !tbaa !6
  br label %14

14:                                               ; preds = %11, %8
  %15 = phi i32 [ %10, %8 ], [ %13, %11 ]
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  ret i32 %16
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
; USERCHECK arm_access
; CHECK arm_access: @cqrt_qram_store_i32_hl_controlled(
; CHECK arm_access: @cqrt_qram_load_i32_hl_controlled_unc(
