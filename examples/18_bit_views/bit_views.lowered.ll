; HAND-WRITTEN. Rules: 1, 2, 3, 4, 5, 20.
; Checked: high_word: u.w[1] (measured, %6 -> %7); bits_of: b (measured, %4 -> %5); from_words: u.d (measured, %11 -> %12).
; Clean: high_word: the bitcast rail %4 and the shifted rail %5; from_words: the two zext rails %7, %8, the shifted rail %9
; and the or rail %10, all uncomputed LIFO and freed before the measurement. bits_of allocates nothing beyond its result.
; Kept: the registers (x %3 in high_word and bits_of; h %5 and l %6 in from_words) and the three measured result rails.
; Rotations: (Ry, x, th, 1) in high_word; (Ry, x, th, 1) in bits_of; (Ry, h, th, 1), (Ry, l, tl, 1) in from_words.
; -O1 (SROA) folds the union and memcpy punning into bitcast/lshr/trunc, so no alloca reaches the lowering: every bit view
; is an SSA value (rule 20). A bitcast between f64 and i64 is a representation change and still lands in a fresh rail by
; the bitcast template (rule 3, 4); the word extraction is lshr by the literal 32 (_hl) and a trunc template; the word
; assembly is two zext templates, a shl by the literal 32, one two-handle or template and a bitcast back to f64.
source_filename = "bit_views.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @high_word(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %3 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %3, double %1)    ; IR: %3 = cq_theta_f64(%0, %1)  [Ry]
  %4 = call i32 @cq_template_bitcast_f64_to_i64(i32 %3)    ; IR: %4 = bitcast double %3 to i64
  %5 = call i32 @cq_template_lshr_i64_hl(i32 %4, i64 32)    ; IR: %5 = lshr i64 %4, 32
  %6 = call i32 @cq_template_trunc_i64_to_i32(i32 %5)    ; IR: %6 = trunc nuw i64 %5 to i32
  call void @cq_template_lshr_i64_hl_unc(i32 %5, i32 %4, i64 32)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %4, i32 %3)    ; IR: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %7 = cq_measure_ui32(%6)
  ret i32 %7    ; IR: ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i64 @bits_of(double noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %3 = cq_theta_f64(%0, %1)  [register]
  call void @cqrt_ry_f64(i32 %3, double %1)    ; IR: %3 = cq_theta_f64(%0, %1)  [Ry]
  %4 = call i32 @cq_template_bitcast_f64_to_i64(i32 %3)    ; IR: %4 = bitcast double %3 to i64
  %5 = call i64 @cqrt_measure_i64(i32 %4)    ; IR: %5 = cq_measure_ull(%4)
  ret i64 %5    ; IR: ret i64 %5
}

; Function Attrs: nounwind ssp uwtable
define double @from_words(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %2)  [register]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_ui32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_ui32(%1, %3)  [register]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_ui32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_zext_i32_to_i64(i32 %6)    ; IR: %7 = zext i32 %6 to i64
  %8 = call i32 @cq_template_zext_i32_to_i64(i32 %5)    ; IR: %8 = zext i32 %5 to i64
  %9 = call i32 @cq_template_shl_i64_hl(i32 %8, i64 32)    ; IR: %9 = shl nuw i64 %8, 32
  %10 = call i32 @cq_template_or_i64(i32 %7, i32 %9)    ; IR: %10 = or disjoint i64 %9, %7
  %11 = call i32 @cq_template_bitcast_i64_to_f64(i32 %10)    ; IR: %11 = bitcast i64 %10 to double
  call void @cq_template_or_i64_unc(i32 %10, i32 %7, i32 %9)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %9, i32 %8, i64 32)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %8, i32 %5)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %7, i32 %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %12 = call double @cqrt_measure_f64(i32 %11)    ; IR: %12 = cq_measure_f64(%11)
  ret double %12    ; IR: ret double %12
}

declare void @cqrt_ry_f64(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cq_template_bitcast_f64_to_i64(i32)

declare i32 @cq_template_lshr_i64_hl(i32, i64)

declare i32 @cq_template_trunc_i64_to_i32(i32)

declare i32 @cq_template_zext_i32_to_i64(i32)

declare i32 @cq_template_shl_i64_hl(i32, i64)

declare i32 @cq_template_or_i64(i32, i32)

declare i32 @cq_template_bitcast_i64_to_f64(i32)

declare i32 @cqrt_measure_i32(i32)

declare i64 @cqrt_measure_i64(i32)

declare double @cqrt_measure_f64(i32)

declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)

declare void @cqrt_free(i32)

declare void @cq_template_bitcast_f64_to_i64_unc(i32, i32)

declare void @cq_template_or_i64_unc(i32, i32, i32)

declare void @cq_template_shl_i64_hl_unc(i32, i32, i64)

declare void @cq_template_zext_i32_to_i64_unc(i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
