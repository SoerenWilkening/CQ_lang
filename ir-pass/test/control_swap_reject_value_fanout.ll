; control_swap_reject_value_fanout.ll — expression-DAG value arm declines as
; IMPURE (4.2 WI-3; PRD Part II §8.3 row "impure"; Rule 8 linear lineage;
; fixture pair partner: control_swap_reject_value_stray.ll).
;
; `if (q > 5) { p = (p + 3) * (p ^ 5); }` — the base %p FANS OUT into two
; sub-expressions whose product feeds the merge: the lineage is a DAG, not the
; linear chain whole-chain reversal needs (reverse-playing a DAG double-
; uncomputes the shared base — use-after-free + double-free, Rule 8). The
; chain walk threads one path (`mul -> add -> %p`); the off-path `xor` is then
; a non-chain op in the arm block and the pure-chain predicate (the
; armBlockIsPureSpine analog over the value chain) rejects the arm.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}impure value arm under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %a = add i32 %p, 3         ; base fans out: %p feeds both %a and %b
  %b = xor i32 %p, 5
  %d = mul i32 %a, %b        ; DAG node — not a linear chain
  br label %merge
merge:
  %pm = phi i32 [ %d, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
