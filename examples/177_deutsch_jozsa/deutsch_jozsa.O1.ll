; ModuleID = 'deutsch_jozsa.c'
source_filename = "deutsch_jozsa.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @deutsch_jozsa(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = alloca i8, i64 %3, align 16
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %2
  %7 = zext nneg i32 %0 to i64
  br label %25

8:                                                ; preds = %25, %2
  switch i32 %1, label %20 [
    i32 0, label %33
    i32 1, label %32
    i32 2, label %9
  ]

9:                                                ; preds = %8
  %10 = icmp sgt i32 %0, 0
  br i1 %10, label %11, label %33

11:                                               ; preds = %9, %11
  %12 = phi i64 [ %18, %11 ], [ 0, %9 ]
  %13 = phi i1 [ %17, %11 ], [ false, %9 ]
  %14 = getelementptr inbounds i8, ptr %4, i64 %12
  %15 = load i8, ptr %14, align 1, !tbaa !6, !range !10, !noundef !11
  %16 = zext i1 %13 to i8
  %17 = icmp ne i8 %15, %16
  %18 = add nuw nsw i64 %12, 1
  %19 = icmp eq i64 %18, %3
  br i1 %19, label %23, label %11, !llvm.loop !12

20:                                               ; preds = %8
  %21 = load i8, ptr %4, align 16, !tbaa !6, !range !10, !noundef !11
  %22 = trunc nuw i8 %21 to i1
  br label %23

23:                                               ; preds = %11, %20
  %24 = phi i1 [ %22, %20 ], [ %17, %11 ]
  br i1 %24, label %32, label %33

25:                                               ; preds = %6, %25
  %26 = phi i64 [ 0, %6 ], [ %30, %25 ]
  %27 = getelementptr inbounds i8, ptr %4, i64 %26
  store i8 0, ptr %27, align 1, !tbaa !6
  %28 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FF921FB54442D18) #2
  %29 = zext i1 %28 to i8
  store i8 %29, ptr %27, align 1, !tbaa !6
  %30 = add nuw nsw i64 %26, 1
  %31 = icmp eq i64 %30, %7
  br i1 %31, label %8, label %25, !llvm.loop !15

32:                                               ; preds = %8, %23
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #3
  br label %33

33:                                               ; preds = %8, %9, %32, %23
  %34 = icmp sgt i32 %0, 0
  br i1 %34, label %35, label %37

35:                                               ; preds = %33
  %36 = zext nneg i32 %0 to i64
  br label %41

37:                                               ; preds = %41, %33
  %38 = icmp sgt i32 %0, 0
  br i1 %38, label %39, label %50

39:                                               ; preds = %37
  %40 = zext nneg i32 %0 to i64
  br label %52

41:                                               ; preds = %35, %41
  %42 = phi i64 [ 0, %35 ], [ %48, %41 ]
  %43 = getelementptr inbounds i8, ptr %4, i64 %42
  %44 = load i8, ptr %43, align 1, !tbaa !6, !range !10, !noundef !11
  %45 = trunc nuw i8 %44 to i1
  %46 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %45, double noundef 0xBFF921FB54442D18) #2
  %47 = zext i1 %46 to i8
  store i8 %47, ptr %43, align 1, !tbaa !6
  %48 = add nuw nsw i64 %42, 1
  %49 = icmp eq i64 %48, %36
  br i1 %49, label %37, label %41, !llvm.loop !16

50:                                               ; preds = %52, %37
  %51 = phi i32 [ 0, %37 ], [ %62, %52 ]
  ret i32 %51

52:                                               ; preds = %39, %52
  %53 = phi i64 [ 0, %39 ], [ %63, %52 ]
  %54 = phi i32 [ 0, %39 ], [ %62, %52 ]
  %55 = getelementptr inbounds i8, ptr %4, i64 %53
  %56 = load i8, ptr %55, align 1, !tbaa !6, !range !10, !noundef !11
  %57 = trunc nuw i8 %56 to i1
  %58 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %57) #3
  %59 = zext i1 %58 to i32
  %60 = trunc nuw nsw i64 %53 to i32
  %61 = shl nuw i32 %59, %60
  %62 = or i32 %61, %54
  %63 = add nuw nsw i64 %53, 1
  %64 = icmp eq i64 %63, %40
  br i1 %64, label %50, label %52, !llvm.loop !17
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

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
!16 = distinct !{!16, !13, !14}
!17 = distinct !{!17, !13, !14}
