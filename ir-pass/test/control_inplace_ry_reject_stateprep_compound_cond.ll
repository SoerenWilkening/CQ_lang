; control_inplace_ry_reject_stateprep_compound_cond.ll — DECLINE: a COMPOUND
; `&&` condition (clang's `select i1`) over a state-prep arm.
;
; `classifyArms` refuses a non-`CmpInst` condition outright, before any arm is
; looked at. Measured IDENTICAL on the pre-Inc-4 oracle.
;
; ⚠ THIS FIXTURE IS ALSO F2's RETIREMENT TRIGGER, COMMITTED (PRD §14.2b). F2
; reads ONE compare and needs no `and`/`or` leaf walk ONLY BECAUSE compound
; conditions reach no control accept path. A compound condition DOES fold, and it
; folds a SECOND register too — `if (q == 5 && p == 3) r = cq_theta(p, .9)`
; arrives as `cq_theta(i32 3, .9)` (probe `p08q`). THE DAY COMPOUND CONDITIONS
; ARE ADMITTED TO ANY CONTROL ACCEPT PATH, F2 MUST BE ASKED OF EVERY LEAF OF THE
; FLAG NETWORK, AND OF EVERY REGISTER ANY LEAF PINS — not just of the register
; the arm rotates. Written now rather than discovered later (the bd 8h7d.5
; F-1/F-3 discipline).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c1 = icmp sgt i32 %q, 5
  %c2 = icmp slt i32 %p, 9
  %cc = select i1 %c1, i1 %c2, i1 false
  br i1 %cc, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
