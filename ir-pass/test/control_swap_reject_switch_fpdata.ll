; control_swap_reject_switch_fpdata.ll — DECLINE: fp-as-DATA merge (G4, FP-fence).
; The double merge does NOT reach a rotation arg-1 (G3 passes via fptosi, which the
; angle walk does not cross), so the FP-fence catches it as un-lowerable fp data.
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
  %dm = phi double [ 0.000000e+00, %entry ], [ 1.000000e+00, %a0 ], [ 2.000000e+00, %a1 ]
  %r = fptosi double %dm to i32
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
