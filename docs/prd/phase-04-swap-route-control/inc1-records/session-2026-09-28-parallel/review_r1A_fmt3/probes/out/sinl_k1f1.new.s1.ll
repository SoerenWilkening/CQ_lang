; ModuleID = 'src/sinl_k1f1.c'
source_filename = "src/sinl_k1f1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !6
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #3
  %10 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 0x3FE6666666666666) #3
  %11 = add nsw i32 %8, 1
  %12 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 4.000000e-01) #3
  %13 = icmp sgt i32 %9, 1
  br i1 %13, label %14, label %16

14:                                               ; preds = %2
  %15 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 2.000000e-01) #3
  br label %18

16:                                               ; preds = %2
  %17 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 6.000000e-01) #3
  br label %18

18:                                               ; preds = %14, %16
  %19 = phi i32 [ %15, %14 ], [ %17, %16 ]
  %20 = tail call i32 @cq_theta_si32(i32 noundef %19, double noundef 1.000000e-02) #3
  br i1 %13, label %21, label %23

21:                                               ; preds = %18
  %22 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 2.000000e-01) #3
  br label %25

23:                                               ; preds = %18
  %24 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 6.000000e-01) #3
  br label %25

25:                                               ; preds = %21, %23
  %26 = phi i32 [ %22, %21 ], [ %24, %23 ]
  %27 = tail call i32 @cq_theta_si32(i32 noundef %26, double noundef 1.000000e-02) #3
  %28 = tail call i32 @cq_measure_si32(i32 noundef %20) #4
  %29 = tail call i32 @cq_measure_si32(i32 noundef %27) #4
  %30 = add nsw i32 %29, %28
  %31 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  %32 = add nsw i32 %30, %31
  ret i32 %32
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
