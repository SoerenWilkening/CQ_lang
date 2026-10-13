; control_inplace_ry_rail_negated_nan_angle.ll — ACCEPT: the l4x4.b NEGATED
; bare-`_Bool` rail arm with a NON-FINITE CONSTANT angle (NaN).
;
;     _Bool b; cq_theta(&b, .5); int r = u1; cq_theta(&r, .25);
;     if (!b) cq_theta(&r, __builtin_nan(""));
;
; The negated rail form is `ry(h_r, θ)` unconditional, then the cancelling
; `cry(h_b, h_r, −θ)` (no `cqrt_x` on a user register). Its l4x4.b round-1
; finding F-1 declined a non-finite constant θ because the `b = 1` branch, which
; the source leaves alone, got `Ry(θ)·Ry(−θ)` with θ non-finite. RETIRED by owner
; ruling 2026-10-13 (`owner-ruling-nonfinite-angle-identity`): a rotation by a
; non-finite angle is the IDENTITY (a backend contract), so that pair is `I·I` on
; `b = 1` and the source's `Ry(θ)` (also the identity) on `b = 0`. One predicate
; per question (bd dm7f.6 round-1 F-B1): the clause and its helper
; `constantAngleIsNonFinite` are deleted. `fneg` is an exact sign flip, so the
; cancelling slot holds `−θ` bit for bit.
;
; THIS FILE WAS `control_inplace_ry_reject_rail_negated_nan_angle.ll` (a
; decline). The `undef` sibling `..._reject_rail_negated_undef_angle.ll` stays a
; decline (an undef angle is not a value; two slots would read two values).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u1) {
entry:
  %c = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 0x7FF8000000000000)
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
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 0x7FF8000000000000)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[B]], i32 %[[R]], double 0xFFF8000000000000)
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[B]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NOT:  call void @cqrt_ry_
; CHECK-NOT:  call void @cqrt_x(
