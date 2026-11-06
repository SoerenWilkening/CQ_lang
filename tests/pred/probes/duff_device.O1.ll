; ModuleID = 'duff_device.c'
source_filename = "duff_device.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@s = local_unnamed_addr global [16 x i8] c"\01\02\03\04\05\06\07\08\09\0A\0B\0C\00\00\00\00", align 16
@d = local_unnamed_addr global [16 x i8] zeroinitializer, align 16
@g = local_unnamed_addr global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define range(i32 -1152, 1144) i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #2
  %3 = and i32 %2, 7
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %39, label %5

5:                                                ; preds = %1
  %6 = add nuw nsw i32 %3, 3
  %7 = lshr i32 %6, 2
  %8 = and i32 %2, 3
  switch i32 %8, label %38 [
    i32 0, label %9
    i32 3, label %16
    i32 2, label %23
    i32 1, label %30
  ]

9:                                                ; preds = %5, %30
  %10 = phi ptr [ %36, %30 ], [ @d, %5 ]
  %11 = phi ptr [ %34, %30 ], [ @s, %5 ]
  %12 = phi i32 [ 1, %30 ], [ %7, %5 ]
  %13 = getelementptr inbounds i8, ptr %11, i64 1
  %14 = load i8, ptr %11, align 1, !tbaa !6
  %15 = getelementptr inbounds i8, ptr %10, i64 1
  store i8 %14, ptr %10, align 1, !tbaa !6
  br label %16

16:                                               ; preds = %5, %9
  %17 = phi ptr [ %15, %9 ], [ @d, %5 ]
  %18 = phi ptr [ %13, %9 ], [ @s, %5 ]
  %19 = phi i32 [ %12, %9 ], [ %7, %5 ]
  %20 = getelementptr inbounds i8, ptr %18, i64 1
  %21 = load i8, ptr %18, align 1, !tbaa !6
  %22 = getelementptr inbounds i8, ptr %17, i64 1
  store i8 %21, ptr %17, align 1, !tbaa !6
  br label %23

23:                                               ; preds = %5, %16
  %24 = phi ptr [ %22, %16 ], [ @d, %5 ]
  %25 = phi ptr [ %20, %16 ], [ @s, %5 ]
  %26 = phi i32 [ %19, %16 ], [ %7, %5 ]
  %27 = getelementptr inbounds i8, ptr %25, i64 1
  %28 = load i8, ptr %25, align 1, !tbaa !6
  %29 = getelementptr inbounds i8, ptr %24, i64 1
  store i8 %28, ptr %24, align 1, !tbaa !6
  br label %30

30:                                               ; preds = %5, %23
  %31 = phi ptr [ @d, %5 ], [ %29, %23 ]
  %32 = phi ptr [ @s, %5 ], [ %27, %23 ]
  %33 = phi i32 [ %7, %5 ], [ %26, %23 ]
  %34 = getelementptr inbounds i8, ptr %32, i64 1
  %35 = load i8, ptr %32, align 1, !tbaa !6
  %36 = getelementptr inbounds i8, ptr %31, i64 1
  store i8 %35, ptr %31, align 1, !tbaa !6
  %37 = icmp sgt i32 %33, 1
  br i1 %37, label %9, label %39, !llvm.loop !9

38:                                               ; preds = %5
  unreachable

39:                                               ; preds = %30, %1
  %40 = load i8, ptr @d, align 16, !tbaa !6
  %41 = tail call signext i8 @cq_measure_c(i8 noundef signext %40) #3
  %42 = sext i8 %41 to i32
  %43 = load i8, ptr getelementptr inbounds (i8, ptr @d, i64 1), align 1, !tbaa !6
  %44 = tail call signext i8 @cq_measure_c(i8 noundef signext %43) #3
  %45 = sext i8 %44 to i32
  %46 = mul nsw i32 %45, 3
  %47 = add nsw i32 %46, %42
  %48 = load i8, ptr getelementptr inbounds (i8, ptr @d, i64 4), align 4, !tbaa !6
  %49 = tail call signext i8 @cq_measure_c(i8 noundef signext %48) #3
  %50 = sext i8 %49 to i32
  %51 = mul nsw i32 %50, 5
  %52 = add nsw i32 %47, %51
  ret i32 %52
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare signext i8 @cq_measure_c(i8 noundef signext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
