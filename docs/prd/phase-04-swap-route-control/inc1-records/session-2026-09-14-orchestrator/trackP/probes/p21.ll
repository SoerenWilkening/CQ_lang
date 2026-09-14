; p21 — TWO prep merge phis as leaves of ONE `and i1` tree at the 4.4 DATA
; SELECT: each phi is admitted by its OWN region, so `PrepRegionIdxs` must carry
; BOTH indices and `lowerControlRegions` must add BOTH precedence edges.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %b0 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br i1 %b0, label %a1, label %m1
a1:
  %t1 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br label %m1
m1:
  %p1 = phi i1 [ %t1, %a1 ], [ false, %entry ]
  br i1 %b0, label %a2, label %m2
a2:
  %t2 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 9.000000e-01)
  br label %m2
m2:
  %p2 = phi i1 [ %t2, %a2 ], [ false, %m1 ]
  %and = and i1 %p1, %p2
  %sel = select i1 %and, i32 2, i32 5
  %x1 = call zeroext i1 @cq_measure_i1(i1 zeroext %p1)
  %z1 = zext i1 %x1 to i32
  %x2 = call zeroext i1 @cq_measure_i1(i1 zeroext %p2)
  %z2 = zext i1 %x2 to i32
  %s0 = add nsw i32 %z1, %z2
  %m = call i32 @cq_measure_si32(i32 %sel)
  %s = add nsw i32 %s0, %m
  ret i32 %s
}
