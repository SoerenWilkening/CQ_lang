; ModuleID = 'deferred.c'
source_filename = "deferred.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f_arm(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %4, 4
  %6 = icmp ne i32 %5, 0
  %7 = icmp sgt i32 %2, 0
  %8 = and i1 %6, %7
  br i1 %8, label %9, label %17

9:                                                ; preds = %3, %9
  %10 = phi i32 [ %15, %9 ], [ 0, %3 ]
  %11 = phi i32 [ %14, %9 ], [ 0, %3 ]
  %12 = mul nsw i32 %11, 3
  %13 = xor i32 %10, %4
  %14 = add nsw i32 %13, %12
  %15 = add nuw nsw i32 %10, 1
  %16 = icmp eq i32 %15, %2
  br i1 %16, label %17, label %9, !llvm.loop !6

17:                                               ; preds = %9, %3
  %18 = phi i32 [ 0, %3 ], [ %14, %9 ]
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #4
  ret i32 %19
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f_arm_brk(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %6 = and i32 %5, 4
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %19, label %8

8:                                                ; preds = %4
  %9 = icmp sgt i32 %3, 0
  br i1 %9, label %10, label %21

10:                                               ; preds = %8, %10
  %11 = phi i32 [ %16, %10 ], [ 0, %8 ]
  %12 = phi i32 [ %14, %10 ], [ 0, %8 ]
  %13 = xor i32 %11, %5
  %14 = add nsw i32 %13, %12
  %15 = icmp sgt i32 %14, %2
  %16 = add nuw nsw i32 %11, 1
  %17 = icmp eq i32 %16, %3
  %18 = select i1 %15, i1 true, i1 %17
  br i1 %18, label %21, label %10, !llvm.loop !9

19:                                               ; preds = %4
  %20 = mul nsw i32 %5, 5
  br label %21

21:                                               ; preds = %10, %8, %19
  %22 = phi i32 [ %20, %19 ], [ 0, %8 ], [ %14, %10 ]
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #4
  ret i32 %23
}

; Function Attrs: nounwind ssp uwtable
define i32 @f_arm_phase(i32 noundef %0, double noundef %1, double noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %6 = and i32 %5, 4
  %7 = icmp ne i32 %6, 0
  %8 = icmp sgt i32 %3, 0
  %9 = and i1 %7, %8
  br i1 %9, label %10, label %21

10:                                               ; preds = %4, %18
  %11 = phi i32 [ %19, %18 ], [ 0, %4 ]
  %12 = phi i32 [ %14, %18 ], [ 0, %4 ]
  %13 = xor i32 %11, %5
  %14 = add nsw i32 %13, %12
  %15 = and i32 %14, 1
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %18, label %17

17:                                               ; preds = %10
  tail call void @cq_phi(double noundef %2) #4
  br label %18

18:                                               ; preds = %10, %17
  %19 = add nuw nsw i32 %11, 1
  %20 = icmp eq i32 %19, %3
  br i1 %20, label %21, label %10, !llvm.loop !10

21:                                               ; preds = %18, %4
  %22 = phi i32 [ 0, %4 ], [ %14, %18 ]
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #4
  ret i32 %23
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @f_oracle(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %6 = icmp sgt i32 %3, 0
  br i1 %6, label %13, label %7

7:                                                ; preds = %13, %4
  %8 = phi i32 [ 0, %4 ], [ %19, %13 ]
  %9 = and i32 %8, %2
  %10 = tail call range(i32 0, 33) i32 @llvm.ctpop.i32(i32 %9)
  %11 = and i32 %10, 1
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %23, label %22

13:                                               ; preds = %4, %13
  %14 = phi i32 [ %20, %13 ], [ 0, %4 ]
  %15 = phi i32 [ %19, %13 ], [ 0, %4 ]
  %16 = lshr i32 %5, %14
  %17 = and i32 %16, 1
  %18 = shl nuw i32 %17, %14
  %19 = or i32 %18, %15
  %20 = add nuw nsw i32 %14, 1
  %21 = icmp eq i32 %20, %3
  br i1 %21, label %7, label %13, !llvm.loop !11

22:                                               ; preds = %7
  tail call void @cq_phi(double noundef 3.141590e+00) #4
  br label %23

23:                                               ; preds = %22, %7
  %24 = fneg double %1
  %25 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %24) #3
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #4
  ret i32 %26
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctpop.i32(i32) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

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
!10 = distinct !{!10, !7, !8}
!11 = distinct !{!11, !7, !8}
