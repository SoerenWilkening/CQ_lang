; ModuleID = 'sub_abort_skip.c'
source_filename = "sub_abort_skip.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @sub_abort_skip(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #3
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #3
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #3
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #3
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #3
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #3
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext true, double noundef 1.000000e+00) #3
  %9 = zext i1 %7 to i32
  %10 = select i1 %8, i32 2, i32 0
  %11 = or disjoint i32 %10, %9
  br i1 %2, label %12, label %49

12:                                               ; preds = %1
  %13 = select i1 %5, i32 8, i32 0
  %14 = select i1 %6, i32 16, i32 0
  %15 = or disjoint i32 %13, %14
  %16 = select i1 %3, i32 2, i32 0
  %17 = select i1 %4, i32 4, i32 0
  %18 = or disjoint i32 %16, %17
  %19 = or disjoint i32 %15, %18
  br label %20

20:                                               ; preds = %12, %42
  %21 = phi i32 [ %46, %42 ], [ %0, %12 ]
  %22 = phi i32 [ %45, %42 ], [ 0, %12 ]
  %23 = phi i32 [ %24, %42 ], [ %19, %12 ]
  %24 = lshr i32 %23, 1
  %25 = and i32 %21, 1
  %26 = icmp eq i32 %25, 0
  br i1 %26, label %42, label %27

27:                                               ; preds = %20
  %28 = shl nuw nsw i32 %24, 2
  %29 = or disjoint i32 %28, %11
  br label %30

30:                                               ; preds = %35, %27
  %31 = phi i32 [ %29, %27 ], [ %36, %35 ]
  %32 = phi i32 [ 0, %27 ], [ %37, %35 ]
  %33 = and i32 %31, 1
  %34 = icmp eq i32 %33, 0
  br i1 %34, label %40, label %35

35:                                               ; preds = %30
  %36 = lshr i32 %31, 1
  %37 = add nuw nsw i32 %32, 1
  %38 = icmp eq i32 %37, 3
  br i1 %38, label %39, label %30, !llvm.loop !6

39:                                               ; preds = %35
  tail call void @abort() #4
  unreachable

40:                                               ; preds = %30
  %41 = add nsw i32 %32, %22
  br label %42

42:                                               ; preds = %40, %20
  %43 = phi i32 [ %41, %40 ], [ %22, %20 ]
  %44 = mul nsw i32 %43, 3
  %45 = add nsw i32 %44, 1
  %46 = add i32 %21, 1
  %47 = and i32 %23, 2
  %48 = icmp eq i32 %47, 0
  br i1 %48, label %49, label %20, !llvm.loop !9

49:                                               ; preds = %42, %1
  %50 = phi i32 [ 0, %1 ], [ %45, %42 ]
  ret i32 %50
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { cold noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { cold noreturn nounwind }

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
