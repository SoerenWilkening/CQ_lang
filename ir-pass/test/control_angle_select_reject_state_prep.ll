; control_angle_select_reject_state_prep.ll — DECLINE (S3): the consumer's arg-0
; is CLASSICAL — controlled STATE PREP (bd drbq Inc 2b; PRD S5 / Increment 4).
;
;     int r = cq_theta(0, q == 5 ? .9 : .3);
;
; There is no live register to rotate in place: the gate would have to MINT one
; (`cqrt_alloc_i32(0)`) and then apply a controlled Ry to the fresh rail, whose
; "prepped vs |0>" disposition on the inactive branch nothing here proves. That
; is Increment 4's shape, with its own fence (the merge/seed identity), and it
; declines until then.
;
; Note the direction: this is a decline of a shape the epic INTENDS to support
; later, not of one it refuses on principle (Rule 17 — the target shape of THIS
; increment is the chained rotation, and that one lowers).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 0, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mt
  ret i32 %s
}
