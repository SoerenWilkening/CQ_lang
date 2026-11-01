; ModuleID = 'register_update.c'
source_filename = "register_update.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @register_update(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = alloca i8, i64 %3, align 16
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %6, label %10

6:                                                ; preds = %2
  %7 = lshr i32 %0, 1
  %8 = zext nneg i32 %7 to i64
  %9 = zext nneg i32 %0 to i64
  br label %14

10:                                               ; preds = %14, %2
  %11 = icmp sgt i32 %0, 1
  br i1 %11, label %12, label %21

12:                                               ; preds = %10
  %13 = zext nneg i32 %0 to i64
  br label %25

14:                                               ; preds = %6, %14
  %15 = phi i64 [ 0, %6 ], [ %19, %14 ]
  %16 = icmp uge i64 %15, %8
  %17 = getelementptr inbounds i8, ptr %4, i64 %15
  %18 = zext i1 %16 to i8
  store i8 %18, ptr %17, align 1, !tbaa !6
  %19 = add nuw nsw i64 %15, 1
  %20 = icmp eq i64 %19, %9
  br i1 %20, label %10, label %14, !llvm.loop !10

21:                                               ; preds = %38, %10
  %22 = icmp sgt i32 %0, 0
  br i1 %22, label %23, label %45

23:                                               ; preds = %21
  %24 = zext nneg i32 %0 to i64
  br label %47

25:                                               ; preds = %12, %38
  %26 = phi i64 [ %13, %12 ], [ %43, %38 ]
  %27 = getelementptr i8, ptr %4, i64 %26
  %28 = getelementptr i8, ptr %27, i64 -2
  %29 = load i8, ptr %28, align 1, !tbaa !6, !range !13, !noundef !14
  %30 = getelementptr i8, ptr %27, i64 -1
  %31 = load i8, ptr %30, align 1, !tbaa !6, !range !13, !noundef !14
  %32 = icmp ne i8 %31, %29
  %33 = zext i1 %32 to i8
  store i8 %33, ptr %30, align 1, !tbaa !6
  br i1 %32, label %34, label %38

34:                                               ; preds = %25
  %35 = trunc nuw i8 %29 to i1
  %36 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %35, double noundef %1) #2
  %37 = zext i1 %36 to i8
  store i8 %37, ptr %28, align 1, !tbaa !6
  br label %38

38:                                               ; preds = %34, %25
  %39 = load i8, ptr %28, align 1, !tbaa !6, !range !13, !noundef !14
  %40 = load i8, ptr %30, align 1, !tbaa !6, !range !13, !noundef !14
  %41 = icmp ne i8 %40, %39
  %42 = zext i1 %41 to i8
  store i8 %42, ptr %30, align 1, !tbaa !6
  %43 = add nsw i64 %26, -1
  %44 = icmp sgt i64 %26, 2
  br i1 %44, label %25, label %21, !llvm.loop !15

45:                                               ; preds = %47, %21
  %46 = phi i32 [ 0, %21 ], [ %57, %47 ]
  ret i32 %46

47:                                               ; preds = %23, %47
  %48 = phi i64 [ 0, %23 ], [ %58, %47 ]
  %49 = phi i32 [ 0, %23 ], [ %57, %47 ]
  %50 = getelementptr inbounds i8, ptr %4, i64 %48
  %51 = load i8, ptr %50, align 1, !tbaa !6, !range !13, !noundef !14
  %52 = trunc nuw i8 %51 to i1
  %53 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %52) #3
  %54 = zext i1 %53 to i32
  %55 = trunc nuw nsw i64 %48 to i32
  %56 = shl nuw i32 %54, %55
  %57 = or i32 %56, %49
  %58 = add nuw nsw i64 %48, 1
  %59 = icmp eq i64 %58, %24
  br i1 %59, label %45, label %47, !llvm.loop !16
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
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = !{i8 0, i8 2}
!14 = !{}
!15 = distinct !{!15, !11, !12}
!16 = distinct !{!16, !11, !12}
; CHECK-COUNT register_update: call void @cqrt_copy_i1( 2
; CHECK-COUNT register_update: call void @cq_template_xor_i1_unc( 2
; CHECK-COUNT register_update: call void @cqrt_ry_i1_controlled( 1
; CHECK register_update: call void @cqrt_free(i32 %{{t}})
