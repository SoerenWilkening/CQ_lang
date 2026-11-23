; ModuleID = 'fenv_loop_noreturn_arm.c'
source_filename = "fenv_loop_noreturn_arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@buf = local_unnamed_addr global [16 x i8] c"abcdefghijklmno\00", align 16

; Function Attrs: noinline nounwind ssp uwtable
define noundef i32 @g(i32 noundef returned %0) local_unnamed_addr #0 {
  %2 = tail call i32 @feraiseexcept(i32 noundef 32) #4
  ret i32 %0
}

declare i32 @feraiseexcept(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @e() local_unnamed_addr #2 {
  %1 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 5.000000e-01) #5
  br label %2

2:                                                ; preds = %8, %0
  %3 = phi i32 [ 0, %0 ], [ %9, %8 ]
  %4 = zext nneg i32 %3 to i64
  %5 = getelementptr inbounds [16 x i8], ptr @buf, i64 0, i64 %4
  %6 = load i8, ptr %5, align 1, !tbaa !6
  %7 = icmp eq i8 %6, %1
  br i1 %7, label %14, label %8

8:                                                ; preds = %2
  %9 = add nuw nsw i32 %3, 1
  %10 = icmp eq i32 %9, 7
  br i1 %10, label %11, label %2, !llvm.loop !9

11:                                               ; preds = %8
  %12 = sext i8 %1 to i32
  %13 = tail call i32 @g(i32 noundef %12)
  tail call void @exit(i32 noundef 3) #6
  unreachable

14:                                               ; preds = %2
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %3) #4
  %16 = tail call i32 @fetestexcept(i32 noundef 32) #4
  %17 = add i32 %16, %15
  ret i32 %17
}

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #1

; Function Attrs: noreturn
declare void @exit(i32 noundef) local_unnamed_addr #3

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @eq() local_unnamed_addr #2 {
  %1 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 5.000000e-01) #5
  %2 = sext i8 %1 to i32
  %3 = and i32 %2, 1
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %7, label %5

5:                                                ; preds = %0
  %6 = tail call i32 @feraiseexcept(i32 noundef 16) #4
  br label %7

7:                                                ; preds = %5, %0
  br label %8

8:                                                ; preds = %7, %14
  %9 = phi i32 [ %15, %14 ], [ 0, %7 ]
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [16 x i8], ptr @buf, i64 0, i64 %10
  %12 = load i8, ptr %11, align 1, !tbaa !6
  %13 = icmp eq i8 %12, %1
  br i1 %13, label %19, label %14

14:                                               ; preds = %8
  %15 = add nuw nsw i32 %9, 1
  %16 = icmp eq i32 %15, 7
  br i1 %16, label %17, label %8, !llvm.loop !11

17:                                               ; preds = %14
  %18 = tail call i32 @g(i32 noundef %2)
  tail call void @exit(i32 noundef 3) #6
  unreachable

19:                                               ; preds = %8
  %20 = tail call i32 @cq_measure_ui32(i32 noundef %9) #4
  %21 = tail call i32 @fetestexcept(i32 noundef 48) #4
  %22 = add i32 %21, %20
  ret i32 %22
}

; Function Attrs: noinline nounwind ssp uwtable
define i32 @h2(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 1
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %6, label %4

4:                                                ; preds = %1
  %5 = tail call i32 @feraiseexcept(i32 noundef 16) #4
  br label %6

6:                                                ; preds = %4, %1
  %7 = icmp sgt i32 %0, 2
  br i1 %7, label %8, label %18

8:                                                ; preds = %6, %8
  %9 = phi i32 [ %15, %8 ], [ 0, %6 ]
  %10 = zext i32 %9 to i64
  %11 = getelementptr inbounds [16 x i8], ptr @buf, i64 0, i64 %10
  %12 = load i8, ptr %11, align 1, !tbaa !6
  %13 = sext i8 %12 to i32
  %14 = icmp eq i32 %13, %0
  %15 = add i32 %9, 1
  br i1 %14, label %16, label %8, !llvm.loop !12

16:                                               ; preds = %8
  %17 = tail call i32 @g(i32 noundef %9)
  tail call void @exit(i32 noundef 3) #6
  unreachable

18:                                               ; preds = %6
  %19 = tail call i32 @fetestexcept(i32 noundef 48) #4
  %20 = add nsw i32 %19, %0
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @en() local_unnamed_addr #2 {
  %1 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 5.000000e-01) #5
  %2 = sext i8 %1 to i32
  %3 = and i32 %2, 4
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %7, label %5

5:                                                ; preds = %0
  %6 = tail call i32 @h2(i32 noundef %2)
  br label %7

7:                                                ; preds = %5, %0
  %8 = phi i32 [ %6, %5 ], [ 0, %0 ]
  %9 = tail call i32 @cq_measure_ui32(i32 noundef %8) #4
  %10 = tail call i32 @fetestexcept(i32 noundef 48) #4
  %11 = add i32 %10, %9
  ret i32 %11
}

; Function Attrs: noinline nounwind ssp uwtable
define i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  br label %2

2:                                                ; preds = %9, %1
  %3 = phi i32 [ 0, %1 ], [ %10, %9 ]
  %4 = zext nneg i32 %3 to i64
  %5 = getelementptr inbounds [16 x i8], ptr @buf, i64 0, i64 %4
  %6 = load i8, ptr %5, align 1, !tbaa !6
  %7 = sext i8 %6 to i32
  %8 = icmp eq i32 %7, %0
  br i1 %8, label %14, label %9

9:                                                ; preds = %2
  %10 = add nuw nsw i32 %3, 1
  %11 = icmp eq i32 %10, 7
  br i1 %11, label %12, label %2, !llvm.loop !14

12:                                               ; preds = %9
  %13 = tail call i32 @g(i32 noundef %0)
  tail call void @exit(i32 noundef 3) #6
  unreachable

14:                                               ; preds = %2
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @ec() local_unnamed_addr #2 {
  %1 = tail call signext i8 @cq_theta_c(i8 noundef signext 0, double noundef 5.000000e-01) #5
  %2 = sext i8 %1 to i32
  %3 = and i32 %2, 1
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %8, label %5

5:                                                ; preds = %0
  %6 = tail call i32 @feraiseexcept(i32 noundef 16) #4
  %7 = tail call i32 @h(i32 noundef %2)
  br label %8

8:                                                ; preds = %5, %0
  %9 = phi i32 [ %7, %5 ], [ 0, %0 ]
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #4
  %11 = tail call i32 @fetestexcept(i32 noundef 48) #4
  %12 = add i32 %11, %10
  ret i32 %12
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
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = distinct !{!9, !10}
!10 = !{!"llvm.loop.unroll.disable"}
!11 = distinct !{!11, !10}
!12 = distinct !{!12, !13, !10}
!13 = !{!"llvm.loop.mustprogress"}
!14 = distinct !{!14, !10}
