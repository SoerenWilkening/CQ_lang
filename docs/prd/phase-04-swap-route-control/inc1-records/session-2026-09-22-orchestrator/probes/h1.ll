; F-2 HAZARD SHAPE: a value-arm diamond whose ARM holds a TAINTED-CONDITION fp
; select (an AngleSelectRegion candidate) feeding a cq_theta in the same arm.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %ac = icmp slt i32 %q, 9              ; TAINTED condition
  %ang = select i1 %ac, double 1.0, double 2.0   ; the ANGLE select
  %r = call i32 @cq_theta_si32(i32 %p, double %ang)
  %v1 = add i32 %r, 3
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
