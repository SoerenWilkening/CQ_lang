; rail phi at an INTERIOR position of an and-tree condition (new E6 surface from 5a)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %prep, label %join
prep:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %join
join:
  %rp = phi i1 [ %b, %prep ], [ false, %entry ]
  %c2 = icmp slt i32 %q, 100
  %cond = and i1 %rp, %c2
  br i1 %cond, label %arm, label %merge
arm:
  br label %merge
merge:
  %a4 = phi i32 [ 2, %arm ], [ 5, %join ]
  %b5 = phi i32 [ 3, %arm ], [ 6, %join ]
  %m1 = call i32 @cq_measure_si32(i32 %a4)
  %m2 = call i32 @cq_measure_si32(i32 %b5)
  %mb = call i1 @cq_measure_i1(i1 %rp)
  %z = zext i1 %mb to i32
  %s = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
