; lowering_predmux_speccall_flatten.ll — ACCEPT (bd adia, 3c6m.55 Lever C):
; PredMux claims a NESTED tainted value region whose inner arm holds a
; TAINTED-ARG call to a VISIBLE, acyclic, all-speculatable PURE body — the
; pending-specialization callee (`isSpeculatablePureCallee`, the coshl→expl
; shape). Under quantum control every basis state executes every arm, so the
; pure call is speculated exactly like every other arm op: the flatten hoists
; it unconditional, the Phase-6 clone Bennett-wraps it, and the 4.4 copy
; merge selects its result under the compound edge predicate.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @purefn(i32 %a) {
  %t = mul i32 %a, 3
  %r = add i32 %t, 7
  ret i32 %r
}
define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %outer, label %merge
outer:
  %c2 = icmp sgt i32 %q, 10
  br i1 %c2, label %inner, label %outmerge
inner:
  %v = call i32 @purefn(i32 %q)
  br label %outmerge
outmerge:
  %p1 = phi i32 [ %v, %inner ], [ %q, %outer ]
  br label %merge
merge:
  %p2 = phi i32 [ %p1, %outmerge ], [ 0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}
; The speculated call is retargeted to the Bennett clone, unconditional in
; the flattened straight line; the merge lowers to the controlled-copy mux
; over the ∧-network edge predicate.
; CHECK: %[[V:.*]] = call i32 @__cq_q_purefn_1(i32 %[[H:.*]])
; CHECK: %[[G:.*]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %{{.*}}, i32 %[[V]], i32 %{{.*}})
; CHECK: define internal i32 @__cq_q_purefn_1(i32 %a)
; CHECK: call i32 @cq_template_mul_i32_hl(i32 %a, i32 3)
; CHECK: call void @cqrt_copy_i32(
; CHECK: call void @cq_template_mul_i32_hl_unc(
