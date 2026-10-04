; control_inplace_ry_derived_base_f64_late_use_frozen.ll — ACCEPT + FREEZE.
; The f64 / `@llvm.sqrt` spelling of `..._derived_base_mul_late_use_frozen.ll`
; (read that fixture's header for the defect and the root cause).
;
; WHY A THIRD FIXTURE FOR ONE DEFECT: the stale key was the theta's arg-0, and
; who erases it depends on WHICH lowering claims the derived op. There are FIVE
; separate `promote()` copies (`ArithLowering`, `CastLowering`, `CompareLowering`,
; `IntrinsicLowering`, and their drivers), each migrating `Tainted` / `BirthOrder`
; / `HandleWidth` from the original to the replacement and none of which knew
; about the freeze. `mul`/`add` go through `ArithLowering`; this one goes through
; `IntrinsicLowering` at a NON-i32 width, so it pins that the fix is a property
; of the emitted gate rather than of one lowering path.
;
;     double q=0, p=0; cq_theta(&q,.5); cq_theta(&p,.3);
;     double r = sqrt(p);
;     if (q > 5.0) cq_theta(&r, .9);
;     double s = r + 1.0;                // POST-REGION user
;     return cq_measure(q);
;
; Pre-fix (measured, `opt` exit 0, verify-clean): `cqrt_free(%h_cmp)` …
; `cqrt_ry_f64_controlled(%h_cmp, %h_intr, -0.9)` … `cqrt_free(%h_intr)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOREV < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT   < %t.cqd0.ll

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.sqrt.f64(double)

define double @example(double %u0, double %u1) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %p = call double @cq_theta_f64(double %u1, double 3.000000e-01)
  %r = call double @llvm.sqrt.f64(double %p)
  %c = fcmp ogt double %q, 5.000000e+00
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ %r, %entry ]
  %s  = fadd double %rm, 1.000000e+00
  %m  = call double @cq_measure_f64(double %q)
  ret double %m
}

; CHECK:      %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sqrt_f64(i32 %h1)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %h, double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_ry_f64_controlled(i32 %[[F]], i32 %[[OP]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %[[F]], i32 %h, double 5.000000e+00)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the post-region `r + 1.0` still lowers forward (a fresh fadd rail)
; CHECK-NEXT: call i32 @cq_template_fadd_f64_hl(i32 %[[OP]], double 1.000000e+00)
; CHECK-NEXT: call double @cqrt_measure_f64(i32 %h)

; Nothing reverses the frozen rail or anything hanging off it.
; NOREV-NOT: double -9.000000e-01
; NOREV-NOT: double -3.000000e-01
; NOREV-NOT: cq_template_sqrt_f64_unc
; NOREV-NOT: cq_template_fadd_f64_hl_unc
; NOREV-NOT: cqrt_free(i32 %h_intr)
; NOREV-NOT: cqrt_free(i32 %h1)

; EXACTLY one free in the whole module: the flag's.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
