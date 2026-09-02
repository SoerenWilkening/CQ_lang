; control_inplace_ry_f64.ll — ACCEPT spec, the control-in-place rotation diamond
; at a NON-i32 width (bd test_C_libtooling-drbq Inc 1).
;
;     double q = cq_theta(0.0,.5); double r = cq_theta(0.0,.3);
;     if (q > 5.0) r = cq_theta(r, .9);
;
; The width tags the SYMBOL and nothing else (Rule 15): `cqrt_ry_f64_controlled`
; takes the same `(i32 ctrl, i32 handle, double angle)` as every other width, and
; the flag comes from the fcmp template rather than the icmp one. The gate is
; still IN PLACE on the user's register.
;
; The ANGLE stays classical and f64-typed here — it is arg 2 of the emitted call
; and never a handle. That is the f64/angle miscompile family's boundary (Rule 3):
; the WIDTH `f64` names the register's data width, not the angle's.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %u1) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %r = call double @cq_theta_f64(double %u1, double 3.000000e-01)
  %c = fcmp ogt double %q, 5.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ %r, %entry ]
  %m  = call double @cq_measure_f64(double %rm)
  ret double %m
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u1)
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[Q]], double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_ry_f64_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %[[F]], i32 %[[Q]], double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK:      call double @cqrt_measure_f64(i32 %[[R]])
; CHECK-NOT:  cqrt_cswap
; CHECK-NOT:  phi double
