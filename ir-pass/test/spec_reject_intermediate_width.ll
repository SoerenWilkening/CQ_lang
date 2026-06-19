; spec_reject_intermediate_width.ll — Phase 6.4 (WI-1.13 over-accept hardening):
; a tainted body with an INTERMEDIATE value at a width with no reversible
; template (here i128) was OVER-ACCEPTED into the clone before 6.4 — the clone
; `__cq_q_helper_1` was created and the i128 op only backstopped LATE at
; lowerOps' `diagnoseNoTemplate` (naming the CLONE, not the source op). 6.4 moves
; the decline to DETECTION, at the offending body op's `!dbg`, with the precise
; "unsupported width" kind. Recorded in `plan6.Diagnosed`, so the carve-out does
; NOT also emit the generic `kMsgUnknownCallee`; CHECK-NOT confirms no clone.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %x) {
entry:
  %w = zext i32 %x to i128
  %m = mul i128 %w, 3
  %t = trunc i128 %m to i32
  ret i32 %t
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %z = call i32 @cq_measure_si32(i32 %r)
  ret i32 %z
}

; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported width)
; CHECK-NOT: cq taint escape
; CHECK-NOT: @__cq_q_helper
