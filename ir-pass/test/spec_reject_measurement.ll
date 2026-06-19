; spec_reject_measurement.ll — Phase 6.4 WI-4.1: a callee body that itself
; MEASURES (contains a `@cq_measure_*` call) collapses the caller's superposition
; and is declined unconditionally (PRD §2.11). Detected by EXACT call-site
; membership against the propagate-collected measure set (never name-prefix —
; C7). Recorded in `plan6.Diagnosed`, so the carve-out does NOT also emit the
; generic `kMsgUnknownCallee`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %x) {
entry:
  %y = add i32 %x, 1
  %m = call i32 @cq_measure_si32(i32 %y)
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
; CHECK-NOT: cq taint escape
