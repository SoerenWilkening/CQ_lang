; control_swap_defer_select.ll — tainted `select` DEFERS to 4.4 (distinct string).
;
; A tainted-condition `select i1` is a coherent data mux, out of 4.1 scope. It
; declines with the existing "select" string (→ "select under quantum control").
; Regression guard: the swap-route detector must keep diagnosing tainted selects
; loudly — never silently pass one through as classical control over quantum data.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}select under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c   = icmp sgt i32 %q, 5
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
