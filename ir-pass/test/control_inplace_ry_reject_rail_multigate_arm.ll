; control_inplace_ry_reject_rail_multigate_arm.ll — DECLINE: a MULTI-GATE arm
; (two chained `cq_theta` on the rotated register) under a bare `_Bool`
; condition. R1 of the drbq Inc-1 recognizer — `inPlaceRotationArmTheta` requires
; the arm to be exactly ONE tainted-operand `cq_theta` — so the arm is not
; claimed by this class at all and falls through to `classifyArms`' closing
; `control flow`.
;
; Committed because the rail gate is what let this shape reach R1 in the first
; place: on `main` it died one clause earlier and nothing in the corpus showed
; that a multi-gate arm on a rail is refused. It is an INHERITED fence (the
; compare spelling declines identically), not a new one.;
; RED ON `main` 0c7380c AND ON the F2 checkpoint 578dbc4: both decline
; `bare i1 register condition` at `classifyArms`' first gate, so neither binary
; can witness this fence at all. The string below is reachable only because
; l4x4.b widened that gate.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout, so every IR-TEXT negative a
; decline fixture could carry is VACUOUS — `2>&1 | FileCheck` sees the diagnostic
; and nothing else. What pins "no silent lowering" is the `not` INVERSION on the
; RUN line above (the pass must exit non-zero) plus the string below, mirrored
; character-for-character against `ir-pass/src`.
; CHECK: error: {{.*}}cq {{[a-z ]*}}lowering: control flow under quantum control

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u1) {
entry:
  %c = call i1 @cq_theta_i1(i1 false, double 1.100000e+00)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  br i1 %c, label %arm, label %merge
arm:
  %r1 = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  %r2 = call i32 @cq_theta_si32(i32 %r1, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %r2, %arm ], [ %r, %entry ]
  %mc = call i1 @cq_measure_i1(i1 %c)
  %zc = zext i1 %mc to i32
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mr, %zc
  ret i32 %s
}
