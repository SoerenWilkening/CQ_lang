; p10 — the phase consumer's condition is a 3-incoming phi: no region's Merge,
; and off `isCondRailPhiShape`'s 2-incoming shape. MUST DECLINE.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare void @cq_phi(double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
define i32 @main(i32 %n) {
entry:
  %t = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  %c1 = icmp sgt i32 %n, 3
  br i1 %c1, label %a1, label %a2
a1:
  br label %merge
a2:
  %c2 = icmp sgt i32 %n, 9
  br i1 %c2, label %a3, label %merge
a3:
  br label %merge
merge:
  %p = phi i1 [ %t, %a1 ], [ false, %a2 ], [ true, %a3 ]
  br i1 %p, label %ph, label %done
ph:
  call void @cq_phi(double 3.000000e-01)
  br label %done
done:
  %m1 = call zeroext i1 @cq_measure_i1(i1 zeroext %t)
  %z1 = zext i1 %m1 to i32
  ret i32 %z1
}
