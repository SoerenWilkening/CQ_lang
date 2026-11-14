; ModuleID = 'table_k.c'
source_filename = "table_k.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@pf = global ptr @kf, align 8
@pm = global ptr @km, align 8
@pn = global ptr @kn, align 8
@pd = global ptr @kd, align 8
@pc = global ptr @kc, align 8
@pr = global ptr @kr, align 8
@ps = global ptr @ks, align 8
@__cq_k_tk_f = internal constant i32 2, align 4
@__cq_k_tk_m = internal constant i32 2, align 4
@__cq_k_tk_n = internal constant i32 2, align 4
@__cq_k_tk_d = internal constant i32 2, align 4
@__cq_k_tk_c = internal constant i32 2, align 4
@__cq_k_tk_r = internal constant i32 2, align 4
@__cq_k_tk_s = internal constant i32 2, align 4
@__cq_k_tk_cls = internal constant i32 2, align 4
@__cq_k_kf = internal constant i32 2, align 4
@__cq_k_km = internal constant i32 2, align 4
@__cq_k_kn = internal constant i32 2, align 4
@__cq_k_kd = internal constant i32 2, align 4
@__cq_k_kc = internal constant i32 2, align 4
@__cq_k_kr = internal constant i32 2, align 4
@__cq_k_ks = internal constant i32 2, align 4
@llvm.used = appending global [15 x ptr] [ptr @__cq_k_kc, ptr @__cq_k_kd, ptr @__cq_k_kf, ptr @__cq_k_km, ptr @__cq_k_kn, ptr @__cq_k_kr, ptr @__cq_k_ks, ptr @__cq_k_tk_c, ptr @__cq_k_tk_cls, ptr @__cq_k_tk_d, ptr @__cq_k_tk_f, ptr @__cq_k_tk_m, ptr @__cq_k_tk_n, ptr @__cq_k_tk_r, ptr @__cq_k_tk_s], section "llvm.metadata"

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @kf(i32 noundef %0, i32 noundef %1) #0 {
  %3 = icmp ugt i32 %0, 9
  br i1 %3, label %4, label %11

4:                                                ; preds = %2, %4
  %5 = phi i32 [ %9, %4 ], [ 0, %2 ]
  %6 = phi i32 [ %8, %4 ], [ %0, %2 ]
  %7 = mul i32 %6, %1
  %8 = add i32 %7, 1
  %9 = add i32 %5, 1
  %10 = icmp ugt i32 %8, 9
  br i1 %10, label %4, label %11, !llvm.loop !6

11:                                               ; preds = %4, %2
  %12 = phi i32 [ 0, %2 ], [ %9, %4 ]
  ret i32 %12
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @km(i32 noundef %0, i32 noundef %1) #0 {
  %3 = icmp ult i32 %0, 9
  br i1 %3, label %16, label %4

4:                                                ; preds = %2, %13
  %5 = phi i32 [ %14, %13 ], [ 0, %2 ]
  %6 = phi i32 [ %8, %13 ], [ %0, %2 ]
  %7 = mul i32 %6, %1
  %8 = add i32 %7, 1
  %9 = and i32 %8, 7
  %10 = icmp eq i32 %9, 3
  br i1 %10, label %11, label %13

11:                                               ; preds = %4
  %12 = add i32 %5, 100
  br label %16

13:                                               ; preds = %4
  %14 = add i32 %5, 1
  %15 = icmp ult i32 %8, 9
  br i1 %15, label %16, label %4, !llvm.loop !9

16:                                               ; preds = %13, %2, %11
  %17 = phi i32 [ %12, %11 ], [ 0, %2 ], [ %14, %13 ]
  ret i32 %17
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @kn(i32 noundef %0, i32 noundef %1) #0 {
  %3 = icmp ugt i32 %0, 9
  br i1 %3, label %4, label %21

4:                                                ; preds = %2, %16
  %5 = phi i32 [ %17, %16 ], [ 0, %2 ]
  %6 = phi i32 [ %19, %16 ], [ %0, %2 ]
  %7 = and i32 %6, 1
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %16, label %9

9:                                                ; preds = %4, %9
  %10 = phi i32 [ %12, %9 ], [ %6, %4 ]
  %11 = phi i32 [ %13, %9 ], [ %5, %4 ]
  %12 = lshr i32 %10, 1
  %13 = add i32 %11, 1
  %14 = and i32 %10, 2
  %15 = icmp eq i32 %14, 0
  br i1 %15, label %16, label %9, !llvm.loop !10

16:                                               ; preds = %9, %4
  %17 = phi i32 [ %5, %4 ], [ %13, %9 ]
  %18 = mul i32 %6, %1
  %19 = add i32 %18, 1
  %20 = icmp ugt i32 %19, 9
  br i1 %20, label %4, label %21, !llvm.loop !11

21:                                               ; preds = %16, %2
  %22 = phi i32 [ %0, %2 ], [ %19, %16 ]
  %23 = phi i32 [ 0, %2 ], [ %17, %16 ]
  %24 = add i32 %23, %22
  ret i32 %24
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @kd(i32 noundef %0, i32 noundef %1) #0 {
  br label %3

