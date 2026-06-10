; control_swap_reject_value_mixed_spine.ll — mixed chain, the OPPOSITE stacking
; order: an in-arm Rz over a changed basis (4.2 WI-3; fixture pair partner of
; control_swap_reject_value_mixed.ll).
;
; `if (q > 5) { p = p + 3; rz(p, a); }` — the phase-spine walk consumes the
; in-arm cq_phi and bottoms at an IN-ARM value op (`cq_phi(add(p,3), a)`). Same
; physics as the partner fixture, mirrored: the Rz fires on a basis the arm
; itself changed, so the chain is neither a pure phase arm (the spine does not
; bottom at the routed handle) nor a pure value chain (a cq_phi link is in the
; lineage). One mixed-arm string covers both stacking orders — the structural
; guarantee that no lowered chain ever carries both a phase and a basis change.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}mixed phase/value arm under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %p1 = add i32 %p, 3                              ; in-arm value link...
  %pr = call i32 @cq_phi_si32(i32 %p1, double %a)  ; ...under an Rz: MIXED
  br label %merge
merge:
  %pm = phi i32 [ %pr, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
