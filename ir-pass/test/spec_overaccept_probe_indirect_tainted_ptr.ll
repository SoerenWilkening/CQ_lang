; spec_overaccept_probe_indirect_tainted_ptr.ll — Phase 6.4 WI-4.3 over-accept
; probe (the WI-4.6 `readsTaintedValue` clearance shape). The call target is a
; FUNCTION POINTER derived from a quantum handle (`inttoptr` of the theta result),
; so `getCalledFunction()` is null — not a candidate. The decline depends on
; `readsTaintedValue` scanning the CALLED OPERAND (an indirect call's callee is an
; operand): the tainted `%fp` trips it and the carve-out fires `kMsgUnknownCallee`.
; Guards against a weakening of `readsTaintedValue` to args-only (which would let a
; quantum-pointer dispatch escape silently).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %fp = inttoptr i32 %q to ptr
  %r = call i32 %fp(i32 5)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: @__cq_q_
