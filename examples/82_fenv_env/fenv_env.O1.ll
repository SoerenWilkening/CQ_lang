; ModuleID = 'fenv_env.c'
source_filename = "fenv_env.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.fenv_t = type { i16, i16, i32, [8 x i8] }    ; C: fenv_t

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @fenv_env(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca %struct.fenv_t, align 4    ; C: fenv_t env;
  %6 = alloca i16, align 2    ; C: fexcept_t saved;
  %7 = alloca %struct.fenv_t, align 4    ; C: fenv_t e2;
  %8 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #5    ; C: cq_theta(&x, th);
  %9 = tail call double @llvm.experimental.constrained.fmul.f64(double %8, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #6    ; C: double p = x * c;
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #7    ; C: (env comes into scope)
  %10 = call i32 @feholdexcept(ptr noundef nonnull %5) #7    ; C: feholdexcept(&env);
  %11 = call double @llvm.experimental.constrained.fdiv.f64(double %9, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #6    ; C: double y = p / c;
  %12 = call i32 @fetestexcept(i32 noundef 32) #7    ; C: int inexact = fetestexcept(FE_INEXACT);
  %13 = call i32 @feupdateenv(ptr noundef nonnull %5) #7    ; C: feupdateenv(&env);
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %6) #7    ; C: (saved comes into scope)
  %14 = call i32 @fegetexceptflag(ptr noundef nonnull %6, i32 noundef 63) #7    ; C: fegetexceptflag(&saved, FE_ALL_EXCEPT);
  %15 = call fastcc double @scale(double noundef %11, double noundef %3) #6    ; C: double z = scale(y, k);
  %16 = call i32 @fesetexceptflag(ptr noundef nonnull %6, i32 noundef 63) #7    ; C: fesetexceptflag(&saved, FE_ALL_EXCEPT);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %7) #7    ; C: (e2 comes into scope)
  %17 = call i32 @fegetenv(ptr noundef nonnull %7) #7    ; C: fegetenv(&e2);
  %18 = call i32 @fesetround(i32 noundef 2048) #7    ; C: fesetround(FE_UPWARD);
  %19 = call double @llvm.experimental.constrained.fmul.f64(double %15, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #6    ; C: double w = z * c;
  %20 = call i32 @fesetenv(ptr noundef nonnull %7) #7    ; C: fesetenv(&e2);
  %21 = call i32 @cq_measure_si32(i32 noundef %12) #7    ; C: cq_measure(inexact)
  %22 = call double @cq_measure_f64(double noundef %19) #7    ; C: cq_measure(w)
  %23 = call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %22, metadata !"fpexcept.strict") #6    ; C: (int)cq_measure(w)
  %24 = add nsw i32 %23, %21    ; C: cq_measure(inexact) + (int)cq_measure(w)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %7) #7    ; C: (e2 goes out of scope)
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %6) #7    ; C: (saved goes out of scope)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #7    ; C: (env goes out of scope)
  ret i32 %24    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #3

declare i32 @feholdexcept(ptr noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #3

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #2

declare i32 @feupdateenv(ptr noundef) local_unnamed_addr #2

declare i32 @fegetexceptflag(ptr noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable
define internal fastcc double @scale(double noundef %0, double noundef %1) unnamed_addr #4 {
  %3 = tail call double @llvm.experimental.constrained.fmuladd.f64(double %0, double %1, double %1, metadata !"round.dynamic", metadata !"fpexcept.strict") #6    ; C: v * c + c
  ret double %3    ; C: return
}

declare i32 @fesetexceptflag(ptr noundef, i32 noundef) local_unnamed_addr #2

declare i32 @fegetenv(ptr noundef) local_unnamed_addr #2

declare i32 @fesetround(i32 noundef) local_unnamed_addr #2

declare i32 @fesetenv(ptr noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmuladd.f64(double, double, double, metadata, metadata) #3

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind strictfp }
attributes #6 = { strictfp }
attributes #7 = { nounwind strictfp }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
