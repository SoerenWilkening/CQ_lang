; ModuleID = 'simon.c'
source_filename = "simon.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @simon(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = alloca i8, i64 %3, align 16
  %5 = alloca i8, i64 %3, align 16
  %6 = icmp eq i32 %1, 0
  %7 = tail call range(i32 0, 33) i32 @llvm.cttz.i32(i32 %1, i1 true)
  %8 = select i1 %6, i32 0, i32 %7
  %9 = icmp sgt i32 %0, 0
  br i1 %9, label %10, label %12

10:                                               ; preds = %2
  %11 = zext nneg i32 %0 to i64
  br label %20

12:                                               ; preds = %20, %2
  %13 = icmp sgt i32 %0, 0
  br i1 %13, label %14, label %27

14:                                               ; preds = %12
  %15 = zext nneg i32 %8 to i64
  %16 = getelementptr inbounds i8, ptr %4, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !6, !range !10, !noundef !11
  %18 = zext nneg i8 %17 to i32
  %19 = zext nneg i32 %0 to i64
  br label %31

20:                                               ; preds = %10, %20
  %21 = phi i64 [ 0, %10 ], [ %25, %20 ]
  %22 = getelementptr inbounds i8, ptr %4, i64 %21
  store i8 0, ptr %22, align 1, !tbaa !6
  %23 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FF921FB54442D18) #3
  %24 = zext i1 %23 to i8
  store i8 %24, ptr %22, align 1, !tbaa !6
  %25 = add nuw nsw i64 %21, 1
  %26 = icmp eq i64 %25, %11
  br i1 %26, label %12, label %20, !llvm.loop !12

27:                                               ; preds = %31, %12
  %28 = icmp sgt i32 %0, 0
  br i1 %28, label %29, label %44

29:                                               ; preds = %27
  %30 = zext nneg i32 %0 to i64
  br label %48

31:                                               ; preds = %14, %31
  %32 = phi i64 [ 0, %14 ], [ %42, %31 ]
  %33 = getelementptr inbounds i8, ptr %4, i64 %32
  %34 = load i8, ptr %33, align 1, !tbaa !6, !range !10, !noundef !11
  %35 = zext nneg i8 %34 to i32
  %36 = trunc nuw nsw i64 %32 to i32
  %37 = lshr i32 %1, %36
  %38 = and i32 %37, %18
  %39 = icmp ne i32 %38, %35
  %40 = getelementptr inbounds i8, ptr %5, i64 %32
  %41 = zext i1 %39 to i8
  store i8 %41, ptr %40, align 1, !tbaa !6
  %42 = add nuw nsw i64 %32, 1
  %43 = icmp eq i64 %42, %19
  br i1 %43, label %27, label %31, !llvm.loop !15

44:                                               ; preds = %48, %27
  %45 = icmp sgt i32 %0, 0
  br i1 %45, label %46, label %57

46:                                               ; preds = %44
  %47 = zext nneg i32 %0 to i64
  br label %62

48:                                               ; preds = %29, %48
  %49 = phi i64 [ 0, %29 ], [ %55, %48 ]
  %50 = getelementptr inbounds i8, ptr %4, i64 %49
  %51 = load i8, ptr %50, align 1, !tbaa !6, !range !10, !noundef !11
  %52 = trunc nuw i8 %51 to i1
  %53 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %52, double noundef 0xBFF921FB54442D18) #3
  %54 = zext i1 %53 to i8
  store i8 %54, ptr %50, align 1, !tbaa !6
  %55 = add nuw nsw i64 %49, 1
  %56 = icmp eq i64 %55, %30
  br i1 %56, label %44, label %48, !llvm.loop !16

57:                                               ; preds = %62, %44
  %58 = phi i32 [ 0, %44 ], [ %72, %62 ]
  %59 = icmp sgt i32 %0, 0
  br i1 %59, label %60, label %77

60:                                               ; preds = %57
  %61 = zext nneg i32 %0 to i64
  br label %80

62:                                               ; preds = %46, %62
  %63 = phi i64 [ 0, %46 ], [ %73, %62 ]
  %64 = phi i32 [ 0, %46 ], [ %72, %62 ]
  %65 = getelementptr inbounds i8, ptr %4, i64 %63
  %66 = load i8, ptr %65, align 1, !tbaa !6, !range !10, !noundef !11
  %67 = trunc nuw i8 %66 to i1
  %68 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %67) #4
  %69 = zext i1 %68 to i32
  %70 = trunc nuw nsw i64 %63 to i32
  %71 = shl nuw i32 %69, %70
  %72 = or i32 %71, %64
  %73 = add nuw nsw i64 %63, 1
  %74 = icmp eq i64 %73, %47
  br i1 %74, label %57, label %62, !llvm.loop !17

75:                                               ; preds = %80
  %76 = shl i32 %90, 16
  br label %77

77:                                               ; preds = %75, %57
  %78 = phi i32 [ 0, %57 ], [ %76, %75 ]
  %79 = or i32 %78, %58
  ret i32 %79

80:                                               ; preds = %60, %80
  %81 = phi i64 [ 0, %60 ], [ %91, %80 ]
  %82 = phi i32 [ 0, %60 ], [ %90, %80 ]
  %83 = getelementptr inbounds i8, ptr %5, i64 %81
  %84 = load i8, ptr %83, align 1, !tbaa !6, !range !10, !noundef !11
  %85 = trunc nuw i8 %84 to i1
  %86 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %85) #4
  %87 = zext i1 %86 to i32
  %88 = trunc nuw nsw i64 %81 to i32
  %89 = shl nuw i32 %87, %88
  %90 = or i32 %89, %82
  %91 = add nuw nsw i64 %81, 1
  %92 = icmp eq i64 %91, %61
  br i1 %92, label %75, label %80, !llvm.loop !18
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.cttz.i32(i32, i1 immarg) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
!17 = distinct !{!17, !13, !14}
!18 = distinct !{!18, !13, !14}
