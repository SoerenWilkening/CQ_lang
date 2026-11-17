; HAND-WRITTEN. Rules: 18, 9, 15, 2, 10, 5.
; Checked: call_result_as_target's y (the clone's result rail %8 -> %9) and x (%7 -> %10); call_result_as_theta_angle's r
; (%10 -> %11) and x (%6 -> %12); call_result_as_phi_angle's x (%5 -> %9), all measured.
; Clean: every clone-internal rail; call_result_as_theta_angle's and call_result_as_phi_angle's clone result v (%7; %6,
; zeroed by the _unc twin), its uitofp (%8; %7) and the angle register A = fl(s * v) (%9; %8), all freed.
; Kept: x in each function (the rotated register, measured); call_result_as_target's y (%8, rotated in place, frozen,
; measured); call_result_as_theta_angle's r (%10, rotated by the angle rail, frozen, measured).
; Rotations: (Ry, x, th, 1); (Ry, y = pick(x, k, a, b), t, 1) in call_result_as_target; (Ry, x, th, 1);
; (Ry, r, val(A), 1) with A = fl(s * pick8(x, k)) in call_result_as_theta_angle; (Ry, x, th, 1); (P, A, val(A), 1) with
; the same A in call_result_as_phi_angle.
; call_result_as_target: the lifted clone __cq_q_pick_1000 (mask left to right, §1.4) hoists both arms, merges them by
; ONE cq_template_select_i32 on the compare flag (rule 9), copies the merge out as the result rail and uncomputes the
; merge and its operands; the caller's second cq_theta is then a plain Ry on the RESULT RAIL: no alloc (the register
; exists), and y is frozen afterwards (rule 10). A QUANTUM-VALUED ANGLE (rule 15, as 79): the angle s * v is computed
; into an f64 REGISTER by ordinary templates (uitofp of the clone's result, fmul_hl by the classical s: the program's
; IEEE double, bit-exact), and the rotation is ONE gate primitive reading that register: cqrt_ry_i32_qangle(r, A) for
; cq_theta, cqrt_rz_qangle(A) for cq_phi (a relative phase, kicked back onto the sources by A's uncompute). The backend
; supplies the N-bit ladder; the IR never spells it. The angle register is only read, so the LIFO spine uncomputes it,
; then the clone's _unc twin (__cq_q_pick8_10_unc) zeroes the result rail as in 07. (Laddering the integer result
; directly, s*2^k per bit, would realize s*v over the reals, not the rounded double fl(s*v).)
source_filename = "call_result_rotation.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @call_result_as_target(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_si32(%0, %1)  [Ry]
  %8 = call fastcc i32 @__cq_q_pick_1000(i32 %7, i32 %2, i32 %3, i32 %4)    ; IR: %8 = call @pick(%7, %2, %3, %4), quantum clone (arg 0 quantum): y
  call void @cqrt_ry_i32(i32 %8, double %5)    ; IR: %9 = cq_theta_si32(%8, %5): Ry on the result rail itself (no alloc, the register exists)
  %9 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %10 = cq_measure_si32(%9)
  %10 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %11 = cq_measure_si32(%7)
  %11 = add nsw i32 %10, %9    ; IR: %12 = add nsw i32 %11, %10  (classical)
  ret i32 %11    ; IR: ret i32 %12
}

define internal fastcc i32 @__cq_q_pick_1000(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i32 @cq_template_add_i32_hl(i32 %0, i32 %2)    ; IR: %6 = add nsw i32 %2, %0  (true arm, hoisted)
  %6 = call i32 @cq_template_mul_i32_hl(i32 %0, i32 %3)    ; IR: %7 = mul nsw i32 %3, %0  (false arm, hoisted)
  %7 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %0, i32 %1)    ; IR: %5 = icmp sgt i32 %0, %1  [the select's flag]
  %8 = call i32 @cq_template_select_i32(i32 %7, i32 %5, i32 %6)    ; IR: %8 = select i1 %5, i32 %6, i32 %7  [the merge: one select on the flag, rule 9]
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %8  [result rail of the call]
  call void @cqrt_copy_i32(i32 %8, i32 %9)    ; IR: copy the result out
  call void @cq_template_select_i32_unc(i32 %8, i32 %7, i32 %5, i32 %6)    ; IR: uncompute the merge
  call void @cqrt_free(i32 %8)    ; IR: release the merge rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %7, i32 %0, i32 %1)    ; IR: uncompute %5
  call void @cqrt_free(i32 %7)    ; IR: release the %5 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %6, i32 %0, i32 %3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %6)    ; IR: release the %7 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %0, i32 %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %5)    ; IR: release the %6 rail (|0>)
  ret i32 %9    ; IR: ret i32 %8
}

