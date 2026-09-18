; ATTACK B — as A, but nothing is measured at all.
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c = icmp sgt i32 %q, 1
  %rail = call i1 @cq_theta_i1(i1 %c, double 5.000000e-01)
  br i1 %rail, label %arm, label %merge
arm:
  br label %merge
merge:
  %p1 = phi i1 [ false, %arm ], [ false, %entry ]
  %p2 = phi i1 [ false, %arm ], [ false, %entry ]
  %z1 = zext i1 %p1 to i32
  %z2 = zext i1 %p2 to i32
  %s  = add i32 %z1, %z2
  ret i32 %s
}
