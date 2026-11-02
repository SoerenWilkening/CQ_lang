; ModuleID = 'trip_ctl.c'
source_filename = "trip_ctl.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%u\0A\00", align 1

; Function Attrs: noinline nounwind ssp uwtable
define void @tc_phase(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 1
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %5, label %4

4:                                                ; preds = %1
  tail call void @cq_phi(double noundef 0x3FE6666666666666) #6
  br label %5

5:                                                ; preds = %4, %1
  ret void
}

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef i32 @tc_mix(i32 noundef %0) local_unnamed_addr #2 {
  %2 = mul i32 %0, 5
  %3 = add i32 %2, 1
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i64 @tk_decl(double noundef %0, double noundef %1) local_unnamed_addr #3 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #7
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi double [ %3, %2 ], [ %9, %4 ]
  %6 = phi double [ 0.000000e+00, %2 ], [ %8, %4 ]
  %7 = tail call double @erf(double noundef %5) #8
  %8 = fadd double %6, %7
  %9 = fmul double %5, 5.000000e-01
  %10 = fcmp ogt double %9, 1.000000e+00
  br i1 %10, label %4, label %11, !llvm.loop !6

11:                                               ; preds = %4
  %12 = tail call double @cq_measure_f64(double noundef %8) #6
  %13 = fmul double %12, 1.024000e+03
  %14 = fptosi double %13 to i64
  ret i64 %14
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare double @erf(double noundef) local_unnamed_addr #4

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i64 @tk_decl_arm(double noundef %0, double noundef %1) local_unnamed_addr #3 {
  %3 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #7
  br label %4

4:                                                ; preds = %11, %2
  %5 = phi double [ %3, %2 ], [ %13, %11 ]
  %6 = phi double [ 0.000000e+00, %2 ], [ %12, %11 ]
  %7 = fcmp ogt double %5, 3.000000e+00
  br i1 %7, label %8, label %11

8:                                                ; preds = %4
  %9 = tail call double @cbrt(double noundef %5) #8
  %10 = fadd double %6, %9
  br label %11

11:                                               ; preds = %8, %4
  %12 = phi double [ %10, %8 ], [ %6, %4 ]
  %13 = fmul double %5, 5.000000e-01
  %14 = fcmp ogt double %13, 1.000000e+00
  br i1 %14, label %4, label %15, !llvm.loop !9

15:                                               ; preds = %11
  %16 = tail call double @cq_measure_f64(double noundef %12) #6
  %17 = fmul double %16, 1.024000e+03
  %18 = fptosi double %17 to i64
  ret i64 %18
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare double @cbrt(double noundef) local_unnamed_addr #4

; Function Attrs: nounwind ssp uwtable
define i32 @tk_lift(i32 noundef %0, double noundef %1) local_unnamed_addr #3 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #7
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %10, %4 ]
  %6 = phi i32 [ 0, %2 ], [ %9, %4 ]
  %7 = and i32 %5, 7
  %8 = tail call i32 @tc_mix(i32 noundef %7)
  %9 = add i32 %8, %6
  tail call void @tc_phase(i32 noundef %5)
  %10 = lshr i32 %5, 1
  %11 = icmp ult i32 %5, 2
  br i1 %11, label %12, label %4, !llvm.loop !10

12:                                               ; preds = %4
  %13 = tail call i32 @cq_measure_ui32(i32 noundef %9) #6
  ret i32 %13
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @tk_print(i32 noundef %0, double noundef %1) local_unnamed_addr #3 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #7
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = and i32 %5, 3
  %7 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %6)
  %8 = lshr i32 %5, 1
  %9 = icmp ult i32 %5, 2
  br i1 %9, label %10, label %4, !llvm.loop !11

10:                                               ; preds = %4
  %11 = tail call i32 @cq_measure_ui32(i32 noundef 0) #6
  ret i32 %11
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #5

