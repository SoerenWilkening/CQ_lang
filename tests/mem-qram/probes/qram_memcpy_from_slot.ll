; 73: memcpy into a QRAM from a slot array filled in a classically bounded loop: one fixed-index _hl store per cell of the
; handle the slot cell holds (read at run time), popped LIFO.
; CHECK-COUNT memcpy_slot_src: call void @cqrt_qram_store_i32_hl( 4
; CHECK-COUNT memcpy_slot_src: call void @cqrt_qram_store_i32_hl_unc( 4
source_filename = "mcs.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @memcpy_slot_src(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5) local_unnamed_addr #0 {
  %7 = alloca [4 x i32], align 16
  %8 = alloca [4 x i32], align 16
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4
  %10 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %3) #4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %7) #5
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %8) #5
  br label %21

11:                                               ; preds = %21
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %8, ptr noundef nonnull align 16 dereferenceable(16) %7, i64 16, i1 false)
  %12 = and i32 %10, 3
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds [4 x i32], ptr %8, i64 0, i64 %13
  store i32 %4, ptr %14, align 4, !tbaa !6
  %15 = getelementptr inbounds i8, ptr %7, i64 4
  %16 = load i32, ptr %15, align 4, !tbaa !6
  %17 = getelementptr inbounds i8, ptr %8, i64 4
  %18 = load i32, ptr %17, align 4, !tbaa !6
  %19 = add nsw i32 %18, %16
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %8) #5
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %7) #5
  ret i32 %20

21:                                               ; preds = %6, %21
  %22 = phi i64 [ 0, %6 ], [ %26, %21 ]
  %23 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %22
  %24 = trunc i64 %22 to i32
  %25 = add i32 %9, %24
  store i32 %25, ptr %23, align 4, !tbaa !6
  %26 = add nuw nsw i64 %22, 1
  %27 = icmp eq i64 %26, 4
  br i1 %27, label %11, label %21, !llvm.loop !10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
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
