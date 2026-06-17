; lowering_uncompute_uninvertible.ll — Phase 5 WI-5 DECLINE (PRD §2.12 / §2.3 /
; §2.10; IMPLEMENTATION §4 WI-5). A DEAD tainted data terminal whose recovered
; DAG contains a primitive Phase 5 has NO in-place adjoint for: a `cqrt_cnot`
; permutation gate on the prep handle, feeding `%t = bad + 7` — the dead
; `cq_template_add` terminal off `%bad`.
;
; `emit_inverse` is TOTAL only over the EMITTED data surface (uncontrolled
; rotations, self-adjoint `cqrt_x`/`cqrt_cswap` involutions, and uncontrolled
; `cq_template_*` whose void `_unc` form it mints). A permutation primitive like
; `cqrt_cnot` is NOT in that surface — Phase 5 never emits it for data and will
; not GUESS an adjoint (whether or not the gate is mathematically self-inverse).
;
; Pre-WI-5 the whole-DAG driver IGNORED `emitInverseCall`'s un-invertible `false`
; return: it silently skipped the gate AND still emitted the `cqrt_free` of its
; rail — a dirty free of an un-reversed register (a hidden projective collapse,
; Rule 6/8), verify-clean. WI-5 pre-scans every recovered gate with
; `isInverseEmittable` BEFORE emitting anything and declines LOUDLY
; (source-located, `opt` exits non-zero) with NO half-reversed chain and NO
; dangling free (DD-1: the driver owns the message; §2.10: an un-invertible link
; emits no free).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cqrt_cnot(i32)

define void @slice(i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %bad = call i32 @cqrt_cnot(i32 %q)             ; un-invertible primitive (no _unc form)
  %t   = add i32 %bad, 7                          ; DEAD cq_template terminal off %bad
  ret void
}

; CHECK: error{{.*}}cq uncompute: dead chain contains an un-invertible primitive
