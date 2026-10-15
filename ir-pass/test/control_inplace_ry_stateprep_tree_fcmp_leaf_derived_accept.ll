; control_inplace_ry_stateprep_tree_fcmp_leaf_derived_accept.ll — ACCEPT, the
; ONE-TOKEN CONTROL of `control_inplace_ry_reject_stateprep_tree_fcmp_leaf_derived.ll`
; (bd test_C_libtooling-dm7f.52): the seed `15.0` → `16.0` and nothing else, so
; `%d = %t * 3.0` (pinned to 15.0 on the true edge through the `fcmp` LEAF) no
; longer folds to the seed, and the controlled state prep lowers under the
; compound condition `and i1 (fcmp oeq %t, 5.0), %b`. It shows the sibling's
; decline is the FOLD matching, not the shape. The stream: the derived compare
; leaf mints its flag from the `fmul` template, the rail `%b` is read as a
; control, the root ancilla drives the controlled Ry on the FRESH 16.0 rail, and
; the LIFO strip runs before the `fmul` chain's own `_unc`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define double @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %b = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  %t = fmul double %q, 2.000000e+00
  %c = fcmp oeq double %t, 5.000000e+00
  %cc = and i1 %c, %b
  br i1 %cc, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double 1.600000e+01, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ 1.600000e+01, %entry ]
  %d = fmul double %t, 3.000000e+00
  %mr = call double @cq_measure_f64(double %rm)
  %md = call double @cq_measure_f64(double %d)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %s  = fadd double %mr, %md
  ret double %s
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[B]], double 2.500000e-01)
; CHECK-NEXT: %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fmul_f64_hl(i32 %[[H]], double 2.000000e+00)
; CHECK-NEXT: %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %[[OP]], double 5.000000e+00)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[C]], i32 %[[B]], i32 %[[G]])
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 1.600000e+01)
; CHECK-NEXT: call void @cqrt_ry_f64_controlled(i32 %[[G]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[C]], i32 %[[B]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %[[C]], i32 %[[OP]], double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[C]])
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
