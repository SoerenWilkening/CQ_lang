; spec_result_classical.ll — Phase 6.1 WI-1.9 (return-taint, false case, §2.7).
; The callee has a tainted param (arg 0) but its RETURN derives from a CLASSICAL
; param only (`return c + c`). The clone proves `ReturnTainted = false`, so
; `specialize` SCRUBS the conservatively-tainted call result (and the forward
; cone that loses all taint) back out of `taint.Tainted` — the caller's
; downstream `add %r, 5` stays a plain CLASSICAL add, never lowered. This is the
; post-drain re-seed correction: the original `propagate` over-tainted the call
; result (a call reading a tainted arg), and the post-lowering verdict fixes it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @double_classical(i32 %t, i32 %c) {
entry:
  %y = add i32 %c, %c
  ret i32 %y
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @double_classical(i32 %q, i32 7)
  %z = add i32 %r, 5
  ret i32 %z
}

; The call retargets (mask "01": arg 0 tainted, arg 1 classical pass-through).
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_double_classical_01(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; The caller's `add` stays a RAW classical add — `%r` was scrubbed back out of
; taint, so the op is NOT lowered to a template.
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = add i32 %[[R]], 5
; CHECK:     ret i32 %[[Z]]
;
; Nothing in this module lowered to a data template — the tainted arg never
; affects the (classical) return, so the clone body and the caller stay raw.
; CHECK-NOT: cq_template
