; HAND-WRITTEN. Rules: 18, 20, 9, 3, 5.
; Checked: f = split(x, &ip, k, mask) (the clone's copied-out return rail %26, measured as %8) and ip (the slot's
; copied-out rail %27, loaded as %9 and measured as %10).
; Clean: every clone-internal rail: the bit view chain %5..%8, the arm predicates %9 and %13, the hoisted arm rails
; %10, %11, %14, %15..%21 and both select ladders %22..%25, all uncomputed and freed.
; Kept: x (%6, the rotated register, a source of both results); the two result rails %26 and %27 (measured).
; Rotations: (Ry_f64, x, th, 1).
; The out-parameter is a non-escaping alloca, so it is a classical SLOT holding the HANDLE of a rail (as example 31).
; Each arm writes the slot: a type-punned `store i64` becomes a bitcast template into a fresh f64 rail (the slot's
; declared view), the `store double` arm hands over the user register's handle. The three arms are exclusive, so the
; slot's final handle is a select ladder over the per-arm rails (arm 2 selected inside, arm 1 outside), and the return
; value is a second select ladder. Both results (the return value and the slot's value) are copied into fresh rails
; (rule 18) and the select ladders are then uncomputed with every other rail before the clone returns; the caller
; measures both copies, so the clone needs no _unc twin. Arm predicates: a1 = (e < k) and a2 = (e > k+51) chained by
; the ladder (a2 is selected inside, where !a1 holds); the else arm is implied by the ladder.
source_filename = "out_param_f64_punned.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @out_param_f64_punned(double noundef %0, double noundef %1, i32 noundef %2, i64 noundef %3) {
  %5 = alloca i32, align 4    ; IR: %5 = alloca double  (classical slot: holds the handle of ip)
  %6 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %6 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %6, double %1)    ; IR: %6 = cq_theta_f64(%0, %1)  [Ry]
  %7 = call fastcc i32 @__cq_q_split_1000(i32 %6, ptr %5, i32 %2, i64 %3)    ; IR: %7 = call @split(%6, %5, %2, %3), clone for mask (quantum, slot, classical, classical)
  %8 = call double @cqrt_measure_f64(i32 %7)    ; IR: %8 = cq_measure_f64(%7)
  %9 = load i32, ptr %5, align 4    ; IR: %9 = load double, ptr %5  (the handle the clone stored)
  %10 = call double @cqrt_measure_f64(i32 %9)    ; IR: %10 = cq_measure_f64(%9)
  %11 = fadd double %8, %10    ; IR: %11 = fadd double %8, %10  (classical)
  ret double %11    ; IR: ret double %11
}

