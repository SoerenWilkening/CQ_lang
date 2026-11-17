; HAND-WRITTEN. Rules: 8, 18, 19, 12, 5, 2.
; Checked: x (measured).
; Clean: the left flag F = (x > k), the clone's result rail, the right flag E = (f(x, c) == m) and the conjunction
; flag G, all freed before the Ry(-tx) on x.
; Kept: none.
; Rotations: (Ry, x, tx, 1); (P, G, p, x > k && x * c + 1 == m); (Ry, x, -tx, 1).
; The right operand of `&&` is a noinline call, so -O1 keeps the short-circuit diamond (block %9 under %8) instead of
; folding to `and i1`. f has no non-pure gate, so under the quantum predicate it is called UNGUARDED (rule 19) as the
; lifted clone __cq_q_f_10 (rule 18, §1.4 mask: x quantum, c classical): the clone computes x * c + 1 out of place,
; copies the result into a fresh rail, uncomputes its body and returns the copy; its twin __cq_q_f_10_unc recomputes,
; XORs the result out and uncomputes, after which the caller frees the result rail. The compare is one flag E on the
; result rail; the phase block's path predicate F & E is one and_i1 into a fresh |0> flag G (rule 8), the phase is a
; kickback on G (rule 12: a quantum predicate is in scope). Teardown is LIFO: G, E, the call result (twin), F, all before
; the non-diagonal Ry on their source x (rule 5). The original f is dead and dropped.
source_filename = "short_circuit_call_rhs.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @short_circuit_call_rhs(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %7, i32 %2)    ; IR: %8 = icmp sgt i32 %7, %2  [path predicate of block %9: the left conjunct]
  %9 = call fastcc i32 @__cq_q_f_10(i32 %7, i32 %3)    ; IR: block %9: %10 = call @f(%7, %3): pure callee, lifted and evaluated unguarded
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 %4)    ; IR: block %9: %11 = icmp eq i32 %10, %4  [the right conjunct]
  %11 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: path predicate of block %12 = %8 & %11  [fresh |0> flag]
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %11)    ; IR: br i1 %11 inside block %9: %8 & %11 (Toffoli into the |0> flag)
  call void @cqrt_rz_i1(i32 %11, double %5)    ; IR: block %12: cq_phi(%5)  [kickback on the conjunction]
  call void @cqrt_and_i1(i32 %8, i32 %10, i32 %11)    ; IR: uncompute the %12 predicate (%8, %11 unchanged)
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %9, i32 %4)    ; IR: uncompute %11
  call void @cqrt_free(i32 %10)    ; IR: release the %11 rail (|0>)
  call fastcc void @__cq_q_f_10_unc(i32 %9, i32 %7, i32 %3)    ; IR: uncompute %10 (the twin XORs the result out of its rail)
  call void @cqrt_free(i32 %9)    ; IR: release the %10 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %8, i32 %7, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  %12 = fneg double %1    ; IR: %14 = fneg double %1  (classical)
  call void @cqrt_ry_i32(i32 %7, double %12)    ; IR: %15 = cq_theta_si32(%7, %14)  [Ry in place on x]
  %13 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %16 = cq_measure_si32(%15)
  ret i32 %13    ; IR: ret i32 %16
}

define internal fastcc i32 @__cq_q_f_10(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_mul_i32_hl(i32 %0, i32 %1)    ; IR: f: %3 = mul nsw i32 %1, %0  (commutative: the classical operand moves to the _hl slot)
  %4 = call i32 @cq_template_add_i32_hl(i32 %3, i32 1)    ; IR: f: %4 = add nsw i32 %3, 1
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: f: ret i32 %4  [result rail of the call]
  call void @cqrt_copy_i32(i32 %4, i32 %5)    ; IR: f: ret i32 %4  [copy the result out]
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %3, i32 1)    ; IR: f: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: f: release the %4 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %3, i32 %0, i32 %1)    ; IR: f: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: f: release the %3 rail (|0>)
  ret i32 %5    ; IR: f: ret i32 %4
}

define internal fastcc void @__cq_q_f_10_unc(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cq_template_mul_i32_hl(i32 %1, i32 %2)    ; IR: f: recompute %3
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 1)    ; IR: f: recompute %4
  call void @cqrt_copy_i32(i32 %5, i32 %0)    ; IR: f: ret i32 %4  [xor the result out of %out]
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %4, i32 1)    ; IR: f: uncompute %4
  call void @cqrt_free(i32 %5)    ; IR: f: release the %4 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %4, i32 %1, i32 %2)    ; IR: f: uncompute %3
  call void @cqrt_free(i32 %4)    ; IR: f: release the %3 rail (|0>)
  ret void    ; IR: f: ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
