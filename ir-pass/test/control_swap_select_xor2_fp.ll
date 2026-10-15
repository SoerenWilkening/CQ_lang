; control_swap_select_xor2_fp.ll — ACCEPT (bd 3c6m.67): the ULP-DIRECTION TEST
; verbatim — `xor i1` of two tainted HL fcmps, `(x > 0.0) ^ (x < y)`, which is
; `src/s_nextafterl.c:55` / `s_nexttoward.c:54` character-for-character modulo
; width. The measured IR those cells present is exactly this benign:
;     %25 = fcmp ogt x86_fp80 %1, 0.0
;     %26 = fcmp olt x86_fp80 %1, 0.5
;     %27 = xor i1 %25, %26
; Both leaves already passed `isSupportedCompareLeaf`; the two-operand xor was
; the ONLY off-grammar node in the whole construct.
;
; The fp accept rides the kjd1 gate-4 un-staging unchanged — the copies mint via
; the select-local `copyControlledFpFn` (`cqrt_copy_f64_controlled`) and the
; compound work is CONDITION-side only, so the three-legged angle fence does not
; move (compound-cond-select-PRD §2). Nothing about fp is special to the xor:
; the node operates on FLAG rails, which are i1 whatever the leaves compared.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=WHOLE < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c1  = fcmp ogt double %q, 0.000000e+00
  %c2  = fcmp olt double %q, 5.000000e-01
  %c   = xor i1 %c1, %c2
  %sel = select i1 %c, double %q, double 2.500000e+00
  %m   = call double @cq_measure_f64(double %sel)
  ret double %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[Q]], double 0.000000e+00)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_olt_f64_hl(i32 %[[Q]], double 5.000000e-01)
; CHECK:     %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[G]])
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[G]])
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[G]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[G]])
; CHECK:     call void @cqrt_xorc_f64_controlled(i32 %[[G]], i32 %[[OUT]], double 2.500000e+00)
; CHECK:     call void @cqrt_x(i32 %[[G]])
; CHECK:     call void @cqrt_cnot(i32 %[[F2]], i32 %[[G]])
; CHECK:     call void @cqrt_cnot(i32 %[[F1]], i32 %[[G]])
; CHECK:     call void @cqrt_free(i32 %[[G]])
; CHECK:     call void @cq_template_fcmp_olt_f64_hl_unc(i32 %[[F2]], i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %[[F1]], i32 %[[Q]], double 0.000000e+00)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[OUT]])
;
; WHOLE-NOT: cqrt_toffoli
; WHOLE-NOT: cq_template_xor_i1
; WHOLE-NOT: select i1