define internal fastcc i32 @__cq_q_split_1000(i32 %0, ptr %1, i32 %2, i64 %3) {
  %5 = call i32 @cq_template_bitcast_f64_to_i64(i32 %0)    ; IR: %5 = bitcast double %0 to i64
  %6 = call i32 @cq_template_lshr_i64_hl(i32 %5, i64 52)    ; IR: %6 = lshr i64 %5, 52
  %7 = call i32 @cq_template_trunc_i64_to_i32(i32 %6)    ; IR: %7 = trunc nuw nsw i64 %6 to i32
  %8 = call i32 @cq_template_and_i32_hl(i32 %7, i32 2047)    ; IR: %8 = and i32 %7, 2047
  %9 = call i32 @cq_template_icmp_slt_i32_hl(i32 %8, i32 %2)    ; IR: %9 = icmp slt i32 %8, %2  [predicate of arm 1, block %10]
  %10 = call i32 @cq_template_and_i64_hl(i32 %5, i64 %3)    ; IR: %11 = and i64 %5, %3  (arm 1, hoisted: pure)
  %11 = call i32 @cq_template_bitcast_i64_to_f64(i32 %10)    ; IR: store i64 %11, ptr %1  [punned store: the slot's f64 view of z, fresh rail]
  %12 = add nsw i32 %2, 51    ; IR: %13 = add nsw i32 %2, 51  (classical)
  %13 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %8, i32 %12)    ; IR: %14 = icmp sgt i32 %8, %13
  %14 = call i32 @cq_template_fsub_f64(i32 %0, i32 %0)    ; IR: %16 = fsub double %0, %0  (arm 2, hoisted; the same operand twice)
  %15 = call i32 @cq_template_sub_i32_hl(i32 %8, i32 %2)    ; IR: %18 = sub nsw i32 %8, %2  (arm 3, hoisted)
  %16 = call i32 @cq_template_zext_i32_to_i64(i32 %15)    ; IR: %19 = zext nneg i32 %18 to i64
  %17 = call i32 @cq_template_ashr_i64_lh(i64 %3, i32 %16)    ; IR: %20 = ashr i64 %3, %19  (classical value, quantum shift amount)
  %18 = call i32 @cq_template_xor_i64_hl(i32 %17, i64 -1)    ; IR: %21 = xor i64 %20, -1
  %19 = call i32 @cq_template_and_i64(i32 %18, i32 %5)    ; IR: %22 = and i64 %21, %5
  %20 = call i32 @cq_template_bitcast_i64_to_f64(i32 %19)    ; IR: %23 = bitcast i64 %22 to double; store i64 %22, ptr %1 is the same rail under the slot's f64 view
  %21 = call i32 @cq_template_fsub_f64(i32 %0, i32 %20)    ; IR: %24 = fsub double %0, %23
  %22 = call i32 @cq_template_select_f64(i32 %13, i32 %0, i32 %20)    ; IR: slot after arms 2/3: (%14) ? %0 : %23  (inner merge, valid where !%9)
  %23 = call i32 @cq_template_select_f64(i32 %9, i32 %11, i32 %22)    ; IR: slot at %25: (%9) ? bits(%11) : inner  (the slot's merge)
  %24 = call i32 @cq_template_select_f64(i32 %13, i32 %14, i32 %21)    ; IR: %26 = phi: (%14) ? %16 : %24  (inner merge)
  %25 = call i32 @cq_template_select_f64(i32 %9, i32 %0, i32 %24)    ; IR: %26 = phi: (%9) ? %0 : inner  (the return merge)
  %26 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret double %26  [result rail of the call, rule 18]
  call void @cqrt_copy_f64(i32 %25, i32 %26)    ; IR: copy the return value out
  %27 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: store ... ptr %1  [ip's rail: the slot's result, copied out the same way]
  call void @cqrt_copy_f64(i32 %23, i32 %27)    ; IR: copy the slot's value out
  store i32 %27, ptr %1, align 4    ; IR: the three stores to ptr %1 resolve to this one handle
  call void @cq_template_select_f64_unc(i32 %25, i32 %9, i32 %0, i32 %24)    ; IR: uncompute the return merge
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %24, i32 %13, i32 %14, i32 %21)    ; IR: uncompute the inner return merge
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %23, i32 %9, i32 %11, i32 %22)    ; IR: uncompute the slot's merge
  call void @cqrt_free(i32 %23)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %22, i32 %13, i32 %0, i32 %20)    ; IR: uncompute the inner slot merge
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  call void @cq_template_fsub_f64_unc(i32 %21, i32 %0, i32 %20)    ; IR: uncompute %24
  call void @cqrt_free(i32 %21)    ; IR: release the %24 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %20, i32 %19)    ; IR: uncompute %23
  call void @cqrt_free(i32 %20)    ; IR: release the %23 rail (|0>)
  call void @cq_template_and_i64_unc(i32 %19, i32 %18, i32 %5)    ; IR: uncompute %22
  call void @cqrt_free(i32 %19)    ; IR: release the %22 rail (|0>)
  call void @cq_template_xor_i64_hl_unc(i32 %18, i32 %17, i64 -1)    ; IR: uncompute %21
  call void @cqrt_free(i32 %18)    ; IR: release the %21 rail (|0>)
  call void @cq_template_ashr_i64_lh_unc(i32 %17, i64 %3, i32 %16)    ; IR: uncompute %20
  call void @cqrt_free(i32 %17)    ; IR: release the %20 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %16, i32 %15)    ; IR: uncompute %19
  call void @cqrt_free(i32 %16)    ; IR: release the %19 rail (|0>)
  call void @cq_template_sub_i32_hl_unc(i32 %15, i32 %8, i32 %2)    ; IR: uncompute %18
  call void @cqrt_free(i32 %15)    ; IR: release the %18 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %14, i32 %0, i32 %0)    ; IR: uncompute %16
  call void @cqrt_free(i32 %14)    ; IR: release the %16 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %13, i32 %8, i32 %12)    ; IR: uncompute %14
  call void @cqrt_free(i32 %13)    ; IR: release the %14 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %11, i32 %10)    ; IR: uncompute the punned view of %11
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %10, i32 %5, i64 %3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %10)    ; IR: release the %11 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %9, i32 %8, i32 %2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %7, i32 2047)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %7, i32 %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %6, i32 %5, i64 52)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %5, i32 %0)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  ret i32 %26    ; IR: ret double %26
}

declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_copy_f64(i32, i32)
declare void @cqrt_ry_f64(i32, double)
declare double @cqrt_measure_f64(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_bitcast_f64_to_i64(i32)
declare void @cq_template_bitcast_f64_to_i64_unc(i32, i32)
declare i32 @cq_template_bitcast_i64_to_f64(i32)
declare void @cq_template_bitcast_i64_to_f64_unc(i32, i32)
declare i32 @cq_template_lshr_i64_hl(i32, i64)
declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_trunc_i64_to_i32(i32)
declare void @cq_template_trunc_i64_to_i32_unc(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_and_i64_hl(i32, i64)
declare void @cq_template_and_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_and_i64(i32, i32)
declare void @cq_template_and_i64_unc(i32, i32, i32)
declare i32 @cq_template_fsub_f64(i32, i32)
declare void @cq_template_fsub_f64_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_ashr_i64_lh(i64, i32)
declare void @cq_template_ashr_i64_lh_unc(i32, i64, i32)
declare i32 @cq_template_xor_i64_hl(i32, i64)
declare void @cq_template_xor_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_select_f64(i32, i32, i32)
declare void @cq_template_select_f64_unc(i32, i32, i32, i32)
