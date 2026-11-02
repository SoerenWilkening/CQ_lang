; M2 (cq-pf4n): a store at a constant offset from a quantum idx (the clone copies its computed index rail out; the
; caller pops the idx form at it); cqcheck user (24 samples): PASS.
; CHECK __cq_q_put3_01: call void @cqrt_qram_store_i32(i32 %{{b}}, i32 %{{i}}, i32 %{{v}})
; CHECK m2v3: call void @cqrt_qram_store_i32_unc(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.m2v3.a = private unnamed_addr constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @m2v3(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, ptr noundef nonnull align 16 dereferenceable(16) @__const.m2v3.a, i64 16, i1 false)
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6
  %6 = and i32 %5, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %7
  store i32 7, ptr %8, align 4, !tbaa !6
  %9 = and i32 %5, 1
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds i32, ptr %4, i64 %10
  call fastcc void @put3(ptr noundef nonnull %11)
  %12 = getelementptr inbounds i8, ptr %4, i64 4
  %13 = load i32, ptr %12, align 4, !tbaa !6
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #5
  %15 = getelementptr inbounds i8, ptr %4, i64 8
  %16 = load i32, ptr %15, align 8, !tbaa !6
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #5
  %18 = shl nsw i32 %17, 4
  %19 = add nsw i32 %18, %14
  %20 = load i32, ptr %8, align 4, !tbaa !6
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #5
  %22 = shl nsw i32 %21, 8
  %23 = add nsw i32 %19, %22
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5
  ret i32 %23
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #2

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc void @put3(ptr nocapture noundef writeonly %0) unnamed_addr #4 {
  %2 = getelementptr inbounds i8, ptr %0, i64 4
  store i32 6, ptr %2, align 4, !tbaa !6
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }
attributes #6 = { nomerge nounwind }

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
