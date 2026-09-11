; control_inplace_ry_reject_rail_cond_wire.ll — DECLINE: the arm rotates the
; CONDITION REGISTER ITSELF, in the UNFOLDED spelling `-O1` cannot reach (hand
; IR: the seed is TAINTED, so there is no edge fact to const-fold the arm with,
; and the arm's `cq_theta` keeps a live tainted arg-0).
;
; This is the shape `control_inplace_ry_rail_cast_base.ll` is one hop away from,
; and the pair is the boundary: a CAST of the condition is a DIFFERENT physical
; wire (every cast CQ lowers is out of place, minting a fresh rail) and accepts;
; the register ITSELF is the same wire and declines.
;
; ⚠ THE STRING IS RUNG (iii)'s, NOT R4's, AND THAT IS MEASURED RATHER THAN
; CHOSEN. The arm's own `cq_theta` is a non-diagonal gate on the condition's wire
; that is NOT provably after the branch, so `railCondWireDisposition` returns
; `DeclineNow` several clauses BEFORE R4's `railWireClosure` intersection is
; computed. R4 is therefore a backstop on this path rather than the fence that
; fires — recorded here so a later reader does not take the absence of
; `rotation arm on a condition wire` in this family as evidence that R4 was
; dropped. It is not: `if (!StatePrep)` still runs it.;
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
; CHECK: error: {{.*}}cq {{[a-z ]*}}lowering: condition predates a non-diagonal gate under quantum control

declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 2.000000e-01)
  %t = trunc i32 %q to i1
  %c = call i1 @cq_theta_i1(i1 %t, double 5.000000e-01)
  br i1 %c, label %arm, label %merge
arm:
  %ct = call i1 @cq_theta_i1(i1 %c, double 9.000000e-01)
  br label %merge
merge:
  %cm = phi i1 [ %ct, %arm ], [ %c, %entry ]
  %mc = call i1 @cq_measure_i1(i1 %cm)
  %zc = zext i1 %mc to i32
  ret i32 %zc
}
