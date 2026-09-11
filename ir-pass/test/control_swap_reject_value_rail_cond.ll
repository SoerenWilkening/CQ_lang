; control_swap_reject_value_rail_cond.ll — DECLINE (bd 3qlq.4, follow-on 1b-B):
; a VALUE arm (`if (b) a = a + 3` on a quantum `a`) under a bare-rail condition.
; Inc 2's emitter hoists the chain and hands a `select` to the 4.4 merge, whose
; classifier is where the rail is refused — the same string as the data select,
; because it IS the same missing lowering (a copy merge controlled on the
; register).
;
; ⚠ AMENDED BY bd `test_C_libtooling-l4x4` sub-increment l4x4.b (2026-09-11) —
; SAME VERDICT, SAME STRING, DIFFERENT FENCE, AND THE DIFFERENCE IS WHY THIS FILE
; NOW MATTERS MORE THAN IT DID. Until l4x4.b every rail-condition region died at
; `classifyArms`' FIRST GATE (`!isa<CmpInst>(Region.Condition)`), so this file
; pinned that one line. l4x4.b WIDENS that gate — the in-place controlled-Ry arm
; and the controlled state prep lower on a rail now — and re-declines the other
; arm classes AT THEIR OWN ACCEPT SITES (SCOPE §2.6; hazard H-8: four classes
; must keep declining after a gate six of them share is widened, and the file's
; own `SawRotationArm` comment records that the one-directional version of
; exactly that check was already wrong once — "Luck is not a fence").
;
; SO THIS MODULE NOW REACHES THE VALUE-ARM ACCEPT SITE AND IS TURNED BACK THERE.
; The reason is unchanged and is one layer down: since 3qlq Inc 2 a value arm is
; the CONTROLLED-COPY MERGE, whose two `cqrt_copy_<W>_controlled` are X-BRACKETED
; — free on a minted ancilla, FORBIDDEN on a user register (bd `3qlq.4`), and
; with no `X·P(θ)·X = e^{iθ}P(−θ)` escape because that identity is about a
; DIAGONAL gate. The rail root would need the 1b-B.1 `CopyRailRoot` CNOT ancilla,
; and `emitValueRegion` builds its own `SelectRegion` and calls
; `emitSelectRegion` directly without going through `CondTreeEmit`. Still bd
; `test_C_libtooling-fg9k`.
;
; THE DISCRIMINATOR IS A RECORDED MUTATION, not a second binary (this file
; declines on `main` 0c7380c, on the F2 checkpoint and here): delete the value
; site's `if (RailCond) return declineRailClass();` and the region is ACCEPTED by
; `classifyArms`, whereupon `emitRegion`'s rail dispatch refuses it with
; `control flow` — a different string from a different layer.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0, i32 %u1) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %a = call i32 @cq_theta_si32(i32 %u1, double 2.000000e-01)
  br i1 %b, label %arm, label %merge
arm:
  %a2 = add i32 %a, 3
  br label %merge
merge:
  %aa = phi i32 [ %a2, %arm ], [ %a, %entry ]
  %n = call i32 @cq_measure_si32(i32 %aa)
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  %s = add i32 %n, %z
  ret i32 %s
}

; CHECK: cq controlled lowering: bare i1 register condition under quantum control