3:                                                ; preds = %3, %2
  %4 = phi i32 [ %0, %2 ], [ %7, %3 ]
  %5 = phi i32 [ 0, %2 ], [ %8, %3 ]
  %6 = mul i32 %4, %1
  %7 = add i32 %6, 1
  %8 = add i32 %5, 2
  %9 = icmp ugt i32 %7, 9
  br i1 %9, label %3, label %10, !llvm.loop !12

10:                                               ; preds = %3
  ret i32 %8
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @kc(i32 noundef %0, i32 noundef %1) #0 {
  %3 = icmp ugt i32 %0, 3
  br i1 %3, label %4, label %15

4:                                                ; preds = %2, %4
  %5 = phi i32 [ %11, %4 ], [ 0, %2 ]
  %6 = phi i32 [ %7, %4 ], [ %0, %2 ]
  %7 = add i32 %6, -1
  %8 = and i32 %7, 1
  %9 = icmp eq i32 %8, 0
  %10 = select i1 %9, i32 %1, i32 0
  %11 = add i32 %10, %5
  %12 = icmp ugt i32 %7, 3
  br i1 %12, label %4, label %13, !llvm.loop !13

13:                                               ; preds = %4
  %14 = shl i32 %11, 4
  br label %15

15:                                               ; preds = %13, %2
  %16 = phi i32 [ %0, %2 ], [ 3, %13 ]
  %17 = phi i32 [ 0, %2 ], [ %14, %13 ]
  %18 = or disjoint i32 %17, %16
  ret i32 %18
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @kr(i32 noundef %0, i32 noundef %1) #0 {
  %3 = icmp eq i32 %0, %1
  br i1 %3, label %4, label %6

4:                                                ; preds = %6, %2
  %5 = phi i32 [ 0, %2 ], [ %10, %6 ]
  ret i32 %5

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %9, %6 ], [ %0, %2 ]
  %9 = lshr i32 %8, 1
  %10 = add i32 %7, 1
  %11 = icmp eq i32 %9, %1
  br i1 %11, label %4, label %6, !llvm.loop !14
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(argmem: read) uwtable
define internal i32 @ks(ptr nocapture noundef readonly %0) #1 {
  br label %2

2:                                                ; preds = %2, %1
  %3 = phi i32 [ 0, %1 ], [ %8, %2 ]
  %4 = zext i32 %3 to i64
  %5 = getelementptr inbounds i8, ptr %0, i64 %4
  %6 = load i8, ptr %5, align 1, !tbaa !15
  %7 = icmp eq i8 %6, 0
  %8 = add i32 %3, 1
  br i1 %7, label %9, label %2, !llvm.loop !18

9:                                                ; preds = %2
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @tk_f(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = load volatile ptr, ptr @pf, align 8, !tbaa !19
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #6
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #6
  ret i32 %7
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #3

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #4

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #3

; Function Attrs: nounwind ssp uwtable
define i32 @tk_m(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = load volatile ptr, ptr @pm, align 8, !tbaa !19
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #6
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #6
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @tk_n(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = load volatile ptr, ptr @pn, align 8, !tbaa !19
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #6
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #6
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @tk_d(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = load volatile ptr, ptr @pd, align 8, !tbaa !19
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #6
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #6
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @tk_c(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = load volatile ptr, ptr @pc, align 8, !tbaa !19
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #6
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #6
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @tk_r(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %5 = load volatile ptr, ptr @pr, align 8, !tbaa !19
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #6
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #6
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @tk_s(i32 noundef %0, double noundef %1) local_unnamed_addr #2 {
  %3 = alloca [8 x i8], align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #6
  store i64 1976943448883713, ptr %3, align 8
  %4 = and i32 %0, 7
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %4, double noundef %1) #5
  %6 = zext i32 %5 to i64
  %7 = getelementptr inbounds [8 x i8], ptr %3, i64 0, i64 %6
  store i8 0, ptr %7, align 1, !tbaa !15
  %8 = load volatile ptr, ptr @ps, align 8, !tbaa !19
  %9 = call i32 %8(ptr noundef nonnull %3) #6
  %10 = call i32 @cq_measure_ui32(i32 noundef %9) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #6
  ret i32 %10
}

; Function Attrs: nounwind ssp uwtable
define i32 @tk_cls(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #2 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %6 = and i32 %3, 1
  %7 = icmp eq i32 %6, 0
  %8 = select i1 %7, ptr @kd, ptr @kf
  %9 = tail call i32 %8(i32 noundef %5, i32 noundef %2) #6, !callees !21
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #6
  ret i32 %10
}

attributes #0 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree noinline norecurse nosync nounwind ssp memory(argmem: read) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !8}
!10 = distinct !{!10, !7, !8}
!11 = distinct !{!11, !7, !8}
!12 = distinct !{!12, !7, !8}
!13 = distinct !{!13, !7, !8}
!14 = distinct !{!14, !8}
!15 = !{!16, !16, i64 0}
!16 = !{!"omnipotent char", !17, i64 0}
!17 = !{!"Simple C/C++ TBAA"}
!18 = distinct !{!18, !7, !8}
!19 = !{!20, !20, i64 0}
!20 = !{!"any pointer", !16, i64 0}
!21 = !{ptr @kd, ptr @kf}
