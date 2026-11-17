; HAND-WRITTEN. Rules: 18, 12, 8, 5, 2.
; Checked: even_step(x, n, k) (measured).
; Clean: every rail inside the clones (arm values, callee results through the twins, the phase flag) and inside the
; twins; only the outermost result rail survives.
; Kept: the user register x; the result rail (measured).
; Rotations: Ry(th) on x; P(0.25) on the flag (x_d > k) at every odd_step level d reached, x_d the level's argument
; (the forward clone only; the pure clones and twins fire no phase).
; MUTUAL RECURSION WITH CLASSICAL DEPTH: even_step and odd_step call each other with n - 1; n is classical, so the
; recursion is ordinary classical control in the clones (rule 18): each clone tests n with a real br and calls the
; other clone, and LLVM's call stack carries the frames (no K bound: the depth is a classical runtime value, unlike
; 98's quantum depth). Each clone follows the call-chain discipline of 33: the result is copied out of a fresh rail
; (the base case copies its argument, it never returns the argument handle itself), the callee's result is uncomputed
; through the callee's _unc twin. odd_step carries a PHASE ARM (03 in a callee, as 35): the flag x > k takes the
; kickback cqrt_rz_i1 and is uncomputed at once. A phase is an effect, not part of the pure value, so a twin must not
; replay it (as 67's tape): the twins recompute through phase-free PURE clones (_pure), and the forward clones (_100)
; are the only ones that fire the phase. Four functions per source function: forward clone, pure clone, twin (the pure
; clone's adjoint xor-out). The twin recursion costs 2^n calls of the deepest level (Bennett's cost for an unrolled
; call tree). Mask suffix as 98: arg 0 quantum, args 1-2 classical.
source_filename = "mutual_recursion.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @mutual_recursion(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call fastcc i32 @__cq_q_even_step_100(i32 %5, i32 %2, i32 %3)    ; IR: %6 = call @even_step(%5, %2, %3), quantum clone (arg 0 quantum)
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %7 = cq_measure_si32(%6)
  ret i32 %7    ; IR: ret i32 %7
}

; even_step, forward clone
define internal fastcc i32 @__cq_q_even_step_100(i32 %0, i32 %1, i32 %2) {
  %4 = icmp slt i32 %1, 1    ; IR: %4 = icmp slt i32 %1, 1  (classical depth test)
  br i1 %4, label %5, label %7    ; IR: br i1 %4  (classical)

5:
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %0 via phi %11  [result rail of the call]
  call void @cqrt_copy_i32(i32 %0, i32 %6)    ; IR: copy the argument out (never return the argument handle)
  ret i32 %6

7:
  %8 = call i32 @cq_template_add_i32_hl(i32 %0, i32 3)    ; IR: %6 = add nsw i32 %0, 3
  %9 = add nsw i32 %1, -1    ; IR: %7  (classical)
  %10 = call fastcc i32 @__cq_q_odd_step_100(i32 %8, i32 %9, i32 %2)    ; IR: %8 = call @odd_step(%6, %7, %2)
  %11 = call i32 @cq_template_sub_i32_hl(i32 %10, i32 %2)    ; IR: %9 = sub nsw i32 %8, %2
  %12 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %11  [result rail of the call]
  call void @cqrt_copy_i32(i32 %11, i32 %12)    ; IR: copy the result out
  call void @cq_template_sub_i32_hl_unc(i32 %11, i32 %10, i32 %2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  call fastcc void @__cq_q_odd_step_100_unc(i32 %10, i32 %8, i32 %9, i32 %2)    ; IR: uncompute %8 (twin of odd_step)
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %0, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  ret i32 %12    ; IR: ret i32 %11
}

; odd_step, forward clone
define internal fastcc i32 @__cq_q_odd_step_100(i32 %0, i32 %1, i32 %2) {
  %4 = icmp slt i32 %1, 1    ; IR: %4 = icmp slt i32 %1, 1  (classical depth test)
  br i1 %4, label %5, label %7    ; IR: br i1 %4  (classical)

5:
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %0 via phi %14  [result rail of the call]
  call void @cqrt_copy_i32(i32 %0, i32 %6)    ; IR: copy the argument out (never return the argument handle)
  ret i32 %6

7:
  %8 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %0, i32 %2)    ; IR: %6 = icmp sgt i32 %0, %2  [flag of block %7]
  call void @cqrt_rz_i1(i32 %8, double 2.500000e-01)    ; IR: block %7 under br i1 %6: cq_phi(0.25)  [kickback onto the flag]
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %8, i32 %0, i32 %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  %9 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -1)    ; IR: %9 = add nsw i32 %0, -1
  %10 = add nsw i32 %1, -1    ; IR: %10  (classical)
  %11 = call fastcc i32 @__cq_q_even_step_100(i32 %9, i32 %10, i32 %2)    ; IR: %11 = call @even_step(%9, %10, %2)
  %12 = call i32 @cq_template_add_i32_hl(i32 %11, i32 1)    ; IR: %12 = add nsw i32 %11, 1
  %13 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %14  [result rail of the call]
  call void @cqrt_copy_i32(i32 %12, i32 %13)    ; IR: copy the result out
  call void @cq_template_add_i32_hl_unc(i32 %12, i32 %11, i32 1)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  call fastcc void @__cq_q_even_step_100_unc(i32 %11, i32 %9, i32 %10, i32 %2)    ; IR: uncompute %11 (twin of even_step)
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %0, i32 -1)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  ret i32 %13    ; IR: ret i32 %14
}

