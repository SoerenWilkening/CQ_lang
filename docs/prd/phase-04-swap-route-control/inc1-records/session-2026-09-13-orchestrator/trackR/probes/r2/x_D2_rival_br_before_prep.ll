; D2 RIVAL of D1 — THE HOLE CANDIDATE.  The both-slots-folded rival (an honest in-place
; Ry on %x's rail) whose downstream read of %x is the br that runs BEFORE the region, so
; R6's post-region stale-record fence (the fence that declined C5) cannot see it.
; If this ACCEPTS, R-2 removes the ONLY decline of a lowerable rival on D1.
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare void @cq_phi(double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %x = icmp slt i32 %q, -2147483648
  br i1 %x, label %a2, label %m2
a2:
  call void @cq_phi(double 7.000000e-01)
  br label %m2
m2:
  %c = icmp sgt i32 %q, 100
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ %x, %m2 ]
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %z2 = zext i1 %mr to i32
  ret i32 %z2
}
