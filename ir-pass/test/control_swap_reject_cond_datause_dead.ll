; control_swap_reject_cond_datause_dead.ll — DECLINE probe (ziov WI-1): the
; tainted condition compare is used as control AND data, but the data lineage is
; DEAD WITHIN THE FUNCTION — neither measured nor escaped.
;
; `%c = icmp sgt q, 5` feeds the `br` (control) AND `%d = zext %c`, but `%d`'s
; lineage (`%dead = add %d, 7`) is never measured, returned, nor passed to
; cq_invert — a quantum bit computed, then orphaned. Sharing the flag here would
; leave it ALLOCATED AND ENTANGLED with q with no downstream owner (a dirty leak
; that dephases under later interference, Rule 6/8); the correct in-function
; uncompute (a deferred `icmp_inv` strip at the data's post-dominator, guarded by
; the WireWalk q-basis discipline) is WI-2. Until then this declines LOUDLY
; (over-declining is always safe; Prime Directive). The escaped/measured twins
; (control_swap_cond_datause_{escape,measured}.ll) ACCEPT.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition data use neither escaped nor measured under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %d = zext i1 %c to i32            ; DATA use of the condition compare
  %dead = add i32 %d, 7            ; DEAD: never measured, returned, or inverted
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
