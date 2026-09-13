declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %seed = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 9.000000e-01)
  %c = icmp eq i32 %q, 1
  br i1 %c, label %arm, label %merge
arm:
  %v = xor i1 %seed, true
  br label %merge
merge:
  %p = phi i1 [ %v, %arm ], [ %seed, %entry ]
  %sel = select i1 %p, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %sel)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %r = add i32 %m, %mq
  ret i32 %r
}
