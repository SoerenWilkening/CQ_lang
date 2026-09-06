; control_phase_kickback_reject_mixed_arm.ll — DECLINE. A MIXED ARM: a `cq_phi`
; BESIDE an Ry on another register (PRD §6.3 row 2).
;
; The accept class is an arm that is exactly `{ N × call void @cq_phi(double); br
; merge }` and NOTHING else. That strictness is load-bearing twice: it puts every
; angle's definition OUTSIDE the arm (so each dominates the branch the gates are
; hoisted to), and it makes "this arm is a pure phase" a STRUCTURAL fact rather
; than a walk that could miss something.
;
; A mixed arm has no single method (Rule 7): the kickback puts a phase on the FLAG
; and touches no register, while the in-place Ry arm must fire
; `cqrt_ry_<W>_controlled` ON the register and carries its own five fences (R4's
; disjoint wires, R6's stale record, the structural freeze). Combining them in one
; region was never analysed and is not this increment.
;
; ⚠ N > 1 `cq_phi` IN ONE ARM IS **NOT** MIXED AND IS AN ACCEPT — see
; `control_phase_kickback_two_calls.ll`. What makes an arm mixed is a NON-PHASE
; instruction in it, not the gate count.
;
; The message is the generic one because the fall-through owns this shape: the
; kickback classifier returns NotApplicable (the arm is not exactly its shape) and
; the region then declines through `recoverRegion`/`classifyArms` exactly as it
; did before this increment existed.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u0, double 2.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  %r1 = call i32 @cq_theta_si32(i32 %r0, double 3.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %r1, %arm ], [ %r0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; CHECK: cq controlled lowering: control flow under quantum control
