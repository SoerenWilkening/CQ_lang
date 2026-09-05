; control_swap_reject_nested_distinct_base.ll — DECLINE: a merge incoming
; carrying an independently-derived base.
;
; `if (q>5) { q = rz(q,b); if (q<9) { r = rz(r,a); q = r; } }` — the inner arm
; merge edge carries r-lineage (a SECOND, independent cq_theta), while the Pred
; and Mid edges carry q. The three incomings do NOT collapse to one i32 base
; through the cq_phi diagonal-alias closure → criterion 4 (N-incoming
; RAUW-collapse) declines `control flow`. (All arms are phase, so homogeneity
; passes; RAUW-collapse is the gate that fires.)
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
define i32 @example(i32 %u0, i32 %v0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r  = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %qm = phi i32 [ %r, %arm ], [ %q, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; CHECK: error{{.*}}cq controlled lowering: impure phase arm under quantum control
