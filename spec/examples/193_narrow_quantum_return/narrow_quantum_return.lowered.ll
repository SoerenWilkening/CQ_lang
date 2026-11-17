; HAND-WRITTEN. Rules: 19, §1.1 (escaped rail), 6, 4, 5, 2, 9.
; Checked: narrow_bool_consumer: (x > k) ? 5 : 2 (measured); narrow_short_consumer: (short)((s + c) * 2) (measured);
;          wide_long_consumer: (x ^ c) + 1 (measured). The three entries return UNMEASURED quantum values: each `ret`
;          carries the HANDLE of the result rail (§1.1, rule 19), checked as that rail's basis value.
; Clean: narrow_return_short: the old s (rule 6: s + c is a bijection in s, s is dead) and t = r - c; wide_return_long: the
;        old x (rule 6: x ^ c) and t = r ^ c; narrow_bool_consumer: the flag x > k (uncomputed after the select, freed);
;        narrow_short_consumer: the sum s + c (uncomputed against s after the shift, freed; rule 6 does NOT apply to s: the
;        composite update (s + c) << 1 is no bijection, so s must stay to uncompute the sum); wide_long_consumer: the old x
;        and the old x ^ c (two rule-6 clean-ups, each a bijective update of a dead value) and their inverses.
; Kept: each entry's returned rail (escapes with the return; never freed); narrow_return_bool's x (the compare is no
;       bijection, so the rotated register stays, frozen); narrow_bool_consumer's x; narrow_short_consumer's s; every
;       measured rail.
; Rotations: Ry(tx) on x / Ry(ts) on s in each function.
; RETURN TYPE OF AN ENTRY RETURNING A QUANTUM VALUE (rule 19, ruling 2026-10-31). Every quantum value is an i32 handle
; (§1.1). A C return type that cannot hold an i32 (`_Bool`: `zeroext i1`; `short`: `signext i16`; `char`; every floating
; or pointer type) is replaced at the external signature by i32: truncating the handle would name another rail, and the
; compiler never measures a value the program does not measure. The parameter list keeps the C ABI (`i16 signext`
; parameters stay). An integer return type of 32 bits or more keeps its C type and carries the handle zero-extended
; (162: i32 as is; wide_return_long: `zext i32 %h to i64`). In-module callers see the entry inlined (rule 19; here by
; clang itself, the entries are not `noinline`), so the consumers are ordinary straight-line functions.
source_filename = "narrow_quantum_return.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @narrow_return_bool(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %4, i32 %2)    ; IR: %5 = icmp sgt i32 %4, %2  [the result rail, width i1]
  ret i32 %5    ; IR: ret i1 %5  (the i32 is the HANDLE of the i1 rail: the external return type widens to i32; an escaped rail, never freed)
}

define i32 @narrow_return_short(i16 noundef signext %0, double noundef %1, i16 noundef signext %2) {
  %4 = call i32 @cqrt_alloc_i16(i16 signext %0)    ; IR: %4 = cq_theta_si16(%0, %1)  [register s]
  call void @cqrt_ry_i16(i32 %4, double %1)    ; IR: %4 = cq_theta_si16(%0, %1)  [Ry]
  %5 = call i32 @cq_template_add_i16_hl(i32 %4, i16 signext %2)    ; IR: %5 = add i16 %4, %2  [the result rail]
  %6 = call i32 @cq_template_sub_i16_hl(i32 %5, i16 %2)    ; IR: rule 6: t = r - c recomputes the old s (the update is a bijection in it)
  call void @cqrt_copy_i16(i32 %6, i32 %4)    ; IR: rule 6: s ^= t: the dead s rail is now |0>
  call void @cq_template_sub_i16_hl_unc(i32 %6, i32 %5, i16 %2)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %6)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the old s rail (|0> after the copy)
  ret i32 %5    ; IR: ret i16 %5  (the i32 is the HANDLE of the i16 rail: the external return type widens to i32; an escaped rail, never freed)
}

define i64 @wide_return_long(i64 noundef %0, double noundef %1, i64 noundef %2) {
  %4 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %4 = cq_theta_sl(%0, %1)  [register x]
  call void @cqrt_ry_i64(i32 %4, double %1)    ; IR: %4 = cq_theta_sl(%0, %1)  [Ry]
  %5 = call i32 @cq_template_xor_i64_hl(i32 %4, i64 %2)    ; IR: %5 = xor i64 %4, %2  [the result rail]
  %6 = call i32 @cq_template_xor_i64_hl(i32 %5, i64 %2)    ; IR: rule 6: t = r ^ c recomputes the old x (xor is its own inverse)
  call void @cqrt_copy_i64(i32 %6, i32 %4)    ; IR: rule 6: x ^= t: the dead x rail is now |0>
  call void @cq_template_xor_i64_hl_unc(i32 %6, i32 %5, i64 %2)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %6)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the old x rail (|0> after the copy)
  %7 = zext i32 %5 to i64    ; IR: the HANDLE zero-extended to the C return type (an i64 holds an i32)
  ret i64 %7    ; IR: ret i64 %5  (an escaped rail, never freed)
}

