; control_inplace_ry_reject_rail_stateprep_negated_inf_angle.ll — DECLINE: a
; NON-FINITE CONSTANT angle (`+inf`) on a NEGATED rail-condition STATE PREP.
;
; THE FOURTH MEMBER of round-1 Rule-13 finding F-1's class (bd
; `test_C_libtooling-l4x4`, sub-increment l4x4.b) — and the one the review did
; NOT name, which is why it is committed rather than assumed. F-1's reproducers
; were all IN-PLACE Ry arms; the CONTROLLED STATE PREP is a different accept
; shape (a fresh rail from a classical seed, PRD §14 / bd drbq Inc 4), and it
; duplicates the angle the SAME way:
;
;     cqrt_alloc_<W>(SEED) ; cqrt_ry_<W>(h_r, θ) ; cqrt_ry_<W>_controlled(h_b, h_r, −θ)
;
; so on the `b = 1` branch — where the source leaves `r` at the SEED — the fresh
; rail sees `Ry(−θ)·Ry(+θ)`, which at θ = ±inf or NaN is NaN rather than `I` and
; leaves the register in no computational state at all.
;
; MEASURED on the pre-fix checkpoint 267937d from PLAIN C at `-O1`
; (`_Bool b = 0; int r = 5; b = cq_theta(b,0.5); if (!b) r = cq_theta(5,
; __builtin_inf());`): rc 0, emitting
; `cqrt_ry_i32(%h1, +inf); cqrt_ry_i32_controlled(%h, %h1, -inf)`. On the fix:
; `rotation angle`, rc 1.
;
; WHAT IT PINS BEYOND ITS SIBLINGS: the CLAUSE'S PLACEMENT. The F-1 conjunct sits
; among the shared rail clauses, ABOVE the three `StatePrep`-guarded clauses (F1,
; F2, the seed checks), so it covers BOTH accept shapes with one question. Move
; it below them — or duplicate it into the rotation path only — and this file
; goes red while its three in-place siblings stay green, which is exactly the
; failure mode the ONE-SPELLING discipline exists to catch. Its FINITE control is
; `control_inplace_ry_stateprep_rail_negated.ll` (already committed, unmoved by
; the fix: `ry(h1,+0.5); cry(h,h1,−0.5)`).
;
; RED ON `main` 0c7380c AND ON the F2 checkpoint 578dbc4 for a DIFFERENT reason
; (`bare i1 register condition`), so only the checkpoint 267937d witnesses it.
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

define i32 @slice() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %b, label %merge, label %arm

arm:
  %rt = call i32 @cq_theta_si32(i32 5, double 0x7FF0000000000000)
  br label %merge

merge:
  %rm = phi i32 [ 5, %entry ], [ %rt, %arm ]
  %mb = call i1 @cq_measure_i1(i1 %b)
  %zb = zext i1 %mb to i32
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mr, %zb
  ret i32 %s
}
