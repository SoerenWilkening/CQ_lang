; ModuleID = 'jacw.c'
source_filename = "jacw.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define range(i32 -1, 2) i32 @jacl(i64 noundef %0, i64 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp eq i64 %0, 0
  br i1 %4, label %54, label %5

5:                                                ; preds = %3
  %6 = and i64 %0, 1
  %7 = icmp eq i64 %6, 0
  br i1 %7, label %8, label %19

8:                                                ; preds = %5
  %9 = lshr i64 %1, 1
  %10 = xor i64 %9, %1
  %11 = trunc i64 %10 to i32
  br label %12

12:                                               ; preds = %8, %12
  %13 = phi i32 [ %2, %8 ], [ %15, %12 ]
  %14 = phi i64 [ %0, %8 ], [ %16, %12 ]
  %15 = xor i32 %13, %11
  %16 = lshr exact i64 %14, 1
  %17 = and i64 %14, 2
  %18 = icmp eq i64 %17, 0
  br i1 %18, label %12, label %19, !llvm.loop !6

19:                                               ; preds = %12, %5
  %20 = phi i64 [ %0, %5 ], [ %16, %12 ]
  %21 = phi i32 [ %2, %5 ], [ %15, %12 ]
  %22 = icmp eq i64 %20, 1
  br i1 %22, label %50, label %23

23:                                               ; preds = %19, %46
  %24 = phi i64 [ %25, %46 ], [ %20, %19 ]
  %25 = phi i64 [ %38, %46 ], [ %1, %19 ]
  %26 = phi i32 [ %49, %46 ], [ %21, %19 ]
  %27 = lshr i64 %25, 1
  %28 = xor i64 %27, %25
  %29 = trunc i64 %28 to i32
  br label %30

30:                                               ; preds = %44, %23
  %31 = phi i64 [ %24, %23 ], [ %38, %44 ]
  %32 = phi i32 [ %26, %23 ], [ %39, %44 ]
  %33 = sub i64 %31, %25
  %34 = icmp eq i64 %33, 0
  br i1 %34, label %54, label %35

35:                                               ; preds = %30, %35
  %36 = phi i64 [ %38, %35 ], [ %33, %30 ]
  %37 = phi i32 [ %39, %35 ], [ %32, %30 ]
  %38 = lshr i64 %36, 1
  %39 = xor i32 %37, %29
  %40 = and i64 %36, 2
  %41 = icmp eq i64 %40, 0
  br i1 %41, label %35, label %42, !llvm.loop !9

42:                                               ; preds = %35
  %43 = icmp eq i64 %38, 1
  br i1 %43, label %50, label %44

44:                                               ; preds = %42
  %45 = icmp ult i64 %38, %25
  br i1 %45, label %46, label %30, !llvm.loop !10

46:                                               ; preds = %44
  %47 = and i64 %38, %25
  %48 = trunc i64 %47 to i32
  %49 = xor i32 %39, %48
  br label %23, !llvm.loop !11

50:                                               ; preds = %42, %19
  %51 = phi i32 [ %21, %19 ], [ %39, %42 ]
  %52 = and i32 %51, 2
  %53 = sub nsw i32 1, %52
  br label %54

54:                                               ; preds = %30, %3, %50
  %55 = phi i32 [ %53, %50 ], [ 0, %3 ], [ 0, %30 ]
  ret i32 %55
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 2) i32 @jacw(i64 noundef %0, i64 noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #1 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #3
  %6 = tail call i32 @jacl(i64 noundef %0, i64 noundef %1, i32 noundef %5)
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define range(i32 -1, 2) i32 @red1l(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  switch i32 %0, label %4 [
    i32 0, label %18
    i32 1, label %14
  ]

4:                                                ; preds = %3, %9
  %5 = phi i32 [ %10, %9 ], [ %0, %3 ]
  %6 = phi i32 [ %11, %9 ], [ %2, %3 ]
  %7 = lshr i32 %5, 1
  %8 = icmp eq i32 %7, %1
  br i1 %8, label %18, label %9

9:                                                ; preds = %4
  %10 = xor i32 %7, %1
  %11 = xor i32 %10, %6
  %12 = and i32 %10, 1
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %4, label %14, !llvm.loop !12

14:                                               ; preds = %9, %3
  %15 = phi i32 [ %2, %3 ], [ %11, %9 ]
  %16 = and i32 %15, 2
  %17 = sub nsw i32 1, %16
  br label %18

18:                                               ; preds = %4, %3, %14
  %19 = phi i32 [ %17, %14 ], [ %0, %3 ], [ 0, %4 ]
  ret i32 %19
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 2) i32 @red1w(i32 noundef %0, i32 noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #1 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #3
  %6 = tail call i32 @red1l(i32 noundef %0, i32 noundef %1, i32 noundef %5)
  ret i32 %6
}

attributes #0 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }

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
!12 = distinct !{!12, !8}
