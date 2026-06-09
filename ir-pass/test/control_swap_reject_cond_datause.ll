; control_swap_reject_cond_datause.ll — DECLINE probe: the tainted condition
; compare is used in BOTH a control AND a data position (swap-route 4.1 §8
; adversarial review, 2026-06-09).
;
; `%c = icmp sgt q, 5` feeds the diamond's `br` (control) AND a `zext` (data) — the
; CSE of a `q>5` reused as a boolean value. The swap-route emitter mints a control
; flag from %c but does NOT consume %c. Once the emitter erases the `br`, the
; data-position gate that kept the compare off OpcodeLowering's work list is gone,
; so OpcodeLowering mints a SECOND flag template for the same condition — two
; distinct flag handles for one logical condition, controlling the route and the
; data use by DIFFERENT physical flags: a verify-clean wrong unitary. A condition
; with any non-branch user is therefore declined (over-decline is safe; Prime
; Directive). Detection is pure SSA-value analysis before any mutation.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition used outside the branch under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %d = zext i1 %c to i32            ; DATA use of the condition compare
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %sum = add i32 %qm, %d
  %m  = call i32 @cq_measure_si32(i32 %sum)
  ret i32 %m
}
