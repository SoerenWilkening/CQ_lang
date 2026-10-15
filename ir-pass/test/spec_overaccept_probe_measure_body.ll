; spec_overaccept_probe_measure_body.ll — Phase 6.4 WI-4.3 over-accept probe. The
; body is otherwise a clean straight-line i32 value function, but it MEASURES its
; own result before returning — collapsing the caller's superposition. Detected by
; exact call-site membership against the propagate-collected measure set (never
; name-prefix). Declines `Measurement`. Guards against a weakening that scans only
; for `cq_theta`/`cq_phi` and misses the sink.
;
; bd p3kd.21 (2026-10-14) — NOW AN ACCEPT; the file name and the DECLINE text
; above are history. A callee that MEASURES is a GATE SUBROUTINE (`cq_measure`
; is a front-end primitive), so the call is compiled at its site
; (SpecializeGateInline.h) and never lifted: the measurement the user wrote is
; the caller's own, exactly as in the hand-inlined twin. The over-accept this
; probe guarded against (a Bennett-lifted clone holding a measurement) still
; cannot happen: `scanBody` still refuses it for every non-inlinable site
; (pinned by spec_reject_gate_sub_devirt_measure.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define i32 @example(
; CHECK: [[Q:%[a-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[a-z0-9_.]+]] = call i32 @cq_template_shl_i32_hl(i32 [[Q]], i32 1)
; CHECK-NEXT: [[M:%[a-z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 [[T]])
; CHECK-NEXT: ret i32 [[M]]
; CHECK-NOT: @__cq_q_helper
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

