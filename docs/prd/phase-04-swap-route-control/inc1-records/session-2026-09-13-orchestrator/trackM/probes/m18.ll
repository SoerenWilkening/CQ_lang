; T1 — owner.main.O1.ll AFTER emitInPlaceRotationRegion (state-prep kind, M-beta)
; and AFTER MergePhiPeel: the select's condition is the hoisted theta CHAIN's last
; gate (a `cq_theta_i1` CALL), exactly what M-beta RAUWs the merge phi to.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
  %b0 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  %amux = select i1 %b0, i32 2, i32 5
  %t = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  %tneg = call zeroext i1 @cq_theta_i1(i1 zeroext %t, double -5.000000e-01)
  %d = add nsw i32 %amux, -3
  %sel = select i1 %tneg, i32 %d, i32 %amux
  %m0 = call zeroext i1 @cq_measure_i1(i1 zeroext %b0)
  %z0 = zext i1 %m0 to i32
  %m1 = call zeroext i1 @cq_measure_i1(i1 zeroext %tneg)
  %z1 = zext i1 %m1 to i32
  %s1 = add nuw nsw i32 %z1, %z0
  %m2 = call i32 @cq_measure_si32(i32 %sel)
  %s2 = add nsw i32 %s1, %m2
  ret i32 %s2
}
