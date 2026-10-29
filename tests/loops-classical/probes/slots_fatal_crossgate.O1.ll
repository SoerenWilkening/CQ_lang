; ModuleID = 'slots_fatal_crossgate.c'
source_filename = "slots_fatal_crossgate.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @f_crossgate(ptr nocapture noundef readonly %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %1 to i64
  %4 = alloca i8, i64 %3, align 16
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %2
  %7 = zext nneg i32 %1 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %4, i8 0, i64 %7, i1 false), !tbaa !6
  br label %8

8:                                                ; preds = %6, %2
  %9 = icmp sgt i32 %1, 0
  br i1 %9, label %10, label %12

10:                                               ; preds = %8
  %11 = zext nneg i32 %1 to i64
  br label %16

12:                                               ; preds = %16, %8
  %13 = icmp sgt i32 %1, 0
  br i1 %13, label %14, label %27

14:                                               ; preds = %12
  %15 = zext nneg i32 %1 to i64
  br label %30

16:                                               ; preds = %10, %16
  %17 = phi i64 [ 0, %10 ], [ %25, %16 ]
  %18 = getelementptr inbounds i8, ptr %4, i64 %17
  %19 = load i8, ptr %18, align 1, !tbaa !6, !range !10, !noundef !11
  %20 = trunc nuw i8 %19 to i1
  %21 = getelementptr inbounds double, ptr %0, i64 %17
  %22 = load double, ptr %21, align 8, !tbaa !12
  %23 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %20, double noundef %22) #3
  %24 = zext i1 %23 to i8
  store i8 %24, ptr %18, align 1, !tbaa !6
  %25 = add nuw nsw i64 %17, 1
  %26 = icmp eq i64 %25, %11
  br i1 %26, label %12, label %16, !llvm.loop !14

27:                                               ; preds = %30, %12
  %28 = phi i32 [ 0, %12 ], [ %37, %30 ]
  %29 = tail call i32 @cq_measure_si32(i32 noundef %28) #4
  ret i32 %29

30:                                               ; preds = %14, %30
  %31 = phi i64 [ 0, %14 ], [ %42, %30 ]
  %32 = phi i32 [ 0, %14 ], [ %37, %30 ]
  %33 = getelementptr inbounds i8, ptr %4, i64 %31
  %34 = load i8, ptr %33, align 1, !tbaa !6, !range !10, !noundef !11
  %35 = trunc nuw i8 %34 to i1
  %36 = zext nneg i8 %34 to i32
  %37 = add nuw nsw i32 %32, %36
  %38 = getelementptr inbounds double, ptr %0, i64 %31
  %39 = load double, ptr %38, align 8, !tbaa !12
  %40 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %35, double noundef %39) #3
  %41 = zext i1 %40 to i8
  store i8 %41, ptr %33, align 1, !tbaa !6
  %42 = add nuw nsw i64 %31, 1
  %43 = icmp eq i64 %42, %15
  br i1 %43, label %27, label %30, !llvm.loop !17
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
