; ModuleID = 'rotated_any.c'
source_filename = "rotated_any.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ra(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = alloca i8, i64 %3, align 16
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %2
  %7 = zext nneg i32 %0 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %4, i8 0, i64 %7, i1 false), !tbaa !6
  br label %8

8:                                                ; preds = %6, %2
  %9 = icmp sgt i32 %0, 0
  br i1 %9, label %10, label %12

10:                                               ; preds = %8
  %11 = zext nneg i32 %0 to i64
  br label %16

12:                                               ; preds = %16, %8
  call fastcc void @rot_all(ptr noundef nonnull %4, i32 noundef %0, double noundef %1)
  %13 = icmp sgt i32 %0, 0
  br i1 %13, label %14, label %25

14:                                               ; preds = %12
  %15 = zext nneg i32 %0 to i64
  br label %27

16:                                               ; preds = %10, %16
  %17 = phi i64 [ 0, %10 ], [ %23, %16 ]
  %18 = getelementptr inbounds i8, ptr %4, i64 %17
  %19 = load i8, ptr %18, align 1, !tbaa !6, !range !10, !noundef !11
  %20 = trunc nuw i8 %19 to i1
  %21 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %20, double noundef 5.000000e-01) #4
  %22 = zext i1 %21 to i8
  store i8 %22, ptr %18, align 1, !tbaa !6
  %23 = add nuw nsw i64 %17, 1
  %24 = icmp eq i64 %23, %11
  br i1 %24, label %12, label %16, !llvm.loop !12

25:                                               ; preds = %27, %12
  %26 = phi i32 [ 0, %12 ], [ %37, %27 ]
  ret i32 %26

27:                                               ; preds = %14, %27
  %28 = phi i64 [ 0, %14 ], [ %38, %27 ]
  %29 = phi i32 [ 0, %14 ], [ %37, %27 ]
  %30 = getelementptr inbounds i8, ptr %4, i64 %28
  %31 = load i8, ptr %30, align 1, !tbaa !6, !range !10, !noundef !11
  %32 = trunc nuw i8 %31 to i1
  %33 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %32) #5
  %34 = zext i1 %33 to i32
  %35 = trunc nuw nsw i64 %28 to i32
  %36 = shl nuw i32 %34, %35
  %37 = or i32 %36, %29
  %38 = add nuw nsw i64 %28, 1
  %39 = icmp eq i64 %38, %15
  br i1 %39, label %25, label %27, !llvm.loop !15
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @rot_all(ptr nocapture noundef %0, i32 noundef %1, double noundef %2) unnamed_addr #2 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %3
  %6 = zext nneg i32 %1 to i64
  br label %8

7:                                                ; preds = %8, %3
  ret void

8:                                                ; preds = %5, %8
  %9 = phi i64 [ 0, %5 ], [ %15, %8 ]
  %10 = getelementptr inbounds i8, ptr %0, i64 %9
  %11 = load i8, ptr %10, align 1, !tbaa !6, !range !10, !noundef !11
  %12 = trunc nuw i8 %11 to i1
  %13 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %12, double noundef %2) #4
  %14 = zext i1 %13 to i8
  store i8 %14, ptr %10, align 1, !tbaa !6
  %15 = add nuw nsw i64 %9, 1
  %16 = icmp eq i64 %15, %6
  br i1 %16, label %7, label %8, !llvm.loop !16
}

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!16 = distinct !{!16, !13, !14}
