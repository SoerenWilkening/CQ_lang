; ModuleID = 'fenv_bracket.c'
source_filename = "fenv_bracket.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.fenv_t = type { i16, i16, i32, [8 x i8] }    ; C: fenv_t

; Function Attrs: nounwind ssp uwtable
define double @fenv_bracket(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca %struct.fenv_t, align 4    ; C: fenv_t env;
  %6 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %7 = tail call i32 @fegetround() #4    ; C: int oround = fegetround();
  %8 = tail call i32 @fesetround(i32 noundef 0) #4    ; C: fesetround(FE_TONEAREST);
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5) #4    ; C: (env comes into scope)
  %9 = call i32 @feholdexcept(ptr noundef nonnull %5) #4    ; C: feholdexcept(&env);
  %10 = fmul double %6, %2    ; C: double y = x * c;
  %11 = call i32 @feupdateenv(ptr noundef nonnull %5) #4    ; C: feupdateenv(&env);
  %12 = fcmp ogt double %10, %3    ; C: if (y > k)
  br i1 %12, label %13, label %15    ; C: if (y > k)

13:                                               ; preds = %4
  %14 = call i32 @feraiseexcept(i32 noundef 32) #4    ; C: feraiseexcept(FE_INEXACT);
  br label %15    ; C: end of if

15:                                               ; preds = %13, %4
  %16 = call i32 @fesetround(i32 noundef %7) #4    ; C: fesetround(oround);
  %17 = call double @cq_measure_f64(double noundef %10) #4    ; C: cq_measure(y)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5) #4    ; C: (env goes out of scope)
  ret double %17    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

declare i32 @fegetround() local_unnamed_addr #2

declare i32 @fesetround(i32 noundef) local_unnamed_addr #2

declare i32 @feholdexcept(ptr noundef) local_unnamed_addr #2

declare i32 @feupdateenv(ptr noundef) local_unnamed_addr #2

declare i32 @feraiseexcept(i32 noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define double @fenv_tested(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  %6 = tail call i32 @fesetround(i32 noundef 2048) #4    ; C: fesetround(FE_UPWARD);
  %7 = tail call i32 @feclearexcept(i32 noundef 32) #4    ; C: feclearexcept(FE_INEXACT);
  %8 = fmul double %5, %2    ; C: double y = x * c;
  %9 = fcmp ogt double %8, %3    ; C: if (y > k)
  br i1 %9, label %10, label %12    ; C: if (y > k)

10:                                               ; preds = %4
  %11 = tail call i32 @feraiseexcept(i32 noundef 32) #4    ; C: feraiseexcept(FE_INEXACT);
  br label %12    ; C: end of if

12:                                               ; preds = %10, %4
  %13 = tail call i32 @fetestexcept(i32 noundef 32) #4    ; C: int f = fetestexcept(FE_INEXACT);
  %14 = tail call double @cq_measure_f64(double noundef %8) #4    ; C: cq_measure(y)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %13) #4    ; C: cq_measure(f)
  %16 = sitofp i32 %15 to double    ; C: (double)cq_measure(f)
  %17 = fadd double %14, %16    ; C: cq_measure(y) + (double)cq_measure(f)
  ret double %17    ; C: return
}

declare i32 @feclearexcept(i32 noundef) local_unnamed_addr #2

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
