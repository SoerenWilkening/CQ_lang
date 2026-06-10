; lowering_reject_taint_escape_indirect_call.ll — DECLINE: tainted value passed
; through an INDIRECT call (function pointer) — unknown callee BY DEFINITION
; (test_C_libtooling-bxv).
;
; `getCalledFunction()` is null for a call through a pointer, so no callee
; predicate can ever prove the shape; without the guard the call survives and
; reads the runtime handle tag after RAUW, exactly like the direct opaque form.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, ptr %fp) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 %fp(i32 %q)                       ; indirect — callee unknowable
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
