; control_swap_reject_switch_value_stalebase.ll — DECLINE (the WI-3 Rule-13 clearance
; probe for `proveSwitchValue`'s POSITION-FREE routed-base wire-staleness guard). The
; switch value twin of control_swap_reject_value_stalebase_inarm.ll (the diamond
; fixture) — same isolation technique.
;
; A single content case `r = p + 3;` is followed IN-ARM by a chained `cq_theta` on
; `p` (dominated, no reach-back), so the position-aware straight-line guard
; (`declineStaleRecordOps`) ACCEPTS the add — and a SINGLE content case avoids a
; sibling arm that guard would conservatively flag. The region must still decline:
; the shared base `p`'s wire gains a non-diagonal (Ry) gate, so the merge's preload
; copy and the hoisted chain would read the POST-Ry wire while the chain names the
; PRE-Ry record, a verify-clean wrong unitary (stale-record family).
; condProvenance(q) stops at the theta source and G10 seeds only the scrutinee %q,
; so this is invisible to every other detection guard; `proveSwitchValue`'s
; position-free guard owns the decline (mirrors the diamond value twin), not the
; valuePureChain backstop. (Pre-3qlq the base was `%pd = cq_phi(%p, 1.0)`.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}routed base predates a non-diagonal gate under quantum control
; the straight-line/scrutinee guards must NOT own this shape, and nothing may emit
; CHECK-NOT: cq opcode lowering: operand predates a non-diagonal gate
; CHECK-NOT: condition predates a non-diagonal gate
; CHECK-NOT: cqrt_copy
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 7.500000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0 ]
a0:
  %v1 = add i32 %p, 3
  %p2 = call i32 @cq_theta_si32(i32 %p, double 2.500000e-01)  ; in-arm chained Ry, AFTER the op
  br label %merge
merge:
  %pm = phi i32 [ %p, %entry ], [ %v1, %a0 ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
