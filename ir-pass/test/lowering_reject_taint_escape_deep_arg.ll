; lowering_reject_taint_escape_deep_arg.ll — DECLINE: tainted value passed to an
; opaque callee at a DEEPER argument position (arg 1 of 2), call result UNUSED
; (void) — the call-chain variant of the taint-escape family
; (test_C_libtooling-bxv).
;
; The escape does not depend on the tainted value being arg 0, on the callee
; returning a value, or on the result being consumed: `call void @sink(7, %q)`
; leaks the runtime handle tag into @sink all the same (confirmed at HEAD
; 6ac1ae3: exit 0, `call void @sink(i32 7, i32 %h)` survives). The handle also
; flows on to a legitimate measure — the escape must be declined even though
; every OTHER use of the value is supported.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @sink(i32, i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  call void @sink(i32 7, i32 %q)                  ; tainted arg in position 1
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
