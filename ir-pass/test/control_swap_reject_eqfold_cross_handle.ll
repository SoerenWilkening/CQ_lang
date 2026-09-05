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
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: control flow under quantum control
; NEW: cq controlled lowering: control flow under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp eq i32 %p, 7                            ; condition on %p, not the routed %q
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)  ; folds to 7
  br label %merge
merge:
  %qm = phi i32 [ 7, %arm ], [ %q, %entry ]       ; straight-through = %q (cross-handle)
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
