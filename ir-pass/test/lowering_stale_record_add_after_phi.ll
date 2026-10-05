; lowering_stale_record_add_after_phi.ll — ACCEPT: written as the diagonal twin
; of lowering_reject_stale_record_add.ll (test_C_libtooling-uzb).
;
; ⚠ ITS DIAGONAL GATE IS GONE (noted by bd jttf, 2026-10-05). Pre-3qlq the
; intervening in-place gate on `%q`'s wire was the register form `cq_phi` (Rz),
; DIAGONAL, so the template emitted at the add's position (after the rz) still
; read exactly the basis record the SSA value `%d = add i32 %q, 1` denotes, and
; the wire walk (WireWalk::findNonDiagonalWireGate) had to walk THROUGH it (bd
; memory rz-diag-flag-strip-invariant). The 3qlq migration deleted that
; uncontrolled phase. A register-free phase creates no in-place gate on `%q`'s
; wire, so the walk-through-a-diagonal-gate subject has no spelling; what this
; file pins today is the theta -> dead-parent `add` -> measure stream below.
;
; RETIRED INTO THIS FILE (bd jttf, 2026-10-05):
; lowering_stale_record_alias_producer.ll, the producer-boundary twin whose add
; read the diagonal alias `%qd = cq_phi(%q, ·)` of a plain `cq_theta` source
; (the backward seed closure crossed diagonal hops only, never the producing
; theta). After 3qlq its module equalled this one up to the add's constant.
;
; M-C NOTE (bd test_C_libtooling-6uqc, Increment 2a): the `q + c` lowers IN PLACE
; to the frozen `cqrt_addc_<W>` (its parent handle has no data use after it), so
; no ancestor rail is minted and the measurement reads the rail itself. Nothing
; else this file pins has moved.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double %g)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[H]], i32 1)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[H]])
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  %d = add i32 %q, 1                               ; post-Rz schedule: still exact
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
