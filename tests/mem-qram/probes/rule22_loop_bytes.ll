; Rule 22 (cq-k65d): a run-time-length memset starting inside a cell whose end may cut a cell: byte pieces, each
; under its own guard (the byte-masked merge: the cell read, merged, stored). cqcheck user (32 samples): PASS.
; CHECK lp_bytes: call i32 @cqrt_qram_load_i32_hl(
; CHECK lp_bytes: call void @cqrt_qram_store_i32_hl_controlled(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #0

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #0

; Function Attrs: nounwind ssp uwtable
define i32 @lp_bytes(i32 noundef %0, double noundef %1, i64 noundef %2, i32 noundef %3) local_unnamed_addr #2 {
  %5 = alloca [6 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %5) #4
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %7 = urem i32 %6, 6
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [6 x i32], ptr %5, i64 0, i64 %8
  store i32 16909060, ptr %9, align 4, !tbaa !6
  %10 = urem i64 %2, 17
  %11 = getelementptr inbounds i8, ptr %5, i64 3
  %12 = trunc i32 %3 to i8
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %11, i8 %12, i64 %10, i1 false)
  %13 = load i32, ptr %9, align 4, !tbaa !6
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  %15 = getelementptr inbounds i8, ptr %5, i64 8
  %16 = load i32, ptr %15, align 8, !tbaa !6
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #4
  %18 = add nsw i32 %17, %14
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %5) #4
  ret i32 %18
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: write) }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
