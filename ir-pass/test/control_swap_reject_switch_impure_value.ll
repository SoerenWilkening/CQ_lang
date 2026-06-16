; control_swap_reject_switch_impure_value.ll — DECLINE (G6): a VALUE switch whose
; arm block holds a STRAY tainted op beside the value chain. `valuePureChain` scans
; the whole arm block: the stray %junk (a DAG sibling on the routed base %p, not on
; the chain) would be SILENTLY DROPPED on flatten (a vanishing user computation,
; Rule 5) and its taint work-list pointer would dangle (UAF) — so the chain is
; impure. Mirrors the flat value-arm `impure value arm` decline (ArmClassify.cpp).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}impure value arm under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %p0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %p0, double 7.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %v0 = add i32 %p, 1
  %junk = add i32 %p, 7
  br label %merge
a1:
  %v1 = add i32 %p, 2
  br label %merge
merge:
  %pm = phi i32 [ %p, %entry ], [ %v0, %a0 ], [ %v1, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
