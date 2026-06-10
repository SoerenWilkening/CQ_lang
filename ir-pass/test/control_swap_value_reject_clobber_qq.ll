; control_swap_value_reject_clobber_qq.ll — a Q+Q link that REWRITES the
; condition register is still the §3c PERMANENT reject, not the QQ defer
; (4.2 WI-3 adversarial probe; PRD Part II §8.3 disposition order: the
; base-identity + provenance checks run BEFORE the QQ-defer check).
;
; `if (q > 5) { q = q + p; }` — the link consumes a second tainted operand
; (%p), but the chain bottoms at the routed slot %q (the QQ walk threads the
; operand identical to the routed straight-through) and %q is in the
; condition's provenance: the arm overwrites the very register the flag was
; minted from. Labeling this with the deferred-subset string would promise a
; future QQ increment could accept it — it cannot (the §3c bind is
; information-theoretic, not a missing feature). Permanent reject.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}arm rewrites a condition operand under quantum control
; CHECK-NOT: value-arm swap-route
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = add i32 %q, %p       ; Q+Q link over the CONDITION register %q
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
