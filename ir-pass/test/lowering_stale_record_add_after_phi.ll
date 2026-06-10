; lowering_stale_record_add_after_phi.ll — ACCEPT: the diagonal twin of
; lowering_reject_stale_record_add.ll (test_C_libtooling-uzb).
;
; The intervening in-place gate on `%q`'s wire is a `cq_phi` (Rz), which is
; DIAGONAL — `Rz = diag(1, e^{i.theta})` preserves the computational basis —
; so the template emitted at the add's position (after the rz) still reads
; exactly the basis record the SSA value `%d = add i32 %q, 1` denotes.
; Non-diagonality is the load-bearing trigger of the stale-record family
; (bd memory rz-diag-flag-strip-invariant); the wire walk
; (WireWalk::findNonDiagonalWireGate) walks THROUGH diagonal gates and must
; not decline this shape.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double %g)
; CHECK-NEXT: call void @cqrt_rz_i32(i32 %[[H]], double %t)
; CHECK-NEXT: %[[D:.*]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[D]])

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  %q2 = call i32 @cq_phi_si32(i32 %q, double %t)   ; diagonal Rz — basis-preserving
  %d = add i32 %q, 1                               ; post-Rz schedule: still exact
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
