; HAND-WRITTEN. Rules: 4, 9, 5, 6, 2.
; Checked: uadd_overflow_qc: overflow ? c : x + c; usub_overflow_qq: (x - y) + (unsigned long)overflow; rotr_qc:
; rotr(x, k); rotr_qq: rotr(x, k) with a quantum k (each measured).
; Clean: uadd_overflow_qc's wrapped sum and overflow flag; usub_overflow_qq's overflow flag, then by rule 6 its old x
; (operand 0 of the sub; t = d + y); rotr_qc's and rotr_qq's old x (rule 6: a rotate is a bijection in x for any amount;
; t = fshl(r, r, k)); each t uncomputed, all freed.
; Kept: uadd_overflow_qc's x (its select result has no inverse), usub_overflow_qq's y, rotr_qq's k (a rotate is no
; bijection in its amount); the measured result rails (the select, the wrapped difference and
; its zext'd flag, the two funnel shifts).
; Rotations: Ry(th) on x (uadd_overflow_qc, rotr_qc); Ry(tx) on x and Ry(ty) on y (usub_overflow_qq); Ry(tx) on x and
; Ry(tk) on k (rotr_qq).
; Width and op variants of 92 and 56, the three intrinsics the LLVM libc census (LIBC_COVERAGE.md) reported without an
; example. llvm.uadd.with.overflow and llvm.usub.with.overflow return { iN, i1 }: as in 92 the aggregate is TWO templates
; over the same operands (rule 4), the value is the plain wrapping opcode (add_i32_hl, sub_i64: that IS element 0) and
; the flag is cq_template_u<op>_overflow_<W>[_hl], an i1 rail with its own _unc; extractvalue picks the rail, zext i1 is
; the cast template. llvm.fshr is the three-operand funnel shift of 56 (fshl): a rotate is fshr(x, x, k), the same rail
; read in both value slots (56's same-operand rule), with the _qql form for a classical amount and the all-quantum form
; cq_template_fshr_i32 (three handles, as fma's unsuffixed form) when the amount is a register. Everything not measured
; is uncomputed in reverse order; a dead register whose kept result is a bijection in it is then cleaned by rule 6.
source_filename = "overflow_fshr_variants.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @uadd_overflow_qc(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %2)    ; IR: %5 = uadd.with.overflow(%4, %2): element 0, the wrapped sum (%7)
  %6 = call i32 @cq_template_uadd_overflow_i32_hl(i32 %4, i32 %2)    ; IR: %5: element 1, the overflow flag (%6)
  %7 = call i32 @cq_template_select_i32_lh(i32 %6, i32 %2, i32 %5)    ; IR: %8 = select i1 %6, i32 %2, i32 %7  [result rail]
  call void @cq_template_uadd_overflow_i32_hl_unc(i32 %6, i32 %4, i32 %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %4, i32 %2)    ; IR: uncompute %7
  call void @cqrt_free(i32 %5)    ; IR: release the %7 rail (|0>)
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %9 = cq_measure_ui32(%8)
  ret i32 %8    ; IR: ret i32 %9
}

define i64 @usub_overflow_qq(i64 noundef %0, i64 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %5 = cq_theta_ul(%0, %2)  [register x]
  call void @cqrt_ry_i64(i32 %5, double %2)    ; IR: %5 = cq_theta_ul(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i64(i64 %1)    ; IR: %6 = cq_theta_ul(%1, %3)  [register y]
  call void @cqrt_ry_i64(i32 %6, double %3)    ; IR: %6 = cq_theta_ul(%1, %3)  [Ry]
  %7 = call i32 @cq_template_sub_i64(i32 %5, i32 %6)    ; IR: %7 = usub.with.overflow(%5, %6): element 0, the wrapped difference (%9)  [measured]
  %8 = call i32 @cq_template_usub_overflow_i64(i32 %5, i32 %6)    ; IR: %7: element 1, the overflow flag (%8)
  %9 = call i32 @cq_template_zext_i1_to_i32(i32 %8)    ; IR: %10 = zext i1 %8 to i32  [measured]
  call void @cq_template_usub_overflow_i64_unc(i32 %8, i32 %5, i32 %6)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %10 = call i32 @cq_template_add_i64(i32 %7, i32 %6)    ; IR: rule 6: t = d + y recomputes the old x (the update is a bijection in it)
  call void @cqrt_copy_i64(i32 %10, i32 %5)    ; IR: rule 6: x ^= t: the dead x rail is now |0>
  call void @cq_template_add_i64_unc(i32 %10, i32 %7, i32 %6)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %10)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %5)    ; IR: release the old x rail (|0> after the copy)
  %11 = call i64 @cqrt_measure_i64(i32 %7)    ; IR: %11 = cq_measure_ul(%9)
  %12 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %12 = cq_measure_si32(%10)
  %13 = sext i32 %12 to i64    ; IR: %13 = sext i32 %12 to i64  (classical)
  %14 = add i64 %11, %13    ; IR: %14 = add i64 %11, %13  (classical)
  ret i64 %14    ; IR: ret i64 %14
}

define i32 @rotr_qc(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_ui32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_fshr_i32_qql(i32 %4, i32 %4, i32 %2)    ; IR: %5 = llvm.fshr.i32(%4, %4, %2)  (x in both value slots, classical amount)  [result rail]
  %6 = call i32 @cq_template_fshl_i32_qql(i32 %5, i32 %5, i32 %2)    ; IR: rule 6: t = rotl(r, c) recomputes the old x (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %6, i32 %4)    ; IR: rule 6: x ^= t: the dead x rail is now |0>
  call void @cq_template_fshl_i32_qql_unc(i32 %6, i32 %5, i32 %5, i32 %2)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %6)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the old x rail (|0> after the copy)
  %7 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_ui32(%5)
  ret i32 %7    ; IR: ret i32 %6
}

