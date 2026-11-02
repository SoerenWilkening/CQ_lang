; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define double @f_floor(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @cq_theta_f64(double noundef %0, double noundef 3.000000e-01) #9
  %3 = tail call double @llvm.floor.f64(double %2)
  %4 = tail call double @cq_measure_f64(double noundef %3) #10
  ret double %4
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.floor.f64(double) #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite)
define double @floor(double noundef %0) local_unnamed_addr #3 {
  %2 = alloca double, align 8
  %3 = bitcast double %0 to i64
  %4 = lshr i64 %3, 52
  %5 = trunc nuw nsw i64 %4 to i32
  %6 = and i32 %5, 2047
  %7 = icmp ugt i32 %6, 1074
  br i1 %7, label %34, label %8

8:                                                ; preds = %1
  %9 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %10 = tail call i1 @llvm.experimental.constrained.fcmp.f64(double %0, double %9, metadata !"oeq", metadata !"fpexcept.ignore") #11
  br i1 %10, label %34, label %11

11:                                               ; preds = %8
  %12 = icmp slt i64 %3, 0
  br i1 %12, label %13, label %16

13:                                               ; preds = %11
  %14 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %15 = tail call double @llvm.experimental.constrained.fadd.f64(double %14, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %19

16:                                               ; preds = %11
  %17 = tail call double @llvm.experimental.constrained.fadd.f64(double %0, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %18 = tail call double @llvm.experimental.constrained.fsub.f64(double %17, double 0x4330000000000000, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %19

19:                                               ; preds = %16, %13
  %20 = phi double [ %18, %16 ], [ %15, %13 ]
  %21 = tail call double @llvm.experimental.constrained.fsub.f64(double %20, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %22 = icmp ult i32 %6, 1023
  br i1 %22, label %23, label %27

23:                                               ; preds = %19
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  store volatile double %21, ptr %2, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  %24 = ashr i64 %3, 63
  %25 = trunc nsw i64 %24 to i32
  %26 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %25, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %34

27:                                               ; preds = %19
  %28 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %29 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %21, double %28, metadata !"ogt", metadata !"fpexcept.ignore") #11
  %30 = tail call double @llvm.experimental.constrained.fadd.f64(double %0, double %21, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br i1 %29, label %31, label %34

31:                                               ; preds = %27
  %32 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %33 = tail call double @llvm.experimental.constrained.fsub.f64(double %30, double %32, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  br label %34

34:                                               ; preds = %31, %27, %23, %8, %1
  %35 = phi double [ %26, %23 ], [ %33, %31 ], [ %0, %8 ], [ %0, %1 ], [ %30, %27 ]
  ret double %35
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmp.f64(double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fsub.f64(double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #5

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #5

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #4

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(none)
define noundef double @fabs(double noundef %0) local_unnamed_addr #6 {
  %2 = tail call double @llvm.fabs.f64(double %0)
  ret double %2
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fabs.f64(double) #2

; Function Attrs: nounwind ssp strictfp
define hidden double @__math_oflow(i32 noundef %0) local_unnamed_addr #7 {
  %2 = tail call double @__math_xflow(i32 noundef %0, double noundef 0x7000000000000000) #12
  ret double %2
}

; Function Attrs: nounwind ssp strictfp
define hidden double @__math_uflow(i32 noundef %0) local_unnamed_addr #7 {
  %2 = tail call double @__math_xflow(i32 noundef %0, double noundef 0x1000000000000000) #12
  ret double %2
}

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite)
define hidden double @__math_xflow(i32 noundef %0, double noundef %1) local_unnamed_addr #3 {
  %3 = alloca double, align 8
  %4 = icmp eq i32 %0, 0
  %5 = fneg double %1
  %6 = select i1 %4, double %1, double %5
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3)
  store volatile double %6, ptr %3, align 8
  %7 = load volatile double, ptr %3, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3)
  %8 = tail call double @llvm.experimental.constrained.fmul.f64(double %7, double %1, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  ret double %8
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #4

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite)
define hidden double @__math_invalid(double noundef %0) local_unnamed_addr #8 {
  %2 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %3 = tail call double @llvm.experimental.constrained.fsub.f64(double %0, double %0, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  %4 = tail call double @llvm.experimental.constrained.fdiv.f64(double %2, double %3, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  ret double %4
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #4

; Function Attrs: nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite)
define hidden double @__math_divzero(i32 noundef %0) local_unnamed_addr #3 {
  %2 = alloca double, align 8
  %3 = icmp eq i32 %0, 0
  %4 = select i1 %3, double 1.000000e+00, double -1.000000e+00
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2)
  store volatile double %4, ptr %2, align 8
  %5 = load volatile double, ptr %2, align 8
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2)
  %6 = tail call double @llvm.experimental.constrained.fdiv.f64(double %5, double 0.000000e+00, metadata !"round.dynamic", metadata !"fpexcept.ignore") #11
  ret double %6
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nofree norecurse nounwind ssp strictfp memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #5 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #6 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(none) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { nounwind ssp strictfp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #8 = { mustprogress nofree norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #9 = { nomerge nounwind }
attributes #10 = { nounwind }
attributes #11 = { strictfp }
attributes #12 = { nobuiltin nounwind strictfp "no-builtins" }

!llvm.ident = !{!0, !0, !0, !0, !0, !0, !0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
