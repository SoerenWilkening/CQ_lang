; ModuleID = 'noexit.c'
source_filename = "noexit.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @na_mixed(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  br label %4

4:                                                ; preds = %11, %2
  %5 = phi i32 [ 0, %2 ], [ %14, %11 ]
  %6 = phi i32 [ 1, %2 ], [ %13, %11 ]
  %7 = ashr i32 %3, %5
  %8 = and i32 %7, 3
  %9 = icmp eq i32 %8, 2
  br i1 %9, label %10, label %11

10:                                               ; preds = %4
  tail call void @abort() #6
  unreachable

11:                                               ; preds = %4
  %12 = mul nsw i32 %6, 3
  %13 = add nsw i32 %12, 1
  %14 = add nuw nsw i32 %5, 1
  %15 = shl i32 2, %5
  %16 = and i32 %15, %3
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %18, label %4, !llvm.loop !6

18:                                               ; preds = %11
  %19 = tail call i32 @cq_measure_si32(i32 noundef %13) #7
  ret i32 %19
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @na_exit(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %20, label %6

6:                                                ; preds = %2, %13
  %7 = phi i32 [ %15, %13 ], [ 0, %2 ]
  %8 = phi i32 [ %16, %13 ], [ 0, %2 ]
  %9 = shl i32 256, %8
  %10 = and i32 %9, %3
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %13, label %12

12:                                               ; preds = %6
  tail call void @cq_phi(double noundef 2.500000e-01) #7
  tail call void @exit(i32 noundef 3) #8
  unreachable

13:                                               ; preds = %6
  %14 = add nuw nsw i32 %8, 2
  %15 = add nuw nsw i32 %14, %7
  %16 = add nuw nsw i32 %8, 1
  %17 = shl nuw i32 2, %8
  %18 = and i32 %17, %3
  %19 = icmp eq i32 %18, 0
  br i1 %19, label %20, label %6, !llvm.loop !9

20:                                               ; preds = %13, %2
  %21 = phi i32 [ 0, %2 ], [ %15, %13 ]
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #7
  ret i32 %22
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: noreturn
declare void @exit(i32 noundef) local_unnamed_addr #3

; Function Attrs: noreturn nounwind ssp uwtable
define void @na_only(i32 noundef %0, double noundef %1) local_unnamed_addr #4 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %4 = or i32 %3, 128
  br label %5

5:                                                ; preds = %5, %2
  %6 = phi i32 [ 0, %2 ], [ %11, %5 ]
  tail call void @cq_phi(double noundef 1.250000e-01) #7
  %7 = and i32 %6, 7
  %8 = shl nuw nsw i32 1, %7
  %9 = and i32 %8, %4
  %10 = icmp eq i32 %9, 0
  %11 = add nuw nsw i32 %6, 1
  br i1 %10, label %5, label %12, !llvm.loop !10

12:                                               ; preds = %5
  tail call void @abort() #6
  unreachable
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { cold noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noreturn nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { cold noreturn nounwind }
attributes #7 = { nounwind }
attributes #8 = { noreturn nounwind }

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
