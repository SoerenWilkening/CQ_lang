; lowering_reject_intrinsic_funnel_fshl_mixed_taint.ll — Phase 7.1 Increment E,
; bd 20xt.1 over-accept fence. The general funnel qql producer requires BOTH data
; operands to be quantum handles. Here %q is tainted but %classical is a plain
; runtime i32 function argument (non-ConstantInt, so the structural predicate
; ADMITS it — the predicate is taint-invariant by design), yet only one operand
; carries taint. There is no template for a tainted+classical funnel mix (the qql
; shape is handle+handle+literal-amount; a classical DATA operand would be a
; different, ungenerated shape), so the rewriter declines LOUDLY via
; diagnoseNoTemplate rather than mint a phantom symbol — the SAME accept-in-
; predicate / decline-in-rewriter pattern as the fma all-literal-product guard.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}no template for opcode 'fshl.i32 general funnel (non-quantum operand)' in tainted context
; CHECK-NOT: cq_template_fshl

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.fshl.i32(i32, i32, i32)

define i32 @example(i32 %u, i32 %classical) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call i32 @llvm.fshl.i32(i32 %q, i32 %classical, i32 16)   ; one classical-runtime operand
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
