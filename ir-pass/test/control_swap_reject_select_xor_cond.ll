; control_swap_reject_select_xor_cond.ll — DECLINE (3c6m.12 L4 probe): an
; `xor i1` condition node is OUTSIDE the accepted tree grammar (and/or over
; CmpInst leaves only — compound-cond-select-PRD §0). `xor …, true` (boolean
; NOT) is likewise out: InstCombine canonicalizes the pure-compare NOT away
; (predicate inversion / operand swap), so neither survives on the -O1/O2
; canonical path; a hand-built one must decline loudly, not lower a guessed
; parity network.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %c2  = icmp slt i32 %q, 100
  %c   = xor i1 %c1, %c2
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
