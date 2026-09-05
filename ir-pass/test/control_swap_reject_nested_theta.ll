; control_swap_reject_nested_theta.ll — DECLINE: a non-cq_phi (cq_theta/Ry)
; intervening outer-arm gate.
;
; `if (q>5) { q = ry(q,b); if (q<9) { q = rz(q,a); } }` — the Mid gate is a
; cq_theta (Ry), NOT a diagonal Rz. Its output %g is NOT in the cq_phi
; diagonal-alias closure, so the Mid merge-edge resolves to a DISTINCT base and
; criterion 4 (N-incoming RAUW-collapse) fires `control flow`. (Homogeneity
; PASSES it through — a cq_theta is a phase leaf, not a value op — so the
; `condition predates a non-diagonal gate` 4.1 string is unreachable on this
; nested row; FA2, pinned to the string that actually fires on real -O1.)
;
;
; 3qlq(prep_a2): the asserted diagnostic was RE-SPELLED on the Inc-1 binary.
; The construct this fixture pins is unchanged; the CLAUSE that refuses it
; MOVED — this is a real disposition change, not a widening, and the new
; string does not contain the old one.
; OLD: lowering: control flow under quantum control
; NEW: cq controlled lowering: impure phase arm under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %g  = call i32 @cq_theta_si32(i32 %q, double %b)
  %c2 = icmp slt i32 %g, 9
  br i1 %c2, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %qm = phi i32 [ %g, %arm ], [ %g, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; CHECK: error{{.*}}cq controlled lowering: impure phase arm under quantum control
