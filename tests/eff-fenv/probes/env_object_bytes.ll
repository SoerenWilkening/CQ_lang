; cq-a63l (CR rule 23 at f684858): see env_object_bytes.c (clang 19.1.7 -O1). A load of a fenv_t holding a
; quantum part reads its host part (its representation is unspecified in C).
; CHECK env_bytes: load i8, ptr %{{e}}
; CHECK env_bytes: call i32 @fesetenv(ptr noundef nonnull %{{e}})
source_filename = "/tmp/fenvobj.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.fenv_t = type { i16, i16, i32, [8 x i8] }

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @env_bytes(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca %struct.fenv_t, align 4
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #4
  %4 = tail call i32 @feclearexcept(i32 noundef 63) #4
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef 1.000000e+00) #5
  %6 = tail call double @llvm.experimental.constrained.fdiv.f64(double %5, double %1, metadata !"round.dynamic", metadata !"fpexcept.strict") #6
  %7 = call i32 @fegetenv(ptr noundef nonnull %3) #4
  %8 = load i8, ptr %3, align 4
  %9 = call i32 @feclearexcept(i32 noundef 63) #4
  %10 = call i32 @fesetenv(ptr noundef nonnull %3) #4
  %11 = zext i8 %8 to i32
  %12 = call i32 @fetestexcept(i32 noundef 63) #4
  %13 = add nsw i32 %12, %11
  %14 = call double @cq_measure_f64(double noundef %6) #4
  %15 = call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %14, metadata !"fpexcept.strict") #6
  %16 = add nsw i32 %13, %15
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #4
  ret i32 %16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @feclearexcept(i32 noundef) local_unnamed_addr #2

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fdiv.f64(double, double, metadata, metadata) #3

declare i32 @fegetenv(ptr noundef) local_unnamed_addr #2

declare i32 @fesetenv(ptr noundef) local_unnamed_addr #2

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #4 = { nounwind strictfp }
attributes #5 = { nomerge nounwind strictfp }
attributes #6 = { strictfp }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
