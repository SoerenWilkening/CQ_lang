; ModuleID = 'computed_goto_into_loop.c'
source_filename = "computed_goto_into_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@f.t = internal unnamed_addr constant [2 x ptr] [ptr blockaddress(@f, %9), ptr blockaddress(@f, %13)], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0) #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #2
  %3 = and i32 %2, 3
  %4 = lshr i32 %2, 2
  %5 = and i32 %4, 1
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [2 x ptr], ptr @f.t, i64 0, i64 %6
  %8 = load ptr, ptr %7, align 8, !tbaa !6
  indirectbr ptr %8, [label %9, label %13]

9:                                                ; preds = %13, %1
  %10 = phi i32 [ %3, %1 ], [ %17, %13 ]
  %11 = phi i32 [ 0, %1 ], [ %16, %13 ]
  %12 = add nsw i32 %11, 1
  br label %13

13:                                               ; preds = %9, %1
  %14 = phi i32 [ %10, %9 ], [ %3, %1 ]
  %15 = phi i32 [ %12, %9 ], [ 0, %1 ]
  %16 = add nsw i32 %15, 2
  %17 = add nsw i32 %14, -1
  %18 = icmp sgt i32 %14, 1
  br i1 %18, label %9, label %19

19:                                               ; preds = %13
  %20 = tail call i32 @cq_measure_si32(i32 noundef %16) #3
  ret i32 %20
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
