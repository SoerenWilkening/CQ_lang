; control_swap_reject_fanout.ll — DECLINE probe: a phase arm whose spine FANS OUT
; (Rule 8 linearity; swap-route 4.1 IMPLEMENTATION §6 / SCOPING §0-Bonus).
;
; The merge-feeding chain is q -> %q1 -> %q2, but %q1 is ALSO consumed by a
; sibling cq_phi (%dead) in the arm — so %q1 has TWO forward consumers. The
; swap-route emitter replays only the merge-feeding spine onto the rail and erases
; that spine; the sibling %dead would be left dangling in taint.PhiCalls,
; referencing the freed %q1 (a use-after-free / broken module when lowerRotations
; re-reads it). Whole-chain reversal requires LINEAR lineage (Rule 8): the arm
; block must be exactly the linear phase spine, so the off-spine sibling %dead
; trips the `impure phase arm` decline (over-decline is safe; Prime Directive).
; Detection is pure SSA-value analysis before any mutation.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}impure phase arm under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b, double %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %k = icmp sgt i32 %q, 5
  br i1 %k, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  call void @cq_phi(double %b)  ; merge-feeding spine
  call void @cq_phi(double %c)  ; FAN-OUT: second use of %q
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
