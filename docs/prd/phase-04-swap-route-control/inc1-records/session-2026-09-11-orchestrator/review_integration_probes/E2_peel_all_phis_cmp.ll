; the same with an INT compare condition (the peel mints a CLONE)
define i32 @main() local_unnamed_addr {
entry:
  %q = tail call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %q, 1
  br i1 %c, label %arm, label %merge
arm:
  br label %merge
merge:
  %a = phi i32 [ 2, %arm ], [ 5, %entry ]
  %z = phi i32 [ 4, %arm ], [ 1, %entry ]
  %m1 = tail call i32 @cq_measure_si32(i32 %a)
  %m2 = tail call i32 @cq_measure_si32(i32 %z)
  %m3 = tail call i32 @cq_measure_si32(i32 %q)
  %s1 = add i32 %m1, %m2
  %s2 = add i32 %s1, %m3
  ret i32 %s2
}
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
