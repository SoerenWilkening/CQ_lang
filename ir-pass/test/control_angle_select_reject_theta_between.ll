; control_angle_select_reject_theta_between.ll — DECLINE (S6): an in-place `Ry`
; sits BETWEEN the compare and the consumer (bd drbq Inc 2b).
;
; S6's positional scan runs from `Cond->getNextNode()` to the CONSUMER — a longer
; window than gate 2c's prong (c), which stops at the select, because this
; emitter mints its flag at the consumer. A `cq_theta` with a tainted arg-0 in
; that window declines.
;
; DELIBERATELY WIRE-BLIND: `%zz` here rotates a THIRD register, disjoint from both
; the condition and the base, so this is an OVER-decline. It is the same
; conservatism `condWireDisposition` and gate 2c prong (c) already carry, and for
; the same reason — a positional scan that tried to be wire-aware would have to
; answer the rail-identity question S8 only answers two clauses later, and the
; two would then be two spellings of one relation (this project's history says
; those eventually disagree: bd `uow0`, bd `1fim`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %z = call i32 @cq_theta_si32(i32 %u2, double 2.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %zz = call i32 @cq_theta_si32(i32 %z, double 4.000000e-01)
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %mz = call i32 @cq_measure_si32(i32 %zz)
  %s = add i32 %mt, %mz
  ret i32 %s
}
