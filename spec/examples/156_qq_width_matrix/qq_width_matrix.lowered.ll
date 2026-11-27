; HAND-WRITTEN. Rules: 4, 2, 1, 5, 6, §1.2, §2.
; Checked: each function's measured result.
; Clean: the shift-amount mask rails of shl_qq_i16 / ashr_qq_i64 (uncomputed and freed before the measurement).
; sub_qq_i8: nothing (its result is the a rail, updated in place, operand 0 of the IR sub).
; Kept: the two rotated registers of every other function (no inverse), sub_qq_i8's b, and the measured result rail (sub_qq_i8's a).
; Rotations: Ry(ta) on a and Ry(tb) on b in every function.
; Both operands quantum at every width the earlier examples lacked (10/12/13/19 covered i32 qq and the _hl/_lh mixed
; forms; sub_qq_i8's sub of the dead a is rule 6's in-place update, sub_i8(b, a), owner 2026-11-27): the template is the bare qq shape cq_template_<op>_<W>(a, b) (§1.2: shape omitted = all handles), operands in
; the IR's order, into a fresh rail (rule 4). The classical mask of a quantum shift amount (b & 7, b & 63) is a _hl and,
; a garbage rail uncomputed right after the shift (rule 5). Totalization (§2): sdiv/srem/udiv by a quantum zero and
; sdiv(INT_MIN, -1) take the table's values; a quantum SHIFT AMOUNT is taken mod W (x86 semantics) although both masks
; here already keep it below W (7 < 16, 63 < 64). fadd/fdiv at f32 and f64 are IEEE round-to-nearest-even.
source_filename = "qq_width_matrix.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define signext i8 @sub_qq_i8(i8 noundef signext %0, i8 noundef signext %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i8(i8 %0)    ; IR: %5 = cq_theta_si8(%0, %2)  [register a]
  call void @cqrt_ry_i8(i32 %5, double %2)    ; IR: %5 = cq_theta_si8(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i8(i8 %1)    ; IR: %6 = cq_theta_si8(%1, %3)  [register b]
  call void @cqrt_ry_i8(i32 %6, double %3)    ; IR: %6 = cq_theta_si8(%1, %3)  [Ry]
  call void @cqrt_sub_i8(i32 %6, i32 %5)    ; IR: %7 = sub i8 %5, %6  [rule 6, in-place update (sub, owner 2026-11-27): a is dead after the sub, so the result IS the a rail: a -= b]
  %7 = call i8 @cqrt_measure_i8(i32 %5)    ; IR: %8 = cq_measure_si8(%7)
  ret i8 %7    ; IR: ret i8 %8
}

define signext i16 @shl_qq_i16(i16 noundef signext %0, i16 noundef signext %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i16(i16 %0)    ; IR: %5 = cq_theta_si16(%0, %2)  [register a]
  call void @cqrt_ry_i16(i32 %5, double %2)    ; IR: %5 = cq_theta_si16(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i16(i16 %1)    ; IR: %6 = cq_theta_si16(%1, %3)  [register b]
  call void @cqrt_ry_i16(i32 %6, double %3)    ; IR: %6 = cq_theta_si16(%1, %3)  [Ry]
  %7 = call i32 @cq_template_and_i16_hl(i32 %6, i16 7)    ; IR: %7 = and i16 %6, 7  [the shift amount, a garbage rail]
  %8 = call i32 @cq_template_shl_i16(i32 %5, i32 %7)    ; IR: %8 = shl i16 %5, %7  [quantum amount: taken mod 16 (§2); here < 8]
  call void @cq_template_and_i16_hl_unc(i32 %7, i32 %6, i16 7)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %9 = call i16 @cqrt_measure_i16(i32 %8)    ; IR: %9 = cq_measure_si16(%8)
  ret i16 %9    ; IR: ret i16 %9
}

define i64 @ashr_qq_i64(i64 noundef %0, i64 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %5 = cq_theta_sll(%0, %2)  [register a]
  call void @cqrt_ry_i64(i32 %5, double %2)    ; IR: %5 = cq_theta_sll(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i64(i64 %1)    ; IR: %6 = cq_theta_sll(%1, %3)  [register b]
  call void @cqrt_ry_i64(i32 %6, double %3)    ; IR: %6 = cq_theta_sll(%1, %3)  [Ry]
  %7 = call i32 @cq_template_and_i64_hl(i32 %6, i64 63)    ; IR: %7 = and i64 %6, 63  [the shift amount, a garbage rail]
  %8 = call i32 @cq_template_ashr_i64(i32 %5, i32 %7)    ; IR: %8 = ashr i64 %5, %7  [quantum amount: taken mod 64 (§2)]
  call void @cq_template_and_i64_hl_unc(i32 %7, i32 %6, i64 63)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %9 = call i64 @cqrt_measure_i64(i32 %8)    ; IR: %9 = cq_measure_sll(%8)
  ret i64 %9    ; IR: ret i64 %9
}

define i32 @sdiv_qq_i32(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %2)  [register a]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_si32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_si32(%1, %3)  [register b]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_si32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_sdiv_i32(i32 %5, i32 %6)    ; IR: %7 = sdiv i32 %5, %6  [§2: b = 0 gives -1 for a >= 0 else +1; INT_MIN / -1 gives INT_MIN]
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %8    ; IR: ret i32 %8
}

define i32 @srem_qq_i32(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %2)  [register a]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_si32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_si32(%1, %3)  [register b]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_si32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_srem_i32(i32 %5, i32 %6)    ; IR: %7 = srem i32 %5, %6  [§2: b = 0 gives a; INT_MIN % -1 gives 0]
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %8    ; IR: ret i32 %8
}

