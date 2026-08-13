; lowering_fpext_f64_to_f80.ll — bd 3c6m.4: the fp-WIDTH cast grid extended to
; long double. A tainted `double` handle widened by `fpext double to x86_fp80`
; (the C `(long double)d` conversion) lowers to the unary cast template
; `cq_template_fpext_f64_to_f80(handle)` (i32→i32; the width pair only names the
; symbol). This is the SAME-DOMAIN widen (f80 completes the fpext/fptrunc grid
; over {f16,f32,f64,f80}) — cross-domain int<->f80 is fenced out (see
; lowering_reject_sitofp_i32_to_f80.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f64(double %u0)
; CHECK:     call i32 @cq_template_fpext_f64_to_f80(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call x86_fp80 @cqrt_measure_f80(
;
; CHECK-NOT: fpext double

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare x86_fp80 @cq_measure_f80(x86_fp80)

define x86_fp80 @example(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %w = fpext double %q to x86_fp80
  %m = call x86_fp80 @cq_measure_f80(x86_fp80 %w)
  ret x86_fp80 %m
}
