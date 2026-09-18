declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}
define i32 @example(i32 %u0, i32 %v0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm1, label %merge1
arm1:
  %r = call i32 @f(i32 %a)
  br label %merge1
merge1:
  %y = phi i32 [ %r, %arm1 ], [ 5, %entry ]
  %c2 = icmp sgt i32 %q, 7
  br i1 %c2, label %arm2, label %merge2
arm2:
  ; (no cone)
  %v1 = add i32 %p, %y
  br label %merge2
merge2:
  %pm = phi i32 [ %v1, %arm2 ], [ %p, %merge1 ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