; even_step, pure clone: same value, no phase
define internal fastcc i32 @__cq_q_even_step_100_pure(i32 %0, i32 %1, i32 %2) {
  %4 = icmp slt i32 %1, 1    ; IR: %4 = icmp slt i32 %1, 1  (classical depth test)
  br i1 %4, label %5, label %7    ; IR: br i1 %4  (classical)

5:
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %0 via phi %11  [result rail of the call]
  call void @cqrt_copy_i32(i32 %0, i32 %6)    ; IR: copy the argument out (never return the argument handle)
  ret i32 %6

7:
  %8 = call i32 @cq_template_add_i32_hl(i32 %0, i32 3)    ; IR: %6 = add nsw i32 %0, 3
  %9 = add nsw i32 %1, -1    ; IR: %7  (classical)
  %10 = call fastcc i32 @__cq_q_odd_step_100_pure(i32 %8, i32 %9, i32 %2)    ; IR: %8 = call @odd_step(%6, %7, %2)  (pure clone: no phase)
  %11 = call i32 @cq_template_sub_i32_hl(i32 %10, i32 %2)    ; IR: %9 = sub nsw i32 %8, %2
  %12 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %11  [result rail of the call]
  call void @cqrt_copy_i32(i32 %11, i32 %12)    ; IR: copy the result out
  call void @cq_template_sub_i32_hl_unc(i32 %11, i32 %10, i32 %2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  call fastcc void @__cq_q_odd_step_100_unc(i32 %10, i32 %8, i32 %9, i32 %2)    ; IR: uncompute %8 (twin of odd_step)
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %0, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  ret i32 %12    ; IR: ret i32 %11
}

; odd_step, pure clone: same value, no phase
define internal fastcc i32 @__cq_q_odd_step_100_pure(i32 %0, i32 %1, i32 %2) {
  %4 = icmp slt i32 %1, 1    ; IR: %4 = icmp slt i32 %1, 1  (classical depth test)
  br i1 %4, label %5, label %7    ; IR: br i1 %4  (classical)

5:
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %0 via phi %14  [result rail of the call]
  call void @cqrt_copy_i32(i32 %0, i32 %6)    ; IR: copy the argument out (never return the argument handle)
  ret i32 %6

7:
  ; IR: %6 / block %7 (the phase arm) omitted: a phase is an effect, fired once by the forward clone only
  %8 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -1)    ; IR: %9 = add nsw i32 %0, -1
  %9 = add nsw i32 %1, -1    ; IR: %10  (classical)
  %10 = call fastcc i32 @__cq_q_even_step_100_pure(i32 %8, i32 %9, i32 %2)    ; IR: %11 = call @even_step(%9, %10, %2)  (pure clone)
  %11 = call i32 @cq_template_add_i32_hl(i32 %10, i32 1)    ; IR: %12 = add nsw i32 %11, 1
  %12 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %14  [result rail of the call]
  call void @cqrt_copy_i32(i32 %11, i32 %12)    ; IR: copy the result out
  call void @cq_template_add_i32_hl_unc(i32 %11, i32 %10, i32 1)    ; IR: uncompute %12
  call void @cqrt_free(i32 %11)    ; IR: release the %12 rail (|0>)
  call fastcc void @__cq_q_even_step_100_unc(i32 %10, i32 %8, i32 %9, i32 %2)    ; IR: uncompute %11 (twin of even_step)
  call void @cqrt_free(i32 %10)    ; IR: release the %11 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %0, i32 -1)    ; IR: uncompute %9
  call void @cqrt_free(i32 %8)    ; IR: release the %9 rail (|0>)
  ret i32 %12    ; IR: ret i32 %14
}

