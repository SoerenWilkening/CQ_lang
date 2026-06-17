; control_swap_reject_eqfold_cross_handle.ll — D3 decline (4.5 WI-5).
;
; The equality compare tests a DIFFERENT tainted handle than the one the merge
; routes: the condition is `icmp eq %p, 7` while the merge's straight-through
; (routed) handle is `%q`, and the arm folds `cq_phi(i32 7, θ)`. This is a genuine
; cross-handle multiplexer, not a phase arm over the routed handle — the
; `icmp_inv` flag-strip (minted from `%p`) could not return the flag to |0> while
; the rail carries a phase of `%q`. `tryEqFoldArm` D3 requires the icmp's
; non-constant operand to BE the routed handle; `%p != %q`, so D3 returns false
; and the region falls through to the generic decline. The `:753` `Base==Routed`
; gate is NOT weakened — a real cross-handle mux still declines loudly (Prime
; Directive: over-decline is safe).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp eq i32 %p, 7                            ; condition on %p, not the routed %q
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 7, double %a)     ; folds to 7
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]       ; straight-through = %q (cross-handle)
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
