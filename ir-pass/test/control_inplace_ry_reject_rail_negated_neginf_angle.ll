; control_inplace_ry_reject_rail_negated_neginf_angle.ll — DECLINE: a NON-FINITE
; CONSTANT angle (`-inf`) on a NEGATED rail arm.
;
; THE THIRD MEMBER of round-1 Rule-13 finding F-1's class (bd
; `test_C_libtooling-l4x4`, sub-increment l4x4.b), and the one that RECORDS A
; READING. The fix brief listed the decline members as "`inf` and `NaN`, plus the
; `-inf` and `−0.0`/`0.0` ACCEPT controls", which groups `-inf` with the accepts.
; IT IS A DECLINE HERE, deliberately, and the reason is physics rather than
; convention: the negated form emits `ry(h,θ); cry(h_b,h,−θ)`, so the `b = 1`
; branch composes `Ry(−θ)·Ry(+θ)`, and at θ = −inf that is `(+inf) + (−inf)` =
; NaN — exactly as at θ = +inf. THE SIGN OF THE INFINITY CHANGES NOTHING, because
; the defect is the SUM of the two slots, not the sign of one. Accepting `-inf`
; while declining `+inf` would be an over-accept on the identical unitary, and
; over-accepting is the one unforgivable outcome (Prime Directive). The ACCEPT
; controls the brief asks for are the FINITE ones, `0.0` / `-0.0`, and they are
; `control_inplace_ry_rail_negated_zero_angle.ll`.
;
; It follows from the predicate, not from a third enumeration: the fence asks
; `!getValueAPF().isFinite()` (the shared `constantAngleIsNonFinite`), which is
; true of `+inf`, `-inf` and every NaN alike. This file is the witness that the
; question really is about FINITENESS and not about a list of two spellings.
;
; RED ON THE l4x4.b CHECKPOINT 267937d (it compiled the `+inf` and NaN siblings
; at `opt` exit 0); red on `main` 0c7380c and the F2 checkpoint 578dbc4 for a
; DIFFERENT reason (`bare i1 register condition`).
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
  %rt = call i32 @cq_theta_si32(i32 %r, double 0xFFF0000000000000)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %mc = call i1 @cq_measure_i1(i1 %c)
  %zc = zext i1 %mc to i32
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mr, %zc
  ret i32 %s
}
