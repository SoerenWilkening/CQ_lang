; ModuleID = 'controlled_ry_bits.c'
source_filename = "controlled_ry_bits.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @controlled_ry_chain(ptr nocapture noundef readonly %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = zext i32 %1 to i64
  %5 = alloca i8, i64 %4, align 16
  %6 = icmp sgt i32 %1, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  %8 = zext nneg i32 %1 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %5, i8 0, i64 %8, i1 false), !tbaa !6
  br label %9

9:                                                ; preds = %7, %3
  %10 = icmp sgt i32 %1, 0
  br i1 %10, label %11, label %13

11:                                               ; preds = %9
  %12 = zext nneg i32 %1 to i64
  br label %18

13:                                               ; preds = %18, %9
  %14 = icmp sgt i32 %1, 1
  br i1 %14, label %15, label %29

15:                                               ; preds = %13
  %16 = add nsw i32 %1, -1
  %17 = zext i32 %16 to i64
  br label %42

18:                                               ; preds = %11, %18
  %19 = phi i64 [ 0, %11 ], [ %27, %18 ]
  %20 = getelementptr inbounds i8, ptr %5, i64 %19
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = trunc nuw i8 %21 to i1
  %23 = getelementptr inbounds double, ptr %0, i64 %19
  %24 = load double, ptr %23, align 8, !tbaa !12
  %25 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %22, double noundef %24) #3
  %26 = zext i1 %25 to i8
  store i8 %26, ptr %20, align 1, !tbaa !6
  %27 = add nuw nsw i64 %19, 1
  %28 = icmp eq i64 %27, %12
  br i1 %28, label %13, label %18, !llvm.loop !14

29:                                               ; preds = %54, %13
  %30 = load i8, ptr %5, align 16, !tbaa !6, !range !10, !noundef !11
  %31 = trunc nuw i8 %30 to i1
  %32 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %31) #4
  %33 = zext i1 %32 to i32
  %34 = sext i32 %1 to i64
  %35 = getelementptr i8, ptr %5, i64 %34
  %36 = getelementptr i8, ptr %35, i64 -1
  %37 = load i8, ptr %36, align 1, !tbaa !6, !range !10, !noundef !11
  %38 = trunc nuw i8 %37 to i1
  %39 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %38) #4
  %40 = zext i1 %39 to i32
  %41 = add nuw nsw i32 %40, %33
  ret i32 %41

42:                                               ; preds = %15, %54
  %43 = phi i64 [ 0, %15 ], [ %56, %54 ]
  %44 = phi i64 [ 1, %15 ], [ %55, %54 ]
  %45 = getelementptr inbounds i8, ptr %5, i64 %43
  %46 = load i8, ptr %45, align 1, !tbaa !6, !range !10, !noundef !11
  %47 = trunc nuw i8 %46 to i1
  br i1 %47, label %48, label %54

48:                                               ; preds = %42
  %49 = getelementptr inbounds i8, ptr %5, i64 %44
  %50 = load i8, ptr %49, align 1, !tbaa !6, !range !10, !noundef !11
  %51 = trunc nuw i8 %50 to i1
  %52 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %51, double noundef %2) #3
  %53 = zext i1 %52 to i8
  store i8 %53, ptr %49, align 1, !tbaa !6
  br label %54

54:                                               ; preds = %42, %48
  %55 = add nuw nsw i64 %44, 1
  %56 = add nuw nsw i64 %43, 1
  %57 = icmp eq i64 %56, %17
  br i1 %57, label %29, label %42, !llvm.loop !17
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 4) i32 @controlled_ry_two(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %0) #3
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %1) #3
  %6 = select i1 %4, i1 %5, i1 false
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %2) #3
  br label %9

9:                                                ; preds = %3, %7
  %10 = phi i1 [ %8, %7 ], [ false, %3 ]
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #4
  %12 = zext i1 %11 to i32
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #4
  %14 = zext i1 %13 to i32
  %15 = add nuw nsw i32 %14, %12
  %16 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10) #4
  %17 = zext i1 %16 to i32
  %18 = add nuw nsw i32 %15, %17
  ret i32 %18
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
!12 = !{!13, !13, i64 0}
!13 = !{!"double", !8, i64 0}
!14 = distinct !{!14, !15, !16}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!"llvm.loop.unroll.disable"}
!17 = distinct !{!17, !15, !16}
