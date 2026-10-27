; HAND-WRITTEN. Rules: 25, 4, 5, 2.
; Checked: mul_i128: (((x | 1 << 64) * c) >> 64) as 64 bits; div_i128: ((hi << 64 | lo) / (x | 1 << 64)) as 64 bits
; (each measured).
; Clean: every i128 intermediate (the zext, the or, the product or quotient, the shift).
; Kept: the user register x of each function; the truncated result rail (measured).
; Rotations: Ry(th) on x (each function).
; 128-bit integers are a WIDTH VARIANT (rule 25): every i128 opcode is the same template family at W = 128
; (zext_i64_to_i128, or_i128_hl, mul_i128_hl, lshr_i128_hl, udiv_i128_lh, trunc_i128_to_i64), with classical i128
; operands passed as i128 values. Note on division: at -O1 the IR still holds `udiv i128` (the __udivti3 libcall
; appears only at codegen, below the IR), so it lowers as the udiv template like 11's i32 udiv (rule 4; §2 fixes
; udiv(a, 0)); the backend's circuit reference for it is compiler-rt's __udivti3 (udivmodti4.c), which is in the
; source bundle for lifting if a direct 128-bit divider is not provided. -O1 rewrote p + (c << 64) in mul_i128 into
; (x | 1 << 64) * c; the lowering follows the IR, not the C.
source_filename = "i128.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i64 @mul_i128(i64 noundef %0, double noundef %1, i64 noundef %2) {
  %4 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %4 = cq_theta_ull(%0, %1)  [register x]
  call void @cqrt_ry_i64(i32 %4, double %1)    ; IR: %4 = cq_theta_ull(%0, %1)  [Ry]
  %5 = call i32 @cq_template_zext_i64_to_i128(i32 %4)    ; IR: %5 = zext i64 %4 to i128
  %6 = zext i64 %2 to i128    ; IR: %6 = zext i64 %2 to i128  (classical)
  %7 = call i32 @cq_template_or_i128_hl(i32 %5, i128 18446744073709551616)    ; IR: %7 = or disjoint i128 %5, 1 << 64
  %8 = call i32 @cq_template_mul_i128_hl(i32 %7, i128 %6)    ; IR: %8 = mul i128 %7, %6
  %9 = call i32 @cq_template_lshr_i128_hl(i32 %8, i128 64)    ; IR: %9 = lshr i128 %8, 64
  %10 = call i32 @cq_template_trunc_i128_to_i64(i32 %9)    ; IR: %10 = trunc nuw i128 %9 to i64  [result rail]
  call void @cq_template_lshr_i128_hl_unc(i32 %9, i32 %8, i128 64)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_mul_i128_hl_unc(i32 %8, i32 %7, i128 %6)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_or_i128_hl_unc(i32 %7, i32 %5, i128 18446744073709551616)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_zext_i64_to_i128_unc(i32 %5, i32 %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %11 = call i64 @cqrt_measure_i64(i32 %10)    ; IR: %11 = cq_measure_ull(%10)
  ret i64 %11    ; IR: ret i64 %11
}

define i64 @div_i128(i64 noundef %0, double noundef %1, i64 noundef %2, i64 noundef %3) {
  %5 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %5 = cq_theta_ull(%0, %1)  [register x]
  call void @cqrt_ry_i64(i32 %5, double %1)    ; IR: %5 = cq_theta_ull(%0, %1)  [Ry]
  %6 = zext i64 %2 to i128    ; IR: %6 = zext i64 %2 to i128  (classical)
  %7 = shl nuw i128 %6, 64    ; IR: %7 = shl nuw i128 %6, 64  (classical)
  %8 = zext i64 %3 to i128    ; IR: %8 = zext i64 %3 to i128  (classical)
  %9 = or disjoint i128 %7, %8    ; IR: %9 = or disjoint i128 %7, %8  (classical: the dividend n)
  %10 = call i32 @cq_template_zext_i64_to_i128(i32 %5)    ; IR: %10 = zext i64 %5 to i128
  %11 = call i32 @cq_template_or_i128_hl(i32 %10, i128 18446744073709551616)    ; IR: %11 = or disjoint i128 %10, 1 << 64  (the divisor, never 0)
  %12 = call i32 @cq_template_udiv_i128_lh(i128 %9, i32 %11)    ; IR: %12 = udiv i128 %9, %11  (classical dividend, quantum divisor)
  %13 = call i32 @cq_template_trunc_i128_to_i64(i32 %12)    ; IR: %13 = trunc nuw i128 %12 to i64  [result rail]
  call void @cq_template_udiv_i128_lh_unc(i32 %12, i128 %9, i32 %11)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_or_i128_hl_unc(i32 %11, i32 %10, i128 18446744073709551616)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_zext_i64_to_i128_unc(i32 %10, i32 %5)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  %14 = call i64 @cqrt_measure_i64(i32 %13)    ; IR: %14 = cq_measure_ull(%13)
  ret i64 %14    ; IR: ret i64 %14
}

declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i64(i32, double)
declare i64 @cqrt_measure_i64(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_zext_i64_to_i128(i32)
declare void @cq_template_zext_i64_to_i128_unc(i32, i32)
declare i32 @cq_template_or_i128_hl(i32, i128)
declare void @cq_template_or_i128_hl_unc(i32, i32, i128)
declare i32 @cq_template_mul_i128_hl(i32, i128)
declare void @cq_template_mul_i128_hl_unc(i32, i32, i128)
declare i32 @cq_template_lshr_i128_hl(i32, i128)
declare void @cq_template_lshr_i128_hl_unc(i32, i32, i128)
declare i32 @cq_template_udiv_i128_lh(i128, i32)
declare void @cq_template_udiv_i128_lh_unc(i32, i128, i32)
declare i32 @cq_template_trunc_i128_to_i64(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
