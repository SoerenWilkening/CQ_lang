; lowering_reject_trig_f32_no_direct_route.ll — bd 3c6m.71: the direct trig
; route is `double` only (Bennett.jl has no binary32 soft_sin). A tainted
; `@sinf(float)` libcall is NOT rewritten to a direct template; with no
; injected body in the module it stays an unknown callee, loudly. (Through
; tools/cqc it binds openlibm's sinf source instead.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee

declare float @cq_theta_f32(float, double)
declare float @cq_measure_f32(float)
declare float @sinf(float)

define float @example(float %u) {
  %q = call float @cq_theta_f32(float %u, double 5.000000e-01)
  %s = call float @sinf(float %q)
  %m = call float @cq_measure_f32(float %s)
  ret float %m
}
