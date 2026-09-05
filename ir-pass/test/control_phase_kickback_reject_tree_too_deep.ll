; control_phase_kickback_reject_tree_too_deep.ll — DECLINE. NINE compare leaves
; in one branch-phase condition tree, one past the bound.
;
; The bound is stated rather than implied: each leaf costs one flag rail and each
; node one |0> ancilla, and ALL of them are live simultaneously between the mint
; and the LIFO strip, so an unbounded tree is an unbounded live ancilla set.
; `kPhaseCondTreeMaxLeaves` / `kPhaseCondTreeMaxNodes` are both 8 — far past
; anything `clang -O1` builds from a C `&&`/`||` chain (the measured customers
; have 1 leaf / 0 nodes and 2 leaves / 1 node) — so the fence exists to make the
; resource claim a FACT rather than a hope.
;
; This fixture pins the bound from ABOVE; `control_phase_kickback_and3_tree.ll`
; is a three-leaf accept, so raising the constant reddens this file and lowering
; it below three reddens that one.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %u2, i32 %u3, i32 %u4, i32 %u5, i32 %u6, i32 %u7, i32 %u8) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q1 = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %u2, double 5.000000e-01)
  %q3 = call i32 @cq_theta_si32(i32 %u3, double 5.000000e-01)
  %q4 = call i32 @cq_theta_si32(i32 %u4, double 5.000000e-01)
  %q5 = call i32 @cq_theta_si32(i32 %u5, double 5.000000e-01)
  %q6 = call i32 @cq_theta_si32(i32 %u6, double 5.000000e-01)
  %q7 = call i32 @cq_theta_si32(i32 %u7, double 5.000000e-01)
  %q8 = call i32 @cq_theta_si32(i32 %u8, double 5.000000e-01)
  %c0 = icmp eq i32 %q0, 0
  %c1 = icmp eq i32 %q1, 1
  %c2 = icmp eq i32 %q2, 2
  %c3 = icmp eq i32 %q3, 3
  %c4 = icmp eq i32 %q4, 4
  %c5 = icmp eq i32 %q5, 5
  %c6 = icmp eq i32 %q6, 6
  %c7 = icmp eq i32 %q7, 7
  %c8 = icmp eq i32 %q8, 8
  %n1 = select i1 %c0, i1 %c1, i1 false
  %n2 = select i1 %n1, i1 %c2, i1 false
  %n3 = select i1 %n2, i1 %c3, i1 false
  %n4 = select i1 %n3, i1 %c4, i1 false
  %n5 = select i1 %n4, i1 %c5, i1 false
  %n6 = select i1 %n5, i1 %c6, i1 false
  %n7 = select i1 %n6, i1 %c7, i1 false
  %n8 = select i1 %n7, i1 %c8, i1 false
  br i1 %n8, label %arm, label %merge
arm:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q0)
  ret i32 %m
}

; CHECK: cq controlled lowering: branch phase condition tree too deep under quantum control
