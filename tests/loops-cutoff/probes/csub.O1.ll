; ModuleID = 'csub.c'
source_filename = "csub.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @cs_guard(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = and i32 %1, 7
  %5 = and i32 %0, 7
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %2) #5
  %7 = icmp sgt i32 %6, 0
  br i1 %7, label %8, label %24

8:                                                ; preds = %3
  %9 = icmp eq i32 %4, 0
  br label %10

10:                                               ; preds = %8, %13
  %11 = phi i32 [ 0, %8 ], [ %14, %13 ]
  %12 = phi i32 [ 0, %8 ], [ %15, %13 ]
  br i1 %9, label %13, label %17

13:                                               ; preds = %17, %10
  %14 = phi i32 [ %11, %10 ], [ %21, %17 ]
  %15 = add nuw nsw i32 %12, 1
  %16 = icmp eq i32 %15, %6
  br i1 %16, label %24, label %10, !llvm.loop !6

17:                                               ; preds = %10, %17
  %18 = phi i32 [ %22, %17 ], [ 0, %10 ]
  %19 = phi i32 [ %21, %17 ], [ %11, %10 ]
  %20 = xor i32 %18, %12
  %21 = add nsw i32 %20, %19
  %22 = add nuw nsw i32 %18, 1
  %23 = icmp eq i32 %22, %4
  br i1 %23, label %13, label %17, !llvm.loop !9

24:                                               ; preds = %13, %3
  %25 = phi i32 [ 0, %3 ], [ %14, %13 ]
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #6
  ret i32 %26
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @cs_const(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  br label %4

4:                                                ; preds = %7, %2
  %5 = phi i32 [ 0, %2 ], [ %8, %7 ]
  %6 = phi i32 [ 0, %2 ], [ %17, %7 ]
  br label %12

7:                                                ; preds = %12
  %8 = add nuw nsw i32 %5, 1
  %9 = shl i32 2, %5
  %10 = and i32 %9, %3
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %20, label %4, !llvm.loop !10

12:                                               ; preds = %4, %12
  %13 = phi i32 [ 0, %4 ], [ %18, %12 ]
  %14 = phi i32 [ %6, %4 ], [ %17, %12 ]
  %15 = mul nsw i32 %14, 3
  %16 = add nuw i32 %13, %5
  %17 = add i32 %16, %15
  %18 = add nuw nsw i32 %13, 1
  %19 = icmp eq i32 %18, 3
  br i1 %19, label %7, label %12, !llvm.loop !11

20:                                               ; preds = %7
  %21 = tail call i32 @cq_measure_si32(i32 noundef %17) #6
  ret i32 %21
}

; Function Attrs: nounwind ssp uwtable
define double @cs_mem(i32 noundef %0, i32 noundef %1, ptr nocapture noundef readonly %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca [8 x double], align 16
  %6 = and i32 %0, 3
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef %3) #5
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %5) #6
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(64) %5, ptr noundef nonnull align 8 dereferenceable(64) %2, i64 64, i1 false), !tbaa !12
  %8 = and i32 %1, 7
  %9 = icmp sgt i32 %7, 0
  br i1 %9, label %10, label %19

10:                                               ; preds = %4
  %11 = icmp eq i32 %8, 0
  %12 = zext nneg i32 %7 to i64
  %13 = zext nneg i32 %8 to i64
  br label %14

14:                                               ; preds = %10, %22
  %15 = phi i64 [ 0, %10 ], [ %25, %22 ]
  %16 = phi double [ 0.000000e+00, %10 ], [ %24, %22 ]
  br i1 %11, label %22, label %17

17:                                               ; preds = %14
  %18 = add nuw nsw i64 %15, 3
  br label %27

19:                                               ; preds = %22, %4
  %20 = phi double [ 0.000000e+00, %4 ], [ %24, %22 ]
  %21 = tail call double @cq_measure_f64(double noundef %20) #6
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %5) #6
  ret double %21

22:                                               ; preds = %27, %14
  %23 = phi double [ 0.000000e+00, %14 ], [ %36, %27 ]
  %24 = fadd double %16, %23
  %25 = add nuw nsw i64 %15, 1
  %26 = icmp eq i64 %25, %12
  br i1 %26, label %19, label %14, !llvm.loop !16

