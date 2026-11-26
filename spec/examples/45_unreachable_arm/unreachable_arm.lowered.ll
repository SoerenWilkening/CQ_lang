; HAND-WRITTEN. Rules: 16, 8, 4, 2, 6.
; Checked: unreachable_arm: x + c; abort_then_rotate: x after the second rotation (measured); the abort flag (x == k)
; is measured by the backend at the end of the shot.
; Clean: nothing to free. unreachable_arm: x is dead after x + c, a bijection in x, so rule 6's in-place update makes the
; add ONE core gate, addc_i32(x, c), on the x rail (%5), which holds x + c from there on (the abort flag x == k stays
; entangled with x + c, which still holds x's information).
; Kept: abort_then_rotate's x; the result rail x + c (unreachable_arm's x rail); the abort flag of each function (never freed); abort_then_rotate's snapshot rail of x
; (taken under the flag, never freed).
; Rotations: unreachable_arm: Ry(th) on x. abort_then_rotate: Ry(th) on x; Ry(t2) on x (uncontrolled, after the
; snapshot).
; A noreturn arm (abort) under a quantum condition (rule 16): the arm predicate rail is handed to cqrt_abort_i1 and
; stays allocated; the backend measures it AFTER the program's last own measurement and reports the outcome as the
; shot's abort status. The program continues uncontrolled. Because the lowering computes out of place, every value live
; at the arm is still intact at the end, except rails that a later operation modifies IN PLACE: those are copied under
; the predicate into fresh snapshot rails before the call. Here the only in-place modification of a program variable is
; a later cq_theta (abort_then_rotate); any other in-place operation falls under the same rule. unreachable_arm's
; in-place add needs no snapshot: the old x is dead (rule 6) and the rail keeps its bijective image x + c.
source_filename = "unreachable_arm.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @unreachable_arm(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 %2)    ; IR: %6 = icmp eq i32 %5, %2  [predicate of the noreturn block %7]
  call void @cqrt_abort_i1(i32 %6)    ; IR: block %7: abort(); unreachable  (noreturn arm flag, kept allocated)
  call void @cqrt_addc_i32(i32 %5, i32 %3)    ; IR: %9 = add nsw i32 %5, %3  (block %8)  [rule 6, in-place update: x is dead after the add, so x + c IS the x rail]
  %7 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %10 = cq_measure_si32(%9)
  ret i32 %7    ; IR: ret i32 %10
}


define i32 @abort_then_rotate(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 %2)    ; IR: %6 = icmp eq i32 %5, %2  [predicate of the noreturn block %7]
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: snapshot of x at the abort point (x is rotated later in block %8)
  call void @cqrt_copy_i32_controlled(i32 %6, i32 %5, i32 %7)    ; IR: snapshot under the predicate; identity on the surviving branch
  call void @cqrt_abort_i1(i32 %6)    ; IR: block %7: abort(); unreachable  (flag measured by the backend at end of shot)
  call void @cqrt_ry_i32(i32 %5, double %3)    ; IR: %9 = cq_theta_si32(%5, %3)  (block %8, runs uncontrolled)
  %8 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %10 = cq_measure_si32(%9)
  ret i32 %8    ; IR: ret i32 %10
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_abort_i1(i32)
declare void @cqrt_copy_i32_controlled(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_addc_i32(i32, i32)
