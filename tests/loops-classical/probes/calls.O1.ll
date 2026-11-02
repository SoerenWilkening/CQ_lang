; ModuleID = 'calls.c'
source_filename = "calls.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef i32 @lc_f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul i32 %0, %0
  %3 = add i32 %2, 3
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @lc_call(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %9, label %6

6:                                                ; preds = %9, %3
  %7 = phi i32 [ 0, %3 ], [ %14, %9 ]
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #5
  ret i32 %8

9:                                                ; preds = %3, %9
  %10 = phi i32 [ %15, %9 ], [ 0, %3 ]
  %11 = phi i32 [ %14, %9 ], [ 0, %3 ]
  %12 = add i32 %10, %4
  %13 = tail call i32 @lc_f(i32 noundef %12)
  %14 = add i32 %13, %11
  %15 = add nuw nsw i32 %10, 1
  %16 = icmp eq i32 %15, %2
  br i1 %16, label %6, label %9, !llvm.loop !6
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define double @lc_libm(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %9, label %6

6:                                                ; preds = %9, %3
  %7 = phi double [ 0.000000e+00, %3 ], [ %18, %9 ]
  %8 = tail call double @cq_measure_f64(double noundef %7) #5
  ret double %8

9:                                                ; preds = %3, %9
  %10 = phi i32 [ %19, %9 ], [ 0, %3 ]
  %11 = phi double [ %18, %9 ], [ 0.000000e+00, %3 ]
  %12 = uitofp nneg i32 %10 to double
  %13 = fsub double %4, %12
  %14 = tail call double @llvm.fabs.f64(double %13)
  %15 = tail call double @llvm.fmuladd.f64(double %4, double %4, double %12)
  %16 = tail call double @llvm.sqrt.f64(double %15)
  %17 = fadd double %14, %16
  %18 = fadd double %11, %17
  %19 = add nuw nsw i32 %10, 1
  %20 = icmp eq i32 %19, %2
  br i1 %20, label %6, label %9, !llvm.loop !9
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.sqrt.f64(double) #3

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @lc_chain(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %9, label %6

6:                                                ; preds = %9, %3
  %7 = phi i32 [ %4, %3 ], [ %13, %9 ]
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #5
  ret i32 %8

9:                                                ; preds = %3, %9
  %10 = phi i32 [ %14, %9 ], [ 0, %3 ]
  %11 = phi i32 [ %13, %9 ], [ %4, %3 ]
  %12 = tail call i32 @lc_f(i32 noundef %11)
  %13 = xor i32 %12, %10
  %14 = add nuw nsw i32 %10, 1
  %15 = icmp eq i32 %14, %2
  br i1 %15, label %6, label %9, !llvm.loop !10
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !7, !8}
!10 = distinct !{!10, !7, !8}