27:                                               ; preds = %17, %27
  %28 = phi i64 [ 0, %17 ], [ %37, %27 ]
  %29 = phi double [ 0.000000e+00, %17 ], [ %36, %27 ]
  %30 = getelementptr inbounds double, ptr %2, i64 %28
  %31 = load double, ptr %30, align 8, !tbaa !12
  %32 = sub nsw i64 %18, %28
  %33 = and i64 %32, 7
  %34 = getelementptr inbounds [8 x double], ptr %5, i64 0, i64 %33
  %35 = load double, ptr %34, align 8, !tbaa !12
  %36 = tail call double @llvm.fmuladd.f64(double %31, double %35, double %29)
  %37 = add nuw nsw i64 %28, 1
  %38 = icmp eq i64 %37, %13
  br i1 %38, label %22, label %27, !llvm.loop !17
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @cs_case3(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = and i32 %1, 7
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #5
  %6 = icmp eq i32 %4, 0
  br label %7

7:                                                ; preds = %18, %3
  %8 = phi i32 [ 0, %3 ], [ %21, %18 ]
  %9 = phi i32 [ 0, %3 ], [ %20, %18 ]
  br i1 %6, label %18, label %10

10:                                               ; preds = %7, %15
  %11 = phi i32 [ %16, %15 ], [ 0, %7 ]
  %12 = shl i32 16, %11
  %13 = and i32 %12, %5
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %18

15:                                               ; preds = %10
  %16 = add nuw nsw i32 %11, 1
  %17 = icmp eq i32 %16, %4
  br i1 %17, label %18, label %10, !llvm.loop !18

18:                                               ; preds = %15, %10, %7
  %19 = phi i32 [ 0, %7 ], [ %4, %15 ], [ %11, %10 ]
  %20 = add nuw nsw i32 %19, %9
  %21 = add nuw nsw i32 %8, 1
  %22 = shl i32 2, %8
  %23 = and i32 %22, %5
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %25, label %7, !llvm.loop !19

25:                                               ; preds = %18
  %26 = tail call i32 @cq_measure_si32(i32 noundef %20) #6
  ret i32 %26
}

; Function Attrs: nounwind ssp uwtable
define i32 @cs_arm(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = and i32 %1, 7
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #5
  br label %6

6:                                                ; preds = %13, %3
  %7 = phi i32 [ 0, %3 ], [ %14, %13 ]
  %8 = shl i32 256, %7
  %9 = and i32 %8, %5
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %13, label %11

11:                                               ; preds = %6
  %12 = icmp eq i32 %4, 0
  br i1 %12, label %28, label %18

13:                                               ; preds = %6
  %14 = add nuw nsw i32 %7, 1
  %15 = shl i32 2, %7
  %16 = and i32 %15, %5
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %28, label %6, !llvm.loop !20

18:                                               ; preds = %11, %18
  %19 = phi i32 [ %26, %18 ], [ 0, %11 ]
  %20 = phi i32 [ %25, %18 ], [ 0, %11 ]
  %21 = mul nsw i32 %20, 3
  %22 = ashr i32 %5, %19
  %23 = and i32 %22, 5
  %24 = add i32 %21, %7
  %25 = add i32 %24, %23
  %26 = add nuw nsw i32 %19, 1
  %27 = icmp eq i32 %26, %4
  br i1 %27, label %28, label %18, !llvm.loop !21

28:                                               ; preds = %13, %18, %11
  %29 = phi i32 [ 0, %11 ], [ %25, %18 ], [ %14, %13 ]
  %30 = tail call i32 @cq_measure_si32(i32 noundef %29) #6
  ret i32 %30
}

; Function Attrs: nounwind ssp uwtable
define i32 @cs_tri(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  br label %4

4:                                                ; preds = %8, %2
  %5 = phi i32 [ 0, %2 ], [ %10, %8 ]
  %6 = phi i32 [ 1, %2 ], [ %9, %8 ]
  %7 = icmp eq i32 %5, 0
  br i1 %7, label %8, label %14

8:                                                ; preds = %14, %4
  %9 = phi i32 [ %6, %4 ], [ %19, %14 ]
  %10 = add nuw nsw i32 %5, 1
  %11 = shl i32 2, %5
  %12 = and i32 %11, %3
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %22, label %4, !llvm.loop !22

14:                                               ; preds = %4, %14
  %15 = phi i32 [ %20, %14 ], [ 0, %4 ]
  %16 = phi i32 [ %19, %14 ], [ %6, %4 ]
  %17 = mul nsw i32 %16, 3
  %18 = xor i32 %15, %3
  %19 = add nsw i32 %18, %17
  %20 = add nuw nsw i32 %15, 1
  %21 = icmp eq i32 %20, %5
  br i1 %21, label %8, label %14, !llvm.loop !23

22:                                               ; preds = %8
  %23 = tail call i32 @cq_measure_si32(i32 noundef %9) #6
  ret i32 %23
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
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
!9 = distinct !{!9, !7, !8}
!10 = distinct !{!10, !7, !8}
!11 = distinct !{!11, !7, !8}
!12 = !{!13, !13, i64 0}
!13 = !{!"double", !14, i64 0}
!14 = !{!"omnipotent char", !15, i64 0}
!15 = !{!"Simple C/C++ TBAA"}
!16 = distinct !{!16, !7, !8}
!17 = distinct !{!17, !7, !8}
!18 = distinct !{!18, !7, !8}
!19 = distinct !{!19, !7, !8}
!20 = distinct !{!20, !7, !8}
!21 = distinct !{!21, !7, !8}
!22 = distinct !{!22, !7, !8}
!23 = distinct !{!23, !7, !8}
