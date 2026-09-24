; condtree_classical_leaf_reject_angle_select.ll — DECLINE (bd test_C_libtooling-xdu2.13).
;
; The mixed tree on an ANGLE select (a `double` select feeding `cq_theta` arg 1).
; The literal is a 4.4 DATA-select capability; the angle-select classifier
; re-derives its own tree without literals, so this keeps the pre-xdu2.13
; verdict and string, asked before the angle hand-off.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

define i32 @slice(i32 %n, i32 %m) {
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %t = icmp ne i32 %q, 0
  %c = icmp eq i32 %m, %n
  %a = and i1 %c, %t
  %ang = select i1 %a, double 5.000000e-01, double 2.500000e-01
  %r0 = call i32 @cq_theta_si32(i32 1, double %ang)
  %r1 = call i32 @cq_measure_si32(i32 %q)
  %r2 = call i32 @cq_measure_si32(i32 %r0)
  %r = add i32 %r1, %r2
  ret i32 %r
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
