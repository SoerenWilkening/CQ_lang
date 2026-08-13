; control_predmux_accept_fp_triangle_solephi.ll — ACCEPT (bd vyqi, W5): the
; one-arm-modifies fp TRIANGLE with the pre-branch value passed through on the
; straight edge (`if (c) z = q*2;` → `phi [%b,%arm],[%q,%entry]`). Previously
; this declined at the SAME ArmClassify fp fence as the if/else (the 4.2 value
; path is type-gated before arm shape matters); clang -O1 usually if-converts
; the single-op pure triangle to a select itself, but a `volatile` accumulator
; (the log10l "***CAUTION***" idiom) suppresses that, so the zco4-promoted
; sole-accumulator triangle reaches the pass as this branch shape. W5's
; witness keys only on the sole 2-incoming scalar-fp DISTINCT-incoming merge
; phi — passthrough vs both-arms-write is irrelevant — so the triangle
; flattens to `select c, b, q` and rides the same kjd1 controlled-copy merge.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='br i1' --implicit-check-not='phi double' < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp olt double %q, 5.000000e-01
  br i1 %c, label %arm, label %merge
arm:
  %b = fmul double %q, 2.000000e+00
  br label %merge
merge:
  %zv = phi double [ %b, %arm ], [ %q, %entry ]    ; passthrough on the false edge
  %m = call double @cq_measure_f64(double %zv)
  ret double %m
}

; CHECK:     call i32 @cq_template_fmul_f64_hl(i32 %{{[a-zA-Z0-9_.]+}}, double 2.000000e+00)
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_olt_f64_hl(
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[FLAG]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[FLAG]])
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[OUT]])
