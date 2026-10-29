; ModuleID = 'slots.c'
source_filename = "slots.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @s_reg(ptr nocapture noundef readonly %0, i32 noundef %1) local_unnamed_addr #0 {
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
  br label %29

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

27:                                               ; preds = %29, %12
  %28 = phi i32 [ 0, %12 ], [ %37, %29 ]
  ret i32 %28

29:                                               ; preds = %14, %29
  %30 = phi i64 [ 0, %14 ], [ %38, %29 ]
  %31 = phi i32 [ 0, %14 ], [ %37, %29 ]
  %32 = getelementptr inbounds i8, ptr %4, i64 %30
  %33 = load i8, ptr %32, align 1, !tbaa !6, !range !10, !noundef !11
  %34 = trunc nuw i8 %33 to i1
  %35 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %34) #4
  %36 = zext i1 %35 to i32
  %37 = add nuw nsw i32 %31, %36
  %38 = add nuw nsw i64 %30, 1
  %39 = icmp eq i64 %38, %15
  br i1 %39, label %27, label %29, !llvm.loop !17
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @s_qft(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = zext i32 %0 to i64
  %4 = alloca i8, i64 %3, align 16
  %5 = icmp sgt i32 %0, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %2
  %7 = zext nneg i32 %0 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %4, i8 0, i64 %7, i1 false), !tbaa !6
  br label %8

8:                                                ; preds = %6, %2
  %9 = icmp sgt i32 %0, 0
  br i1 %9, label %10, label %17

10:                                               ; preds = %8
  %11 = zext nneg i32 %0 to i64
  %12 = zext nneg i32 %0 to i64
  %13 = zext nneg i32 %0 to i64
  br label %21

14:                                               ; preds = %43, %21
  %15 = add nuw nsw i64 %23, 1
  %16 = icmp eq i64 %29, %12
  br i1 %16, label %17, label %21, !llvm.loop !18

17:                                               ; preds = %14, %8
  %18 = icmp sgt i32 %0, 0
  br i1 %18, label %19, label %46

19:                                               ; preds = %17
  %20 = zext nneg i32 %0 to i64
  br label %48

21:                                               ; preds = %10, %14
  %22 = phi i64 [ 0, %10 ], [ %29, %14 ]
  %23 = phi i64 [ 1, %10 ], [ %15, %14 ]
  %24 = getelementptr inbounds i8, ptr %4, i64 %22
  %25 = load i8, ptr %24, align 1, !tbaa !6, !range !10, !noundef !11
  %26 = trunc nuw i8 %25 to i1
  %27 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %26, double noundef %1) #3
  %28 = zext i1 %27 to i8
  store i8 %28, ptr %24, align 1, !tbaa !6
  %29 = add nuw nsw i64 %22, 1
  %30 = icmp ult i64 %29, %11
  br i1 %30, label %31, label %14

31:                                               ; preds = %21, %43
  %32 = phi i64 [ %44, %43 ], [ %23, %21 ]
  %33 = getelementptr inbounds i8, ptr %4, i64 %32
  %34 = load i8, ptr %33, align 1, !tbaa !6, !range !10, !noundef !11
  %35 = trunc nuw i8 %34 to i1
  %36 = select i1 %35, i1 %27, i1 false
  br i1 %36, label %37, label %43

37:                                               ; preds = %31
  %38 = sub nuw nsw i64 %32, %22
  %39 = trunc nsw i64 %38 to i32
  %40 = shl nuw i32 1, %39
  %41 = sitofp i32 %40 to double
  %42 = fdiv double %1, %41
  tail call void @cq_phi(double noundef %42) #4
  br label %43

43:                                               ; preds = %31, %37
  %44 = add nuw nsw i64 %32, 1
  %45 = icmp eq i64 %44, %13
  br i1 %45, label %14, label %31, !llvm.loop !19

46:                                               ; preds = %48, %17
  %47 = phi i32 [ 0, %17 ], [ %58, %48 ]
  ret i32 %47

