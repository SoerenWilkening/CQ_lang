declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @main(i32 %n) {
entry:
  %r1 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  %r2 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 9.000000e-01)
  %c = icmp sgt i32 %n, 3
  br i1 %c, label %a, label %b
a:
  br label %m
b:
  br label %m
m:
  %p = phi i1 [ %r1, %a ], [ %r2, %b ]
  %sel = select i1 %p, i32 2, i32 5
  %mm = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %mm
}
