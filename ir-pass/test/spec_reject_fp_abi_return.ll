; spec_reject_fp_abi_return.ll — Phase 6.4 WI-4.2: an f64 RETURN declines via the
; null `copyFn` path, NOT via `abiWidthFromType` (the f64-angle trap, C10/DD-3).
; `abiWidthFromType(double)` is the NON-EMPTY "f64" (an f64 has a valid width yet
; is an angle, never data — keying data-mux/copy lowering on a non-empty width was
; the f64 silent miscompile family); the reject is keyed on `wd.copyFn("f64")`
; being null (no `cqrt_copy_f64` exists — `cqrt-copy-abi-invariant`). Recorded in
; `plan6.Diagnosed`, so the carve-out does NOT also emit `kMsgUnknownCallee`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define double @helper(i32 %x) {
entry:
  %f = sitofp i32 %x to double
  ret double %f
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call double @helper(i32 %q)
  %z = call i32 @cq_measure_si32(i32 %q)
  ret i32 %z
}

; CHECK: error{{.*}}cq specialization: floating-point quantum argument or return has no reversible copy
; CHECK-NOT: cq taint escape
