; m31 — the merge phi as a LEAF of a COMPOUND tree at the select (`b1 && q>3`).
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @main(i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 7.000000e-01)
  %b0 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br i1 %b0, label %merge, label %arm
arm:
  %t = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br label %merge
merge:
  %p = phi i1 [ %t, %arm ], [ false, %entry ]
  %c = icmp sgt i32 %q, 3
  %and = and i1 %p, %c
  %sel = select i1 %and, i32 2, i32 5
  %m1 = call zeroext i1 @cq_measure_i1(i1 zeroext %p)
  %z1 = zext i1 %m1 to i32
  %m2 = call i32 @cq_measure_si32(i32 %sel)
  %s = add nsw i32 %z1, %m2
  ret i32 %s
}
