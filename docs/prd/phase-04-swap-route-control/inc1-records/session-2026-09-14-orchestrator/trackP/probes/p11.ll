; p11 — the phase consumer's condition is a 2-incoming i1 phi whose diamond is
; NOT in the plan at all (the br is untainted/classical, so no region is made).
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare void @cq_phi(double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
define i32 @main(i32 %n) {
entry:
  %c = icmp sgt i32 %n, 3
  br i1 %c, label %arm, label %merge
arm:
  %t = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br label %merge
merge:
  %p = phi i1 [ %t, %arm ], [ false, %entry ]
  br i1 %p, label %ph, label %done
ph:
  call void @cq_phi(double 3.000000e-01)
  br label %done
done:
  %m1 = call zeroext i1 @cq_measure_i1(i1 zeroext %p)
  %z1 = zext i1 %m1 to i32
  ret i32 %z1
}
