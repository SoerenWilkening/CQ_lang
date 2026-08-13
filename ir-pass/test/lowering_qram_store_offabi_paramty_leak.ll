; lowering_qram_store_offabi_paramty_leak.ll — SAFE LEAK (bd test_C_libtooling-1fim,
; the Rule-13 round). THE PARAMETER-TYPE AXIS — the third and last of the frozen store's
; shape axes, and the one a Rule-13 VERIFIER found still open after the first two were
; closed.
;
; The frozen prototype is uniform at all nine widths (runtime/cq_runtime.h:541-549):
;     void cqrt_qram_store_<W>(int32_t arr, int32_t idx, int32_t val)
; Every operand is an `i32` HANDLE regardless of the cell width — Rule 15, "a runtime
; handle is always i32". The declaration below is VOID and at the FROZEN ARITY 3, so a
; name+void+arity predicate ACCEPTS it, and only the operand type gives it away.
;
; MEASURED at HEAD (pre-1fim), `opt` rc=0 and verify-clean, the pass emitted:
;
;   call void @cqrt_qram_store_i32_unc(i32 %h, i32 3, double 4.000000e+00)
;   call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
;   call void @cqrt_free(i32 %h)
;
; and declared `void @cqrt_qram_store_i32_unc(i32, i32, double)`. THAT IS NOT CAUGHT AT
; LINK — C symbols carry no signature, so the name resolves to the REAL `(i32,i32,i32)`
; runtime body and the call runs with a reinterpreted operand. (A Rule-13 verifier
; established this by linking and RUNNING the analogous load case; the earlier
; "dangling symbol, loud at link" reasoning was wrong on the mechanism and is recorded
; as corrected in bd memory [abi-shape-predicate-drift-2026-08-11].) `%h` was then
; freed on the strength of that adjoint.
;
; POST-FIX the store is not an ABI store, hence not an in-place gate on `%h`, hence an
; unrecognized user that marks the DAG NotClosed — so NO reversal is emitted at all and
; the rail is LEFT ALLOCATED. That is Rule 6's sanctioned fallback (a leak is legal; a
; dirty free is not) and the existing designed behaviour for an unprovable DAG, so this
; is an ACCEPT-with-leak fixture rather than a decline: nothing here is a shape we set
; out to lower (Rule 17), it is off-ABI input that is UB before the pass runs.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
; VOID and FROZEN ARITY 3 — but `val` is `double`, not the frozen `i32` handle.
declare void @cqrt_qram_store_i32(i32, i32, double)

define void @paramty_store(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 5.000000e-01)
  call void @cqrt_qram_store_i32(i32 %q, i32 3, double 4.000000e+00)
  %t = add i32 %q, 1
  ret void
}

; The forward stream still lowers; the reversal does not run.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_qram_store_i32(i32 %[[H]], i32 3, double 4.000000e+00)
;
; No adjoint is synthesized for the off-ABI store, and NOTHING is freed on the strength
; of one. Both are the discrimination controls against HEAD, which emitted both.
; CHECK-NOT: cqrt_qram_store_i32_unc
; CHECK-NOT: cqrt_free
; CHECK-NOT: cqrt_measure
