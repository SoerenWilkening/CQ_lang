; control_angle_select_reject_nested_select.ll — DECLINE (S2): a NESTED angle
; select (bd drbq Inc 2b).
;
;     r = cq_theta(r, q == 5 ? .9 : (q == 6 ? .3 : .1));
;
; The inner select's only user is the OUTER select, not a rotation arg-1, so S2
; refuses it; the outer select's FALSE operand is the inner select's result,
; which S1 would also have to accept as classical. A three-way angle needs a
; two-flag composition (the by-difference identity chains, but the second
; difference must be controlled on the CONJUNCTION of the two flags), which is
; outside this increment. Both selects decline; the first diagnostic wins.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c1 = icmp eq i32 %q, 5
  %c2 = icmp eq i32 %q, 6
  %inner = select i1 %c2, double 3.000000e-01, double 1.000000e-01
  %ang = select i1 %c1, double 9.000000e-01, double %inner
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
