; control_swap_reject_switch_vector.ll — DECLINE: <2 x i32> vector merge (G4). Not a
; scalar integer; isFPOrFPVectorTy / !isIntegerTy / empty width all catch it.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %vm = phi <2 x i32> [ <i32 0, i32 0>, %entry ], [ <i32 1, i32 1>, %a0 ], [ <i32 2, i32 2>, %a1 ]
  %e = extractelement <2 x i32> %vm, i32 0
  %m = call i32 @cq_measure_si32(i32 %e)
  ret i32 %m
}
