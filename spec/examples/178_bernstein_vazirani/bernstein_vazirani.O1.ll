; ModuleID = 'bernstein_vazirani.c'
source_filename = "bernstein_vazirani.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @bernstein_vazirani(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = alloca i8, i64 %3, align 16
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %2
  %7 = zext nneg i32 %0 to i64
  br label %12

8:                                                ; preds = %12, %2
  %9 = icmp sgt i32 %0, 0
  br i1 %9, label %10, label %19

10:                                               ; preds = %8
  %11 = zext nneg i32 %0 to i64
  br label %25

12:                                               ; preds = %6, %12
  %13 = phi i64 [ 0, %6 ], [ %17, %12 ]
  %14 = getelementptr inbounds i8, ptr %4, i64 %13
  store i8 0, ptr %14, align 1, !tbaa !6
  %15 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FF921FB54442D18) #3
  %16 = zext i1 %15 to i8
  store i8 %16, ptr %14, align 1, !tbaa !6
  %17 = add nuw nsw i64 %13, 1
  %18 = icmp eq i64 %17, %7
  br i1 %18, label %8, label %12, !llvm.loop !10

19:                                               ; preds = %25, %8
  %20 = phi i32 [ 0, %8 ], [ %33, %25 ]
  %21 = and i32 %20, %1
  %22 = tail call range(i32 0, 33) i32 @llvm.ctpop.i32(i32 %21)
  %23 = and i32 %22, 1
  %24 = icmp eq i32 %23, 0
  br i1 %24, label %37, label %36

25:                                               ; preds = %10, %25
  %26 = phi i64 [ 0, %10 ], [ %34, %25 ]
  %27 = phi i32 [ 0, %10 ], [ %33, %25 ]
  %28 = getelementptr inbounds i8, ptr %4, i64 %26
  %29 = load i8, ptr %28, align 1, !tbaa !6, !range !13, !noundef !14
  %30 = zext nneg i8 %29 to i32
  %31 = trunc nuw nsw i64 %26 to i32
  %32 = shl nuw i32 %30, %31
  %33 = or i32 %32, %27
  %34 = add nuw nsw i64 %26, 1
  %35 = icmp eq i64 %34, %11
  br i1 %35, label %19, label %25, !llvm.loop !15

36:                                               ; preds = %19
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #4
  br label %37

37:                                               ; preds = %36, %19
  %38 = icmp sgt i32 %0, 0
  br i1 %38, label %39, label %41

39:                                               ; preds = %37
  %40 = zext nneg i32 %0 to i64
  br label %45

41:                                               ; preds = %45, %37
  %42 = icmp sgt i32 %0, 0
  br i1 %42, label %43, label %54

43:                                               ; preds = %41
  %44 = zext nneg i32 %0 to i64
  br label %56

45:                                               ; preds = %39, %45
  %46 = phi i64 [ 0, %39 ], [ %52, %45 ]
  %47 = getelementptr inbounds i8, ptr %4, i64 %46
  %48 = load i8, ptr %47, align 1, !tbaa !6, !range !13, !noundef !14
  %49 = trunc nuw i8 %48 to i1
  %50 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %49, double noundef 0xBFF921FB54442D18) #3
  %51 = zext i1 %50 to i8
  store i8 %51, ptr %47, align 1, !tbaa !6
  %52 = add nuw nsw i64 %46, 1
  %53 = icmp eq i64 %52, %40
  br i1 %53, label %41, label %45, !llvm.loop !16

54:                                               ; preds = %56, %41
  %55 = phi i32 [ 0, %41 ], [ %66, %56 ]
  ret i32 %55

56:                                               ; preds = %43, %56
  %57 = phi i64 [ 0, %43 ], [ %67, %56 ]
  %58 = phi i32 [ 0, %43 ], [ %66, %56 ]
  %59 = getelementptr inbounds i8, ptr %4, i64 %57
  %60 = load i8, ptr %59, align 1, !tbaa !6, !range !13, !noundef !14
  %61 = trunc nuw i8 %60 to i1
  %62 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %61) #4
  %63 = zext i1 %62 to i32
  %64 = trunc nuw nsw i64 %57 to i32
  %65 = shl nuw i32 %63, %64
  %66 = or i32 %65, %58
  %67 = add nuw nsw i64 %57, 1
  %68 = icmp eq i64 %67, %44
  br i1 %68, label %54, label %56, !llvm.loop !17
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.ctpop.i32(i32) #2

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

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
!17 = distinct !{!17, !11, !12}
