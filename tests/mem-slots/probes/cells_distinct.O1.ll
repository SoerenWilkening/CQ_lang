; ModuleID = 'cells_distinct.c'
source_filename = "cells_distinct.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @cells_distinct(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = zext i32 %0 to i64
  %6 = alloca i8, i64 %5, align 16
  %7 = icmp sgt i32 %0, 0
  br i1 %7, label %8, label %10

8:                                                ; preds = %4
  %9 = zext nneg i32 %0 to i64
  br label %25

10:                                               ; preds = %25, %4
  %11 = sext i32 %1 to i64
  %12 = getelementptr i8, ptr %6, i64 %11
  %13 = getelementptr i8, ptr %12, i64 -3
  %14 = load i8, ptr %13, align 1, !tbaa !6, !range !10, !noundef !11
  %15 = getelementptr i8, ptr %12, i64 -1
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = icmp ne i8 %16, %14
  %18 = zext i1 %17 to i8
  store i8 %18, ptr %15, align 1, !tbaa !6
  %19 = select i1 %17, i32 2, i32 0
  %20 = getelementptr i8, ptr %12, i64 -2
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = zext nneg i8 %21 to i32
  %23 = or disjoint i32 %19, %22
  %24 = icmp eq i32 %23, 3
  br i1 %24, label %32, label %36

25:                                               ; preds = %8, %25
  %26 = phi i64 [ 0, %8 ], [ %30, %25 ]
  %27 = getelementptr inbounds i8, ptr %6, i64 %26
  store i8 0, ptr %27, align 1, !tbaa !6
  %28 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %2) #2
  %29 = zext i1 %28 to i8
  store i8 %29, ptr %27, align 1, !tbaa !6
  %30 = add nuw nsw i64 %26, 1
  %31 = icmp eq i64 %30, %9
  br i1 %31, label %10, label %25, !llvm.loop !12

32:                                               ; preds = %10
  %33 = trunc nuw i8 %14 to i1
  %34 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %33, double noundef %3) #2
  %35 = zext i1 %34 to i8
  store i8 %35, ptr %13, align 1, !tbaa !6
  br label %36

36:                                               ; preds = %32, %10
  %37 = load i8, ptr %13, align 1, !tbaa !6, !range !10, !noundef !11
  %38 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %39 = icmp ne i8 %38, %37
  %40 = zext i1 %39 to i8
  store i8 %40, ptr %15, align 1, !tbaa !6
  %41 = icmp sgt i32 %0, 0
  br i1 %41, label %42, label %44

42:                                               ; preds = %36
  %43 = zext nneg i32 %0 to i64
  br label %46

44:                                               ; preds = %46, %36
  %45 = phi i32 [ 0, %36 ], [ %56, %46 ]
  ret i32 %45

46:                                               ; preds = %42, %46
  %47 = phi i64 [ 0, %42 ], [ %57, %46 ]
  %48 = phi i32 [ 0, %42 ], [ %56, %46 ]
  %49 = getelementptr inbounds i8, ptr %6, i64 %47
  %50 = load i8, ptr %49, align 1, !tbaa !6, !range !10, !noundef !11
  %51 = trunc nuw i8 %50 to i1
  %52 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %51) #3
  %53 = zext i1 %52 to i32
  %54 = trunc nuw nsw i64 %47 to i32
  %55 = shl nuw i32 %53, %54
  %56 = or i32 %55, %48
  %57 = add nuw nsw i64 %47, 1
  %58 = icmp eq i64 %57, %43
  br i1 %58, label %44, label %46, !llvm.loop !15
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

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
; CHECK-COUNT cells_distinct: call void @cqrt_ry_i1_controlled( 1
; CHECK-COUNT cells_distinct: call void @cq_template_icmp_eq_i32_hl_unc( 1
