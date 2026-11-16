; ModuleID = 'diff_f5.c'
source_filename = "diff_f5.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%u\0A\00", align 1
@f5_tab = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16
@f5_G = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @f5_phi(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %11, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %8, %6 ], [ %3, %2 ]
  tail call void @cq_phi(double noundef %1) #6
  %8 = lshr i32 %7, 1
  %9 = and i32 %7, 2
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %6, !llvm.loop !6

11:                                               ; preds = %6, %2
  %12 = phi i32 [ %3, %2 ], [ %8, %6 ]
  %13 = tail call i32 @cq_measure_ui32(i32 noundef %12) #6
  ret i32 %13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare void @cq_phi(double noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @f5_phi_if(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  br label %4

4:                                                ; preds = %9, %2
  %5 = phi i32 [ %3, %2 ], [ %10, %9 ]
  %6 = and i32 %5, 4
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %9, label %8

8:                                                ; preds = %4
  tail call void @cq_phi(double noundef %1) #6
  br label %9

9:                                                ; preds = %8, %4
  %10 = lshr i32 %5, 1
  %11 = and i32 %5, 2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %4, !llvm.loop !9

13:                                               ; preds = %9
  %14 = tail call i32 @cq_measure_ui32(i32 noundef %10) #6
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @f5_theta(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %14, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %10, %6 ], [ 1, %2 ]
  %8 = phi i32 [ %11, %6 ], [ %3, %2 ]
  %9 = add i32 %7, 2
  %10 = tail call i32 @cq_theta_ui32(i32 noundef %9, double noundef %1) #5
  %11 = lshr i32 %8, 1
  %12 = and i32 %8, 2
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !10

14:                                               ; preds = %6, %2
  %15 = phi i32 [ 1, %2 ], [ %10, %6 ]
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %15) #6
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @f5_theta_x(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %14, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %11, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %10, %6 ], [ %3, %2 ]
  %9 = lshr i32 %8, 1
  %10 = tail call i32 @cq_theta_ui32(i32 noundef %9, double noundef %1) #5
  %11 = add i32 %7, 1
  %12 = and i32 %10, 1
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !11

14:                                               ; preds = %6, %2
  %15 = phi i32 [ 0, %2 ], [ %11, %6 ]
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %15) #6
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @f5_printf(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %12, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %9, %6 ], [ %3, %2 ]
  %8 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %7)
  %9 = lshr i32 %7, 1
  %10 = and i32 %7, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %6, !llvm.loop !12

12:                                               ; preds = %6, %2
  %13 = phi i32 [ %3, %2 ], [ %9, %6 ]
  %14 = tail call i32 @cq_measure_ui32(i32 noundef %13) #6
  ret i32 %14
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @f5_store(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #6
  call void @llvm.memset.p0.i64(ptr align 16 %3, i8 0, i64 16, i1 true)
  %5 = and i32 %4, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %17, label %7

7:                                                ; preds = %2, %7
  %8 = phi i32 [ %14, %7 ], [ 0, %2 ]
  %9 = phi i32 [ %13, %7 ], [ %4, %2 ]
  %10 = and i32 %8, 3
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %11
  store volatile i32 %9, ptr %12, align 4, !tbaa !13
  %13 = lshr i32 %9, 1
  %14 = add i32 %8, 1
  %15 = and i32 %9, 2
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %17, label %7, !llvm.loop !17

17:                                               ; preds = %7, %2
  %18 = phi i32 [ %4, %2 ], [ %13, %7 ]
  %19 = load volatile i32, ptr %3, align 16, !tbaa !13
  %20 = getelementptr inbounds i8, ptr %3, i64 4
  %21 = load volatile i32, ptr %20, align 4, !tbaa !13
  %22 = add i32 %19, %18
  %23 = add i32 %22, %21
  %24 = tail call i32 @cq_measure_ui32(i32 noundef %23) #6
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #6
  ret i32 %24
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #4

; Function Attrs: nounwind ssp uwtable
define i32 @f5_load(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %17, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %13, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %14, %6 ], [ %3, %2 ]
  %9 = and i32 %8, 7
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [8 x i32], ptr @f5_tab, i64 0, i64 %10
  %12 = load i32, ptr %11, align 4, !tbaa !13
  %13 = add i32 %12, %7
  %14 = lshr i32 %8, 1
  %15 = and i32 %8, 2
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %17, label %6, !llvm.loop !18

17:                                               ; preds = %6, %2
  %18 = phi i32 [ 0, %2 ], [ %13, %6 ]
  %19 = tail call i32 @cq_measure_ui32(i32 noundef %18) #6
  ret i32 %19
}

; Function Attrs: nounwind ssp uwtable
define i32 @f5_gstore(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %16, label %6

6:                                                ; preds = %2
  %7 = load i32, ptr @f5_G, align 4, !tbaa !13
  br label %8

8:                                                ; preds = %6, %8
  %9 = phi i32 [ %12, %8 ], [ %3, %6 ]
  %10 = phi i32 [ %11, %8 ], [ %7, %6 ]
  %11 = add i32 %10, %9
  %12 = lshr i32 %9, 1
  %13 = and i32 %9, 2
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %8, !llvm.loop !19

15:                                               ; preds = %8
  store i32 %11, ptr @f5_G, align 4, !tbaa !13
  br label %16

16:                                               ; preds = %15, %2
  %17 = phi i32 [ %12, %15 ], [ %3, %2 ]
  %18 = load i32, ptr @f5_G, align 4, !tbaa !13
  %19 = add i32 %18, %17
  %20 = tail call i32 @cq_measure_ui32(i32 noundef %19) #6
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @f5_meas(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %15, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %11, %6 ], [ 0, %2 ]
  %8 = phi i32 [ %12, %6 ], [ %3, %2 ]
  %9 = and i32 %8, 6
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #6
  %11 = add i32 %10, %7
  %12 = lshr i32 %8, 1
  %13 = and i32 %8, 2
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %6, !llvm.loop !20

15:                                               ; preds = %6, %2
  %16 = phi i32 [ %3, %2 ], [ %12, %6 ]
  %17 = phi i32 [ 0, %2 ], [ %11, %6 ]
  %18 = tail call i32 @cq_measure_ui32(i32 noundef %16) #6
  %19 = add i32 %18, %17
  ret i32 %19
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !7, !8}
!10 = distinct !{!10, !7, !8}
!11 = distinct !{!11, !7, !8}
!12 = distinct !{!12, !7, !8}
!13 = !{!14, !14, i64 0}
!14 = !{!"int", !15, i64 0}
!15 = !{!"omnipotent char", !16, i64 0}
!16 = !{!"Simple C/C++ TBAA"}
!17 = distinct !{!17, !7, !8}
!18 = distinct !{!18, !7, !8}
!19 = distinct !{!19, !7, !8}
!20 = distinct !{!20, !7, !8}
