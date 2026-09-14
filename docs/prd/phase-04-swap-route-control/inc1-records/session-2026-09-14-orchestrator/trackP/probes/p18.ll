; p18 (T1-TREE) — p05's module AFTER M-beta: the phase consumer's condition is
; `select i1 %tneg, i1 %cmp, i1 false` with %tneg a RAIL (a `cq_theta_i1` call)
; at an INTERIOR position of the tree. The ORACLE accepts it (an interior RAIL
; leaf is the shipped 3qlq.4 path) and prints the target stream for p05.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare void @cq_phi(double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 7.000000e-01)
  %b0 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  %t = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  %tneg = call zeroext i1 @cq_theta_i1(i1 zeroext %t, double -5.000000e-01)
  %c = icmp sgt i32 %q, 3
  %and = select i1 %tneg, i1 %c, i1 false
  br i1 %and, label %ph, label %done
ph:
  call void @cq_phi(double 3.000000e-01)
  br label %done
done:
  %m0 = call zeroext i1 @cq_measure_i1(i1 zeroext %b0)
  %z0 = zext i1 %m0 to i32
  %m1 = call zeroext i1 @cq_measure_i1(i1 zeroext %tneg)
  %z1 = zext i1 %m1 to i32
  %s1 = add nuw nsw i32 %z1, %z0
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %s2 = add nsw i32 %s1, %m2
  ret i32 %s2
}
