; control_phase_kickback_reject_cmp_inplace_xor_bridge.ll — DECLINE, and a
; DOCUMENTED OVER-DECLINE of the COMPARE path (bd 3qlq.4, Rule-13 round-2 finding
; F-1b2-4): the compare spelling of `control_phase_kickback_rail_inplace_xor_bridge.ll`.
;
;     int q = u; cq_theta(&q,.5); int x = q ^ 7; int c = x; cq_theta(&c,.9);
;     if (q == 1) cq_phi(.7); return cq_measure(c);
;
; `condWireDisposition`'s positional scan (P5) refuses any tainted-operand theta
; between the compare and the branch "even on another wire", and `c = x; cq_theta(&c,
; .9)` sits there — although the `xor` lowers OUT of place (M-C's G6, as the
; rail twin pins), so the program is safe. Pinned as the asymmetry the rail path
; does NOT pay; pre-existing on `main`, unchanged by the increment.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %e = icmp eq i32 %q, 1
  %x = xor i32 %q, 7
  %c = call i32 @cq_theta_si32(i32 %x, double 9.000000e-01)
  br i1 %e, label %arm, label %merge
arm:
  call void @cq_phi(double 7.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %c)
  ret i32 %m
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
