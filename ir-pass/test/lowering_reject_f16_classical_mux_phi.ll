; lowering_reject_f16_classical_mux_phi.ll — Phase 7.1 Increment D: a
; classical-condition merge phi over two DISTINCT tainted f16 registers is a
; real data mux and declines (kMsgClassicalPhi). f16 data cannot be muxed: there
; is no reversible copy for an fp carrier (no cqrt_copy_f16 — copyFn null-guards
; on isIntegerTy), so the only accept is the one-register renaming lift, which
; this is not (the two incomings resolve to different wire bases). Complements
; control_swap_reject_select_f16.ll (the tainted-condition angle fence) with the
; classical-condition data-mux path. The merge result is MEASURED so the decline
; is the mux guard, not the non-i32-return gate.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition phi
; CHECK-NOT: cqrt_copy

declare half @cq_theta_f16(half, double)
declare half @cq_measure_f16(half)

define half @example(i1 %c, half %x, half %y) {
entry:
  %a = call half @cq_theta_f16(half %x, double 5.000000e-01)
  %b = call half @cq_theta_f16(half %y, double 2.500000e-01)
  br i1 %c, label %t, label %f
t:
  br label %m
f:
  br label %m
m:
  %p = phi half [ %a, %t ], [ %b, %f ]
  %r = call half @cq_measure_f16(half %p)
  ret half %r
}
