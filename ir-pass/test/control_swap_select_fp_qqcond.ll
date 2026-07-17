; control_swap_select_fp_qqcond.ll — ACCEPT (bd adia, 3c6m.55 Lever C): a Q+Q
; **fcmp** select condition — BOTH compare operands tainted — over fp DATA
; arms. Mints the QQ fcmp flag `cq_template_fcmp_ogt_f64(h, h)` (the frozen
; 7.1 Q+Q fcmp family; NO new symbol) and merges through the kjd1
; select-local `cqrt_copy_f64_controlled`. The fcmp twin of
; control_swap_select_qqcond.ll; formerly the fp-data-select-PRD §5 matrix-8
; decline.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %u1, double %x) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %y   = call double @cq_theta_f64(double %u1, double 5.000000e-01)
  %c   = fcmp ogt double %q, %y                  ; Q+Q fcmp condition (both tainted)
  %sel = select i1 %c, double %q, double %x
  %m   = call double @cq_measure_f64(double %sel)
  ret double %m
}
; CHECK: %[[F:.*]] = call i32 @cq_template_fcmp_ogt_f64(i32 %[[HQ:.*]], i32 %[[HY:.*]])
; CHECK-NEXT: %[[OUT:.*]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[HQ]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[XS:.*]] = call i32 @cqrt_alloc_f64(double %x)
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[XS]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call i32 @cq_template_fcmp_ogt_f64_inv(i32 %[[HQ]], i32 %[[HY]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK: call double @cqrt_measure_f64(i32 %[[OUT]])
