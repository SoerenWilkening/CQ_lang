; spec_reject_intrinsic_dyn_rotate.ll — Phase 7.1-E follow-up
; (test_C_libtooling-mvjc) DECLINE PROBE (Rule 12, mirrors the accept). A
; CURATED-FAMILY intrinsic id (`@llvm.fshl.i32`, the rotate idiom) but in a
; NON-curated FORM — a DYNAMIC rotation amount (`%amt` is not a `ConstantInt`) —
; must STILL loud-decline inside a would-be clone, NEVER over-accept. The
; rotation-form guard in `isCuratedReversibleIntrinsic` (arg0==arg1 AND a
; CONSTANT amount) is what bounds the accept to the in-table reversible idioms;
; a dynamic-amount funnel shift has no frozen `cq_template_fshl_i32_hl` (the `_hl`
; literal slot needs a compile-time amount), so it fails the predicate and rides
; the existing declaration-only "nested call" decline. The arity/widths are
; otherwise perfectly liftable (all i32), so the ONLY reason for decline is the
; intrinsic — pinning that the whitelist did not widen to the dynamic form.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.fshl.i32(i32, i32, i32)

define i32 @rot_helper(i32 %a, i32 %amt) {
entry:
  %r = call i32 @llvm.fshl.i32(i32 %a, i32 %a, i32 %amt)
  ret i32 %r
}

define void @example(i32 %u0, i32 %amt) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %r = call i32 @rot_helper(i32 %q, i32 %amt)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (nested call)
; CHECK-NOT: @__cq_q_rot_helper
; CHECK-NOT: cq_template_fshl
