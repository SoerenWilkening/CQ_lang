; M2b (cq-pf4n, CR rules 18, 21; 191): loads through a triple formal after stores through the same formal, which the
; clone defers to its end, read them forwarded: select(idx == idx_j && flag_j, v_j, cell) per earlier store (a store
; at a constant offset from a quantum idx copies its index rail out; one under a quantum predicate is _controlled).
; cqcheck user (31 samples): PASS.
; CHECK __cq_q_ls_01110_b6_8: call i32 @cq_template_icmp_eq_i32(
; CHECK __cq_q_ls_01110_b6_8: call void @cqrt_qram_store_i32_controlled(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.las.a = private unnamed_addr constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @las(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #5
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, ptr noundef nonnull align 16 dereferenceable(16) @__const.las.a, i64 16, i1 false)
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6
  %6 = and i32 %5, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %7
  store i32 7, ptr %8, align 4, !tbaa !6
  %9 = and i32 %5, 1
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds i32, ptr %4, i64 %10
  %12 = and i32 %5, 6
  %13 = and i32 %5, 8
  %14 = call fastcc i32 @ls(ptr noundef nonnull %11, i32 noundef %12, i32 noundef %13, i32 noundef %2)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #5
  %16 = getelementptr inbounds i8, ptr %4, i64 4
  %17 = load i32, ptr %16, align 4, !tbaa !6
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #5
  %19 = mul nsw i32 %18, 1000
  %20 = add nsw i32 %19, %15
  %21 = load i32, ptr %8, align 4, !tbaa !6
  %22 = tail call i32 @cq_measure_si32(i32 noundef %21) #5
  %23 = mul nsw i32 %22, 100000
  %24 = add nsw i32 %20, %23
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #5
  ret i32 %24
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #2

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc i32 @ls(ptr nocapture noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) unnamed_addr #4 {
  %5 = getelementptr inbounds i8, ptr %0, i64 4
  store i32 %1, ptr %5, align 4, !tbaa !6
  %6 = icmp eq i32 %2, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %4
  %8 = add nuw nsw i32 %1, 1
  store i32 %8, ptr %0, align 4, !tbaa !6
  br label %9

9:                                                ; preds = %7, %4
  %10 = and i32 %3, 1
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds i32, ptr %0, i64 %11
  %13 = load i32, ptr %12, align 4, !tbaa !6
  %14 = lshr i32 %3, 1
  %15 = and i32 %14, 1
  %16 = zext nneg i32 %15 to i64
  %17 = getelementptr inbounds i32, ptr %0, i64 %16
  %18 = load i32, ptr %17, align 4, !tbaa !6
  %19 = mul nsw i32 %18, 10
  %20 = add nsw i32 %19, %13
  ret i32 %20
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
