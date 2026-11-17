; HAND-WRITTEN. Rules: 25, 4, 9, 5, 2.
; Checked: i128_compare_merge: (p > lim << 64 ? p >> 65 : (p + 1) >> 64) truncated to 64 bits, p = (i128)x * c;
; fshl_mixed: (x << 3) | (c >> 29) (each measured).
; Clean: i128_compare_merge: the zext, the product, the compare flag, both arms, the merge (every rail but the
; truncated result).
; Kept: the user register x of each function; the result rails (measured).
; Rotations: Ry(th) on x (i128_compare_merge, i64); Ry(th) on x (fshl_mixed, i32).
; WIDTH VARIANTS, not new mechanisms (rule 25): an i128 compare is the i32 compare of 03 at width 128
; (cq_template_icmp_ugt_i128_hl, one i1 flag rail), an i128 merge under a quantum flag is the select of 04 at width
; 128 (cq_template_select_i128, rule 9), and the i128 literal operands print as in 93. The funnel shift with a QUANTUM
; data operand, a CLASSICAL data operand and a literal amount is the third operand shape of 56's fshl (_qql = two
; quantum, literal amount): _qll = quantum, literal, literal. Only the measured rail survives; every other rail is
; uncomputed LIFO (the select before its arms, the arms before the compare, the compare before the product).
source_filename = "i128_compare_fshl_mixed.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i64 @i128_compare_merge(i64 noundef %0, double noundef %1, i64 noundef %2, i64 noundef %3) {
  %5 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %5 = cq_theta_ull(%0, %1)  [register x]
  call void @cqrt_ry_i64(i32 %5, double %1)    ; IR: %5 = cq_theta_ull(%0, %1)  [Ry]
  %6 = call i32 @cq_template_zext_i64_to_i128(i32 %5)    ; IR: %6 = zext i64 %5 to i128
  %7 = zext i64 %2 to i128    ; IR: %7 = zext i64 %2 to i128  (classical)
  %8 = call i32 @cq_template_mul_i128_hl(i32 %6, i128 %7)    ; IR: %8 = mul nuw i128 %6, %7
  %9 = zext i64 %3 to i128    ; IR: %9 = zext i64 %3 to i128  (classical)
  %10 = shl nuw i128 %9, 64    ; IR: %10 = shl nuw i128 %9, 64  (classical)
  %11 = call i32 @cq_template_icmp_ugt_i128_hl(i32 %8, i128 %10)    ; IR: %11 = icmp ugt i128 %8, %10  [the merge's flag]
  %12 = call i32 @cq_template_lshr_i128_hl(i32 %8, i128 65)    ; IR: %12 = lshr i128 %8, 65  (then arm: r >> 64 with r = p >> 1)
  %13 = call i32 @cq_template_add_i128_hl(i32 %8, i128 1)    ; IR: %13 = add nuw i128 %8, 1  (else arm)
  %14 = call i32 @cq_template_lshr_i128_hl(i32 %13, i128 64)    ; IR: %14 = lshr i128 %13, 64
  %15 = call i32 @cq_template_select_i128(i32 %11, i32 %12, i32 %14)    ; IR: %15 = select i1 %11, i128 %12, i128 %14  [the merge]
  %16 = call i32 @cq_template_trunc_i128_to_i64(i32 %15)    ; IR: %16 = trunc nuw i128 %15 to i64  [result rail]
  call void @cq_template_select_i128_unc(i32 %15, i32 %11, i32 %12, i32 %14)    ; IR: uncompute %15
  call void @cqrt_free(i32 %15)    ; IR: release the %15 rail (|0>)
  call void @cq_template_lshr_i128_hl_unc(i32 %14, i32 %13, i128 64)    ; IR: uncompute %14
  call void @cqrt_free(i32 %14)    ; IR: release the %14 rail (|0>)
  call void @cq_template_add_i128_hl_unc(i32 %13, i32 %8, i128 1)    ; IR: uncompute %13
  call void @cqrt_free(i32 %13)    ; IR: release the %13 rail (|0>)
  call void @cq_template_lshr_i128_hl_unc(i32 %12, i32 %8, i128 65)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call void @cq_template_icmp_ugt_i128_hl_unc(i32 %11, i32 %8, i128 %10)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_mul_i128_hl_unc(i32 %8, i32 %6, i128 %7)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_zext_i64_to_i128_unc(i32 %6, i32 %5)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  %17 = call i64 @cqrt_measure_i64(i32 %16)    ; IR: %17 = cq_measure_ull(%16)
  ret i64 %17    ; IR: ret i64 %17
}

define i32 @fshl_mixed(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_fshl_i32_qll(i32 %4, i32 %2, i32 3)    ; IR: %5 = llvm.fshl.i32(%4, %2, 3): quantum high word, classical low word, literal amount
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_ui32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

declare i32 @cqrt_alloc_i64(i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i64(i32, double)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_zext_i64_to_i128(i32)
declare void @cq_template_zext_i64_to_i128_unc(i32, i32)
declare i32 @cq_template_mul_i128_hl(i32, i128)
declare void @cq_template_mul_i128_hl_unc(i32, i32, i128)
declare i32 @cq_template_icmp_ugt_i128_hl(i32, i128)
declare void @cq_template_icmp_ugt_i128_hl_unc(i32, i32, i128)
declare i32 @cq_template_lshr_i128_hl(i32, i128)
declare void @cq_template_lshr_i128_hl_unc(i32, i32, i128)
declare i32 @cq_template_add_i128_hl(i32, i128)
declare void @cq_template_add_i128_hl_unc(i32, i32, i128)
declare i32 @cq_template_select_i128(i32, i32, i32)
declare void @cq_template_select_i128_unc(i32, i32, i32, i32)
declare i32 @cq_template_trunc_i128_to_i64(i32)
declare i32 @cq_template_fshl_i32_qll(i32, i32, i32)
declare void @cqrt_free(i32)
declare i64 @cqrt_measure_i64(i32)
declare i32 @cqrt_measure_i32(i32)
