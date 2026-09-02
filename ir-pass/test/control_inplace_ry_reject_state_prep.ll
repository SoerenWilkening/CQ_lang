; control_inplace_ry_reject_state_prep.ll — DECLINE: CONTROLLED STATE PREP — the
; arm's `cq_theta` has a CLASSICAL arg-0 (PRD shape S5; owner Q7 scheduled it as
; Inc 4; bd test_C_libtooling-drbq).
;
;     int q = cq_theta(0,.5); int r = 0;
;     if (q > 5) r = cq_theta(0, .9);
;
; A classical seed means the theta ALLOCATES a rail, and lowering it under control
; needs two things Inc 1 does not have: the `cqrt_alloc` must hoist with the gate
; (an alloc inside an erased arm block is a dropped mint), and the merge φ's
; PRED-edge incoming must be a `Constant` BIT-IDENTICAL to the theta's seed —
; otherwise the region is a data MUX between a prepared register and some other
; value, which is not a rotation arm at all. Anything less is a rail whose
; |0>-vs-prepped disposition nothing proved.
;
; The recognizer therefore requires a TAINTED arg-0 (a chained Ry on a live
; register) and this module keeps the pre-existing generic decline. `lowerRotations`
; carries the same fence as an assertion of last resort: a `ControlledRotations`
; entry on a classical-operand theta bails LOUDLY rather than emitting.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
