; ModuleID = 'fatal_qram_barrier.c'
source_filename = "fatal_qram_barrier.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p29(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  br label %12

6:                                                ; preds = %12
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %5, double noundef %2) #4
  %8 = load i32, ptr %4, align 16, !tbaa !6
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #5
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %7) #5
  %11 = add i32 %10, %9
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5
  ret i32 %11

12:                                               ; preds = %3, %12
  %13 = phi i32 [ 0, %3 ], [ %21, %12 ]
  %14 = shl nuw nsw i32 %13, 1
  %15 = lshr i32 %5, %14
  %16 = and i32 %15, 3
  %17 = zext nneg i32 %16 to i64
  %18 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %17
  %19 = load i32, ptr %18, align 4, !tbaa !6
  %20 = add nsw i32 %19, 1
  store i32 %20, ptr %18, align 4, !tbaa !6
  %21 = add nuw nsw i32 %13, 1
  %22 = icmp eq i32 %21, 4
  br i1 %22, label %6, label %12, !llvm.loop !10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
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
