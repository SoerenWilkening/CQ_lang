; ModuleID = 'split_cells_intrinsic.c'
source_filename = "split_cells_intrinsic.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @split_cells_intrinsic(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4)
  store i32 151587081, ptr %4, align 4
  %6 = and i32 %5, 3
  %7 = zext nneg i32 %6 to i64
  call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 4 %4, ptr align 1 %2, i64 %7, i1 false)
  %8 = lshr i32 %5, 2
  %9 = and i32 %8, 3
  %10 = zext nneg i32 %9 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 4 %4, i8 0, i64 %10, i1 false)
  %11 = load i8, ptr %4, align 4, !tbaa !6
  %12 = zext i8 %11 to i32
  %13 = getelementptr inbounds i8, ptr %4, i64 3
  %14 = load i8, ptr %13, align 1, !tbaa !6
  %15 = zext i8 %14 to i32
  %16 = add nuw nsw i32 %15, %12
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4)
  ret i32 %17
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
; CHECK-COUNT split_cells_intrinsic: = call i32 @cqrt_alloc_i8(i8 9) 4
; CHECK split_cells_intrinsic: call void @cqrt_free(i32 %6)
; CHECK split_cells_intrinsic: call void @cqrt_free(i32 %7)
; CHECK split_cells_intrinsic: call void @cqrt_free(i32 %9)
; CHECK split_cells_intrinsic: call void @cqrt_free(i32 %11)
; CHECK-COUNT split_cells_intrinsic: call void @cqrt_free( 24
