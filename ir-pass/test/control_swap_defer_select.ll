; control_swap_defer_select.ll — tainted integer-data `select` ACCEPTS at 4.4 but
; declines TRANSITIONALLY until the emitter lands (WI-1; IMPLEMENTATION-4.4 §5c).
;
; `(q>5) ? q : x` is the §5a quantum+classical-operand shape: a tainted-condition
; integer-data mux that passes all six §0 gates (lowerable icmp, NOT an angle,
; i32 ABI width, no coherent operand, disjoint operands). WI-1 ships detection
; only, so an ACCEPT declines transitionally via the `control flow` string —
; pushing a SelectRegion now would reach `emitRegion`'s null-block deref (no
; SelectRegion dispatch until WI-3). Regression guard: the detector must keep
; diagnosing tainted selects loudly, never silently pass one through.
;
; WI-3 graduates this to an ACCEPT (→ control_swap_select_qc.ll): the controlled-
; XOR copy merge replaces the decline CHECK below. (Rule 12 deliberate baseline:
; the old "select" string is replaced, not retained.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
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
