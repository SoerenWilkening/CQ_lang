; control_inplace_ry_reject_rail_negated_undef_angle.ll — DECLINE: an
; `undef` ANGLE on a NEGATED rail arm, refused BEFORE any mutation.
;
; THIS IS THE ONE LITERAL HAZARD ANTI-CONTROL BY Ry ADDITIVITY CREATES, and it is
; fenced where the second slot is created rather than left to a module-wide
; sweep. The negated lowering emits the rotation TWICE — `ry(h, θ)`
; unconditionally and `cry(h_b, h, −θ)` to cancel it — so an `undef` angle would
; occupy TWO emitted gate slots and be READ AS TWO DIFFERENT VALUES at the `-O0`
; stage 3 (bd `xy9n`, `LiteralIntegrity.cpp`): the cancelling gate would then not
; cancel on the `b = 1` branch, verify-clean. `declineUnpairedUndefLiterals` would
; catch it module-wide at the very end, but that is a decline AFTER mutation —
; Rule 9 says detect first.
;
; ASKED WITH `valueCarriesUndef` (the shared spelling, Rule 14) and ONLY for the
; negated rail shape: nothing else in this emitter duplicates an angle, so a
; broader clause would be an over-decline with no subject. The UN-negated twin of
; this module ACCEPTS — `undef` in ONE slot is the ordinary case the rest of the
; pass already handles.;
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
; CHECK: error: {{.*}}cq {{[a-z ]*}}lowering: rotation angle under quantum control

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u1) {
entry:
  %c = call i1 @cq_theta_i1(i1 false, double 1.100000e+00)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double undef)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %mc = call i1 @cq_measure_i1(i1 %c)
  %zc = zext i1 %mc to i32
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mr, %zc
  ret i32 %s
}
