; ModuleID = 'l2b.c'
source_filename = "l2b.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = and i32 %0, 7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #4
  %5 = mul nsw i32 %4, 3
  %6 = xor i32 %5, %4
  %7 = icmp eq i32 %6, 10
  br i1 %7, label %8, label %9

8:                                                ; preds = %2
  tail call void @cq_phi(double noundef 3.141590e+00) #4
  br label %9

9:                                                ; preds = %8, %2
  %10 = icmp sgt i32 %1, 0
  br i1 %10, label %17, label %11

11:                                               ; preds = %23, %9
  %12 = tail call i32 @h(i32 noundef %0, i32 noundef %5) #4
  %13 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 0x3FE6666666666666) #4
  %14 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  %15 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  %16 = add nsw i32 %15, %14
  ret i32 %16

17:                                               ; preds = %9, %23
  %18 = phi i32 [ %24, %23 ], [ 0, %9 ]
  %19 = shl nuw i32 1, %18
  %20 = and i32 %19, %5
  %21 = icmp eq i32 %20, 0
  br i1 %21, label %23, label %22

22:                                               ; preds = %17
  tail call void @cq_phi(double noundef 2.000000e-01) #4
  br label %23

23:                                               ; preds = %17, %22
  %24 = add nuw nsw i32 %18, 1
  %25 = icmp eq i32 %24, %1
  br i1 %25, label %11, label %17, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @h(i32 noundef, i32 noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !9
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8, !tbaa !9
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call i32 @slice(i32 noundef %5, i32 noundef %8)
  %10 = and i32 %9, 1
  ret i32 %10
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!9 = !{!10, !10, i64 0}
!10 = !{!"any pointer", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
