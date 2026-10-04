; control_inplace_ry_rail_unnegated_inf_angle.ll — ACCEPT: the UN-NEGATED rail
; arm with a non-finite constant angle (`+inf`). THE DISCRIMINATOR FOR ROUND-1
; RULE-13 FINDING F-1's `Region.ArmNegated` CONJUNCT (bd
; `test_C_libtooling-l4x4`, sub-increment l4x4.b).
;
; WHAT IT PINS, and why it is an ACCEPT rather than a fourth decline. F-1's fence
; is about DUPLICATION, not about non-finite angles in general. This module's arm
; is the TRUE successor, so the emitter hoists ONE gate and controls it —
;
;     cqrt_ry_i32_controlled(h_b, h_r, +inf)
;
; — exactly one emitted slot for exactly one user angle. Whatever `Ry(inf)` means
; on the firing branch, it is what the SOURCE NAMED, and the non-firing branch
; gets nothing at all. That is the same disposition an uncontrolled
; `cq_theta(&q, INFINITY)` already has on EVERY binary in this tree, and the same
; distinction `control_angle_select_reject_inf_arm.ll`'s header draws for the
; sibling emitter: the fence belongs on the angle a lowering DUPLICATES, never on
; non-finite angles as such. Turning it into a blanket refusal would over-decline
; a program the compiler renders faithfully.
;
; SO: DROP THE `Region.ArmNegated` CONJUNCT AND THIS FILE GOES RED, which is the
; only way to tell F-1's clause from a blanket one. Its negated twins are
; `..._reject_rail_negated_{inf,nan,neginf}_angle.ll`, which differ from this
; module in ONE token — the branch orientation — and decline.
;
; Transcribed from plain C at `-O1`: `if (b) cq_theta(&r, __builtin_inf());`
; over the `..._rail_diamond.ll` source.
;
; RED ON `main` 0c7380c AND ON the F2 checkpoint 578dbc4 (`bare i1 register
; condition`), GREEN on the l4x4.b checkpoint 267937d and after the F-1 fix.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOX     < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CRCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1) {
entry:
  %c = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 0x7FF0000000000000)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %mc = call i1 @cq_measure_i1(i1 %c)
  %zc = zext i1 %mc to i32
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mr, %zc
  ret i32 %s
}

; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[B]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[B]], i32 %[[R]], double 0x7FF0000000000000)
;
; ---------------------------------------------------------------------------
; ONE controlled gate and TWO uncontrolled ones (the two source thetas) — i.e.
; NO unconditional twin, which is the whole difference from the negated form.
; NOX-NOT: call void @cqrt_x(
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: call i32 @cq_theta
; NOROUTE-NOT: cq_phi
; NOROUTE-NOT: = phi
; NOROUTE-NOT: fneg
; CRCNT-COUNT-1: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; RYCNT-COUNT-2: call void @cqrt_ry_{{[a-z0-9]+}}(
; RYCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}(
; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-NOT: call void @cqrt_free(
