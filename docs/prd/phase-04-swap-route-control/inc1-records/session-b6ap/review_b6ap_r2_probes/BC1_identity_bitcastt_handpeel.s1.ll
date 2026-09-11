declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  %a = call i32 @cq_theta_si32(i32 0, double 4.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %m
arm:
  %a2 = call i32 @cq_theta_si32(i32 %a, double 9.000000e-01)
  br label %m
m:
  %ap = phi i32 [ %a2, %arm ], [ %a, %entry ]
  %cq.peel.cond = icmp eq i32 %q, 5
  %mux = select i1 %cq.peel.cond, i32 7, i32 5
  %cq.peel.cond1 = icmp eq i32 %q, 5
  %nux = select i1 %cq.peel.cond1, i32 2, i32 1
  %bc = bitcast i32 %mux to i32
  %w = add nsw i32 %bc, 3
  %x0 = call i32 @cq_measure_si32(i32 %ap)
  %x1 = call i32 @cq_measure_si32(i32 %w)
  %x2 = call i32 @cq_measure_si32(i32 %nux)
  %s1 = add nsw i32 %x0, %x1
  %s2 = add nsw i32 %s1, %x2
  ret i32 %s2
}

define i32 @main() {
  %r = call i32 @example()
  ret i32 0
}
