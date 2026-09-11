; control_inplace_ry_reject_rail_negated_nan_angle.ll — DECLINE: a NON-FINITE
; CONSTANT angle (a quiet NaN) on a NEGATED rail arm.
;
; THE SECOND MEMBER OF ROUND-1 RULE-13 FINDING F-1's class (bd
; `test_C_libtooling-l4x4`, sub-increment l4x4.b). Plain C at `-O1`
; (`review_l4x4b_r1_probes/x02_neg_nan_angle.c`): the same program as
; `..._negated_inf_angle.ll` with `__builtin_nan("")` in the angle slot. The
; l4x4.b checkpoint 267937d emitted
;
;     cqrt_ry_i32(%h1, 0x7FF8000000000000)
;     cqrt_ry_i32_controlled(%h, %h1, 0xFFF8000000000000)
;
; so on the `b = 1` branch — where the source is the IDENTITY — the register sees
; `Ry(NaN)·Ry(NaN)`, which is NaN and not `I`. The anti-control identity
; `Ry(θ)·Ry(−θ) = I` holds for FINITE θ only.
;
; WHY A SEPARATE FILE FROM THE `+inf` ONE, and it is not decoration: `+inf`, NaN
; and `-inf` are three distinct `APFloat` categories, and the fence is spelled as
; ONE question over all of them (`!getValueAPF().isFinite()`, the shared
; `constantAngleIsNonFinite`). A fence pinned on one category only is a fence
; whose next narrowing has no witness for the other two — this family's own
; F-1 is exactly what happens when the sibling clause is pinned and this one is
; not. `..._negated_neginf_angle.ll` is the third.
;
; RED ON THE CHECKPOINT 267937d (it compiled this module, `opt` exit 0,
; verify-clean); red on `main` 0c7380c and the F2 checkpoint 578dbc4 for a
; DIFFERENT reason (`bare i1 register condition`), so neither can witness it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout, so every IR-TEXT negative
; here would be VACUOUS; the `not` INVERSION on the RUN line plus the mirrored
; string below are what pin "no silent lowering".
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