define i32 @rotr_qq(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_ui32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_ui32(%1, %3)  [register k]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_ui32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_fshr_i32(i32 %5, i32 %5, i32 %6)    ; IR: %7 = llvm.fshr.i32(%5, %5, %6)  (x in both value slots, quantum amount)  [result rail]
  %8 = call i32 @cq_template_fshl_i32(i32 %7, i32 %7, i32 %6)    ; IR: rule 6: t = rotl(r, k) recomputes the old x (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %8, i32 %5)    ; IR: rule 6: x ^= t: the dead x rail is now |0>
  call void @cq_template_fshl_i32_unc(i32 %8, i32 %7, i32 %7, i32 %6)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %8)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %5)    ; IR: release the old x rail (|0> after the copy)
  %9 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %8 = cq_measure_ui32(%7)
  ret i32 %9    ; IR: ret i32 %8
}

declare void @cqrt_copy_i64(i32, i32)

declare void @cq_template_add_i64_unc(i32, i32, i32)

declare i32 @cq_template_add_i64(i32, i32)

declare void @cq_template_fshl_i32_unc(i32, i32, i32, i32)

declare i32 @cq_template_fshl_i32(i32, i32, i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cq_template_fshl_i32_qql_unc(i32, i32, i32, i32)

declare i32 @cq_template_fshl_i32_qql(i32, i32, i32)

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i64(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare i64 @cqrt_measure_i64(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_uadd_overflow_i32_hl(i32, i32)
declare void @cq_template_uadd_overflow_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare i32 @cq_template_sub_i64(i32, i32)
declare i32 @cq_template_usub_overflow_i64(i32, i32)
declare void @cq_template_usub_overflow_i64_unc(i32, i32, i32)
declare i32 @cq_template_zext_i1_to_i32(i32)
declare i32 @cq_template_fshr_i32_qql(i32, i32, i32)
declare i32 @cq_template_fshr_i32(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
