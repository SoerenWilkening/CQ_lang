; lowering_reject_freeze_escaped_return.ll — DECLINE (R-B blocker): a tainted
; INTEGER `freeze` whose RESULT is RETURNED must NOT launder its operand into the
; ACCEPTED i32-ret Escaped case (Phase-7.1 Increment B, the R-B hazard).
;
; A bare `isa<FreezeInst>` whitelist would fold `%f = freeze i32 %q; ret i32 %f`
; to `ret i32 %q` — silently admitting it as the already-accepted i32-handle
; Escaped case, with NO ownership/uncompute proof. That is a silent miscompile
; (the freeze re-laundering an Escaped value). The narrow R-B rule declines: the
; freeze RESULT reaches a `ret`, so `freezeResultWouldEscape` is true and the
; freeze falls through to the generic escape decline (`kMsgOther`). Over-decline
; is safe (Prime Directive); the local pure-identity case
; (`lowering_freeze_passthrough_i32.ll`) is the only accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %f = freeze i32 %q                              ; result is RETURNED -> escape
  ret i32 %f
}

; CHECK: error{{.*}}cq taint escape: tainted value reaches an unsupported instruction
; CHECK-NOT: ret i32 %q
; CHECK-NOT: cqrt_alloc
