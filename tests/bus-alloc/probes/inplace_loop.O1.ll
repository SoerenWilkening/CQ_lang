; ModuleID = 'tests/bus-alloc/probes/inplace_loop.c'
source_filename = "tests/bus-alloc/probes/inplace_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = global [8 x i32] zeroinitializer, align 16

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define void @put(ptr nocapture noundef writeonly %0, i32 noundef %1) local_unnamed_addr #0 {
  store i32 %1, ptr %0, align 4, !tbaa !6
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @ip_loop_theta_out(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #1 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #4
  tail call void @put(ptr noundef nonnull @g, i32 noundef %5)
  %6 = load i32, ptr @g, align 16, !tbaa !6
  %7 = and i32 %1, 3
  %8 = tail call i32 @llvm.umax.i32(i32 %7, i32 1)
  br label %9

9:                                                ; preds = %9, %4
  %10 = phi i32 [ 0, %4 ], [ %12, %9 ]
  %11 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef %3) #4
  %12 = add nuw nsw i32 %10, 1
  %13 = icmp eq i32 %12, %8
  br i1 %13, label %14, label %9, !llvm.loop !10

14:                                               ; preds = %9
  store i32 %11, ptr @g, align 16, !tbaa !6
  %15 = tail call i32 @cq_measure_si32(i32 noundef %11) #5
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umax.i32(i32, i32) #3

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

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