define i32 @narrow_bool_consumer(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]  (narrow_return_bool inlined by clang)
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %4, i32 %2)    ; IR: %5 = icmp sgt i32 %4, %2  [the entry's result, a flag]
  %6 = call i32 @cq_template_select_i32_ll(i32 %5, i32 5, i32 2)    ; IR: %6 = select i1 %5, i32 5, i32 2  [result rail; two classical arms]
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %5, i32 %4, i32 %2)    ; IR: uncompute the flag (its last use was the select)
  call void @cqrt_free(i32 %5)    ; IR: release the flag (|0>)
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %7 = cq_measure_si32(%6)
  ret i32 %7    ; IR: ret i32 %7
}

define i32 @narrow_short_consumer(i16 noundef signext %0, double noundef %1, i16 noundef signext %2) {
  %4 = call i32 @cqrt_alloc_i16(i16 signext %0)    ; IR: %4 = cq_theta_si16(%0, %1)  [register s]  (narrow_return_short inlined by clang)
  call void @cqrt_ry_i16(i32 %4, double %1)    ; IR: %4 = cq_theta_si16(%0, %1)  [Ry]
  %5 = call i32 @cq_template_add_i16_hl(i32 %4, i16 signext %2)    ; IR: %5 = add i16 %4, %2  [the entry's result]
  %6 = call i32 @cq_template_shl_i16_hl(i32 %5, i16 signext 1)    ; IR: %6 = shl i16 %5, 1  [result rail]
  call void @cq_template_add_i16_hl_unc(i32 %5, i32 %4, i16 signext %2)    ; IR: uncompute the sum against s (rule 5; the composite (s + c) << 1 is no bijection, so rule 6 leaves s)
  call void @cqrt_free(i32 %5)    ; IR: release the sum (|0>)
  %7 = call signext i16 @cqrt_measure_i16(i32 %6)    ; IR: %7 = cq_measure_si16(%6)
  %8 = sext i16 %7 to i32    ; IR: %8 = sext i16 %7 to i32  (classical)
  ret i32 %8    ; IR: ret i32 %8
}

define i64 @wide_long_consumer(i64 noundef %0, double noundef %1, i64 noundef %2) {
  %4 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %4 = cq_theta_sl(%0, %1)  [register x]  (wide_return_long inlined by clang)
  call void @cqrt_ry_i64(i32 %4, double %1)    ; IR: %4 = cq_theta_sl(%0, %1)  [Ry]
  %5 = call i32 @cq_template_xor_i64_hl(i32 %4, i64 %2)    ; IR: %5 = xor i64 %4, %2  [the entry's result]
  %6 = call i32 @cq_template_xor_i64_hl(i32 %5, i64 %2)    ; IR: rule 6: t = r ^ c recomputes the old x
  call void @cqrt_copy_i64(i32 %6, i32 %4)    ; IR: rule 6: x ^= t: |0>
  call void @cq_template_xor_i64_hl_unc(i32 %6, i32 %5, i64 %2)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %6)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the old x rail (|0>)
  %7 = call i32 @cq_template_add_i64_hl(i32 %5, i64 1)    ; IR: %6 = add nsw i64 %5, 1  [result rail]
  %8 = call i32 @cq_template_sub_i64_hl(i32 %7, i64 1)    ; IR: rule 6: t = p - 1 recomputes the old r (r + 1 is a bijection in r, r is dead)
  call void @cqrt_copy_i64(i32 %8, i32 %5)    ; IR: rule 6: r ^= t: |0>
  call void @cq_template_sub_i64_hl_unc(i32 %8, i32 %7, i64 1)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %8)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %5)    ; IR: release the old r rail (|0>)
  %9 = call i64 @cqrt_measure_i64(i32 %7)    ; IR: %7 = cq_measure_sl(%6)
  ret i64 %9    ; IR: ret i64 %7
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i16(i16 signext)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i16(i32, double)
declare void @cqrt_ry_i64(i32, double)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare i32 @cq_template_add_i16_hl(i32, i16 signext)
declare void @cq_template_add_i16_hl_unc(i32, i32, i16 signext)
declare i32 @cq_template_sub_i16_hl(i32, i16)
declare void @cq_template_sub_i16_hl_unc(i32, i32, i16)
declare i32 @cq_template_shl_i16_hl(i32, i16 signext)
declare i32 @cq_template_xor_i64_hl(i32, i64)
declare void @cq_template_xor_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare i32 @cq_template_sub_i64_hl(i32, i64)
declare void @cq_template_sub_i64_hl_unc(i32, i32, i64)
declare void @cqrt_copy_i16(i32, i32)
declare void @cqrt_copy_i64(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare signext i16 @cqrt_measure_i16(i32)
declare i64 @cqrt_measure_i64(i32)
