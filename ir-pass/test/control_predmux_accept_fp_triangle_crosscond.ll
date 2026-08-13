; control_predmux_accept_fp_triangle_crosscond.ll — ACCEPT (bd vyqi, W5;
; FORMERLY the 4.2 WI-3 DECLINE pin control_swap_reject_value_fp_merge.ll):
; `if (q > 5) { ang = ang + 0.5; }` — an fp triangle whose condition reads a
; DIFFERENT tainted register (i32 %q) than the merged fp value (%ang0).
;
; The old pin's premise — "an FP-typed merge under tainted control is
; categorically an ANGLE, never routable data" — predates the kjd1 fp-DATA
; un-staging: an fp merge is an angle AT ROTATION CONSUMERS (that fence is
; intact — gates 3/5 of the select ladder, plus ArmClassify's fp fence for
; everything W5 does not claim), but at a COPY consumer it is data over the
; frozen `cqrt_copy_f{16,32,64,80}_controlled` family. W5 claims the sole-phi
; fp triangle, PredMux flattens it to `select (q>5), ang0+0.5, ang0`, and the
; kjd1 ladder adjudicates: theta-only lineage (Ry basis superposition, no
; relative phase), measured consumer — a sound controlled-copy merge. Nothing
; routes; no uncontrolled `cqrt_copy_f64` exists or is minted (the dead-ABI
; guarantee the old pin protected is untouched — only the `_controlled` family
; fires).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='phi double' --implicit-check-not='call i32 @cqrt_copy_f64(' < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
define double @example(i32 %u0, double %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ang0 = call double @cq_theta_f64(double %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %f1 = fadd double %ang0, 5.000000e-01
  br label %merge
merge:
  %am = phi double [ %f1, %arm ], [ %ang0, %entry ]
  %m  = call double @cq_measure_f64(double %am)
  ret double %m
}

; CHECK:     call i32 @cq_template_fadd_f64_hl(
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[OUT]])
