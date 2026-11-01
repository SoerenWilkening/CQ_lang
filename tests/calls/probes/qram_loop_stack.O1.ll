; ModuleID = 'qram_loop_stack.c'
source_filename = "qram_loop_stack.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @t8(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #4
  br label %16

6:                                                ; preds = %16
  %7 = and i32 %5, 3
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %8
  store i32 %2, ptr %9, align 4, !tbaa !6
  %10 = add i32 %5, 1
  %11 = and i32 %10, 3
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %12
  %14 = load i32, ptr %13, align 4, !tbaa !6
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #4
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #4
  ret i32 %15

16:                                               ; preds = %3, %16
  %17 = phi i64 [ 0, %3 ], [ %22, %16 ]
  %18 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %17
  %19 = trunc i64 %17 to i32
  %20 = mul i32 %19, 7
  %21 = add i32 %20, 1
  store i32 %21, ptr %18, align 4, !tbaa !6
  %22 = add nuw nsw i64 %17, 1
  %23 = icmp eq i64 %22, 4
  br i1 %23, label %6, label %16, !llvm.loop !10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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
