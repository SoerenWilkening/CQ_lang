; control_swap_defer_value_qq.ll — Q+Q chain link DEFERS (recognized value
; shape, not yet routable; 4.2 WI-3; PRD Part II §8.3 row "QQ").
;
; `if (q > 5) { p = p + r; }` — the arm's single link consumes a SECOND tainted
; operand (%r), so it is not the sole-tainted-operand HL/LH chain the 4.2
; routed replay handles (the rail substitution retargets exactly one threaded
; operand; a second live handle in the link is unanalyzed routing). The chain
; still bottoms at the routed slot %p and %p is disjoint from the condition's
; provenance, so this is NOT a §3c clobber and NOT a mux — it keeps the
; deferred-subset string until a QQ-capable increment.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}value-arm swap-route under quantum control
; CHECK-NOT: arm rewrites a condition operand
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, i32 %w0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %r = call i32 @cq_theta_si32(i32 %w0, double 1.250000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %p1 = add i32 %p, %r       ; BOTH operands tainted — a Q+Q link, deferred
  br label %merge
merge:
  %pm = phi i32 [ %p1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
