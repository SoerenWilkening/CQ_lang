; ModuleID = 'fnptr_shapes.c'
source_filename = "fnptr_shapes.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }

@p_sumv = global ptr @sumv, align 8
@p_bysum = global ptr @bysum, align 8
@p_half = global ptr @half, align 8
@p_rec = global ptr @rec, align 8
@p_wr = global ptr @wr, align 8
@g_store = local_unnamed_addr global i32 0, align 4

; Function Attrs: nofree noinline norecurse nosync nounwind ssp uwtable
define internal i32 @sumv(i32 noundef %0, ...) #0 {
  %2 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %2) #9
  call void @llvm.va_start.p0(ptr nonnull %2)
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %4, label %12

4:                                                ; preds = %1
  %5 = load i32, ptr %2, align 16
  %6 = getelementptr inbounds i8, ptr %2, i64 8
  %7 = getelementptr inbounds i8, ptr %2, i64 16
  %8 = load ptr, ptr %7, align 16
  %9 = load ptr, ptr %6, align 8
  %10 = add nsw i32 %0, -1
  %11 = call i32 @llvm.umin.i32(i32 %10, i32 2)
  br label %14

12:                                               ; preds = %26, %1
  %13 = phi i32 [ 0, %1 ], [ %31, %26 ]
  call void @llvm.va_end.p0(ptr %2)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %2) #9
  ret i32 %13

14:                                               ; preds = %4, %26
  %15 = phi ptr [ %9, %4 ], [ %27, %26 ]
  %16 = phi i32 [ 0, %4 ], [ %32, %26 ]
  %17 = phi i32 [ 0, %4 ], [ %31, %26 ]
  %18 = phi i32 [ %5, %4 ], [ %28, %26 ]
  %19 = icmp ult i32 %18, 41
  br i1 %19, label %20, label %24

20:                                               ; preds = %14
  %21 = zext nneg i32 %18 to i64
  %22 = getelementptr i8, ptr %8, i64 %21
  %23 = add nuw nsw i32 %18, 8
  store i32 %23, ptr %2, align 16
  br label %26

24:                                               ; preds = %14
  %25 = getelementptr i8, ptr %15, i64 8
  store ptr %25, ptr %6, align 8
  br label %26

26:                                               ; preds = %24, %20
  %27 = phi ptr [ %15, %20 ], [ %25, %24 ]
  %28 = phi i32 [ %23, %20 ], [ %18, %24 ]
  %29 = phi ptr [ %22, %20 ], [ %15, %24 ]
  %30 = load i32, ptr %29, align 4, !tbaa !6
  %31 = add nsw i32 %30, %17
  %32 = add nuw nsw i32 %16, 1
  %33 = icmp eq i32 %16, %11
  br i1 %33, label %12, label %14, !llvm.loop !10
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal i64 @bysum(i64 %0, i64 %1) #1 {
  %3 = mul i64 %0, 4294967297
  %4 = ashr i64 %3, 32
  %5 = add nsw i64 %4, %1
  ret i64 %5
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal noundef double @half(double noundef %0) #1 {
  %2 = fmul double %0, 5.000000e-01
  ret double %2
}

; Function Attrs: nofree noinline nosync nounwind ssp memory(none) uwtable
define internal i32 @rec(i32 noundef %0) #2 {
  br label %2

2:                                                ; preds = %6, %1
  %3 = phi i32 [ 0, %1 ], [ %8, %6 ]
  %4 = phi i32 [ %0, %1 ], [ %7, %6 ]
  %5 = icmp slt i32 %4, 1
  br i1 %5, label %9, label %6

6:                                                ; preds = %2
  %7 = add nsw i32 %4, -2
  %8 = add nsw i32 %3, 1
  br label %2

9:                                                ; preds = %2
  %10 = add nsw i32 %3, 0
  ret i32 %10
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define internal range(i32 -2147483641, -2147483648) i32 @wr(i32 noundef %0) #3 {
  store i32 %0, ptr @g_store, align 4, !tbaa !6
  %2 = add nsw i32 %0, 7
  ret i32 %2
}

; Function Attrs: nounwind ssp uwtable
define i32 @s_va(i32 noundef %0, double noundef %1) local_unnamed_addr #4 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #10
  %4 = load volatile ptr, ptr @p_sumv, align 8, !tbaa !13
  %5 = tail call i32 (i32, ...) %4(i32 noundef 2, i32 noundef %3, i32 noundef 5) #9
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #9
  ret i32 %6
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #5

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #6

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #6

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #5

; Function Attrs: nounwind ssp uwtable
define i64 @s_by(i32 noundef %0, double noundef %1) local_unnamed_addr #4 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #10
  %4 = zext i32 %3 to i64
  %5 = or disjoint i64 %4, 8589934592
  %6 = load volatile ptr, ptr @p_bysum, align 8, !tbaa !13
  %7 = tail call i64 %6(i64 %5, i64 3) #9
  %8 = tail call i64 @cq_measure_sl(i64 noundef %7) #9
  ret i64 %8
}

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #6

; Function Attrs: nounwind ssp uwtable
define double @s_fp(double noundef %0, double noundef %1) local_unnamed_addr #4 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #10
  %4 = load volatile ptr, ptr @p_half, align 8, !tbaa !13
  %5 = tail call double %4(double noundef %3) #9
  %6 = tail call double @cq_measure_f64(double noundef %5) #9
  ret double %6
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #6

declare double @cq_measure_f64(double noundef) local_unnamed_addr #6

; Function Attrs: nounwind ssp uwtable
define i32 @s_rec(i8 noundef zeroext %0, double noundef %1) local_unnamed_addr #4 {
  %3 = and i8 %0, 7
  %4 = zext nneg i8 %3 to i32
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef %1) #10
  %6 = load volatile ptr, ptr @p_rec, align 8, !tbaa !13
  %7 = tail call i32 %6(i32 noundef %5) #9
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #9
  ret i32 %8
}

; Function Attrs: nounwind ssp uwtable
define i32 @s_wr(i32 noundef %0, double noundef %1) local_unnamed_addr #4 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #10
  %4 = load volatile ptr, ptr @p_wr, align 8, !tbaa !13
  %5 = tail call i32 %4(i32 noundef %3) #9
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #9
  %7 = load i32, ptr @g_store, align 4, !tbaa !6
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #9
  %9 = add nsw i32 %8, %6
  ret i32 %9
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #7

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #7

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #8

attributes #0 = { nofree noinline norecurse nosync nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree noinline nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #6 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #8 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #9 = { nounwind }
attributes #10 = { nomerge nounwind }

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
!13 = !{!14, !14, i64 0}
!14 = !{!"any pointer", !8, i64 0}
