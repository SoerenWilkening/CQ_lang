; spec_overaccept_probe_measure_body.ll — Phase 6.4 WI-4.3 over-accept probe. The
; body is otherwise a clean straight-line i32 value function, but it MEASURES its
; own result before returning — collapsing the caller's superposition. Detected by
; exact call-site membership against the propagate-collected measure set (never
; name-prefix). Declines `Measurement`. Guards against a weakening that scans only
; for `cq_theta`/`cq_phi` and misses the sink.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %x) {
entry:
  %t = mul i32 %x, 2
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %z = call i32 @cq_measure_si32(i32 %r)
  ret i32 %z
}

; CHECK: error{{.*}}cq specialization: callee measures under quantum lift
; CHECK-NOT: @__cq_q_helper