define i32 @udiv_qq_i32(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %2)  [register a]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_ui32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_ui32(%1, %3)  [register b]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_ui32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_udiv_i32(i32 %5, i32 %6)    ; IR: %7 = udiv i32 %5, %6  [§2: b = 0 gives 2^32 - 1]
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_ui32(%7)
  ret i32 %8    ; IR: ret i32 %8
}

define i64 @and_qq_i64(i64 noundef %0, i64 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %5 = cq_theta_sll(%0, %2)  [register a]
  call void @cqrt_ry_i64(i32 %5, double %2)    ; IR: %5 = cq_theta_sll(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i64(i64 %1)    ; IR: %6 = cq_theta_sll(%1, %3)  [register b]
  call void @cqrt_ry_i64(i32 %6, double %3)    ; IR: %6 = cq_theta_sll(%1, %3)  [Ry]
  %7 = call i32 @cq_template_and_i64(i32 %6, i32 %5)    ; IR: %7 = and i64 %6, %5  [qq shape, the IR's operand order]
  %8 = call i64 @cqrt_measure_i64(i32 %7)    ; IR: %8 = cq_measure_sll(%7)
  ret i64 %8    ; IR: ret i64 %8
}

define float @fadd_qq_f32(float noundef %0, float noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_f32(float %0)    ; IR: %5 = cq_theta_f32(%0, %2)  [register a]
  call void @cqrt_ry_f32(i32 %5, double %2)    ; IR: %5 = cq_theta_f32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_f32(float %1)    ; IR: %6 = cq_theta_f32(%1, %3)  [register b]
  call void @cqrt_ry_f32(i32 %6, double %3)    ; IR: %6 = cq_theta_f32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_fadd_f32(i32 %5, i32 %6)    ; IR: %7 = fadd float %5, %6  [IEEE binary32, round to nearest even]
  %8 = call float @cqrt_measure_f32(i32 %7)    ; IR: %8 = cq_measure_f32(%7)
  ret float %8    ; IR: ret float %8
}

define float @fdiv_qq_f32(float noundef %0, float noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_f32(float %0)    ; IR: %5 = cq_theta_f32(%0, %2)  [register a]
  call void @cqrt_ry_f32(i32 %5, double %2)    ; IR: %5 = cq_theta_f32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_f32(float %1)    ; IR: %6 = cq_theta_f32(%1, %3)  [register b]
  call void @cqrt_ry_f32(i32 %6, double %3)    ; IR: %6 = cq_theta_f32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_fdiv_f32(i32 %5, i32 %6)    ; IR: %7 = fdiv float %5, %6  [IEEE binary32; a / 0 is the IEEE result (Inf / NaN)]
  %8 = call float @cqrt_measure_f32(i32 %7)    ; IR: %8 = cq_measure_f32(%7)
  ret float %8    ; IR: ret float %8
}

define double @fdiv_qq_f64(double noundef %0, double noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %5 = cq_theta_f64(%0, %2)  [register a]
  call void @cqrt_ry_f64(i32 %5, double %2)    ; IR: %5 = cq_theta_f64(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_f64(double %1)    ; IR: %6 = cq_theta_f64(%1, %3)  [register b]
  call void @cqrt_ry_f64(i32 %6, double %3)    ; IR: %6 = cq_theta_f64(%1, %3)  [Ry]
  %7 = call i32 @cq_template_fdiv_f64(i32 %5, i32 %6)    ; IR: %7 = fdiv double %5, %6  [IEEE binary64, round to nearest even]
  %8 = call double @cqrt_measure_f64(i32 %7)    ; IR: %8 = cq_measure_f64(%7)
  ret double %8    ; IR: ret double %8
}

declare i32 @cqrt_alloc_i8(i8 signext)
declare i32 @cqrt_alloc_i16(i16 signext)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare i32 @cqrt_alloc_f32(float)
declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_i8(i32, double)
declare void @cqrt_ry_i16(i32, double)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i64(i32, double)
declare void @cqrt_ry_f32(i32, double)
declare void @cqrt_ry_f64(i32, double)
declare void @cqrt_sub_i8(i32, i32)
declare i32 @cq_template_and_i16_hl(i32, i16 signext)
declare void @cq_template_and_i16_hl_unc(i32, i32, i16 signext)
declare i32 @cq_template_shl_i16(i32, i32)
declare i32 @cq_template_and_i64_hl(i32, i64)
declare void @cq_template_and_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_ashr_i64(i32, i32)
declare i32 @cq_template_sdiv_i32(i32, i32)
declare i32 @cq_template_srem_i32(i32, i32)
declare i32 @cq_template_udiv_i32(i32, i32)
declare i32 @cq_template_and_i64(i32, i32)
declare i32 @cq_template_fadd_f32(i32, i32)
declare i32 @cq_template_fdiv_f32(i32, i32)
declare i32 @cq_template_fdiv_f64(i32, i32)
declare void @cqrt_free(i32)
declare signext i8 @cqrt_measure_i8(i32)
declare signext i16 @cqrt_measure_i16(i32)
declare i32 @cqrt_measure_i32(i32)
declare i64 @cqrt_measure_i64(i32)
declare float @cqrt_measure_f32(i32)
declare double @cqrt_measure_f64(i32)
