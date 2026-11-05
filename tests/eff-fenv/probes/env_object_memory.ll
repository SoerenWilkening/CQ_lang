; ModuleID = 'tests/eff-fenv/probes/env_object_memory.c'
source_filename = "tests/eff-fenv/probes/env_object_memory.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.fenv_t = type { i16, i16, i32, [8 x i8] }

@genv = global %struct.fenv_t zeroinitializer, align 4
@gflag = internal global i16 0, align 2

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @p_env_callee(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca %struct.fenv_t, align 4
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #6
  %6 = tail call double @llvm.experimental.constrained.fmul.f64(double %5, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #7
  call fastcc void @save_env(ptr noundef nonnull %4) #7
  %7 = call i32 @feclearexcept(i32 noundef 63) #6
  %8 = call double @llvm.experimental.constrained.fdiv.f64(double %6, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #7
  call fastcc void @restore_env(ptr noundef nonnull %4) #7
  %9 = call i32 @fetestexcept(i32 noundef 63) #6
  %10 = call i32 @cq_measure_si32(i32 noundef %9) #6
  %11 = call double @cq_measure_f64(double noundef %8) #6
  %12 = call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %11, metadata !"fpexcept.strict") #7
  %13 = add nsw i32 %12, %10
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #6
  ret i32 %13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #3

; Function Attrs: noinline nounwind ssp strictfp uwtable
define internal fastcc void @save_env(ptr noundef %0) unnamed_addr #4 {
  %2 = tail call i32 @fegetenv(ptr noundef %0) #6
  ret void
}

declare i32 @feclearexcept(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #3

; Function Attrs: noinline nounwind ssp strictfp uwtable
define internal fastcc void @restore_env(ptr noundef %0) unnamed_addr #4 {
  %2 = tail call i32 @fesetenv(ptr noundef %0) #6
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @p_env_global(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  %5 = tail call double @llvm.experimental.constrained.fmul.f64(double %4, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #7
  %6 = tail call i32 @feholdexcept(ptr noundef nonnull @genv) #6
  %7 = tail call double @llvm.experimental.constrained.fadd.f64(double %5, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #7
  %8 = tail call i32 @feupdateenv(ptr noundef nonnull @genv) #6
  %9 = tail call i32 @fetestexcept(i32 noundef 63) #6
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #6
  %11 = tail call double @cq_measure_f64(double noundef %7) #6
  %12 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %11, metadata !"fpexcept.strict") #7
  %13 = add nsw i32 %12, %10
  ret i32 %13
}

declare i32 @feholdexcept(ptr noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fadd.f64(double, double, metadata, metadata) #3

declare i32 @feupdateenv(ptr noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @p_flag_global(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  %5 = tail call double @llvm.experimental.constrained.fdiv.f64(double %4, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #7
  %6 = tail call i32 @fegetexceptflag(ptr noundef nonnull @gflag, i32 noundef 63) #6
  %7 = tail call i32 @feclearexcept(i32 noundef 63) #6
  %8 = tail call double @llvm.experimental.constrained.fmul.f64(double %5, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #7
  %9 = tail call i32 @fesetexceptflag(ptr noundef nonnull @gflag, i32 noundef 32) #6
  %10 = tail call i32 @fetestexcept(i32 noundef 63) #6
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #6
  %12 = tail call double @cq_measure_f64(double noundef %8) #6
  %13 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %12, metadata !"fpexcept.strict") #7
  %14 = add nsw i32 %13, %11
  ret i32 %14
}

declare i32 @fegetexceptflag(ptr noundef, i32 noundef) local_unnamed_addr #2

declare i32 @fesetexceptflag(ptr noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @p_env_pred(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca %struct.fenv_t, align 4
  %6 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #6
  call fastcc void @save_env(ptr noundef nonnull %5) #7
  %7 = call double @llvm.experimental.constrained.fmul.f64(double %6, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #7
  %8 = call i1 @llvm.experimental.constrained.fcmps.f64(double %6, double %3, metadata !"ogt", metadata !"fpexcept.strict") #7
  br i1 %8, label %9, label %11

9:                                                ; preds = %4
  %10 = call i32 @fegetenv(ptr noundef nonnull %5) #6
  br label %11

11:                                               ; preds = %9, %4
  %12 = call double @llvm.experimental.constrained.fadd.f64(double %7, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #7
  %13 = call i32 @fesetenv(ptr noundef nonnull %5) #6
  %14 = call i32 @fetestexcept(i32 noundef 63) #6
  %15 = call i32 @cq_measure_si32(i32 noundef %14) #6
  %16 = call double @cq_measure_f64(double noundef %12) #6
  %17 = call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %16, metadata !"fpexcept.strict") #7
  %18 = add nsw i32 %17, %15
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #6
  ret i32 %18
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #3

declare i32 @fegetenv(ptr noundef) local_unnamed_addr #2

declare i32 @fesetenv(ptr noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #4 = { noinline nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind strictfp }
attributes #6 = { nounwind strictfp }
attributes #7 = { strictfp }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
