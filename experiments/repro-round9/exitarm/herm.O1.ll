; ModuleID = 'herm.c'
source_filename = "herm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(argmem: write) uwtable
define range(i32 0, 5) i32 @hermc(i32 noundef %0, i32 noundef %1, double noundef %2, ptr nocapture noundef writeonly %3) local_unnamed_addr #0 {
  %5 = or i32 %1, %0
  %6 = icmp slt i32 %5, 0
  br i1 %6, label %37, label %7

7:                                                ; preds = %4
  %8 = icmp eq i32 %0, 0
  br i1 %8, label %9, label %34

9:                                                ; preds = %7
  %10 = icmp slt i32 %1, 2
  %11 = tail call double @llvm.fabs.f64(double %2)
  %12 = fcmp ogt double %11, 8.000000e+00
  %13 = or i1 %10, %12
  br i1 %13, label %37, label %14

14:                                               ; preds = %9
  %15 = zext nneg i32 %1 to i64
  br label %16

16:                                               ; preds = %14, %24
  %17 = phi i64 [ 1, %14 ], [ %28, %24 ]
  %18 = phi double [ %2, %14 ], [ %27, %24 ]
  %19 = phi double [ 1.000000e+00, %14 ], [ %18, %24 ]
  %20 = trunc nuw nsw i64 %17 to i32
  %21 = uitofp nneg i32 %20 to double
  %22 = fdiv double 6.400000e+01, %21
  %23 = fcmp ogt double %19, %22
  br i1 %23, label %37, label %24

24:                                               ; preds = %16
  %25 = fneg double %19
  %26 = fmul double %25, %21
  %27 = tail call double @llvm.fmuladd.f64(double %2, double %18, double %26)
  %28 = add nuw nsw i64 %17, 1
  %29 = getelementptr inbounds double, ptr %3, i64 %28
  store double %27, ptr %29, align 8, !tbaa !6
  %30 = icmp uge i64 %28, %15
  %31 = tail call double @llvm.fabs.f64(double %27)
  %32 = fcmp ogt double %31, 8.000000e+00
  %33 = select i1 %30, i1 true, i1 %32
  br i1 %33, label %37, label %16, !llvm.loop !10

34:                                               ; preds = %7
  %35 = icmp slt i32 %1, %0
  %36 = select i1 %35, i32 4, i32 2
  br label %37

37:                                               ; preds = %16, %24, %34, %9, %4
  %38 = phi i32 [ 1, %4 ], [ 0, %9 ], [ %36, %34 ], [ 0, %24 ], [ 0, %16 ]
  ret i32 %38
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 5) i32 @herm(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, double noundef %4, ptr nocapture noundef writeonly %5) local_unnamed_addr #2 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %3) #5
  %8 = tail call double @cq_theta_f64(double noundef %2, double noundef %4) #5
  %9 = tail call i32 @hermc(i32 noundef %7, i32 noundef %1, double noundef %8, ptr noundef %5)
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 5) i32 @herme(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, double noundef %4, ptr nocapture noundef writeonly %5) local_unnamed_addr #2 {
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %3) #5
  %8 = tail call double @cq_theta_f64(double noundef %2, double noundef %4) #5
  %9 = or i32 %7, %1
  %10 = icmp slt i32 %9, 0
  br i1 %10, label %41, label %11

11:                                               ; preds = %6
  %12 = icmp eq i32 %7, 0
  br i1 %12, label %13, label %38

13:                                               ; preds = %11
  %14 = icmp slt i32 %1, 2
  %15 = tail call double @llvm.fabs.f64(double %8)
  %16 = fcmp ogt double %15, 8.000000e+00
  %17 = select i1 %14, i1 true, i1 %16
  br i1 %17, label %41, label %18

18:                                               ; preds = %13
  %19 = zext nneg i32 %1 to i64
  br label %20

20:                                               ; preds = %18, %28
  %21 = phi i64 [ 1, %18 ], [ %32, %28 ]
  %22 = phi double [ %8, %18 ], [ %31, %28 ]
  %23 = phi double [ 1.000000e+00, %18 ], [ %22, %28 ]
  %24 = trunc nuw nsw i64 %21 to i32
  %25 = uitofp nneg i32 %24 to double
  %26 = fdiv double 6.400000e+01, %25
  %27 = fcmp ogt double %23, %26
  br i1 %27, label %41, label %28

28:                                               ; preds = %20
  %29 = fneg double %23
  %30 = fmul double %29, %25
  %31 = tail call double @llvm.fmuladd.f64(double %8, double %22, double %30)
  %32 = add nuw nsw i64 %21, 1
  %33 = getelementptr inbounds double, ptr %5, i64 %32
  store double %31, ptr %33, align 8, !tbaa !6
  %34 = icmp uge i64 %32, %19
  %35 = tail call double @llvm.fabs.f64(double %31)
  %36 = fcmp ogt double %35, 8.000000e+00
  %37 = select i1 %34, i1 true, i1 %36
  br i1 %37, label %41, label %20, !llvm.loop !13

38:                                               ; preds = %11
  %39 = icmp sgt i32 %7, %1
  %40 = select i1 %39, i32 4, i32 2
  br label %41

41:                                               ; preds = %20, %28, %38, %13, %6
  %42 = phi i32 [ 1, %6 ], [ 0, %13 ], [ %40, %38 ], [ 0, %28 ], [ 0, %20 ]
  ret i32 %42
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #4

attributes #0 = { nofree noinline norecurse nosync nounwind ssp memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
