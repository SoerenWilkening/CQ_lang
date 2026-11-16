; ModuleID = 'diff_fb.c'
source_filename = "diff_fb.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @fb_fcmp(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = and i32 %0, 255
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %3, double noundef %1) #3
  %5 = uitofp i32 %4 to double
  %6 = fadd double %5, 5.000000e-01
  %7 = fcmp olt double %6, 1.000000e+02
  br i1 %7, label %8, label %14

8:                                                ; preds = %2, %8
  %9 = phi i32 [ %12, %8 ], [ 0, %2 ]
  %10 = phi double [ %11, %8 ], [ %6, %2 ]
  %11 = tail call double @llvm.fmuladd.f64(double %10, double 3.700000e+00, double 1.000000e+00)
  %12 = add i32 %9, 1
  %13 = fcmp olt double %11, 1.000000e+02
  br i1 %13, label %8, label %14, !llvm.loop !6

14:                                               ; preds = %8, %2
  %15 = phi i32 [ 0, %2 ], [ %12, %8 ]
  %16 = tail call i32 @cq_measure_ui32(i32 noundef %15) #4
  ret i32 %16
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @fb_fenv(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = tail call i32 @feclearexcept(i32 noundef 63) #4
  %5 = and i32 %3, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %17, label %7

7:                                                ; preds = %2, %7
  %8 = phi double [ %10, %7 ], [ 1.000000e+00, %2 ]
  %9 = phi i32 [ %11, %7 ], [ %3, %2 ]
  %10 = fdiv double %8, 3.000000e+00
  %11 = lshr i32 %9, 1
  %12 = and i32 %9, 2
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %7, !llvm.loop !9

14:                                               ; preds = %7
  %15 = fmul double %10, 1.000000e+03
  %16 = fptosi double %15 to i32
  br label %17

17:                                               ; preds = %14, %2
  %18 = phi i32 [ 1000, %2 ], [ %16, %14 ]
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #4
  %20 = tail call i32 @fetestexcept(i32 noundef 32) #4
  %21 = icmp eq i32 %20, 0
  %22 = select i1 %21, i32 0, i32 100000
  %23 = add nsw i32 %22, %19
  ret i32 %23
}

declare i32 @feclearexcept(i32 noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define float @fb_float(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = phi float [ 2.000000e+00, %2 ], [ %7, %4 ]
  %7 = tail call float @llvm.fmuladd.f32(float %6, float %6, float -1.000000e+00)
  %8 = lshr i32 %5, 1
  %9 = and i32 %5, 2
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %4, !llvm.loop !10

11:                                               ; preds = %4
  %12 = tail call float @cq_measure_f32(float noundef %7) #4
  ret float %12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fmuladd.f32(float, float, float) #2

declare float @cq_measure_f32(float noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @fb_conv(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = and i32 %0, 1023
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %3, double noundef %1) #3
  %5 = and i32 %4, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %17, label %7

7:                                                ; preds = %2
  %8 = uitofp i32 %4 to double
  br label %9

9:                                                ; preds = %7, %9
  %10 = phi i32 [ %13, %9 ], [ 0, %7 ]
  %11 = phi double [ %12, %9 ], [ %8, %7 ]
  %12 = fmul double %11, 5.000000e-01
  %13 = add i32 %10, 1
  %14 = fptosi double %12 to i32
  %15 = and i32 %14, 1
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %17, label %9, !llvm.loop !11

17:                                               ; preds = %9, %2
  %18 = phi i32 [ 0, %2 ], [ %13, %9 ]
  %19 = tail call i32 @cq_measure_ui32(i32 noundef %18) #4
  ret i32 %19
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !7, !8}
!10 = distinct !{!10, !7, !8}
!11 = distinct !{!11, !7, !8}
