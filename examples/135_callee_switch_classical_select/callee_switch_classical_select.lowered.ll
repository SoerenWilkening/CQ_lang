; HAND-WRITTEN. Rules: 18, 13, 9, 4, 5, 2.
; Checked: callee_switch: dispatch(x, a, b); callee_classical_select: pick(x, c) (each measured).
; Clean: inside the dispatch clone: the scrutinee x & 3, the three case flags, the three arm values and the three
; merges; inside the pick clone: the one arm value computed.
; Kept: the user register x of each function; the clone's copied-out result rail (measured).
; Rotations: Ry(th) on x (each function).
; Both are the TOP-LEVEL mechanisms inside a lifted clone (rule 18, 33's call-chain discipline: result copied out of a
; fresh rail, operands uncomputed in the clone). The switch is 22's (rule 13): one equality flag per case on the
; scrutinee, value arms merged by a chain of selects (the default/case-3 arm is the argument itself; the unreachable
; default label gets no flag). The classical-condition select is CLASSICAL CONTROL: a real br on the classical flag,
; each arm computing only its own value and copying it out; the two out rails meet in a phi (a classical mux of
; handles). Nothing quantum is minted for the classical condition.
source_filename = "callee_switch_classical_select.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @callee_switch(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call fastcc i32 @__cq_q_dispatch_100(i32 %5, i32 %2, i32 %3)    ; IR: %6 = call @dispatch(%5, %2, %3), quantum clone (arg 0 quantum)
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %7 = cq_measure_si32(%6)
  ret i32 %7    ; IR: ret i32 %7
}

define internal fastcc i32 @__cq_q_dispatch_100(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cq_template_and_i32_hl(i32 %0, i32 3)    ; IR: %4 = and i32 %0, 3  [scrutinee]
  %5 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 0)    ; IR: switch i32 %4: i32 0 -> %5
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 1)    ; IR: switch i32 %4: i32 1 -> %7
  %7 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 2)    ; IR: switch i32 %4: i32 2 -> %9
  %8 = call i32 @cq_template_add_i32_hl(i32 %0, i32 %1)    ; IR: %6 = add nsw i32 %1, %0  (commutative: classical operand in the _hl slot)
  %9 = call i32 @cq_template_mul_i32_hl(i32 %0, i32 %2)    ; IR: %8 = mul nsw i32 %2, %0
  %10 = call i32 @cq_template_sub_i32_hl(i32 %0, i32 %1)    ; IR: %10 = sub nsw i32 %0, %1
  %11 = call i32 @cq_template_select_i32(i32 %7, i32 %10, i32 %0)    ; IR: %13 = phi: [ %10, %9 ] else [ %0, %3 ] (case 3; the default label is unreachable)
  %12 = call i32 @cq_template_select_i32(i32 %6, i32 %9, i32 %11)    ; IR: %13 = phi: [ %8, %7 ]
  %13 = call i32 @cq_template_select_i32(i32 %5, i32 %8, i32 %12)    ; IR: %13 = phi: [ %6, %5 ]
  %14 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %13  [result rail of the call]
  call void @cqrt_copy_i32(i32 %13, i32 %14)    ; IR: ret i32 %13  [copy the result out]
  call void @cq_template_select_i32_unc(i32 %13, i32 %5, i32 %8, i32 %12)    ; IR: uncompute the outer merge
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %12, i32 %6, i32 %9, i32 %11)    ; IR: uncompute the inner merge
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cq_template_select_i32_unc(i32 %11, i32 %7, i32 %10, i32 %0)    ; IR: uncompute the innermost merge
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_sub_i32_hl_unc(i32 %10, i32 %0, i32 %1)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %9, i32 %0, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %9)    ; IR: release the %8 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %0, i32 %1)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %7, i32 %4, i32 2)    ; IR: uncompute case-2 flag
  call void @cqrt_free(i32 %7)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %6, i32 %4, i32 1)    ; IR: uncompute case-1 flag
  call void @cqrt_free(i32 %6)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %5, i32 %4, i32 0)    ; IR: uncompute case-0 flag
  call void @cqrt_free(i32 %5)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %4, i32 %0, i32 3)    ; IR: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  ret i32 %14    ; IR: ret i32 %13
}

define i32 @callee_classical_select(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call fastcc i32 @__cq_q_pick_10(i32 %4, i32 %2)    ; IR: %5 = call @pick(%4, %2), quantum clone (arg 0 quantum)
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)
  ret i32 %6    ; IR: ret i32 %6
}

define internal fastcc i32 @__cq_q_pick_10(i32 %0, i32 %1) {
  %3 = icmp eq i32 %1, 0    ; IR: %3 = icmp eq i32 %1, 0  (classical condition of %6: stays classical)
  br i1 %3, label %7, label %4    ; IR: %6 = select i1 %3, i32 %5, i32 %4: a classical branch, one arm computed
4:
  %5 = call i32 @cq_template_add_i32_hl(i32 %0, i32 1)    ; IR: %4 = add nsw i32 %0, 1
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret %6 = %4  [result rail of the call]
  call void @cqrt_copy_i32(i32 %5, i32 %6)    ; IR: copy the result out
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %0, i32 1)    ; IR: uncompute %4
  call void @cqrt_free(i32 %5)    ; IR: release the %4 rail (|0>)
  br label %10
7:
  %8 = call i32 @cq_template_shl_i32_hl(i32 %0, i32 1)    ; IR: %5 = shl nsw i32 %0, 1
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret %6 = %5  [result rail of the call]
  call void @cqrt_copy_i32(i32 %8, i32 %9)    ; IR: copy the result out
  call void @cq_template_shl_i32_hl_unc(i32 %8, i32 %0, i32 1)    ; IR: uncompute %5
  call void @cqrt_free(i32 %8)    ; IR: release the %5 rail (|0>)
  br label %10
10:
  %11 = phi i32 [ %6, %4 ], [ %9, %7 ]    ; IR: %6: the classical mux of the two out rails
  ret i32 %11    ; IR: ret i32 %6
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
