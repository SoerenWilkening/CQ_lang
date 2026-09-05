; control_inplace_ry_reject_stateprep_ifelse_diff_seeds.ll — DECLINE: an if/else
; with two state preps of DIFFERENT seeds (probe `p14b`, which from C survives as
; a real if/else rather than folding to an angle select).
;
; ⚠ PRD §14.3 ROW IE-3 IS CORRECTED BY THIS FIXTURE. §14 predicted `impure phase
; arm` — which is what the PRE-INC-4 ORACLE prints (measured), because there the
; classical-seed theta was not a rotation arm at all and the region fell through
; to the if/else leaf-anchor path, whose `armBlockIsPureSpine` walks a `cq_phi`
; spine and finds a theta. After Inc 4 the arm IS recognized, so the if/else
; clause adjudicates first and the message names the real defect. A decline
; either way; the string moved because the CLAUSE moved, which is the honest
; outcome and is recorded rather than papered over.
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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}if/else state prep allocates two rails under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %armt, label %armf
armt:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
armf:
  %rf = call i32 @cq_theta_si32(i32 3, double 4.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %armt ], [ %rf, %armf ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s = add i32 %mq, %mr
  ret i32 %s
}
