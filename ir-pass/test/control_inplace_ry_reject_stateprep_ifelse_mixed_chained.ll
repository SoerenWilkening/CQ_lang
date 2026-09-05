; control_inplace_ry_reject_stateprep_ifelse_mixed_chained.ll — DECLINE: a state
; prep in one arm beside a CHAINED in-place rotation in the other (probe `p05`,
; from C).
;
;     if (q == 5) r = cq_theta(0, .9);   else r = cq_theta(p, .4);
;
; The prep arm is `Region.Arm` (successor 0) and is processed FIRST, so the
; if/else clause fires before any homogeneity flag is set. PRD §14.3 row IE-4
; predicted `impure phase arm` — the PRE-INC-4 ORACLE's string, measured — and is
; CORRECTED by this fixture for the same reason as IE-3.
;
; The physics is worse than "two rails": the two arms name two DIFFERENT physical
; wires (a fresh rail and `p`'s live register), so this is a cross-handle mux on
; top of the two-rails objection.
; §14.2e — THE IF/ELSE CLAUSE, AN OWNER RULING SPELLED OUT. It gets its own
; string rather than riding F1's absence, because F1 fires through the ABSENCE of
; a Pred edge (an if/else merge φ has none), and a fence that fires by absence is
; a fence nobody can find — which is how a later widener removes a bound without
; noticing there was one.
;
; ⚠ THE "R3 WOULD LET IT THROUGH" AND "M-β WOULD BE PHYSICALLY CORRECT"
; PARAGRAPHS WERE REMOVED FROM THIS FILE 2026-09-05 (round-1 Rule-13 review, lens
; L7 finding F-L7-8): both are about TWO ARMS WHOSE SEEDS ARE THE SAME CONSTANT,
; which is true of `..._ifelse_two_preps.ll` and of no other file that carried
; them. They live there.
;
;
; ⚠ THE STRING MOVED 2026-09-05 (round-1 Rule-13 review, lens L7 finding
; F-L7-8). HEAD used to print `if/else state prep allocates two rails` here, and
; THIS FILE HAS ONLY ONE PREP: the other arm is a CHAINED Ry on a live register, so nothing allocates
; two rails and the message described a different program. The §14.2e clause now
; asks what the OTHER arm is — with the same `inPlaceRotationArmTheta` predicate
; it is already inside, never a second spelling — and says
; `if/else state prep beside a chained or phase arm` for this shape, keeping the
; two-rails wording for `..._ifelse_two_preps.ll` and `..._ifelse_diff_seeds.ll`,
; where it is true.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}if/else state prep beside a chained or phase arm under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %armt, label %armf
armt:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
armf:
  %rf = call i32 @cq_theta_si32(i32 %p, double 4.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %armt ], [ %rf, %armf ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s = add i32 %mq, %mr
  ret i32 %s
}
