; spec_reject_no_ir.ll — Phase 6.1 WI-1.2: a DECLARATION-ONLY tainted-arg callee
; is NEVER a specialization candidate (the DD-2 no-IR contract: a visible body is
; required to clone). It is absent from `plan6.Pending` AND `plan6.Diagnosed`, so
; the `:419` carve-out fires the EXISTING `kMsgUnknownCallee` — keeping the
; declaration-only siblings (`_opaque_call`/`_deep_arg`) green.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @helper(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