; even_step, twin: xor the pure value out of %out
define internal fastcc void @__cq_q_even_step_100_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = icmp slt i32 %2, 1    ; IR: %4 = icmp slt i32 %1, 1  (classical depth test)
  br i1 %5, label %6, label %7    ; IR: br i1 %4  (classical)

6:
  call void @cqrt_copy_i32(i32 %1, i32 %0)    ; IR: ret i32 %0 via phi %11  [xor the base-case value out of %out]
  ret void

7:
  %8 = call i32 @cq_template_add_i32_hl(i32 %1, i32 3)    ; IR: %6 = add nsw i32 %0, 3
  %9 = add nsw i32 %2, -1    ; IR: %7  (classical)
  %10 = call fastcc i32 @__cq_q_odd_step_100_pure(i32 %8, i32 %9, i32 %3)    ; IR: %8 = call @odd_step(%6, %7, %2)  (pure clone: no phase)
  %11 = call i32 @cq_template_sub_i32_hl(i32 %10, i32 %3)    ; IR: %9 = sub nsw i32 %8, %2
  call void @cqrt_copy_i32(i32 %11, i32 %0)    ; IR: ret i32 %11  [xor the result out of %out]
  call void @cq_template_sub_i32_hl_unc(i32 %11, i32 %10, i32 %3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  call fastcc void @__cq_q_odd_step_100_unc(i32 %10, i32 %8, i32 %9, i32 %3)    ; IR: uncompute %8 (twin of odd_step)
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %1, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  ret void
}

; odd_step, twin: xor the pure value out of %out
define internal fastcc void @__cq_q_odd_step_100_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = icmp slt i32 %2, 1    ; IR: %4 = icmp slt i32 %1, 1  (classical depth test)
  br i1 %5, label %6, label %7    ; IR: br i1 %4  (classical)

6:
  call void @cqrt_copy_i32(i32 %1, i32 %0)    ; IR: ret i32 %0 via phi %14  [xor the base-case value out of %out]
  ret void

7:
  ; IR: %6 / block %7 (the phase arm) omitted: a phase is an effect, fired once by the forward clone only
  %8 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)    ; IR: %9 = add nsw i32 %0, -1
  %9 = add nsw i32 %2, -1    ; IR: %10  (classical)
  %10 = call fastcc i32 @__cq_q_even_step_100_pure(i32 %8, i32 %9, i32 %3)    ; IR: %11 = call @even_step(%9, %10, %2)  (pure clone)
  %11 = call i32 @cq_template_add_i32_hl(i32 %10, i32 1)    ; IR: %12 = add nsw i32 %11, 1
  call void @cqrt_copy_i32(i32 %11, i32 %0)    ; IR: ret i32 %14  [xor the result out of %out]
  call void @cq_template_add_i32_hl_unc(i32 %11, i32 %10, i32 1)    ; IR: uncompute %12
  call void @cqrt_free(i32 %11)    ; IR: release the %12 rail (|0>)
  call fastcc void @__cq_q_even_step_100_unc(i32 %10, i32 %8, i32 %9, i32 %3)    ; IR: uncompute %11 (twin of even_step)
  call void @cqrt_free(i32 %10)    ; IR: release the %11 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %1, i32 -1)    ; IR: uncompute %9
  call void @cqrt_free(i32 %8)    ; IR: release the %9 rail (|0>)
  ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
