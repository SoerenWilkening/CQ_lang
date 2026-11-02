; M2 (cq-pf4n, CR rules 18, 21; 191): clone stores through a QRAM triple formal beyond 191's shape, each probe a
; separate entry: m2v1 a store under a quantum predicate (a _controlled deferred store, its flag copied out and
; popped by the caller with it); cqcheck user (21 samples): PASS.
; CHECK __cq_q_put_001_b4: call void @cqrt_qram_store_i32_hl_controlled(
; CHECK m2v1: call void @cqrt_qram_store_i32_hl_controlled_unc(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.m2v1.a = private unnamed_addr constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @m2v1(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, ptr noundef nonnull align 16 dereferenceable(16) @__const.m2v1.a, i64 16, i1 false)
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6
  %6 = and i32 %5, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %7
  store i32 7, ptr %8, align 4, !tbaa !6
  %9 = and i32 %5, 4
  call fastcc void @put(ptr noundef nonnull %4, i32 noundef %9)
  %10 = getelementptr inbounds i8, ptr %4, i64 4
  %11 = load i32, ptr %10, align 4, !tbaa !6
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #5
  %13 = getelementptr inbounds i8, ptr %4, i64 8
  %14 = load i32, ptr %13, align 8, !tbaa !6
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #5
  %16 = shl nsw i32 %15, 4
  %17 = add nsw i32 %16, %12
  %18 = load i32, ptr %8, align 4, !tbaa !6
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #5
  %20 = shl nsw i32 %19, 8
  %21 = add nsw i32 %17, %20
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5
  ret i32 %21
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #2

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc void @put(ptr nocapture noundef writeonly %0, i32 noundef %1) unnamed_addr #4 {
  %3 = icmp eq i32 %1, 0
  br i1 %3, label %6, label %4

4:                                                ; preds = %2
  %5 = getelementptr inbounds i8, ptr %0, i64 12
  store i32 9, ptr %5, align 4, !tbaa !6
  br label %6

6:                                                ; preds = %4, %2
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
