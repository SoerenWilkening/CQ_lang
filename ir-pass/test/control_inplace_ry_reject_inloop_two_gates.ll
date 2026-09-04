; control_inplace_ry_reject_inloop_two_gates.ll — DECLINE (PRD §13.2 row R1): TWO
; chained `cq_theta`s in one in-loop arm.
;
; R1's shape half (`inPlaceRotationArmTheta`) admits ONE tainted-arg-0 `cq_theta`
; that IS the whole arm; a second gate leaves the arm block impure and the class
; does not match, so the region falls through to the closing `control flow`. Inc 3
; changes nothing about the arm shape — it moves only the LOOP question and R6's
; position predicates — and this fixture is what says so.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r1 = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  %r2 = call i32 @cq_theta_si32(i32 %r1, double 3.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %r2, %arm ], [ %r, %loop ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
