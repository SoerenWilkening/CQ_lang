; ModuleID = 'tests/calls/probes/meas_table_t_paths.c'
source_filename = "tests/calls/probes/meas_table_t_paths.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @sumin(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = and i32 %1, 3
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %8

5:                                                ; preds = %8, %2
  %6 = phi i32 [ 0, %2 ], [ %13, %8 ]
  %7 = add nsw i32 %6, %0
  ret i32 %7

8:                                                ; preds = %2, %8
  %9 = phi i32 [ %14, %8 ], [ 0, %2 ]
  %10 = phi i32 [ %13, %8 ], [ 0, %2 ]
  %11 = add nsw i32 %9, %0
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  %13 = add nsw i32 %12, %10
  %14 = add nuw nsw i32 %9, 1
  %15 = icmp eq i32 %14, %3
  br i1 %15, label %5, label %8, !llvm.loop !6
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @id(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = add nsw i32 %1, %0
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #3 {
  %4 = icmp eq i32 %1, 0
  %5 = select i1 %4, ptr @id, ptr @sumin
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %7 = add nsw i32 %6, 1
  %8 = tail call i32 %5(i32 noundef %7, i32 noundef %2) #4, !callees !9
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  %10 = add nsw i32 %9, %8
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define i32 @some(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = and i32 %1, 1
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %8, label %5

5:                                                ; preds = %2
  %6 = tail call i32 @cq_measure_si32(i32 noundef %0) #4
  %7 = add nsw i32 %6, %0
  br label %10

8:                                                ; preds = %2
  %9 = add nsw i32 %0, 2
  br label %10

10:                                               ; preds = %8, %5
  %11 = phi i32 [ %7, %5 ], [ %9, %8 ]
  ret i32 %11
}

; Function Attrs: nounwind ssp uwtable
define i32 @g(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #3 {
  %4 = icmp eq i32 %1, 0
  %5 = select i1 %4, ptr @id, ptr @some
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #5
  %7 = add nsw i32 %6, 1
  %8 = tail call i32 %5(i32 noundef %7, i32 noundef %2) #4, !callees !10
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) #4
  %10 = add nsw i32 %9, %8
  ret i32 %10
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

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
!9 = !{ptr @id, ptr @sumin}
!10 = !{ptr @id, ptr @some}
