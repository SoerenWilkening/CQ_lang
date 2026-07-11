; control_swap_reject_select_stale_leaf_theta.ll — DECLINE (3c6m.12 L4 probe):
; the gate-2c stale-condition guard runs PER LEAF of a compound condition. A
; chained cq_theta between the leaf compares and the select re-rotates the
; condition wire; the flag network is minted AT THE SELECT, so BOTH leaf flags
; would encode the post-Ry(0.7) basis while the SSA `or` denotes the pre-Ry
; record — copies routed on the wrong predicate, verify-clean (the kjd1 fcmp-
; lens BLOCKER family, now with a compound condition). The compound walk must
; seed from EVERY leaf's provenance; missing one leaf re-opens the hole.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define void @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t   = add i32 %q, 1                                             ; derived data operand
  %c1  = icmp sgt i32 %q, 5                                        ; SOURCE record: pre-Ry(0.7)
  %c2  = icmp slt i32 %q, 100                                      ; SOURCE record: pre-Ry(0.7)
  %c   = or i1 %c1, %c2
  %q2  = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)      ; chained theta on q's wire
  %sel = select i1 %c, i32 %t, i32 %x
  %m1  = call i32 @cq_measure_si32(i32 %sel)
  %m2  = call i32 @cq_measure_si32(i32 %q2)
  ret void
}
