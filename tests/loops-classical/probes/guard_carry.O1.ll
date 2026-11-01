; ModuleID = 'tests/loops-classical/probes/guard_carry.c'
source_filename = "tests/loops-classical/probes/guard_carry.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @g_carry(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = zext i32 %0 to i64
  %5 = alloca i8, i64 %4, align 16
  %6 = icmp sgt i32 %0, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  %8 = zext nneg i32 %0 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %5, i8 0, i64 %8, i1 false), !tbaa !6
  br label %9

9:                                                ; preds = %7, %3
  %10 = icmp sgt i32 %0, 0
  br i1 %10, label %11, label %13

11:                                               ; preds = %9
  %12 = zext nneg i32 %0 to i64
  br label %17

13:                                               ; preds = %17, %9
  %14 = icmp sgt i32 %0, 0
  br i1 %14, label %15, label %28

15:                                               ; preds = %13
  %16 = zext nneg i32 %0 to i64
  br label %34

17:                                               ; preds = %11, %17
  %18 = phi i64 [ 0, %11 ], [ %24, %17 ]
  %19 = getelementptr inbounds i8, ptr %5, i64 %18
  %20 = load i8, ptr %19, align 1, !tbaa !6, !range !10, !noundef !11
  %21 = trunc nuw i8 %20 to i1
  %22 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %21, double noundef %2) #3
  %23 = zext i1 %22 to i8
  store i8 %23, ptr %19, align 1, !tbaa !6
  %24 = add nuw nsw i64 %18, 1
  %25 = icmp eq i64 %24, %12
  br i1 %25, label %13, label %17, !llvm.loop !12

26:                                               ; preds = %34
  %27 = sitofp i32 %42 to double
  br label %28

28:                                               ; preds = %26, %13
  %29 = phi double [ 0.000000e+00, %13 ], [ %27, %26 ]
  %30 = icmp sgt i32 %1, 0
  br i1 %30, label %31, label %45

31:                                               ; preds = %28
  %32 = load i8, ptr %5, align 16, !tbaa !6, !range !10, !noundef !11
  %33 = trunc nuw i8 %32 to i1
  br label %49

34:                                               ; preds = %15, %34
  %35 = phi i64 [ 0, %15 ], [ %43, %34 ]
  %36 = phi i32 [ 0, %15 ], [ %42, %34 ]
  %37 = getelementptr inbounds i8, ptr %5, i64 %35
  %38 = load i8, ptr %37, align 1, !tbaa !6, !range !10, !noundef !11
  %39 = zext nneg i8 %38 to i32
  %40 = trunc nuw nsw i64 %35 to i32
  %41 = shl nuw i32 %39, %40
  %42 = or i32 %41, %36
  %43 = add nuw nsw i64 %35, 1
  %44 = icmp eq i64 %43, %16
  br i1 %44, label %26, label %34, !llvm.loop !15

45:                                               ; preds = %55, %28
  %46 = icmp sgt i32 %0, 0
  br i1 %46, label %47, label %58

47:                                               ; preds = %45
  %48 = zext nneg i32 %0 to i64
  br label %60

49:                                               ; preds = %31, %55
  %50 = phi i32 [ 0, %31 ], [ %56, %55 ]
  br i1 %33, label %51, label %55

51:                                               ; preds = %49
  %52 = shl nuw i32 1, %50
  %53 = sitofp i32 %52 to double
  %54 = fmul double %29, %53
  tail call void @cq_phi(double noundef %54) #4
  br label %55

55:                                               ; preds = %49, %51
  %56 = add nuw nsw i32 %50, 1
  %57 = icmp eq i32 %56, %1
  br i1 %57, label %45, label %49, !llvm.loop !16

58:                                               ; preds = %60, %45
  %59 = phi i32 [ 0, %45 ], [ %70, %60 ]
  ret i32 %59

60:                                               ; preds = %47, %60
  %61 = phi i64 [ 0, %47 ], [ %71, %60 ]
  %62 = phi i32 [ 0, %47 ], [ %70, %60 ]
  %63 = getelementptr inbounds i8, ptr %5, i64 %61
  %64 = load i8, ptr %63, align 1, !tbaa !6, !range !10, !noundef !11
  %65 = trunc nuw i8 %64 to i1
  %66 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %65) #4
  %67 = zext i1 %66 to i32
  %68 = trunc nuw nsw i64 %61 to i32
  %69 = shl nuw i32 %67, %68
  %70 = or i32 %69, %62
  %71 = add nuw nsw i64 %61, 1
  %72 = icmp eq i64 %71, %48
  br i1 %72, label %58, label %60, !llvm.loop !17
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }
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
