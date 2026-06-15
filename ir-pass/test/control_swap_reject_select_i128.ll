; control_swap_reject_select_i128.ll — DECLINE: an i128-result select (4.4 WI-1
; gate 4 width gate). i128 IS an integer type, but its ABI width is unsupported
; (`abiWidthFromType` returns "" for the non-{i1,i8,i16,i32,i64} widths), so the
; WI-3 emitter could mint no alloc/copy symbol for it. This is the trap the gate
; is NECESSARY-not-sufficient for: `!isIntegerTy()` is FALSE here, so the decline
; rides the `abiWidthFromType(T).empty()` arm — never key the decision on the
; type-class alone. Declines `control flow`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)

define i64 @example(i64 %u0) {
entry:
  %q   = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %c   = icmp sgt i64 %q, 5
  %qe  = zext i64 %q to i128                      ; tainted i128 (valid integer, bad width)
  %sel = select i1 %c, i128 %qe, i128 0           ; i128-result mux
  %st  = trunc i128 %sel to i64                   ; back to a measurable handle
  %m   = call i64 @cq_measure_sll(i64 %st)
  ret i64 %m
}
