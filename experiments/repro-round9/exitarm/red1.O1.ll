; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/r13-exitarm/work/../reduced/red1.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/1dd3c431-0687-4066-b923-d1dfeec82d5a/scratchpad/r13-exitarm/work/../reduced/red1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 2) i32 @red1(i32 noundef %0, i32 noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #2
  switch i32 %0, label %6 [
    i32 0, label %20
    i32 1, label %16
  ]

6:                                                ; preds = %4, %11
  %7 = phi i32 [ %12, %11 ], [ %0, %4 ]
  %8 = phi i32 [ %13, %11 ], [ %5, %4 ]
  %9 = lshr i32 %7, 1
  %10 = icmp eq i32 %9, %1
  br i1 %10, label %20, label %11

11:                                               ; preds = %6
  %12 = xor i32 %9, %1
  %13 = xor i32 %12, %8
  %14 = and i32 %12, 1
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %6, label %16, !llvm.loop !6

16:                                               ; preds = %11, %4
  %17 = phi i32 [ %5, %4 ], [ %13, %11 ]
  %18 = and i32 %17, 2
  %19 = sub nsw i32 1, %18
  br label %20

20:                                               ; preds = %6, %4, %16
  %21 = phi i32 [ %19, %16 ], [ %0, %4 ], [ 0, %6 ]
  ret i32 %21
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 -1, 2) i32 @red2(i32 noundef %0, i32 noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #2
  switch i32 %0, label %6 [
    i32 0, label %29
    i32 1, label %25
  ]

6:                                                ; preds = %4, %23
  %7 = phi i32 [ %24, %23 ], [ %1, %4 ]
  %8 = phi i32 [ %14, %23 ], [ %0, %4 ]
  %9 = phi i32 [ %17, %23 ], [ %5, %4 ]
  br label %10

10:                                               ; preds = %20, %6
  %11 = phi i32 [ %8, %6 ], [ %14, %20 ]
  %12 = phi i32 [ %9, %6 ], [ %17, %20 ]
  %13 = lshr i32 %11, 1
  %14 = xor i32 %13, %7
  %15 = icmp eq i32 %13, %7
  br i1 %15, label %29, label %16

16:                                               ; preds = %10
  %17 = xor i32 %14, %12
  %18 = and i32 %14, 1
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %20, label %25

20:                                               ; preds = %16
  %21 = and i32 %14, 4
  %22 = icmp eq i32 %21, 0
  br i1 %22, label %10, label %23, !llvm.loop !8

23:                                               ; preds = %20
  %24 = lshr i32 %7, 1
  br label %6, !llvm.loop !9

25:                                               ; preds = %16, %4
  %26 = phi i32 [ %5, %4 ], [ %17, %16 ]
  %27 = and i32 %26, 2
  %28 = sub nsw i32 1, %27
  br label %29

29:                                               ; preds = %10, %4, %25
  %30 = phi i32 [ %28, %25 ], [ %0, %4 ], [ 0, %10 ]
  ret i32 %30
}

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
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.unroll.disable"}
!8 = distinct !{!8, !7}
!9 = distinct !{!9, !7}
