; control_swap_diamond_derived_f64.ll — ACCEPT: derived base at f64 / fcmp condition.
;
; The derived-base diamond (test_C_libtooling-9hh) over a FLOAT quantum handle
; with an `fcmp` condition — the first float-width fixture in the control_swap
; family (the §8 completeness review found the fcmp control path entirely
; unpinned, 2026-06-10). Same diagonality argument as i32: Rz preserves the
; basis value at any width, so fcmp(q) is recoverable by fcmp_inv(q). Handles
; stay i32 (Rule 15); f64 appears only as the alloc seed, the template literal,
; and the angle.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %a) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %qd = call double @cq_phi_f64(double %q, double 9.000000e-01)
  %c = fcmp ogt double %qd, 5.0
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call double @cq_phi_f64(double %qd, double %a)
  br label %merge
merge:
  %qm = phi double [ %q1, %arm ], [ %qd, %entry ]
  %m  = call double @cq_measure_f64(double %qm)
  ret double %m
}

; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK:     call void @cqrt_ry_f64(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_f64(i32 %[[Q]], double 9.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[Q]], double 5.000000e+00)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_rz_f64(i32 %[[T]], double %a)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_free(i32 %[[T]])
; CHECK:     call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %[[F]], i32 %[[Q]], double 5.000000e+00)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[Q]])
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi double

; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
