; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0, i32 %1) local_unnamed_addr #0 {
  %3 = and i32 %0, 7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #5
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 3.000000e-01) #5
  %6 = mul nsw i32 %4, 3
  %7 = xor i32 %6, %4
  %8 = icmp eq i32 %7, 10
  br i1 %8, label %10, label %9

9:                                                ; preds = %10, %2
  br label %19

10:                                               ; preds = %2
  tail call void @cq_phi(double noundef 3.141590e+00) #5
  br label %9

11:                                               ; preds = %26
  %12 = tail call i32 @h(i32 noundef %0, i32 noundef %6) #5
  %13 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 9.000000e-01) #5
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #5
  %15 = tail call i32 @cq_measure_si32(i32 noundef %27) #5
  %16 = add nsw i32 %15, %14
  %17 = tail call i32 @cq_measure_si32(i32 noundef %12) #5
  %18 = add nsw i32 %16, %17
  ret i32 %18

19:                                               ; preds = %26, %9
  %20 = phi i32 [ %28, %26 ], [ 0, %9 ]
  %21 = phi i32 [ %27, %26 ], [ %5, %9 ]
  %22 = shl nuw nsw i32 1, %20
  %23 = and i32 %22, %6
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %26, label %25

25:                                               ; preds = %19
  tail call void @cq_phi(double noundef 2.000000e-01) #5
  br label %26

26:                                               ; preds = %25, %19
  %27 = tail call i32 @cq_theta_si32(i32 noundef %21, double noundef 1.000000e-01) #5
  %28 = add nuw nsw i32 %20, 1
  %29 = icmp eq i32 %28, 3
  br i1 %29, label %11, label %19, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !9
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @slice(i32 noundef %5, i32 poison)
  %7 = and i32 %6, 1
  ret i32 %7
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = !{!10, !10, i64 0}
!10 = !{!"any pointer", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