; Function Attrs: nounwind ssp uwtable
define i64 @t3_decl(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #3 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #7
  %5 = icmp sgt i32 %2, 0
  %6 = fcmp ogt double %4, 1.000000e+00
  %7 = select i1 %5, i1 %6, i1 false
  br i1 %7, label %13, label %8

8:                                                ; preds = %13, %3
  %9 = phi double [ 0.000000e+00, %3 ], [ %18, %13 ]
  %10 = tail call double @cq_measure_f64(double noundef %9) #6
  %11 = fmul double %10, 1.024000e+03
  %12 = fptosi double %11 to i64
  ret i64 %12

13:                                               ; preds = %3, %13
  %14 = phi i32 [ %20, %13 ], [ 0, %3 ]
  %15 = phi double [ %18, %13 ], [ 0.000000e+00, %3 ]
  %16 = phi double [ %19, %13 ], [ %4, %3 ]
  %17 = tail call double @erf(double noundef %16) #8
  %18 = fadd double %15, %17
  %19 = fmul double %16, 5.000000e-01
  %20 = add nuw nsw i32 %14, 1
  %21 = icmp slt i32 %20, %2
  %22 = fcmp ogt double %19, 1.000000e+00
  %23 = and i1 %21, %22
  br i1 %23, label %13, label %8, !llvm.loop !12
}

; Function Attrs: nounwind ssp uwtable
define i32 @t3_lift(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #3 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #7
  %5 = icmp sgt i32 %2, 0
  %6 = icmp ne i32 %4, 0
  %7 = select i1 %5, i1 %6, i1 false
  br i1 %7, label %11, label %8

8:                                                ; preds = %11, %3
  %9 = phi i32 [ 0, %3 ], [ %17, %11 ]
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #6
  ret i32 %10

11:                                               ; preds = %3, %11
  %12 = phi i32 [ %19, %11 ], [ 0, %3 ]
  %13 = phi i32 [ %17, %11 ], [ 0, %3 ]
  %14 = phi i32 [ %18, %11 ], [ %4, %3 ]
  %15 = and i32 %14, 7
  %16 = tail call i32 @tc_mix(i32 noundef %15)
  %17 = add i32 %16, %13
  tail call void @tc_phase(i32 noundef %14)
  %18 = lshr i32 %14, 1
  %19 = add nuw nsw i32 %12, 1
  %20 = icmp slt i32 %19, %2
  %21 = icmp ugt i32 %14, 1
  %22 = and i1 %20, %21
  br i1 %22, label %11, label %8, !llvm.loop !13
}

; Function Attrs: nounwind ssp uwtable
define i64 @t3_arm(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #3 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #7
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %6, label %18

6:                                                ; preds = %3, %14
  %7 = phi i32 [ %16, %14 ], [ 0, %3 ]
  %8 = phi double [ %15, %14 ], [ %4, %3 ]
  %9 = fcmp olt double %8, 2.000000e+00
  br i1 %9, label %10, label %14

10:                                               ; preds = %6
  tail call void @tc_phase(i32 noundef %7)
  %11 = tail call double @erf(double noundef %8) #8
  %12 = uitofp nneg i32 %7 to double
  %13 = fadd double %11, %12
  br label %18

14:                                               ; preds = %6
  %15 = fmul double %8, 5.000000e-01
  %16 = add nuw nsw i32 %7, 1
  %17 = icmp eq i32 %16, %2
  br i1 %17, label %18, label %6, !llvm.loop !14

18:                                               ; preds = %14, %3, %10
  %19 = phi double [ %13, %10 ], [ -1.000000e+00, %3 ], [ -1.000000e+00, %14 ]
  %20 = tail call double @cq_measure_f64(double noundef %19) #6
  %21 = fmul double %20, 1.024000e+03
  %22 = fptosi double %21 to i64
  ret i64 %22
}

; Function Attrs: nounwind ssp uwtable
define i64 @t1_decl(double noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #3 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #7
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %11, label %6

6:                                                ; preds = %11, %3
  %7 = phi double [ 0.000000e+00, %3 ], [ %17, %11 ]
  %8 = tail call double @cq_measure_f64(double noundef %7) #6
  %9 = fmul double %8, 1.024000e+03
  %10 = fptosi double %9 to i64
  ret i64 %10

11:                                               ; preds = %3, %11
  %12 = phi i32 [ %18, %11 ], [ 0, %3 ]
  %13 = phi double [ %17, %11 ], [ 0.000000e+00, %3 ]
  %14 = uitofp nneg i32 %12 to double
  %15 = fadd double %4, %14
  %16 = tail call double @erf(double noundef %15) #8
  %17 = fadd double %13, %16
  %18 = add nuw nsw i32 %12, 1
  %19 = icmp eq i32 %18, %2
  br i1 %19, label %6, label %11, !llvm.loop !15
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }
attributes #8 = { nounwind willreturn memory(none) }

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
!12 = distinct !{!12, !7, !8}
!13 = distinct !{!13, !7, !8}
!14 = distinct !{!14, !7, !8}
!15 = distinct !{!15, !7, !8}