48:                                               ; preds = %19, %48
  %49 = phi i64 [ 0, %19 ], [ %59, %48 ]
  %50 = phi i32 [ 0, %19 ], [ %58, %48 ]
  %51 = getelementptr inbounds i8, ptr %4, i64 %49
  %52 = load i8, ptr %51, align 1, !tbaa !6, !range !10, !noundef !11
  %53 = trunc nuw i8 %52 to i1
  %54 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %53) #4
  %55 = zext i1 %54 to i32
  %56 = trunc nuw nsw i64 %49 to i32
  %57 = shl nuw i32 %55, %56
  %58 = add nsw i32 %57, %50
  %59 = add nuw nsw i64 %49, 1
  %60 = icmp eq i64 %59, %20
  br i1 %60, label %46, label %48, !llvm.loop !20
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @s_int(ptr nocapture noundef readonly %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = zext i32 %1 to i64
  %5 = alloca i32, i64 %4, align 16
  %6 = icmp sgt i32 %1, 0
  br i1 %6, label %7, label %10

7:                                                ; preds = %3
  %8 = zext i32 %2 to i64
  %9 = zext nneg i32 %1 to i64
  br label %15

10:                                               ; preds = %15, %3
  %11 = icmp sgt i32 %1, 1
  br i1 %11, label %12, label %26

12:                                               ; preds = %10
  %13 = add nsw i32 %1, -1
  %14 = zext i32 %13 to i64
  br label %30

15:                                               ; preds = %7, %15
  %16 = phi i64 [ 0, %7 ], [ %24, %15 ]
  %17 = mul i64 %16, %8
  %18 = getelementptr inbounds i32, ptr %5, i64 %16
  %19 = trunc i64 %17 to i32
  store i32 %19, ptr %18, align 4, !tbaa !21
  %20 = getelementptr inbounds double, ptr %0, i64 %16
  %21 = load double, ptr %20, align 8, !tbaa !12
  %22 = trunc i64 %17 to i32
  %23 = tail call i32 @cq_theta_si32(i32 noundef %22, double noundef %21) #3
  store i32 %23, ptr %18, align 4, !tbaa !21
  %24 = add nuw nsw i64 %16, 1
  %25 = icmp eq i64 %24, %9
  br i1 %25, label %10, label %15, !llvm.loop !23

26:                                               ; preds = %41, %10
  %27 = icmp sgt i32 %1, 0
  br i1 %27, label %28, label %45

28:                                               ; preds = %26
  %29 = zext nneg i32 %1 to i64
  br label %47

30:                                               ; preds = %12, %41
  %31 = phi i64 [ 0, %12 ], [ %43, %41 ]
  %32 = phi i64 [ 1, %12 ], [ %42, %41 ]
  %33 = getelementptr inbounds i32, ptr %5, i64 %31
  %34 = load i32, ptr %33, align 4, !tbaa !21
  %35 = getelementptr inbounds i32, ptr %5, i64 %32
  %36 = load i32, ptr %35, align 4, !tbaa !21
  %37 = icmp eq i32 %34, %36
  br i1 %37, label %38, label %41

38:                                               ; preds = %30
  %39 = getelementptr inbounds double, ptr %0, i64 %31
  %40 = load double, ptr %39, align 8, !tbaa !12
  tail call void @cq_phi(double noundef %40) #4
  br label %41

41:                                               ; preds = %30, %38
  %42 = add nuw nsw i64 %32, 1
  %43 = add nuw nsw i64 %31, 1
  %44 = icmp eq i64 %43, %14
  br i1 %44, label %26, label %30, !llvm.loop !24

45:                                               ; preds = %47, %26
  %46 = phi i32 [ 0, %26 ], [ %53, %47 ]
  ret i32 %46

47:                                               ; preds = %28, %47
  %48 = phi i64 [ 0, %28 ], [ %54, %47 ]
  %49 = phi i32 [ 0, %28 ], [ %53, %47 ]
  %50 = getelementptr inbounds i32, ptr %5, i64 %48
  %51 = load i32, ptr %50, align 4, !tbaa !21
  %52 = tail call i32 @cq_measure_si32(i32 noundef %51) #4
  %53 = add nsw i32 %52, %49
  %54 = add nuw nsw i64 %48, 1
  %55 = icmp eq i64 %54, %29
  br i1 %55, label %45, label %47, !llvm.loop !25
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

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
!18 = distinct !{!18, !15, !16}
!19 = distinct !{!19, !15, !16}
!20 = distinct !{!20, !15, !16}
!21 = !{!22, !22, i64 0}
!22 = !{!"int", !8, i64 0}
!23 = distinct !{!23, !15, !16}
!24 = distinct !{!24, !15, !16}
!25 = distinct !{!25, !15, !16}
