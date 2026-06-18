; lowering_uncompute_compare_fcmp.ll — Phase 6 WI-0 ACCEPT (§6.0; the compare
; `_unc` grid, floating-point sibling of lowering_uncompute_compare_icmp.ll). A
; DEAD, source-derived, tainted DATA-position floating compare (`fcmp` — ordinary
; C `int w = (q < 5.0)`) reaching the whole-DAG uncompute spine.
;
; Same lift and same physics as the `icmp` sibling: the compare lowers to a
; `cq_template_fcmp_olt_f64_hl` flag-handle producer; PRE-WI-0 it had NO `_unc`
; grid and declined as un-invertible (the WI-7 over-decline that PINNED this
; fixture to `kMsgUninvertible`). WI-0 adds `unc_qq`/`unc_hl` for compares, so the
; flag rail reverses in place via `cq_template_fcmp_olt_f64_hl_unc(out, src, lit)`
; — recompute-and-XOR from the still-live root, a self-inverse permutation, never
; a phase (no dephasing), then a proven-|0> free. The f64 RAIL handle is still an
; i32 (Rule 15 — handles are always i32); the classical operand keeps its f64
; width in the forward slot. fp tainted DATA rides Phase 5 here — the Phase-6
; specializer fp-ABI reject is a separate path (the `copyFn`-null trap).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare double @cq_theta_f64(double, double)

define void @slice(double %x) {
entry:
  %q = call double @cq_theta_f64(double %x, double 2.500000e-01)
  %c = fcmp olt double %q, 5.000000e+00  ; tainted data-position fp compare -> flag (HL)
  %w = zext i1 %c to i32                  ; DEAD widened-flag terminal off the compare lineage
  ret void
}

; Forward chain: theta -> alloc + ry (f64 rail), the HL fp compare flag, then zext.
; CHECK:     call void @cqrt_ry_f64(i32 %[[H:[a-zA-Z0-9_.]+]], double 2.500000e-01)
; CHECK:     %[[CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_olt_f64_hl(i32 %[[H]], double 5.000000e+00)
; CHECK:     %[[CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[CMP]])
; Reversed adjoint (LIFO): zext_unc(out=%w, src=%c) BEFORE the compare adjoint
; fcmp_..._hl_unc(out=%c, src=%q, f64 5.0) reading the still-live root — DD-3 slots
; (out i32, src i32 handle, f64 classical), then the proven-|0> rail free, then
; un-rotate + free the root. Void `_unc`, no fresh mint.
; CHECK:     call void @cq_template_zext_i1_to_i32_unc(i32 %[[CAST]], i32 %[[CMP]])
; CHECK:     call void @cq_template_fcmp_olt_f64_hl_unc(i32 %[[CMP]], i32 %[[H]], double 5.000000e+00)
; CHECK:     call void @cqrt_free(i32 %[[CMP]])
; CHECK:     call void @cqrt_ry_f64(i32 %[[H]], double -2.500000e-01)
; CHECK:     call void @cqrt_free(i32 %[[H]])
;
; The adjoint is the VOID `_unc`, never the fresh-minting `_inv`; the theta is lowered.
; CHECK-NOT: cq_template_fcmp_olt_f64_hl_inv
; CHECK-NOT: cq_template_fcmp_olt_f64_inv
; CHECK-NOT: cq_theta_f64
