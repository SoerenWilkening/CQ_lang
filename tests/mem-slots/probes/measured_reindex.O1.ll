; ModuleID = 'tests/mem-slots/probes/measured_reindex.c'
source_filename = "tests/mem-slots/probes/measured_reindex.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @measured_reindex(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [4 x i32], align 16
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %2) #4
  %4 = add nsw i32 %3, 7
  store i32 %4, ptr %2, align 16, !tbaa !6
  br label %6

5:                                                ; preds = %6
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %2) #4
  ret i32 %13

6:                                                ; preds = %1, %6
  %7 = phi i64 [ 1, %1 ], [ %16, %6 ]
  %8 = phi i32 [ 0, %1 ], [ %13, %6 ]
  %9 = getelementptr inbounds [4 x i32], ptr %2, i64 0, i64 %7
  %10 = getelementptr inbounds i8, ptr %9, i64 -4
  %11 = load i32, ptr %10, align 4, !tbaa !6
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  %13 = add nsw i32 %12, %8
  %14 = trunc i64 %7 to i32
  %15 = add i32 %3, %14
  store i32 %15, ptr %9, align 4, !tbaa !6
  %16 = add nuw nsw i64 %7, 1
  %17 = icmp eq i64 %16, 4
  br i1 %17, label %5, label %6, !llvm.loop !10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
; CHECK-COUNT measured_reindex: cq_template_add_i32_hl_unc( 0
; CHECK-COUNT measured_reindex: cqrt_measure_i32( 1
