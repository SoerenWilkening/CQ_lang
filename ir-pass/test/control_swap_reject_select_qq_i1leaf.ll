; control_swap_reject_select_qq_i1leaf.ll — DECLINE probe (bd adia): the Q+Q
; select-condition widening must NOT bypass the i1-OPERAND leaf fence. A
; compare OVER two tainted i1 values (`icmp eq i1 %b0, %b1` — the boolean-NOT/
; XNOR evasion shape) is non-canonical and its mint would pass raw i1 flags
; into handle slots; it stays declined in the control dialect even though both
; operands are tainted at a "valid" logical width. Pins gate order: the i1
; fence survives the qqSelectLeafWidth accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %u1, i32 %x) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q1 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %b0 = icmp sgt i32 %q0, 5
  %b1 = icmp sgt i32 %q1, 5
  %c  = icmp eq i1 %b0, %b1          ; Q+Q — but OVER i1 operands: fence holds
  %sel = select i1 %c, i32 %q0, i32 %x
  %m  = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
