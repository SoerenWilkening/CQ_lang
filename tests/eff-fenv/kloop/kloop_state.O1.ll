; ModuleID = 'kloop_state.c'
source_filename = "kloop_state.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @ks_div(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %5 = tail call i32 @feclearexcept(i32 noundef 63) #5
  %6 = and i32 %4, 1
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %15, label %8

8:                                                ; preds = %3, %8
  %9 = phi i32 [ %12, %8 ], [ %4, %3 ]
  %10 = phi double [ %11, %8 ], [ %2, %3 ]
  %11 = tail call double @llvm.experimental.constrained.fdiv.f64(double %10, double 3.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %12 = ashr i32 %9, 1
  %13 = and i32 %9, 2
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %8, !llvm.loop !6

15:                                               ; preds = %8, %3
  %16 = phi double [ %2, %3 ], [ %11, %8 ]
  %17 = tail call i32 @fetestexcept(i32 noundef 32) #5
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #5
  %19 = tail call double @cq_measure_f64(double noundef %16) #5
  %20 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %19, metadata !"fpexcept.strict") #6
  %21 = add nsw i32 %20, %18
  ret i32 %21
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @feclearexcept(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #2

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata) #2

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @ks_raise(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = tail call i32 @feclearexcept(i32 noundef 63) #5
  %5 = and i32 %3, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %15, label %7

7:                                                ; preds = %2, %7
  %8 = phi i32 [ %12, %7 ], [ 0, %2 ]
  %9 = phi i32 [ %11, %7 ], [ %3, %2 ]
  %10 = tail call i32 @feraiseexcept(i32 noundef 8) #5
  %11 = ashr i32 %9, 1
  %12 = add nuw nsw i32 %8, 1
  %13 = and i32 %9, 2
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %7, !llvm.loop !9

15:                                               ; preds = %7, %2
  %16 = phi i32 [ 0, %2 ], [ %12, %7 ]
  %17 = tail call i32 @fetestexcept(i32 noundef 8) #5
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #5
  %19 = tail call i32 @cq_measure_si32(i32 noundef %16) #5
  %20 = add nsw i32 %19, %18
  ret i32 %20
}

declare i32 @feraiseexcept(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @ks_round(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = tail call i32 @fesetround(i32 noundef 0) #5
  %5 = and i32 %3, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %20, label %7

7:                                                ; preds = %2, %7
  %8 = phi i32 [ %14, %7 ], [ %3, %2 ]
  %9 = phi i32 [ %15, %7 ], [ 0, %2 ]
  %10 = and i32 %8, 2
  %11 = icmp eq i32 %10, 0
  %12 = select i1 %11, i32 1024, i32 2048
  %13 = tail call i32 @fesetround(i32 noundef %12) #5
  %14 = ashr i32 %8, 1
  %15 = add nuw nsw i32 %9, 1
  %16 = and i32 %8, 2
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %18, label %7, !llvm.loop !10

18:                                               ; preds = %7
  %19 = shl nsw i32 %15, 4
  br label %20

20:                                               ; preds = %18, %2
  %21 = phi i32 [ 0, %2 ], [ %19, %18 ]
  %22 = tail call i32 @fegetround() #5
  %23 = tail call i32 @fesetround(i32 noundef 0) #5
  %24 = add nsw i32 %22, %21
  %25 = tail call i32 @cq_measure_si32(i32 noundef %24) #5
  ret i32 %25
}

declare i32 @fesetround(i32 noundef) local_unnamed_addr #1

declare i32 @fegetround() local_unnamed_addr #1

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @ks_clone(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %5 = tail call i32 @feclearexcept(i32 noundef 63) #5
  %6 = and i32 %4, 1
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %17, label %8

8:                                                ; preds = %3, %8
  %9 = phi i32 [ %14, %8 ], [ %4, %3 ]
  %10 = phi double [ %13, %8 ], [ %2, %3 ]
  %11 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %9, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %12 = tail call double @llvm.experimental.constrained.fadd.f64(double %10, double %11, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %13 = tail call fastcc double @ks_third(double noundef %12) #6
  %14 = ashr i32 %9, 1
  %15 = and i32 %9, 2
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %17, label %8, !llvm.loop !11

17:                                               ; preds = %8, %3
  %18 = phi double [ %2, %3 ], [ %13, %8 ]
  %19 = tail call i32 @fetestexcept(i32 noundef 32) #5
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #5
  %21 = tail call double @cq_measure_f64(double noundef %18) #5
  %22 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %21, metadata !"fpexcept.strict") #6
  %23 = add nsw i32 %22, %20
  ret i32 %23
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable
define internal fastcc double @ks_third(double noundef %0) unnamed_addr #3 {
  %2 = tail call double @llvm.experimental.constrained.fdiv.f64(double %0, double 3.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  ret double %2
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #2

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @ks_read(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = tail call i32 @feclearexcept(i32 noundef 63) #5
  %5 = and i32 %3, 4
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %2
  %8 = tail call i32 @feraiseexcept(i32 noundef 16) #5
  br label %9

9:                                                ; preds = %7, %2
  %10 = and i32 %3, 1
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %21, label %12

12:                                               ; preds = %9, %12
  %13 = phi i32 [ %18, %12 ], [ 0, %9 ]
  %14 = phi i32 [ %17, %12 ], [ %3, %9 ]
  %15 = ashr i32 %14, 1
  %16 = tail call i32 @fetestexcept(i32 noundef 16) #5
  %17 = add nsw i32 %16, %15
  %18 = add nuw nsw i32 %13, 1
  %19 = and i32 %17, 1
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %21, label %12, !llvm.loop !12

21:                                               ; preds = %12, %9
  %22 = phi i32 [ 0, %9 ], [ %18, %12 ]
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #5
  ret i32 %23
}

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind strictfp }
attributes #5 = { nounwind strictfp }
attributes #6 = { strictfp }

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
