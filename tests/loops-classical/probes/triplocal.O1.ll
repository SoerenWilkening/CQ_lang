; ModuleID = 'triplocal.c'
source_filename = "triplocal.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @t_grover(i32 noundef %0, i32 noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca [4 x i8], align 1
  %6 = and i32 %0, 3
  %7 = and i32 %2, 3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #3
  %8 = icmp eq i32 %6, 0
  br i1 %8, label %11, label %9

9:                                                ; preds = %4
  %10 = zext nneg i32 %6 to i64
  br label %19

11:                                               ; preds = %19, %4
  %12 = icmp eq i32 %7, 0
  br i1 %12, label %26, label %13

13:                                               ; preds = %11
  %14 = icmp eq i32 %6, 0
  %15 = zext nneg i32 %6 to i64
  %16 = icmp eq i32 %6, 0
  %17 = fneg double %3
  %18 = zext nneg i32 %6 to i64
  br label %30

19:                                               ; preds = %9, %19
  %20 = phi i64 [ 0, %9 ], [ %24, %19 ]
  %21 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %20
  store i8 0, ptr %21, align 1, !tbaa !6
  %22 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %3) #4
  %23 = zext i1 %22 to i8
  store i8 %23, ptr %21, align 1, !tbaa !6
  %24 = add nuw nsw i64 %20, 1
  %25 = icmp eq i64 %24, %10
  br i1 %25, label %11, label %19, !llvm.loop !10

26:                                               ; preds = %48, %11
  %27 = icmp eq i32 %6, 0
  br i1 %27, label %60, label %28

28:                                               ; preds = %26
  %29 = zext nneg i32 %6 to i64
  br label %62

30:                                               ; preds = %13, %48
  %31 = phi i32 [ 0, %13 ], [ %49, %48 ]
  br i1 %14, label %43, label %32

32:                                               ; preds = %30, %32
  %33 = phi i64 [ %41, %32 ], [ 0, %30 ]
  %34 = phi i32 [ %40, %32 ], [ 0, %30 ]
  %35 = getelementptr inbounds i8, ptr %5, i64 %33
  %36 = load i8, ptr %35, align 1, !tbaa !6, !range !13, !noundef !14
  %37 = zext nneg i8 %36 to i32
  %38 = trunc nuw nsw i64 %33 to i32
  %39 = shl nuw nsw i32 %37, %38
  %40 = or i32 %39, %34
  %41 = add nuw nsw i64 %33, 1
  %42 = icmp eq i64 %41, %15
  br i1 %42, label %43, label %32, !llvm.loop !15

43:                                               ; preds = %32, %30
  %44 = phi i32 [ 0, %30 ], [ %40, %32 ]
  %45 = icmp eq i32 %44, %1
  br i1 %45, label %46, label %47

46:                                               ; preds = %43
  tail call void @cq_phi(double noundef 3.000000e+00) #3
  br label %47

47:                                               ; preds = %46, %43
  br i1 %16, label %48, label %51

48:                                               ; preds = %51, %47
  %49 = add nuw nsw i32 %31, 1
  %50 = icmp eq i32 %49, %7
  br i1 %50, label %26, label %30, !llvm.loop !16

51:                                               ; preds = %47, %51
  %52 = phi i64 [ %58, %51 ], [ 0, %47 ]
  %53 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %52
  %54 = load i8, ptr %53, align 1, !tbaa !6, !range !13, !noundef !14
  %55 = trunc nuw i8 %54 to i1
  %56 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %55, double noundef %17) #4
  %57 = zext i1 %56 to i8
  store i8 %57, ptr %53, align 1, !tbaa !6
  %58 = add nuw nsw i64 %52, 1
  %59 = icmp eq i64 %58, %18
  br i1 %59, label %48, label %51, !llvm.loop !17

60:                                               ; preds = %62, %26
  %61 = phi i32 [ 0, %26 ], [ %72, %62 ]
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #3
  ret i32 %61

62:                                               ; preds = %28, %62
  %63 = phi i64 [ 0, %28 ], [ %73, %62 ]
  %64 = phi i32 [ 0, %28 ], [ %72, %62 ]
  %65 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %63
  %66 = load i8, ptr %65, align 1, !tbaa !6, !range !13, !noundef !14
  %67 = trunc nuw i8 %66 to i1
  %68 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %67) #3
  %69 = zext i1 %68 to i32
  %70 = trunc nuw nsw i64 %63 to i32
  %71 = shl nuw nsw i32 %69, %70
  %72 = or i32 %71, %64
  %73 = add nuw nsw i64 %63, 1
  %74 = icmp eq i64 %73, %29
  br i1 %74, label %60, label %62, !llvm.loop !18
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare void @cq_phi(double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

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
!18 = distinct !{!18, !11, !12}
