; ModuleID = 'jac.c'
source_filename = "jac.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 2) i32 @jac(i64 noundef %0, i64 noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #2
  %6 = icmp eq i64 %0, 0
  br i1 %6, label %56, label %7

7:                                                ; preds = %4
  %8 = and i64 %0, 1
  %9 = icmp eq i64 %8, 0
  br i1 %9, label %10, label %21

10:                                               ; preds = %7
  %11 = lshr i64 %1, 1
  %12 = xor i64 %11, %1
  %13 = trunc i64 %12 to i32
  br label %14

14:                                               ; preds = %10, %14
  %15 = phi i32 [ %5, %10 ], [ %17, %14 ]
  %16 = phi i64 [ %0, %10 ], [ %18, %14 ]
  %17 = xor i32 %15, %13
  %18 = lshr exact i64 %16, 1
  %19 = and i64 %16, 2
  %20 = icmp eq i64 %19, 0
  br i1 %20, label %14, label %21, !llvm.loop !6

21:                                               ; preds = %14, %7
  %22 = phi i64 [ %0, %7 ], [ %18, %14 ]
  %23 = phi i32 [ %5, %7 ], [ %17, %14 ]
  %24 = icmp eq i64 %22, 1
  br i1 %24, label %52, label %25

25:                                               ; preds = %21, %48
  %26 = phi i64 [ %40, %48 ], [ %1, %21 ]
  %27 = phi i64 [ %26, %48 ], [ %22, %21 ]
  %28 = phi i32 [ %51, %48 ], [ %23, %21 ]
  %29 = lshr i64 %26, 1
  %30 = xor i64 %29, %26
  %31 = trunc i64 %30 to i32
  br label %32

32:                                               ; preds = %46, %25
  %33 = phi i64 [ %27, %25 ], [ %40, %46 ]
  %34 = phi i32 [ %28, %25 ], [ %41, %46 ]
  %35 = sub i64 %33, %26
  %36 = icmp eq i64 %35, 0
  br i1 %36, label %56, label %37

37:                                               ; preds = %32, %37
  %38 = phi i64 [ %40, %37 ], [ %35, %32 ]
  %39 = phi i32 [ %41, %37 ], [ %34, %32 ]
  %40 = lshr i64 %38, 1
  %41 = xor i32 %39, %31
  %42 = and i64 %38, 2
  %43 = icmp eq i64 %42, 0
  br i1 %43, label %37, label %44, !llvm.loop !9

44:                                               ; preds = %37
  %45 = icmp eq i64 %40, 1
  br i1 %45, label %52, label %46

46:                                               ; preds = %44
  %47 = icmp ult i64 %40, %26
  br i1 %47, label %48, label %32, !llvm.loop !10

48:                                               ; preds = %46
  %49 = and i64 %40, %26
  %50 = trunc i64 %49 to i32
  %51 = xor i32 %41, %50
  br label %25, !llvm.loop !11

52:                                               ; preds = %44, %21
  %53 = phi i32 [ %23, %21 ], [ %41, %44 ]
  %54 = and i32 %53, 2
  %55 = sub nsw i32 1, %54
  br label %56

56:                                               ; preds = %32, %4, %52
  %57 = phi i32 [ %55, %52 ], [ 0, %4 ], [ 0, %32 ]
  ret i32 %57
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }

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
!10 = distinct !{!10, !8}
!11 = distinct !{!11, !8}
