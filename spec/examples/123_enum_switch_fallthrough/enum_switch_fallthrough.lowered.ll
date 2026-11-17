; HAND-WRITTEN. Rules: 13, 8, 9, 4, 5, 2.
; Checked: y (the result rail %16 -> %17, measured) and m (%5 -> %18, measured), summed.
; Clean: the four case flags e0..e3 (%6..%9), the two OR predicates (%11, %12), the GREEN-body select %14 and the BLUE
; product %15, each |0> at its free.
; Kept: the enum register m (%5, rotated and measured) and the result rail y (%16, measured).
; Rotations: (Ry, m, th, 1); (P, e0, p, m == 0); (P, e3, -p, m == 3).
; The scrutinee is a quantum enum (enum mode * matches unsigned int * in cq_theta's _Generic: an enum is its compatible
; integer type, i32 in IR). Each case label gets one equality flag; the flags are mutually exclusive, and the missing
; default is the implicit no-op arm (a value outside 0..3 runs no case, so its predicate is the complement and needs no
; flag). Fallthrough is not a C-level notion in IR: it is a block reached from several switch edges, so a block's
; predicate is the disjoint OR of the case flags that reach it:
;   block %6 (RED body)   e0              -> phase arm: kickback cq_phi(p) onto e0
;   block %7 (GREEN body) e0 | e1         -> value: %8 = y0 + 1 (classical: y0 is a parameter)
;   block %9 (BLUE body)  e0 | e1 | e2    -> value: %10 = phi selects %8 when entered from %7 (e0|e1), y0 from the switch (e2)
;   block %12 (ALPHA)     e3              -> phase arm: kickback cq_phi(-p) onto e3
; The two OR predicates are cqrt_or_i1 into fresh |0> flags (rule 8; the edge flags are disjoint); the second reuses the
; first. The phase of the RED body is fired once, on e0 alone, not on the OR: the phase belongs to the block where cq_phi
; stands, and the value code it falls into is shared (method matches arm class: the phase goes to a flag, the values
; merge by select). %10 has two classical data operands (select _ll); the final merge %15 is the quantum %11 when the
; BLUE block ran (e0|e1|e2) and the classical y0 otherwise (select _hl; the ALPHA and no-case edges both carry y0).
; Everything but the result and the enum register is uncomputed LIFO; the enum register is rotated, so it stays (frozen)
; and is measured.
source_filename = "enum_switch_fallthrough.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @enum_switch_fallthrough(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register m: the quantum enum]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 0)    ; IR: switch i32 %5: i32 0 -> %6  [RED]
  %7 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 1)    ; IR: switch i32 %5: i32 1 -> %7  [GREEN]
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 2)    ; IR: switch i32 %5: i32 2 -> %9  [BLUE]
  %9 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 3)    ; IR: switch i32 %5: i32 3 -> %12  [ALPHA]
  call void @cqrt_rz_i1(i32 %6, double %3)    ; IR: block %6: cq_phi(%3)  [kickback onto the RED flag only]
  %10 = fneg double %3    ; IR: %13 = fneg double %3  (classical)
  call void @cqrt_rz_i1(i32 %9, double %10)    ; IR: block %12: cq_phi(%13)  [kickback onto the ALPHA flag]
  %11 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %7 = (%5 == 0) | (%5 == 1)  (RED falls into GREEN)
  call void @cqrt_or_i1(i32 %6, i32 %7, i32 %11)    ; IR: OR of the (disjoint) edge flags %6 -> %7 and switch -> %7
  %12 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %9 = pred(%7) | (%5 == 2)  (GREEN falls into BLUE)
  call void @cqrt_or_i1(i32 %11, i32 %8, i32 %12)    ; IR: OR of the (disjoint) edge flags %7 -> %9 and switch -> %9
  %13 = add nsw i32 %2, 1    ; IR: %8 = add nsw i32 %2, 1  (classical: y0 + 1)
  %14 = call i32 @cq_template_select_i32_ll(i32 %11, i32 %13, i32 %2)    ; IR: %10 = phi i32 [ %2, %4 ], [ %8, %7 ]  (entered from %7 iff e0|e1)
  %15 = call i32 @cq_template_mul_i32_hl(i32 %14, i32 3)    ; IR: %11 = mul nsw i32 %10, 3
  %16 = call i32 @cq_template_select_i32_hl(i32 %12, i32 %15, i32 %2)    ; IR: %15 = phi i32 [ %2, %4 ], [ %2, %12 ], [ %11, %9 ]  [result rail]
  call void @cq_template_mul_i32_hl_unc(i32 %15, i32 %14, i32 3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %15)    ; IR: release the %11 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %14, i32 %11, i32 %13, i32 %2)    ; IR: uncompute %10
  call void @cqrt_free(i32 %14)    ; IR: release the %10 rail (|0>)
  call void @cqrt_or_i1(i32 %11, i32 %8, i32 %12)    ; IR: uncompute pred(%9) (self-inverse)
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cqrt_or_i1(i32 %6, i32 %7, i32 %11)    ; IR: uncompute pred(%7) (self-inverse)
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %9, i32 %5, i32 3)    ; IR: uncompute the ALPHA flag
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %5, i32 2)    ; IR: uncompute the BLUE flag
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %7, i32 %5, i32 1)    ; IR: uncompute the GREEN flag
  call void @cqrt_free(i32 %7)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %6, i32 %5, i32 0)    ; IR: uncompute the RED flag
  call void @cqrt_free(i32 %6)    ; IR: release it (|0>)
  %17 = call i32 @cqrt_measure_i32(i32 %16)    ; IR: %16 = cq_measure_si32(%15)
  %18 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %17 = cq_measure_ui32(%5)
  %19 = add nsw i32 %18, %17    ; IR: %18  (classical)
  ret i32 %19    ; IR: ret i32 %18
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_or_i1(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32_hl(i32, i32, i32)
declare void @cq_template_select_i32_hl_unc(i32, i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
