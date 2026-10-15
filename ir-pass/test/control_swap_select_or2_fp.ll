; control_swap_select_or2_fp.ll — ACCEPT (3c6m.12 L4): the fdim-family fp
; compound — `or i1` of two tainted HL fcmps gating an f64 DATA select. The fp
; accept rides the kjd1 gate-4 un-staging unchanged: the copies mint via the
; select-local `copyControlledFpFn` (`cqrt_copy_f64_controlled`); the compound
; work is condition-side only, so the three-legged angle fence does not move
; (compound-cond-select-PRD §2). The FALSE operand is a classical literal —
; materialized `cqrt_alloc_f64(2.5)`, the §16.3 option-A path.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c1  = fcmp olt double %q, 2.500000e-01
  %c2  = fcmp ogt double %q, 7.500000e-01
  %c   = or i1 %c1, %c2
  %sel = select i1 %c, double %q, double 2.500000e+00
  %m   = call double @cq_measure_f64(double %sel)
  ret double %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_olt_f64_hl(i32 %[[Q]], double 2.500000e-01)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[Q]], double 7.500000e-01)
; CHECK:     %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[G]])
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[G]])
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[G]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[G]])
; CHECK:     call void @cqrt_xorc_f64_controlled(i32 %[[G]], i32 %[[OUT]], double 2.500000e+00)
; CHECK:     call void @cqrt_x(i32 %[[G]])
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[G]])
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[G]])
; CHECK:     call void @cqrt_free(i32 %[[G]])
; CHECK:     call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %[[F2]], i32 %[[Q]], double 7.500000e-01)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call void @cq_template_fcmp_olt_f64_hl_unc(i32 %[[F1]], i32 %[[Q]], double 2.500000e-01)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[OUT]])
; CHECK-NOT: select i1
; CHECK-NOT: cq_template_or_i1
