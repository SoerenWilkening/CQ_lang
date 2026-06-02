; lowering_control_angle_chain_nonexcl.ll — Phase 4.1 WP16 (PRD §8.4, epic
; `-aht.1`), negative. The additive base+difference lowering of an angle-select
; CHAIN (lowering_control_angle_switch.ll) is only valid when the cases are
; MUTUALLY EXCLUSIVE — `a_default + Σ_k f_k·(a_k − a_default)` equals the nested
; select `f_n ? a_n : (…)` exactly when at most one flag fires. An `if-else-if`
; chain over a NON-exclusive predicate (`u>5` implies `u>2`) does NOT satisfy
; that, so it would miscompile under the additive form. The mutual-exclusivity
; guard (`icmp eq` on one scrutinee with distinct constants) declines it; it
; stays the loud B1 "rotation angle under quantum control" diagnostic rather
; than a silent miscompile. (A correct lowering needs AND-NOT case guards — a
; future generalization, not first-cut WP16.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
define i32 @example(i32 %u0, double %a, double %b, double %c) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %u, 5                          ; NOT eq — not exclusive with %c2
  %c2 = icmp sgt i32 %u, 2
  %inner = select i1 %c2, double %b, double %c
  %ang = select i1 %c1, double %a, double %inner
  %r = call i32 @cq_phi_si32(i32 %u, double %ang)
  ret i32 0
}
