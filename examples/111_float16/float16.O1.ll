; ModuleID = 'float16.c'
source_filename = "float16.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define float @float16_q(float noundef %0, double noundef %1, float noundef %2) local_unnamed_addr #0 {
  %4 = tail call float @cq_theta_f32(float noundef %0, double noundef %1) #4    ; C: cq_theta(&f, th);
  %5 = fptrunc float %4 to half    ; C: _Float16 h = (_Float16)f;
  %6 = fpext half %5 to float    ; C: h (promoted to float for the arithmetic)
  %7 = fptrunc float %2 to half    ; C: (_Float16)c
  %8 = fpext half %7 to float    ; C: (_Float16)c (promoted)
  %9 = tail call float @llvm.fmuladd.f32(float %6, float %8, float 1.000000e+00)    ; C: h * (_Float16)c + 1.0f16  (in float)
  %10 = fptrunc float %9 to half    ; C: h = ...;  (back to _Float16)
  %11 = tail call fastcc half @twice16(half noundef %10)    ; C: twice16(h)
  %12 = fpext half %11 to float    ; C: (float)twice16(h)
  %13 = tail call float @cq_measure_f32(float noundef %12) #5    ; C: cq_measure((float)twice16(h))
  ret float %13    ; C: return
}

declare float @cq_theta_f32(float noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fmuladd.f32(float, float, float) #2

declare float @cq_measure_f32(float noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc noundef half @twice16(half noundef %0) unnamed_addr #3 {
  %2 = fadd half %0, %0    ; C: h + h
  ret half %2    ; C: return
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
