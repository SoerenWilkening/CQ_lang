; cq-nqa6: a _ctl clone's controlled Ry on a cell of its pointer formal under its entry flag (117's grover_1000_ctl) assumes
; the flag names no rail the clone reaches otherwise; here the caller's flag is x[0], a cell of the array it passes:
; calls::finalize must stop (C: if (x[0]) rot(x, n), rot rotating every x[i]).
; FATAL: calls: a _ctl call whose entry flag may name a rail the clone reaches otherwise
; ModuleID = 'ctl.O1.ll'
source_filename = "ctl.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #0

; Function Attrs: noinline nounwind ssp uwtable
define hidden fastcc void @rot(ptr nocapture noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  br label %7

6:                                                ; preds = %7, %2
  ret void

7:                                                ; preds = %7, %4
  %8 = phi i64 [ 0, %4 ], [ %14, %7 ]
  %9 = getelementptr inbounds i8, ptr %0, i64 %8
  %10 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef 5.000000e-01) #4
  %13 = zext i1 %12 to i8
  store i8 %13, ptr %9, align 1, !tbaa !6
  %14 = add nuw nsw i64 %8, 1
  %15 = icmp eq i64 %14, %5
  br i1 %15, label %6, label %7, !llvm.loop !12
}

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #0

; Function Attrs: nounwind ssp uwtable
define i32 @ctl_alias(double noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = zext i32 %1 to i64
  %4 = alloca i8, i64 %3, align 16
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %2
  %7 = zext nneg i32 %1 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %4, i8 0, i64 %7, i1 false), !tbaa !6
  br label %8

8:                                                ; preds = %6, %2
  %9 = load i8, ptr %4, align 16, !tbaa !6, !range !10, !noundef !11
  %10 = trunc nuw i8 %9 to i1
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %10, double noundef %0) #4
  %12 = zext i1 %11 to i8
  store i8 %12, ptr %4, align 16, !tbaa !6
  br i1 %11, label %13, label %14

13:                                               ; preds = %8
  call fastcc void @rot(ptr noundef nonnull %4, i32 noundef %1)
  br label %14

14:                                               ; preds = %13, %8
  %15 = icmp sgt i32 %1, 0
  br i1 %15, label %16, label %18

16:                                               ; preds = %14
  %17 = zext nneg i32 %1 to i64
  br label %20

18:                                               ; preds = %20, %14
  %19 = phi i32 [ 0, %14 ], [ %30, %20 ]
  ret i32 %19

20:                                               ; preds = %20, %16
  %21 = phi i64 [ 0, %16 ], [ %31, %20 ]
  %22 = phi i32 [ 0, %16 ], [ %30, %20 ]
  %23 = getelementptr inbounds i8, ptr %4, i64 %21
  %24 = load i8, ptr %23, align 1, !tbaa !6, !range !10, !noundef !11
  %25 = trunc nuw i8 %24 to i1
  %26 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %25) #5
  %27 = zext i1 %26 to i32
  %28 = trunc nuw nsw i64 %21 to i32
  %29 = shl nuw i32 %27, %28
  %30 = add nsw i32 %29, %22
  %31 = add nuw nsw i64 %21, 1
  %32 = icmp eq i64 %31, %17
  br i1 %32, label %18, label %20, !llvm.loop !15
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

attributes #0 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
