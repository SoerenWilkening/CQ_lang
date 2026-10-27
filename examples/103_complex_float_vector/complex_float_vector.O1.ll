; ModuleID = 'complex_float_vector.c'
source_filename = "complex_float_vector.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define float @complex_float(float noundef %0, double noundef %1, float noundef %2, float noundef %3) local_unnamed_addr #0 {
  %5 = tail call float @cq_theta_f32(float noundef %0, double noundef %1) #3    ; C: cq_theta(&a, th);
  %6 = fmul float %2, 0.000000e+00    ; C: b * I  (imaginary unit: real part b * 0)
  %7 = fadd float %6, %5    ; C: a + b * I  (real part of z)
  %8 = fmul float %7, %3    ; C: z * c  (real part)
  %9 = fmul float %2, %3    ; C: z * c  (imaginary part, classical)
  %10 = fadd float %7, %8    ; C: z * c + z  (real part of w)
  %11 = fadd float %9, %2    ; C: z * c + z  (imaginary part of w, classical)
  %12 = insertelement <2 x float> poison, float %10, i64 0    ; C: w as <2 x float>: lane 0 = real
  %13 = insertelement <2 x float> %12, float %11, i64 1    ; C: w as <2 x float>: lane 1 = imaginary
  %14 = tail call fastcc <2 x float> @twicef(<2 x float> noundef %13)    ; C: float _Complex q = twicef(w);
  %15 = shufflevector <2 x float> %14, <2 x float> poison, <2 x i32> <i32 1, i32 poison>    ; C: cimagf(q)  (lane 1 moved to lane 0)
  %16 = fadd <2 x float> %14, %15    ; C: crealf(q) + cimagf(q)  (lane 0)
  %17 = extractelement <2 x float> %16, i64 0    ; C: crealf(q) + cimagf(q)
  %18 = tail call float @cq_measure_f32(float noundef %17) #4    ; C: cq_measure(crealf(q) + cimagf(q))
  ret float %18    ; C: return
}

declare float @cq_theta_f32(float noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc <2 x float> @twicef(<2 x float> noundef %0) unnamed_addr #2 {
  %2 = fadd <2 x float> %0, %0    ; C: z + z  (both lanes)
  %3 = fadd <2 x float> %0, %0    ; C: z + z  (the same sum again, for the other lane)
  %4 = shufflevector <2 x float> %2, <2 x float> %3, <2 x i32> <i32 0, i32 3>    ; C: z + z  (lane 0 of the first, lane 1 of the second)
  ret <2 x float> %4    ; C: return
}

declare float @cq_measure_f32(float noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="64" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="64" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
