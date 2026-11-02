; ModuleID = 'c3two.c'
source_filename = "c3two.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @t_or(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %1) #3
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %1) #3
  %5 = tail call i32 @llvm.smax.i32(i32 %0, i32 0)
  %6 = add i32 %4, -1
  %7 = tail call i32 @llvm.umin.i32(i32 %3, i32 %6)
  br label %8

8:                                                ; preds = %12, %2
  %9 = phi i32 [ 0, %2 ], [ %13, %12 ]
  %10 = phi i32 [ 0, %2 ], [ %14, %12 ]
  %11 = icmp eq i32 %10, %5
  br i1 %11, label %16, label %12

12:                                               ; preds = %8
  %13 = add nsw i32 %9, %3
  %14 = add nuw i32 %10, 1
  %15 = icmp eq i32 %10, %7
  br i1 %15, label %16, label %8, !llvm.loop !6

16:                                               ; preds = %12, %8
  %17 = phi i32 [ %9, %8 ], [ %13, %12 ]
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #4
  ret i32 %18
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @t_bool(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %1) #3
  %4 = fmul double %1, 5.000000e-01
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %4) #3
  %6 = icmp sgt i32 %0, 0
  br i1 %6, label %7, label %18

7:                                                ; preds = %2
  %8 = xor i1 %5, true
  %9 = or i1 %3, %8
  %10 = shl nuw i32 %0, 1
  br label %14

11:                                               ; preds = %14
  %12 = add nuw nsw i32 %15, 1
  %13 = icmp eq i32 %12, %0
  br i1 %13, label %18, label %14, !llvm.loop !9

14:                                               ; preds = %7, %11
  %15 = phi i32 [ 0, %7 ], [ %12, %11 ]
  %16 = phi i32 [ 0, %7 ], [ %17, %11 ]
  %17 = add nuw nsw i32 %16, 2
  br i1 %9, label %18, label %11

18:                                               ; preds = %11, %14, %2
  %19 = phi i32 [ 0, %2 ], [ %17, %14 ], [ %10, %11 ]
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #4
  ret i32 %20
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @t_do(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %1) #3
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef %1) #3
  br label %5

5:                                                ; preds = %5, %2
  %6 = phi i32 [ 0, %2 ], [ %9, %5 ]
  %7 = phi i32 [ 0, %2 ], [ %10, %5 ]
  %8 = xor i32 %7, %3
  %9 = add nsw i32 %8, %6
  %10 = add nuw nsw i32 %7, 1
  %11 = icmp sge i32 %10, %0
  %12 = icmp eq i32 %3, %10
  %13 = select i1 %11, i1 true, i1 %12
  %14 = shl nuw nsw i32 %10, 1
  %15 = icmp eq i32 %4, %14
  %16 = select i1 %13, i1 true, i1 %15
  br i1 %16, label %17, label %5, !llvm.loop !10

17:                                               ; preds = %5
  %18 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  ret i32 %18
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
