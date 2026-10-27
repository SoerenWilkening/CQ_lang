; ModuleID = 'fenv_extras.c'
source_filename = "fenv_extras.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.fenv_t = type { i16, i16, i32, [8 x i8] }

@_FE_DFL_ENV = external constant %struct.fenv_t, align 4

; Function Attrs: nounwind ssp strictfp uwtable
define double @fenv_dfl_env(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %5 = tail call double @llvm.experimental.constrained.fmul.f64(double %4, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #5    ; C: double y = x * c;
  %6 = tail call i32 @fesetenv(ptr noundef nonnull @_FE_DFL_ENV) #6    ; C: fesetenv(FE_DFL_ENV);
  %7 = tail call double @llvm.experimental.constrained.fadd.f64(double %5, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #5    ; C: double z = y + c;
  %8 = tail call i32 @feupdateenv(ptr noundef nonnull @_FE_DFL_ENV) #6    ; C: feupdateenv(FE_DFL_ENV);
  %9 = tail call i32 @fetestexcept(i32 noundef 63) #6    ; C: int f = fetestexcept(FE_ALL_EXCEPT);
  %10 = tail call double @cq_measure_f64(double noundef %7) #6    ; C: cq_measure(z)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %9) #6    ; C: cq_measure(f)
  %12 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %11, metadata !"round.dynamic", metadata !"fpexcept.strict") #5    ; C: (double)cq_measure(f)
  %13 = tail call double @llvm.experimental.constrained.fadd.f64(double %10, double %12, metadata !"round.dynamic", metadata !"fpexcept.strict") #5    ; C: cq_measure(z) + (double)cq_measure(f)
  ret double %13    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #3

declare i32 @fesetenv(ptr noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #3

declare i32 @feupdateenv(ptr noundef) local_unnamed_addr #2

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @fenv_narrow_mask(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca i16, align 2    ; C: fexcept_t saved;
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %6 = tail call double @llvm.experimental.constrained.fdiv.f64(double %5, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #5    ; C: double y = x / c;
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %4) #6    ; C: (saved comes into scope)
  %7 = call i32 @fegetexceptflag(ptr noundef nonnull %4, i32 noundef 32) #6    ; C: fegetexceptflag(&saved, FE_INEXACT);
  %8 = call double @llvm.experimental.constrained.fmul.f64(double %6, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #5    ; C: double z = y * c;
  %9 = call i32 @fesetexceptflag(ptr noundef nonnull %4, i32 noundef 32) #6    ; C: fesetexceptflag(&saved, FE_INEXACT);
  %10 = call i32 @fetestexcept(i32 noundef 63) #6    ; C: fetestexcept(FE_ALL_EXCEPT)
  %11 = call i32 @cq_measure_si32(i32 noundef %10) #6    ; C: cq_measure(fetestexcept(...))
  %12 = call double @cq_measure_f64(double noundef %8) #6    ; C: cq_measure(z)
  %13 = call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %12, metadata !"fpexcept.strict") #5    ; C: (int)cq_measure(z)
  %14 = add nsw i32 %13, %11    ; C: ... + ...
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %4) #6    ; C: (saved goes out of scope)
  ret i32 %14    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #3

declare i32 @fegetexceptflag(ptr noundef, i32 noundef) local_unnamed_addr #2

declare i32 @fesetexceptflag(ptr noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata) #3

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @fenv_op_in_arm(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #4    ; C: cq_theta(&x, th);
  %6 = tail call i32 @feclearexcept(i32 noundef 63) #6    ; C: feclearexcept(FE_ALL_EXCEPT);
  %7 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %5, double %3, metadata !"ogt", metadata !"fpexcept.strict") #5    ; C: if (x > k)
  br i1 %7, label %8, label %10    ; C: if (x > k)

8:                                                ; preds = %4
  %9 = tail call double @llvm.experimental.constrained.fmul.f64(double %5, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #5    ; C: y = x * c;
  br label %10    ; C: end of if

10:                                               ; preds = %8, %4
  %11 = phi double [ %9, %8 ], [ %5, %4 ]    ; C: double y (merged)
  %12 = tail call i32 @fetestexcept(i32 noundef 63) #6    ; C: fetestexcept(FE_ALL_EXCEPT)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #6    ; C: cq_measure(fetestexcept(...))
  %14 = tail call double @cq_measure_f64(double noundef %11) #6    ; C: cq_measure(y)
  %15 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %14, metadata !"fpexcept.strict") #5    ; C: (int)cq_measure(y)
  %16 = add nsw i32 %15, %13    ; C: ... + ...
  ret i32 %16    ; C: return
}

declare i32 @feclearexcept(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #3

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @fenv_quantum_mode(i32 noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4    ; C: cq_theta(&m, th);
  %6 = tail call i32 @fesetround(i32 noundef %5) #6    ; C: int rc = fesetround((int)m);
  %7 = tail call double @llvm.experimental.constrained.fadd.f64(double %2, double %3, metadata !"round.dynamic", metadata !"fpexcept.strict") #5    ; C: double s = a + b;
  %8 = tail call i32 @fesetround(i32 noundef 0) #6    ; C: fesetround(FE_TONEAREST);
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) #6    ; C: cq_measure(rc)
  %10 = tail call double @cq_measure_f64(double noundef %7) #6    ; C: cq_measure(s)
  %11 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %10, metadata !"fpexcept.strict") #5    ; C: (int)cq_measure(s)
  %12 = add nsw i32 %11, %9    ; C: cq_measure(rc) + (int)cq_measure(s)
  ret i32 %12    ; C: return
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @fesetround(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #4 = { nomerge nounwind strictfp }
attributes #5 = { strictfp }
attributes #6 = { nounwind strictfp }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
