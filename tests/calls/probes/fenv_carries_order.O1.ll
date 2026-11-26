; ModuleID = 'probes/fenv_carries_order.c'
source_filename = "probes/fenv_carries_order.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable
define double @X(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 1.000000e-01, metadata !"round.dynamic", metadata !"fpexcept.strict") #5
  ret double %2
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable
define double @B(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @X(double noundef %0) #5
  ret double %2
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(inaccessiblemem: readwrite) uwtable
define double @A(double noundef %0) local_unnamed_addr #2 {
  %2 = fmul double %0, 0.000000e+00
  %3 = tail call double @X(double noundef %2)
  %4 = fadd double %3, %0
  ret double %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable
define double @R(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call double @A(double noundef %0) #5
  %3 = tail call double @B(double noundef %2) #5
  ret double %3
}

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @e(i32 noundef %0, double noundef %1) local_unnamed_addr #3 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  %4 = tail call i32 @feclearexcept(i32 noundef 63) #7
  %5 = tail call double @llvm.experimental.constrained.sitofp.f64.i32(i32 %3, metadata !"round.dynamic", metadata !"fpexcept.strict") #5
  %6 = tail call double @R(double noundef %5) #5
  %7 = tail call i32 @fetestexcept(i32 noundef 32) #7
  %8 = icmp ne i32 %7, 0
  %9 = zext i1 %8 to i32
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #7
  %11 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %6, metadata !"fpexcept.strict") #5
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #7
  %13 = shl nsw i32 %12, 1
  %14 = add nsw i32 %13, %10
  ret i32 %14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

declare i32 @feclearexcept(i32 noundef) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.sitofp.f64.i32(i32, metadata, metadata) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata) #1

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp strictfp willreturn memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { strictfp }
attributes #6 = { nomerge nounwind strictfp }
attributes #7 = { nounwind strictfp }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
