; lowering_reject_invtrig_f32_no_direct_route.ll — bd 3c6m.71: the direct
; inverse-trig route is `double` only (Bennett.jl has no binary32 soft_asin).
; A tainted `@llvm.asin.f32` is not admitted, and with no injected body it stays
; an unknown callee, loudly. (Through tools/cqc it binds openlibm's asinf.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee

declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)
declare float @llvm.asin.f32(float)

define float @example(float %u) {
  %q = call float @cq_theta_f32(float %u, double 5.000000e-01)
  %a = call float @llvm.asin.f32(float %q)
  %m = call float @cq_measure_f32(float %a)
  ret float %m
}
