; control_swap_reject_phase_rail_cond.ll — DECLINE: the PHASE arm class under a
; bare `_Bool` (rail-root) condition — here an EMPTY arm, which `classifyArms`
; classifies as phase (`Base == Routed`, `armBlockIsPureSpine` trivially true).
;
; UNREACHABLE FROM PLAIN C, and committed anyway. The register-carrying
; `cq_phi_<sfx>` family was RETIRED at 3qlq Inc 1 (owner decision D1), and the
; register-free `void cq_phi(double)` is PRE-PEELED by
; `ArmClassify::classifyPhaseKickback` before `classifyArms` is ever reached — so
; the only way into this clause is a gate-free arm like the one below. It is
; pinned because the gate at the top of `classifyArms` is shared by six arm
; classes and a class must never acquire an accept nobody cleared it for.;
; ---- §2.6, THE PER-ARM-CLASS RE-DECLINE, AND WHY IT IS NOT RED-GREEN ---------
;
; This file declines with the SAME STRING on `main` 0c7380c, on the F2 checkpoint
; and here — but for DIFFERENT REASONS, and the difference is the whole point.
; Before l4x4.b every rail-condition region died at `classifyArms`' FIRST GATE;
; now the gate admits the rail and runs the §13.3 ladder, and this arm class is
; refused at its own ACCEPT SITE instead. Widening a gate that six arm classes
; share and re-declining only at the end would hand the other five an accept
; nobody cleared them for (hazard H-8), which is exactly the shape the file's own
; `SawRotationArm` comment records as having been wrong once already ("Luck is
; not a fence").
;
; THE DISCRIMINATOR IS THE RECORDED MUTATION, not a second binary: delete this
; class's `if (RailCond) return declineRailClass();` and the region is ACCEPTED
; by `classifyArms`, whereupon `emitRegion`'s rail dispatch refuses it with
; `control flow` — a DIFFERENT string, from a DIFFERENT layer. The fence is
; therefore load-bearing and the emitter backstop is the second line of defence,
; not the first.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout, so every IR-TEXT negative a
; decline fixture could carry is VACUOUS — `2>&1 | FileCheck` sees the diagnostic
; and nothing else. What pins "no silent lowering" is the `not` INVERSION on the
; RUN line above (the pass must exit non-zero) plus the string below, mirrored
; character-for-character against `ir-pass/src`.
; CHECK: error: {{.*}}cq {{[a-z ]*}}lowering: bare i1 register condition under quantum control

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
  br label %merge
merge:
  %rm = phi i32 [ %r, %arm ], [ %r, %entry ]
  %mc = call i1 @cq_measure_i1(i1 %c)
  %zc = zext i1 %mc to i32
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mr, %zc
  ret i32 %s
}
