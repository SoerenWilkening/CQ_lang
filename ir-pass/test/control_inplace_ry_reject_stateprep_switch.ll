; control_inplace_ry_reject_stateprep_switch.ll — DECLINE: a tainted `switch`
; whose case arms are state preps.
;
; The 4.5 switch path has four accept shapes (homogeneous phase, homogeneous
; value, all-`ConstantInt` data mux, eq-folded diamond) and a rotation arm is
; none of them; the N-way eq-flag ROUTE has the same `Ry|0> != |0>` objection as
; the nest. Measured IDENTICAL on the pre-Inc-4 oracle.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 1, label %k1
                                i32 2, label %k2 ]
k1:
  %g1 = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
k2:
  %g2 = call i32 @cq_theta_si32(i32 0, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ 0, %entry ], [ %g1, %k1 ], [ %g2, %k2 ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
