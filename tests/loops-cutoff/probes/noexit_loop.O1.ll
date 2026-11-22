; ModuleID = 'noexit_loop.c'
source_filename = "noexit_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noreturn nounwind ssp uwtable
define void @ne_call(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #7
  store i32 0, ptr %3, align 4, !tbaa !6
  br label %5

5:                                                ; preds = %5, %2
  %6 = phi i32 [ %4, %2 ], [ %8, %5 ]
  %7 = mul nsw i32 %6, 3
  %8 = add nsw i32 %7, 1
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #7
  call fastcc void @tick(ptr noundef nonnull %3)
  br label %5, !llvm.loop !10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @tick(ptr nocapture noundef %0) unnamed_addr #3 {
  %2 = load i32, ptr %0, align 4, !tbaa !6
  %3 = add nsw i32 %2, 1
  store i32 %3, ptr %0, align 4, !tbaa !6
  %4 = icmp eq i32 %3, 3
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  tail call void @exit(i32 noundef 0) #8
  unreachable

6:                                                ; preds = %1
  ret void
}

; Function Attrs: noreturn nounwind ssp uwtable
define void @ne_qif(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #7
  store i32 0, ptr %3, align 4, !tbaa !6
  br label %5

5:                                                ; preds = %5, %2
  %6 = phi i32 [ %4, %2 ], [ %11, %5 ]
  %7 = and i32 %6, 1
  %8 = icmp eq i32 %7, 0
  %9 = add nsw i32 %6, 5
  %10 = xor i32 %6, 3
  %11 = select i1 %8, i32 %10, i32 %9
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #7
  call fastcc void @tick(ptr noundef nonnull %3)
  br label %5, !llvm.loop !12
}

; Function Attrs: noreturn nounwind ssp uwtable
define void @ne_cif(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #7
  store i32 0, ptr %4, align 4, !tbaa !6
  br label %6

6:                                                ; preds = %6, %3
  %7 = phi i32 [ %1, %3 ], [ %13, %6 ]
  %8 = phi i32 [ %5, %3 ], [ %12, %6 ]
  %9 = and i32 %7, 1
  %10 = icmp eq i32 %9, 0
  %11 = add nsw i32 %8, 5
  %12 = select i1 %10, i32 %8, i32 %11
  %13 = ashr i32 %7, 1
  call fastcc void @tick(ptr noundef nonnull %4)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %12) #7
  br label %6, !llvm.loop !13
}

; Function Attrs: noreturn nounwind ssp uwtable
define void @ne_arm(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #7
  store i32 0, ptr %3, align 4, !tbaa !6
  %5 = and i32 %4, 8
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %12, label %7

7:                                                ; preds = %2, %7
  %8 = phi i32 [ %10, %7 ], [ %4, %2 ]
  %9 = mul nsw i32 %8, 3
  %10 = add nsw i32 %9, 1
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #7
  call fastcc void @tick(ptr noundef nonnull %3)
  br label %7, !llvm.loop !14

12:                                               ; preds = %2
  %13 = tail call i32 @cq_measure_si32(i32 noundef %4) #7
  store i32 %13, ptr %3, align 4, !tbaa !6
  %14 = and i32 %13, 1
  tail call void @exit(i32 noundef %14) #8
  unreachable
}

; Function Attrs: noreturn
declare void @exit(i32 noundef) local_unnamed_addr #4

; Function Attrs: noreturn nounwind ssp uwtable
define void @ne_after_exit(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #7
  store i32 0, ptr %3, align 4, !tbaa !6
  %5 = and i32 %4, 8
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %8, label %7

7:                                                ; preds = %2
  tail call void @exit(i32 noundef 1) #8
  unreachable

8:                                                ; preds = %2, %8
  %9 = phi i32 [ %11, %8 ], [ %4, %2 ]
  %10 = mul nsw i32 %9, 3
  %11 = add nsw i32 %10, 1
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #7
  call fastcc void @tick(ptr noundef nonnull %3)
  br label %8, !llvm.loop !15
}

; Function Attrs: noreturn nounwind ssp uwtable
define void @ne_arm_reads(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %7, %4 ]
  %6 = mul nsw i32 %5, 3
  %7 = add nsw i32 %6, 1
  %8 = and i32 %7, 16
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %4, label %10, !llvm.loop !16

10:                                               ; preds = %4
  %11 = and i32 %5, 2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %14, label %13

13:                                               ; preds = %10
  tail call void @cq_phi(double noundef 2.500000e-01) #7
  br label %14

14:                                               ; preds = %13, %10
  tail call void @abort() #9
  unreachable
}

declare void @cq_phi(double noundef) local_unnamed_addr #2

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #5

attributes #0 = { noreturn nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { cold noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }
attributes #8 = { noreturn nounwind }
attributes #9 = { cold noreturn nounwind }

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
!10 = distinct !{!10, !11}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = distinct !{!12, !11}
!13 = distinct !{!13, !11}
!14 = distinct !{!14, !11}
!15 = distinct !{!15, !11}
!16 = distinct !{!16, !11}
