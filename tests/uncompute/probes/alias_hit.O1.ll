; ModuleID = 'alias_hit.c'
source_filename = "alias_hit.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ah_loop(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = and i32 %0, 3
  %6 = add nuw nsw i32 %5, 1
  %7 = and i32 %1, 7
  %8 = zext nneg i32 %6 to i64
  %9 = alloca i8, i64 %8, align 16
  %10 = alloca i8, i64 %8, align 16
  %11 = and i32 %0, 3
  %12 = add nuw nsw i32 %11, 1
  %13 = zext nneg i32 %12 to i64
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(1) %9, i8 0, i64 %13, i1 false), !tbaa !6
  %14 = and i32 %0, 3
  %15 = add nuw nsw i32 %14, 1
  %16 = zext nneg i32 %15 to i64
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(1) %10, i8 0, i64 %16, i1 false), !tbaa !6
  %17 = add nuw nsw i32 %5, 1
  %18 = zext nneg i32 %17 to i64
  br label %24

19:                                               ; preds = %24
  %20 = urem i32 %7, %6
  %21 = zext nneg i32 %20 to i64
  %22 = getelementptr inbounds i8, ptr %9, i64 %21
  %23 = zext nneg i32 %17 to i64
  br label %38

24:                                               ; preds = %4, %24
  %25 = phi i64 [ 0, %4 ], [ %36, %24 ]
  %26 = getelementptr inbounds i8, ptr %9, i64 %25
  %27 = load i8, ptr %26, align 1, !tbaa !6, !range !10, !noundef !11
  %28 = trunc nuw i8 %27 to i1
  %29 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %28, double noundef %2) #3
  %30 = zext i1 %29 to i8
  store i8 %30, ptr %26, align 1, !tbaa !6
  %31 = getelementptr inbounds i8, ptr %10, i64 %25
  %32 = load i8, ptr %31, align 1, !tbaa !6, !range !10, !noundef !11
  %33 = trunc nuw i8 %32 to i1
  %34 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %33, double noundef %2) #3
  %35 = zext i1 %34 to i8
  store i8 %35, ptr %31, align 1, !tbaa !6
  %36 = add nuw nsw i64 %25, 1
  %37 = icmp eq i64 %36, %18
  br i1 %37, label %19, label %24, !llvm.loop !12

38:                                               ; preds = %19, %51
  %39 = phi i64 [ 0, %19 ], [ %52, %51 ]
  %40 = getelementptr inbounds i8, ptr %9, i64 %39
  %41 = load i8, ptr %40, align 1, !tbaa !6, !range !10, !noundef !11
  %42 = getelementptr inbounds i8, ptr %10, i64 %39
  %43 = load i8, ptr %42, align 1, !tbaa !6, !range !10, !noundef !11
  %44 = and i8 %43, %41
  %45 = icmp eq i8 %44, 0
  store i8 0, ptr %22, align 1, !tbaa !6
  %46 = load i8, ptr %40, align 1, !tbaa !6, !range !10, !noundef !11
  %47 = trunc nuw i8 %46 to i1
  %48 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %47, double noundef %2) #3
  %49 = zext i1 %48 to i8
  store i8 %49, ptr %40, align 1, !tbaa !6
  br i1 %45, label %51, label %50

50:                                               ; preds = %38
  tail call void @cq_phi(double noundef %3) #4
  br label %51

51:                                               ; preds = %50, %38
  %52 = add nuw nsw i64 %39, 1
  %53 = icmp eq i64 %52, %23
  br i1 %53, label %54, label %38, !llvm.loop !15

54:                                               ; preds = %51
  %55 = zext nneg i32 %17 to i64
  br label %57

56:                                               ; preds = %57
  ret i32 %71

57:                                               ; preds = %54, %57
  %58 = phi i64 [ 0, %54 ], [ %72, %57 ]
  %59 = phi i32 [ 0, %54 ], [ %71, %57 ]
  %60 = getelementptr inbounds i8, ptr %9, i64 %58
  %61 = load i8, ptr %60, align 1, !tbaa !6, !range !10, !noundef !11
  %62 = trunc nuw i8 %61 to i1
  %63 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %62) #4
  %64 = zext i1 %63 to i32
  %65 = getelementptr inbounds i8, ptr %10, i64 %58
  %66 = load i8, ptr %65, align 1, !tbaa !6, !range !10, !noundef !11
  %67 = trunc nuw i8 %66 to i1
  %68 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %67) #4
  %69 = zext i1 %68 to i32
  %70 = add nuw nsw i32 %59, %64
  %71 = add nuw nsw i32 %70, %69
  %72 = add nuw nsw i64 %58, 1
  %73 = icmp eq i64 %72, %55
  br i1 %73, label %56, label %57, !llvm.loop !16
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @ah_line(i32 noundef %0, i32 noundef %1, i32 noundef %2, double noundef %3, double noundef %4) local_unnamed_addr #0 {
  %6 = and i32 %0, 3
  %7 = add nuw nsw i32 %6, 1
  %8 = and i32 %2, 7
  %9 = urem i32 %8, %7
  %10 = and i32 %1, 7
  %11 = urem i32 %10, %7
  %12 = zext nneg i32 %7 to i64
  %13 = alloca i8, i64 %12, align 16
  %14 = zext nneg i32 %11 to i64
  %15 = getelementptr inbounds i8, ptr %13, i64 %14
  store i8 0, ptr %15, align 1, !tbaa !6
  %16 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %3) #3
  %17 = zext i1 %16 to i8
  store i8 %17, ptr %15, align 1, !tbaa !6
  %18 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %3) #3
  %19 = and i1 %16, %18
  %20 = zext nneg i32 %9 to i64
  %21 = getelementptr inbounds i8, ptr %13, i64 %20
  store i8 0, ptr %21, align 1, !tbaa !6
  %22 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %23 = trunc nuw i8 %22 to i1
  %24 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %23, double noundef %3) #3
  %25 = zext i1 %24 to i8
  store i8 %25, ptr %15, align 1, !tbaa !6
  br i1 %19, label %26, label %27

26:                                               ; preds = %5
  tail call void @cq_phi(double noundef %4) #4
  br label %27

27:                                               ; preds = %26, %5
  %28 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %24) #4
  %29 = zext i1 %28 to i32
  %30 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %18) #4
  %31 = zext i1 %30 to i32
  %32 = add nuw nsw i32 %31, %29
  ret i32 %32
}

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
