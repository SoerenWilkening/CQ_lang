; control_swap_reject_select_qq_leaf.ll — DECLINE (3c6m.12 L4 probe): a Q+Q
; LEAF inside an accepted-grammar tree (`or(q0>5, q0>q1)`). The per-leaf gate
; 2b mirror: `lowerCompareToFlag` is HL-only on the select path (no Q+Q flag
; mint — the logical width is unrecoverable from two laundered handles), so a
; both-operands-tainted leaf declines in the CONTROL dialect at detection,
; before any mint (never the mid-emission `no template` mis-brand — the WI-3
; NIT, now per-leaf).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %x) {
entry:
  %q0  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q1  = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c1  = icmp sgt i32 %q0, 5
  %c2  = icmp sgt i32 %q0, %q1       ; Q+Q leaf — both operands tainted
  %c   = or i1 %c1, %c2
  %sel = select i1 %c, i32 %q0, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
