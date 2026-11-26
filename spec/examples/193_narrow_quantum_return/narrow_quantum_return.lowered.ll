; HAND-WRITTEN. Rules: 19, §1.1 (escaped rail), 6, 4, 5, 2, 9.
; Checked: narrow_bool_consumer: (x > k) ? 5 : 2 (measured); narrow_short_consumer: (short)((s + c) * 2) (measured);
;          wide_long_consumer: (x ^ c) + 1 (measured). The three entries return UNMEASURED quantum values: each `ret`
;          carries the HANDLE of the result rail (§1.1, rule 19), checked as that rail's basis value.
; Clean: narrow_return_short and wide_return_long: nothing (s + c and x ^ c are rule 6's in-place updates: s and x are
;        dead, so each is ONE core gate on the register's rail, nothing to free); narrow_bool_consumer: the flag x > k (uncomputed after the select, freed);
;        narrow_short_consumer: the sum s + c (uncomputed against s after the shift, freed; rule 6 does NOT apply to s: the
;        composite update (s + c) << 1 is no bijection, so s must stay to uncompute the sum); wide_long_consumer: nothing (x ^ c
;        and (x ^ c) + 1 are a chain of two rule-6 in-place updates, xorc_i64 then addc_i64, on the x rail).
; Kept: each entry's returned rail (escapes with the return; never freed; in narrow_return_short and wide_return_long the
;       register's own rail, updated in place); narrow_return_bool's x (the compare is no
;       bijection, so the rotated register stays, frozen); narrow_bool_consumer's x; narrow_short_consumer's s; every
;       measured rail (in wide_long_consumer the x rail after its two in-place updates).
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
  call void @cqrt_addc_i16(i32 %4, i16 %2)    ; IR: %5 = add i16 %4, %2  [rule 6, in-place update: s is dead after the add, so the result IS the s rail]
  ret i32 %4    ; IR: ret i16 %5  (the i32 is the HANDLE of the i16 rail: the external return type widens to i32; an escaped rail, never freed)
}

define i64 @wide_return_long(i64 noundef %0, double noundef %1, i64 noundef %2) {
  %4 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %4 = cq_theta_sl(%0, %1)  [register x]
  call void @cqrt_ry_i64(i32 %4, double %1)    ; IR: %4 = cq_theta_sl(%0, %1)  [Ry]
  call void @cqrt_xorc_i64(i32 %4, i64 %2)    ; IR: %5 = xor i64 %4, %2  [rule 6, in-place update: x is dead after the xor, so the result IS the x rail]
  %5 = zext i32 %4 to i64    ; IR: the HANDLE zero-extended to the C return type (an i64 holds an i32)
  ret i64 %5    ; IR: ret i64 %5  (an escaped rail, never freed)
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
  call void @cqrt_xorc_i64(i32 %4, i64 %2)    ; IR: %5 = xor i64 %4, %2  [the entry's result; rule 6, in-place update: x is dead after the xor, so r IS the x rail]
  call void @cqrt_addc_i64(i32 %4, i64 1)    ; IR: %6 = add nsw i64 %5, 1  [rule 6, in-place update: r is dead after the add, so the result IS the same rail]
  %5 = call i64 @cqrt_measure_i64(i32 %4)    ; IR: %7 = cq_measure_sl(%6)
  ret i64 %5    ; IR: ret i64 %7
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
declare void @cqrt_addc_i16(i32, i16)
declare i32 @cq_template_shl_i16_hl(i32, i16 signext)
declare void @cqrt_xorc_i64(i32, i64)
declare void @cqrt_addc_i64(i32, i64)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare signext i16 @cqrt_measure_i16(i32)
declare i64 @cqrt_measure_i64(i32)
