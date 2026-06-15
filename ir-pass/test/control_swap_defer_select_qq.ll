; control_swap_defer_select_qq.ll — tainted integer-data `select` with TWO
; quantum operands ACCEPTS at 4.4 but declines TRANSITIONALLY until the emitter
; lands (WI-1; the §5b shape). Sibling of control_swap_defer_select.ll (§5a, one
; quantum + one classical operand).
;
; `(q>5) ? q : q+1` — both operands are tainted handles, and `%q1 = q+1` is a
; FRESH out-of-place value (a distinct lineage from `%q`), so the operands are
; disjoint (gate 6 accepts) and `%q1` is NOT a downstream rotation of `%q` (gate
; 5 accepts — `add` is a basis permutation, not a coherence-creating gate). All
; six §0 gates pass → ACCEPT → transitional `control flow` (no SelectRegion
; dispatch until WI-3). Confirms `(q>5)?q:q+1` is the out-of-place accept the
; §3.4 aliasing guard distinguishes from the hoisted-in-place alias family.
;
; (At detection `%q1` is still the stock `add` — rotation/op lowering runs LATER;
; the §0 ladder reads pre-mutation SSA, Rule 9.) WI-3 graduates this to an ACCEPT
; (→ control_swap_select_qq.ll): the controlled-XOR copy merge replaces the
; decline CHECK below. (Rule 12 deliberate baseline.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q1  = add nsw i32 %q, 1                 ; fresh out-of-place tainted operand
  %c   = icmp sgt i32 %q, 5
  %sel = select i1 %c, i32 %q, i32 %q1
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
