; ModuleID = 'calloc_exact.c'
source_filename = "calloc_exact.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @c_rails(i64 noundef %0, i64 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i64 @cq_theta_ul(i64 noundef %0, double noundef 3.000000e-01) #3
  %4 = tail call i64 @cq_theta_ul(i64 noundef %1, double noundef 3.000000e-01) #3
  %5 = tail call ptr @calloc(i64 noundef %3, i64 noundef %4) #4
  %6 = icmp ne ptr %5, null
  %7 = zext i1 %6 to i32
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #5
  ret i32 %8
}

declare i64 @cq_theta_ul(i64 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: allocsize(0,1)
declare ptr @calloc(i64 noundef, i64 noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @c_rail_count(i64 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i64 @cq_theta_ul(i64 noundef %0, double noundef 3.000000e-01) #3
  %3 = tail call ptr @calloc(i64 noundef %2, i64 noundef 8) #4
  %4 = icmp ne ptr %3, null
  %5 = zext i1 %4 to i32
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #5
  ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @c_classical(i64 noundef %0, i64 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %2, double noundef 3.000000e-01) #3
  %5 = tail call ptr @calloc(i64 noundef %0, i64 noundef %1) #4
  %6 = icmp eq ptr %5, null
  br i1 %6, label %8, label %7

7:                                                ; preds = %3
  store i8 1, ptr %5, align 1, !tbaa !6
  br label %8

8:                                                ; preds = %3, %7
  %9 = phi i32 [ 1, %7 ], [ 7, %3 ]
  %10 = add i32 %4, %9
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %10) #5
  ret i32 %11
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { allocsize(0,1) "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nobuiltin nomerge nounwind "no-builtins" }
attributes #4 = { nobuiltin nounwind allocsize(0,1) "no-builtins" }
attributes #5 = { nobuiltin nounwind "no-builtins" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
