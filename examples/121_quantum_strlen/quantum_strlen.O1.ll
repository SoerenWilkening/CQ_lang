; ModuleID = 'quantum_strlen.c'
source_filename = "quantum_strlen.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @quantum_strlen(ptr nocapture noundef readonly %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #3
  store i32 0, ptr %3, align 4
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = zext nneg i32 %1 to i64
  br label %11

7:                                                ; preds = %11, %2
  %8 = icmp sgt i32 %1, 0
  br i1 %8, label %9, label %29

9:                                                ; preds = %7
  %10 = zext nneg i32 %1 to i64
  br label %19

11:                                               ; preds = %5, %11
  %12 = phi i64 [ 0, %5 ], [ %17, %11 ]
  %13 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %12
  store i8 97, ptr %13, align 1, !tbaa !6
  %14 = getelementptr inbounds double, ptr %0, i64 %12
  %15 = load double, ptr %14, align 8, !tbaa !9
  %16 = tail call signext i8 @cq_theta_c(i8 noundef signext 97, double noundef %15) #4
  store i8 %16, ptr %13, align 1, !tbaa !6
  %17 = add nuw nsw i64 %12, 1
  %18 = icmp eq i64 %17, %6
  br i1 %18, label %7, label %11, !llvm.loop !11

19:                                               ; preds = %9, %24
  %20 = phi i64 [ 0, %9 ], [ %25, %24 ]
  %21 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %20
  %22 = load i8, ptr %21, align 1, !tbaa !6
  %23 = icmp eq i8 %22, 0
  br i1 %23, label %27, label %24

24:                                               ; preds = %19
  %25 = add nuw nsw i64 %20, 1
  %26 = icmp eq i64 %25, %10
  br i1 %26, label %29, label %19, !llvm.loop !14

27:                                               ; preds = %19
  %28 = trunc nuw nsw i64 %20 to i32
  br label %29

29:                                               ; preds = %27, %24, %7
  %30 = phi i32 [ 0, %7 ], [ %28, %27 ], [ %1, %24 ]
  %31 = tail call i32 @cq_measure_si32(i32 noundef %30) #3
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #3
  ret i32 %31
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @quantum_strcmp(ptr nocapture noundef readonly %0, ptr nocapture noundef readonly %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i8], align 4
  %5 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #3
  store i32 0, ptr %4, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #3
  store i32 0, ptr %5, align 4
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  %8 = zext nneg i32 %2 to i64
  br label %13

9:                                                ; preds = %13, %3
  %10 = icmp sgt i32 %2, 0
  br i1 %10, label %11, label %43

11:                                               ; preds = %9
  %12 = zext nneg i32 %2 to i64
  br label %28

13:                                               ; preds = %7, %13
  %14 = phi i64 [ 0, %7 ], [ %23, %13 ]
  %15 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %14
  store i8 97, ptr %15, align 1, !tbaa !6
  %16 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %14
  store i8 97, ptr %16, align 1, !tbaa !6
  %17 = getelementptr inbounds double, ptr %0, i64 %14
  %18 = load double, ptr %17, align 8, !tbaa !9
  %19 = tail call signext i8 @cq_theta_c(i8 noundef signext 97, double noundef %18) #4
  store i8 %19, ptr %16, align 1, !tbaa !6
  %20 = getelementptr inbounds double, ptr %1, i64 %14
  %21 = load double, ptr %20, align 8, !tbaa !9
  %22 = tail call signext i8 @cq_theta_c(i8 noundef signext 97, double noundef %21) #4
  store i8 %22, ptr %15, align 1, !tbaa !6
  %23 = add nuw nsw i64 %14, 1
  %24 = icmp eq i64 %23, %8
  br i1 %24, label %9, label %13, !llvm.loop !15

25:                                               ; preds = %33
  %26 = add nuw nsw i64 %29, 1
  %27 = icmp eq i64 %26, %12
  br i1 %27, label %43, label %28, !llvm.loop !16

28:                                               ; preds = %11, %25
  %29 = phi i64 [ 0, %11 ], [ %26, %25 ]
  %30 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %29
  %31 = load i8, ptr %30, align 1, !tbaa !6
  %32 = icmp eq i8 %31, 0
  br i1 %32, label %37, label %33

33:                                               ; preds = %28
  %34 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %29
  %35 = load i8, ptr %34, align 1, !tbaa !6
  %36 = icmp eq i8 %31, %35
  br i1 %36, label %25, label %37

37:                                               ; preds = %33, %28
  %38 = sext i8 %31 to i32
  %39 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %29
  %40 = load i8, ptr %39, align 1, !tbaa !6
  %41 = sext i8 %40 to i32
  %42 = sub nsw i32 %38, %41
  br label %43

43:                                               ; preds = %25, %9, %37
  %44 = phi i32 [ %42, %37 ], [ 0, %9 ], [ 0, %25 ]
  %45 = tail call i32 @cq_measure_si32(i32 noundef %44) #3
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #3
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #3
  ret i32 %45
}

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
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!10, !10, i64 0}
!10 = !{!"double", !7, i64 0}
!11 = distinct !{!11, !12, !13}
!12 = !{!"llvm.loop.mustprogress"}
!13 = !{!"llvm.loop.unroll.disable"}
!14 = distinct !{!14, !12, !13}
!15 = distinct !{!15, !12, !13}
!16 = distinct !{!16, !12, !13}
