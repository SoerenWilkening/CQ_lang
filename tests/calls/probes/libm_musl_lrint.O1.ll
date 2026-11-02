; ModuleID = '/tmp/babj/libm_musl_lrint.full.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i64 @f_lrint(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #9
  %3 = tail call i64 @llvm.lrint.i64.f64(double %2)
  %4 = tail call i64 @cq_measure_sl(i64 noundef %3) #10
  ret i64 %4
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.lrint.i64.f64(double) #2

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i64 @f_lround(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #9
  %3 = tail call i64 @llvm.lround.i64.f64(double %2)
  %4 = tail call i64 @cq_measure_sl(i64 noundef %3) #10
  ret i64 %4
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.lround.i64.f64(double) #2

; Function Attrs: nounwind ssp uwtable
define double @f_nearbyint(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #9
  %3 = tail call double @llvm.nearbyint.f64(double %2)
  %4 = tail call double @cq_measure_f64(double noundef %3) #10
  ret double %4
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.nearbyint.f64(double) #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define float @f_nearbyintf(float noundef %0) local_unnamed_addr #0 {
  %2 = tail call float @cq_theta_f32(float noundef %0, double noundef 3.000000e-01) #9
  %3 = tail call float @llvm.nearbyint.f32(float %2)
  %4 = tail call float @cq_measure_f32(float noundef %3) #10
  ret float %4
}

declare float @cq_theta_f32(float noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.nearbyint.f32(float) #2

declare float @cq_measure_f32(float noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fsub.f64(double, double, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmp.f64(double, double, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare float @llvm.experimental.constrained.fsub.f32(float, float, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare float @llvm.experimental.constrained.fadd.f32(float, float, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #2

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare float @llvm.experimental.constrained.sitofp.f32.i32(i32, metadata, metadata) #3

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmp.f32(float, float, metadata, metadata) #3

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(none)
define noundef i32 @fetestexcept(i32 noundef %0) local_unnamed_addr #5 {
  ret i32 0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(none)
define noundef i32 @feclearexcept(i32 noundef %0) local_unnamed_addr #5 {
  ret i32 0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite)
define double @rint(double noundef %0) local_unnamed_addr #6 {
  %2 = bitcast double %0 to i64
  %3 = and i64 %2, 9218868437227405312
  %4 = icmp ugt i64 %3, 4836865999795912704
  br i1 %4, label %20, label %5

5:                                                ; preds = %1
  %6 = icmp sgt i64 %2, -1
  br i1 %6, label %10, label %7

7:                                                ; preds = %5
  %8 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %9 = tail call double @llvm.experimental.constrained.fadd.f64(double %8, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %13

10:                                               ; preds = %5
  %11 = tail call double @llvm.experimental.constrained.fadd.f64(double %0, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %12 = tail call double @llvm.experimental.constrained.fsub.f64(double %11, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %13

13:                                               ; preds = %10, %7
  %14 = phi double [ %9, %7 ], [ %12, %10 ]
  %15 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %16 = tail call i1 @llvm.experimental.constrained.fcmp.f64(double %14, double %15, metadata !"oeq", metadata !"fpexcept.ignore") #11
  br i1 %16, label %17, label %20

17:                                               ; preds = %13
  %18 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %19 = select i1 %6, double %18, double -0.000000e+00
  br label %20

20:                                               ; preds = %17, %13, %1
  %21 = phi double [ %19, %17 ], [ %0, %1 ], [ %14, %13 ]
  ret double %21
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i64 @llvm.experimental.constrained.fptosi.i64.f64(double, metadata) #3

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite)
define float @rintf(float noundef %0) local_unnamed_addr #6 {
  %2 = bitcast float %0 to i32
  %3 = and i32 %2, 2130706432
  %4 = icmp ugt i32 %3, 1249902592
  br i1 %4, label %19, label %5

5:                                                ; preds = %1
  %6 = icmp sgt i32 %2, -1
  br i1 %6, label %10, label %7

7:                                                ; preds = %5
  %8 = tail call float @llvm.experimental.constrained.fsub.f32(float %0, float 0x4160000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %9 = tail call float @llvm.experimental.constrained.fadd.f32(float %8, float 0x4160000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %13

10:                                               ; preds = %5
  %11 = tail call float @llvm.experimental.constrained.fadd.f32(float %0, float 0x4160000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %12 = tail call float @llvm.experimental.constrained.fsub.f32(float %11, float 0x4160000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %13

13:                                               ; preds = %10, %7
  %14 = phi float [ -0.000000e+00, %7 ], [ 0.000000e+00, %10 ]
  %15 = phi float [ %9, %7 ], [ %12, %10 ]
  %16 = tail call float @llvm.experimental.constrained.sitofp.f32.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %17 = tail call i1 @llvm.experimental.constrained.fcmp.f32(float %15, float %16, metadata !"oeq", metadata !"fpexcept.ignore") #11
  %18 = select i1 %17, float %14, float %15
  br label %19

19:                                               ; preds = %13, %1
  %20 = phi float [ %0, %1 ], [ %18, %13 ]
  ret float %20
}

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite)
define double @round(double noundef %0) local_unnamed_addr #7 {
  %2 = alloca double, align 8
  %3 = bitcast double %0 to i64
  %4 = lshr i64 %3, 52
  %5 = trunc nuw nsw i64 %4 to i32
  %6 = and i32 %5, 2047
  %7 = icmp ugt i32 %6, 1074
  br i1 %7, label %34, label %8

8:                                                ; preds = %1
  %9 = tail call double @llvm.fabs.f64(double %0)
  %10 = icmp ult i32 %6, 1022
  %11 = tail call double @llvm.experimental.constrained.fadd.f64(double %9, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br i1 %10, label %12, label %15

12:                                               ; preds = %8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  store volatile double %11, ptr %2, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  %13 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %14 = tail call double @llvm.experimental.constrained.fmul.f64(double %13, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %34

15:                                               ; preds = %8
  %16 = tail call double @llvm.experimental.constrained.fsub.f64(double %11, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %17 = tail call double @llvm.experimental.constrained.fsub.f64(double %16, double %9, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %18 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %17, double 5.000000e-01, metadata !"ogt", metadata !"fpexcept.ignore") #11
  br i1 %18, label %19, label %23

19:                                               ; preds = %15
  %20 = tail call double @llvm.experimental.constrained.fadd.f64(double %17, double %9, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %21 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %22 = tail call double @llvm.experimental.constrained.fsub.f64(double %20, double %21, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %29

23:                                               ; preds = %15
  %24 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %17, double -5.000000e-01, metadata !"ole", metadata !"fpexcept.ignore") #11
  %25 = tail call double @llvm.experimental.constrained.fadd.f64(double %17, double %9, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br i1 %24, label %26, label %29

26:                                               ; preds = %23
  %27 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %28 = tail call double @llvm.experimental.constrained.fadd.f64(double %25, double %27, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %29

29:                                               ; preds = %26, %23, %19
  %30 = phi double [ %22, %19 ], [ %28, %26 ], [ %25, %23 ]
  %31 = fneg double %30
  %32 = icmp slt i64 %3, 0
  %33 = select i1 %32, double %31, double %30
  br label %34

34:                                               ; preds = %29, %12, %1
  %35 = phi double [ %14, %12 ], [ %33, %29 ], [ %0, %1 ]
  ret double %35
}

; Function Attrs: nounwind ssp strictfp
define i64 @lrint(double noundef %0) local_unnamed_addr #8 {
  %2 = tail call double @rint(double noundef %0) #12
  %3 = tail call i64 @llvm.experimental.constrained.fptosi.i64.f64(double %2, metadata !"fpexcept.ignore") #11
  ret i64 %3
}

; Function Attrs: nounwind ssp strictfp
define i64 @lround(double noundef %0) local_unnamed_addr #8 {
  %2 = tail call double @round(double noundef %0) #12
  %3 = tail call i64 @llvm.experimental.constrained.fptosi.i64.f64(double %2, metadata !"fpexcept.ignore") #11
  ret i64 %3
}

; Function Attrs: nounwind ssp strictfp
define double @nearbyint(double noundef %0) local_unnamed_addr #8 {
  %2 = tail call i32 @fetestexcept(i32 noundef 32) #12
  %3 = tail call double @rint(double noundef %0) #12
  %4 = icmp eq i32 %2, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = tail call i32 @feclearexcept(i32 noundef 32) #12
  br label %7

7:                                                ; preds = %5, %1
  ret double %3
}

; Function Attrs: nounwind ssp strictfp
define float @nearbyintf(float noundef %0) local_unnamed_addr #8 {
  %2 = tail call i32 @fetestexcept(i32 noundef 32) #12
  %3 = tail call float @rintf(float noundef %0) #12
  %4 = icmp eq i32 %2, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = tail call i32 @feclearexcept(i32 noundef 32) #12
  br label %7

7:                                                ; preds = %5, %1
  ret float %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #4 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(none) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #8 = { nounwind ssp strictfp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #9 = { nomerge nounwind }
attributes #10 = { nounwind }
attributes #11 = { strictfp }
attributes #12 = { nobuiltin nounwind strictfp "no-builtins" }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5, !6}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{i32 7, !"PIE Level", i32 2}
