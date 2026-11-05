; /* tests/spine probe (CR rule 5 sentences 1, 3): 202's shape on a global: a copy un-copied and freed before the store, a
;  * copy the store overtakes (un-copied, not freed), a kept store at an address rail, a measured copy. */
; ModuleID = 'bus_kept_overtaken.c'
source_filename = "bus_kept_overtaken.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@a = local_unnamed_addr global [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @kept_overtaken(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %8 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #2
  %9 = and i32 %7, 3
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [4 x i32], ptr @a, i64 0, i64 %10
  %12 = load i32, ptr %11, align 4, !tbaa !6
  %13 = icmp sgt i32 %12, 2
  br i1 %13, label %14, label %15

14:                                               ; preds = %6
  tail call void @cq_phi(double noundef %4) #3
  br label %15

15:                                               ; preds = %14, %6
  %16 = lshr i32 %7, 2
  %17 = and i32 %16, 3
  %18 = zext nneg i32 %17 to i64
  %19 = getelementptr inbounds [4 x i32], ptr @a, i64 0, i64 %18
  %20 = load i32, ptr %19, align 4, !tbaa !6
  store i32 %8, ptr %11, align 4, !tbaa !6
  %21 = icmp sgt i32 %20, 2
  br i1 %21, label %22, label %23

22:                                               ; preds = %15
  tail call void @cq_phi(double noundef %5) #3
  br label %23

23:                                               ; preds = %22, %15
  %24 = load i32, ptr @a, align 16, !tbaa !6
  %25 = tail call i32 @cq_measure_si32(i32 noundef %24) #3
  ret i32 %25
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

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
; USERCHECK kept_overtaken
; CHECK-COUNT kept_overtaken: call void @cqrt_qram_store_i32( 1
; CHECK-COUNT kept_overtaken: call void @cqrt_qram_load_i32_unc( 2
; CHECK-COUNT kept_overtaken: call i32 @cqrt_qram_load_i32_hl( 1