define i32 @call_result_as_theta_angle(i8 noundef zeroext %0, double noundef %1, i8 noundef zeroext %2, i32 noundef %3, double noundef %4) {
  %6 = call i32 @cqrt_alloc_i8(i8 %0)    ; IR: %6 = cq_theta_ui8(%0, %1)  [register x]
  call void @cqrt_ry_i8(i32 %6, double %1)    ; IR: %6 = cq_theta_ui8(%0, %1)  [Ry]
  %7 = call fastcc i32 @__cq_q_pick8_10(i32 %6, i8 %2)    ; IR: %7 = call @pick8(%6, %2), quantum clone (arg 0 quantum): v
  %8 = call i32 @cq_template_uitofp_i8_to_f64(i32 %7)    ; IR: %8 = uitofp i8 %7 to double
  %9 = call i32 @cq_template_fmul_f64_hl(i32 %8, double %4)    ; IR: %9 = fmul double %8, %4  [the angle register: the program's double]
  %10 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: %10 = cq_theta_si32(%3, %9)  [register r]
  call void @cqrt_ry_i32_qangle(i32 %10, i32 %9)    ; IR: %10 = cq_theta_si32(%3, %9): Ry(val(%9)) on r, controlled by the bits of %9
  call void @cq_template_fmul_f64_hl_unc(i32 %9, i32 %8, double %4)    ; IR: uncompute %9 (only read by the rotation)
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_uitofp_i8_to_f64_unc(i32 %8, i32 %7)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call fastcc void @__cq_q_pick8_10_unc(i32 %7, i32 %6, i8 %2)    ; IR: uncompute %7 (adjoint of the call)
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %11 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %11 = cq_measure_si32(%10)
  %12 = call i8 @cqrt_measure_i8(i32 %6)    ; IR: %12 = cq_measure_ui8(%6)
  %13 = zext i8 %12 to i32    ; IR: %13 = zext i8 %12 to i32  (classical)
  %14 = add nsw i32 %11, %13    ; IR: %14 = add nsw i32 %11, %13  (classical)
  ret i32 %14    ; IR: ret i32 %14
}

define i32 @call_result_as_phi_angle(i8 noundef zeroext %0, double noundef %1, i8 noundef zeroext %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i8(i8 %0)    ; IR: %5 = cq_theta_ui8(%0, %1)  [register x]
  call void @cqrt_ry_i8(i32 %5, double %1)    ; IR: %5 = cq_theta_ui8(%0, %1)  [Ry]
  %6 = call fastcc i32 @__cq_q_pick8_10(i32 %5, i8 %2)    ; IR: %6 = call @pick8(%5, %2), quantum clone (arg 0 quantum): v
  %7 = call i32 @cq_template_uitofp_i8_to_f64(i32 %6)    ; IR: %7 = uitofp i8 %6 to double
  %8 = call i32 @cq_template_fmul_f64_hl(i32 %7, double %3)    ; IR: %8 = fmul double %7, %3  [the angle register]
  call void @cqrt_rz_qangle(i32 %8)    ; IR: cq_phi(%8): e^(i val(%8)), a relative phase on the angle register, kicked back onto v and x by the uncomputes
  call void @cq_template_fmul_f64_hl_unc(i32 %8, i32 %7, double %3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_uitofp_i8_to_f64_unc(i32 %7, i32 %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call fastcc void @__cq_q_pick8_10_unc(i32 %6, i32 %5, i8 %2)    ; IR: uncompute %6 (adjoint of the call)
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  %9 = call i8 @cqrt_measure_i8(i32 %5)    ; IR: %9 = cq_measure_ui8(%5)
  %10 = zext i8 %9 to i32    ; IR: %10 = zext i8 %9 to i32  (classical)
  ret i32 %10    ; IR: ret i32 %10
}

define internal fastcc i32 @__cq_q_pick8_10(i32 %0, i8 %1) {
  %3 = call i32 @cq_template_add_i8_hl(i32 %0, i8 1)    ; IR: %4 = add i8 %0, 1  (true arm, hoisted)
  %4 = call i32 @cq_template_shl_i8_hl(i32 %0, i8 1)    ; IR: %5 = shl i8 %0, 1  (false arm, hoisted)
  %5 = call i32 @cq_template_icmp_ugt_i8_hl(i32 %0, i8 %1)    ; IR: %3 = icmp ugt i8 %0, %1  [the select's flag]
  %6 = call i32 @cq_template_select_i8(i32 %5, i32 %3, i32 %4)    ; IR: %6 = select i1 %3, i8 %4, i8 %5  [the merge: one select on the flag, rule 9]
  %7 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: ret i8 %6  [result rail of the call]
  call void @cqrt_copy_i8(i32 %6, i32 %7)    ; IR: copy the result out
  call void @cq_template_select_i8_unc(i32 %6, i32 %5, i32 %3, i32 %4)    ; IR: uncompute the merge
  call void @cqrt_free(i32 %6)    ; IR: release the merge rail (|0>)
  call void @cq_template_icmp_ugt_i8_hl_unc(i32 %5, i32 %0, i8 %1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %5)    ; IR: release the %3 rail (|0>)
  call void @cq_template_shl_i8_hl_unc(i32 %4, i32 %0, i8 1)    ; IR: uncompute %5
  call void @cqrt_free(i32 %4)    ; IR: release the %5 rail (|0>)
  call void @cq_template_add_i8_hl_unc(i32 %3, i32 %0, i8 1)    ; IR: uncompute %4
  call void @cqrt_free(i32 %3)    ; IR: release the %4 rail (|0>)
  ret i32 %7    ; IR: ret i8 %6
}

define internal fastcc void @__cq_q_pick8_10_unc(i32 %0, i32 %1, i8 %2) {
  %4 = call i32 @cq_template_add_i8_hl(i32 %1, i8 1)    ; IR: recompute %4
  %5 = call i32 @cq_template_shl_i8_hl(i32 %1, i8 1)    ; IR: recompute %5
  %6 = call i32 @cq_template_icmp_ugt_i8_hl(i32 %1, i8 %2)    ; IR: recompute %3
  %7 = call i32 @cq_template_select_i8(i32 %6, i32 %4, i32 %5)    ; IR: recompute the merge
  call void @cqrt_copy_i8(i32 %7, i32 %0)    ; IR: ret i8 %6  [xor the result out of %out]
  call void @cq_template_select_i8_unc(i32 %7, i32 %6, i32 %4, i32 %5)    ; IR: uncompute the merge
  call void @cqrt_free(i32 %7)    ; IR: release the merge rail (|0>)
  call void @cq_template_icmp_ugt_i8_hl_unc(i32 %6, i32 %1, i8 %2)    ; IR: uncompute %3
  call void @cqrt_free(i32 %6)    ; IR: release the %3 rail (|0>)
  call void @cq_template_shl_i8_hl_unc(i32 %5, i32 %1, i8 1)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  call void @cq_template_add_i8_hl_unc(i32 %4, i32 %1, i8 1)    ; IR: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i8(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare void @cqrt_copy_i8(i32, i32)
declare i32 @cq_template_select_i8(i32, i32, i32)
declare void @cq_template_select_i8_unc(i32, i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i8_hl(i32, i8)
declare void @cq_template_add_i8_hl_unc(i32, i32, i8)
declare i32 @cq_template_shl_i8_hl(i32, i8)
declare void @cq_template_shl_i8_hl_unc(i32, i32, i8)
declare i32 @cq_template_icmp_ugt_i8_hl(i32, i8)
declare void @cq_template_icmp_ugt_i8_hl_unc(i32, i32, i8)
declare void @cqrt_ry_i32_qangle(i32, i32)
declare void @cqrt_rz_qangle(i32)
declare i32 @cq_template_uitofp_i8_to_f64(i32)
declare void @cq_template_uitofp_i8_to_f64_unc(i32, i32)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i8 @cqrt_measure_i8(i32)
