; control_predmux_leave_fp128_arith.ll — LEAVE→DECLINE (3c6m.14 L6, the
; Rule-13 clearance finding): an arm computing through fp128 intermediates
; (fpext → fmul fp128 → fptrunc back to a muxable double). E4's
; isTemplateWidthType gate LEAVES the region (fp128 has no template at any
; consumer), so it falls through to the existing loud control decline —
; detect-before-mutate: the region must NOT be flattened first and then die
; at lowerOps with an op-level message.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
define double @example(double %u0) {
entry:
  %q  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c1 = fcmp ogt double %q, 0.000000e+00
  br i1 %c1, label %mid, label %merge
mid:
  %w  = fpext double %q to fp128
  %w2 = fmul fp128 %w, %w
  %v1 = fptrunc fp128 %w2 to double
  %c2 = fcmp ogt double %q, 1.000000e+00
  br i1 %c2, label %arm, label %merge
arm:
  %v2 = fadd double %v1, 1.000000e+00
  br label %merge
merge:
  %rm = phi double [ %q, %entry ], [ %v1, %mid ], [ %v2, %arm ]
  %m  = call double @cq_measure_f64(double %rm)
  ret double %m
}
; CHECK: error{{.*}}under quantum control
; CHECK-NOT: no template
