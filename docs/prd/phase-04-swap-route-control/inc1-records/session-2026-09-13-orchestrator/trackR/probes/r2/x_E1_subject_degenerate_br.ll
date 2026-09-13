; E1 SUBJECT — the SYNTACTIC hazard in R-2's spelling: `br i1 %x, label %m2, label %m2`
; is a conditional br whose condition is the pinned collider, but both successors are the
; same block, so it is no region and no region fence ever adjudicates %x.  R-2 fires here.
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare void @cq_phi(double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %x = icmp slt i32 %q, -2147483648
  br i1 %x, label %m2, label %m2
m2:
  %c = icmp sgt i32 %q, 100
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 false, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ false, %m2 ]
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %z2 = zext i1 %mr to i32
  ret i32 %z2
}
