; control_inplace_ry_reject_rail_negated_inf_angle.ll — DECLINE: a NON-FINITE
; CONSTANT angle (`+inf`) on a NEGATED rail arm.
;
; *** ROUND-1 RULE-13 REVIEW FINDING F-1 (bd `test_C_libtooling-l4x4`,
; sub-increment l4x4.b), graded OVER-ACCEPT-ARGUED and fixed before landing. ***
; RED ON THE l4x4.b CHECKPOINT 267937d ITSELF — that binary compiled this module
; at `opt` exit 0, verify-clean and stage-2b clean, which is the whole reason
; this file exists. It is ALSO red on `main` 0c7380c and on the F2 checkpoint
; 578dbc4, but for a DIFFERENT reason (`bare i1 register condition` at
; `classifyArms`' first gate), so neither reference binary can witness this fence
; and only the checkpoint can. Plain C at `-O1`
; (`review_l4x4b_r1_probes/x01_neg_inf_angle.c`):
;
;     _Bool b = 0; int r = 7;  b = cq_theta(b,0.5);  r = cq_theta(r,0.25);
;     if (!b) { r = cq_theta(r, __builtin_inf()); }
;
; THE DEFECT. The negated form is anti-control by Ry ADDITIVITY (SCOPE §2.3
; option A): the arm's rotation is emitted UNCONDITIONALLY and cancelled under
; the register's own control —
;
;     cqrt_ry_i32(h_r, θ) ; cqrt_ry_i32_controlled(h_b, h_r, −θ)
;
; so on the `b = 1` branch, WHERE THE SOURCE IS THE IDENTITY, the register sees
; `Ry(−θ)·Ry(+θ)`. That is `I` for every FINITE θ and for NOTHING ELSE: at
; θ = ±inf the composed angle is `inf + (−inf)` = NaN, and the checkpoint emitted
; exactly `ry(%h1, +inf); ry_controlled(%h, %h1, -inf)`. The compiler destroys a
; register on a branch the source leaves alone.
;
; THE COMPARE TWIN IS FAITHFUL, which is what makes this l4x4.b's own hole rather
; than a pre-existing disposition about non-finite angles: it brackets ONE gate
; with `cqrt_x` (`x(f); cry(f,h1,+inf); x(f)`), so its non-firing branch is
; untouched — measured on the ORACLE, `review_l4x4b_r1_probes/x01c_neg_inf_cmp.c`.
; And the UN-NEGATED rail form also emits ONE gate and therefore still ACCEPTS:
; `control_inplace_ry_rail_unnegated_inf_angle.ll` is that discriminator, and it
; is what reddens if the `Region.ArmNegated` conjunct is ever dropped.
;
; THE FENCE, and it is ONE SPELLING (Rule 14). `constantAngleIsNonFinite` is
; shared with `angleSelectArmsAdmissible`'s clauses (2a)/(2b) — the sibling
; emitter that is the only other place in the tree putting ONE user angle into
; TWO gate slots, and which has had this fence since the bd drbq Inc-2b round-1
; Rule-13 review. l4x4.b shipped the `undef` half of the same argument
; (`..._negated_undef_angle.ll`) and stopped one conjunct short of the non-finite
; half. NO NEW DIAGNOSTIC STRING: `rotation angle`, the same string the undef
; clause uses and the same one the angle-select family's non-finite arm produces
; (`control_angle_select_reject_inf_arm.ll`).
;
; A RUN-TIME ANGLE KEEPS ACCEPTING and that is a DECISION, not an omission
; (`control_inplace_ry_rail_negated_runtime_angle.ll` pins it). The Inc-2b
; clearance blocker F-11's structure does not transfer: `fsub` manufactures a
; non-finite value FROM TWO FINITE ARMS, whereas `fneg` flips one sign bit and
; cannot leave the finite class — so the only input that breaks the identity is
; an angle that was ALREADY non-finite, i.e. an ill-formed CQ program in every
; spelling. The residual (a run-time angle non-finite at run time) and the owner
; option that removes it for every angle (the 1b-B.1 `CopyRailRoot` ancilla with
; the `cqrt_x` bracket ON THE ANCILLA — one gate fired, exact for any angle) are
; recorded at the clause in `ArmClassify.cpp` and in `FIX_l4x4b_R1.md`.
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
  %c = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br i1 %c, label %merge, label %arm
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
