; lowering_uncompute_nonvoid_addc_fake_leak.ll — ACCEPT-with-LEAK pin (bd
; test_C_libtooling-6uqc Inc 2a Rule-13 round; the bd 1fim return-type axis, on
; the M-C rows). A hand-written NON-void `cqrt_addc_i32` at the frozen arity is
; NOT the frozen in-place gate: it MINTS a rail the same-args adjoint recipe
; cannot name. `isInPlaceGateOn` / `preservesBasisUnderRecord` /
; `isInverseEmittable` all test VOID-ness (the property), not arity (the proxy),
; so this module's DAG is `NotClosed` and the spine emits NOTHING for it — the
; Rule-6 sanctioned safe leak, identical to pre-M-C HEAD.
;
; MEASURED against the arity-only draft of the Inc-2a rows (the Rule-13 round's
; MUST-FIX 1): the DAG closed, `cq_template_mul_i32_hl_unc` + `cqrt_free` fired,
; a same-args "adjoint" `%0 = call i32 @cqrt_addc_i32(%h, -5)` was emitted for a
; rail-MINTING call, and the source rail was un-rotated and freed — `opt` rc=0,
; verify-clean, `free_pairing_check.py` 0 violations, wrong. The CHECK-NOTs below
; pin every element of that wrong stream.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cqrt_addc_i32(i32, i32)

define i32 @main(i32 %x, double %g) {
  %q   = call i32 @cq_theta_si32(i32 %x, double %g)
  %bad = call i32 @cqrt_addc_i32(i32 %q, i32 5)   ; NON-void fake, frozen arity
  %t   = mul i32 %q, 7                            ; dead template terminal off %q
  ret i32 %bad
}

; The forward stream survives verbatim, and the spine emits NOTHING:
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double %g)
; CHECK:      %[[BAD:.*]] = call i32 @cqrt_addc_i32(i32 %[[H]], i32 5)
; CHECK:      call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 7)
; CHECK-NOT:  call void @cq_template_mul_i32_hl_unc
; CHECK-NOT:  call i32 @cqrt_addc_i32(i32 %[[H]], i32 -5)
; CHECK-NOT:  call void @cqrt_ry_i32(i32 %[[H]], double
; CHECK-NOT:  call void @cqrt_free
