; ModuleID = 'bounded_two_exits.c'
source_filename = "bounded_two_exits.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  tail call void @cq_phi(double noundef 2.500000e-01) #4
  %3 = and i32 %1, 7
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %16, label %5

5:                                                ; preds = %2, %12
  %6 = phi i32 [ %14, %12 ], [ 0, %2 ]
  %7 = phi i32 [ %13, %12 ], [ %0, %2 ]
  %8 = add nuw nsw i32 %6, 5
  %9 = icmp eq i32 %8, %1
  br i1 %9, label %10, label %12

10:                                               ; preds = %5
  %11 = mul nsw i32 %7, 3
  br label %16

12:                                               ; preds = %5
  %13 = add nsw i32 %6, %7
  %14 = add nuw nsw i32 %6, 1
  %15 = icmp eq i32 %14, %3
  br i1 %15, label %16, label %5, !llvm.loop !6

16:                                               ; preds = %12, %2, %10
  %17 = phi i32 [ %11, %10 ], [ %0, %2 ], [ %13, %12 ]
  ret i32 %17
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @bt_ret(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 5.000000e-01) #5
  %3 = sext i8 %2 to i32
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %8, label %6

6:                                                ; preds = %1
  %7 = tail call i32 @f(i32 noundef %3, i32 noundef %0)
  br label %8

8:                                                ; preds = %6, %1
  %9 = phi i32 [ %7, %6 ], [ 0, %1 ]
  %10 = add nsw i32 %9, %3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #4
  ret i32 %11
}

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define i32 @g(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  tail call void @cq_phi(double noundef 2.500000e-01) #4
  %3 = and i32 %1, 7
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %8, label %5

5:                                                ; preds = %2
  %6 = add nsw i32 %3, -6
  %7 = icmp ult i32 %6, -5
  br label %10

8:                                                ; preds = %14, %2
  %9 = phi i32 [ %0, %2 ], [ %15, %14 ]
  ret i32 %9

10:                                               ; preds = %5, %14
  %11 = phi i32 [ %16, %14 ], [ 0, %5 ]
  %12 = phi i32 [ %15, %14 ], [ %0, %5 ]
  br i1 %7, label %13, label %14

13:                                               ; preds = %10
  tail call void @exit(i32 noundef 4) #6
  unreachable

14:                                               ; preds = %10
  %15 = add nsw i32 %11, %12
  %16 = add nuw nsw i32 %11, 1
  %17 = icmp eq i32 %16, %3
  br i1 %17, label %8, label %10, !llvm.loop !9
}

; Function Attrs: noreturn
declare void @exit(i32 noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @bt_exit(i32 noundef %0) local_unnamed_addr #2 {
  %2 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 5.000000e-01) #5
  %3 = sext i8 %2 to i32
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %8, label %6

6:                                                ; preds = %1
  %7 = tail call i32 @g(i32 noundef %3, i32 noundef %0)
  br label %8

8:                                                ; preds = %6, %1
  %9 = phi i32 [ %7, %6 ], [ 0, %1 ]
  %10 = add nsw i32 %9, %3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #4
  ret i32 %11
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }
attributes #6 = { noreturn nounwind }

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
