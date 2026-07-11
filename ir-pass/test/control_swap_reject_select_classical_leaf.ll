; control_swap_reject_select_classical_leaf.ll — DECLINE (3c6m.12 L4 probe): a
; compound condition mixing a TAINTED leaf with a CLASSICAL (untainted) leaf
; (`or(q>5, k>7)`). The or-result is tainted (one tainted operand), so gate 1
; passes — but a classical leaf has no quantum flag to mint, and promoting it
; would allocate a qubit for classical data (the §5.2 prohibition). A hybrid
; classical∧quantum conjunction is out of scope this increment
; (compound-cond-select-PRD §2): every leaf must be a TAINTED HL compare.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %k, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %c2  = icmp sgt i32 %k, 7          ; classical leaf — %k is untainted
  %c   = or i1 %c1, %c2
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
