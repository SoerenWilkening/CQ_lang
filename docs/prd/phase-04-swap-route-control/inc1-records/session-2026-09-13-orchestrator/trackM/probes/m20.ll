; T2 — the select's condition is a merge phi whose incomings are both on ONE wire
; (`%arm`'s arg-0 IS `%seed`) — boi6 probe p5's shape, reached through the SELECT.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @main(i32 %n) {
entry:
  %seed = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 9.000000e-01)
  %c = icmp sgt i32 %n, 3
  br i1 %c, label %arm, label %merge
arm:
  %armv = call zeroext i1 @cq_theta_i1(i1 zeroext %seed, double 2.000000e-01)
  br label %merge
merge:
  %p = phi i1 [ %armv, %arm ], [ %seed, %entry ]
  %sel = select i1 %p, i32 2, i32 5
  %m1 = call zeroext i1 @cq_measure_i1(i1 zeroext %p)
  %z1 = zext i1 %m1 to i32
  %m2 = call i32 @cq_measure_si32(i32 %sel)
  %s = add nsw i32 %z1, %m2
  ret i32 %s
}
