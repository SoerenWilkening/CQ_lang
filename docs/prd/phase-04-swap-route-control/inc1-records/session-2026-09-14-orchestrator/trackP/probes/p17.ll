; p17 (T1-PHASE) — p01's module AFTER emitInPlaceRotationRegion's M-beta: the
; kickback's condition is the hoisted theta CHAIN's last gate (a `cq_theta_i1`
; CALL), exactly what M-beta RAUWs the prep's merge phi to. The ORACLE accepts
; this and prints THE TARGET STREAM for p01 — the discriminator that the
; widening adds an ACCEPT, not a STREAM.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare void @cq_phi(double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %b0 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  %t = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  %tneg = call zeroext i1 @cq_theta_i1(i1 zeroext %t, double -5.000000e-01)
  br i1 %tneg, label %ph, label %done
ph:
  call void @cq_phi(double 3.000000e-01)
  br label %done
done:
  %amux = select i1 %b0, i32 2, i32 5
  %m0 = call zeroext i1 @cq_measure_i1(i1 zeroext %b0)
  %z0 = zext i1 %m0 to i32
  %m1 = call zeroext i1 @cq_measure_i1(i1 zeroext %tneg)
  %z1 = zext i1 %m1 to i32
  %s1 = add nuw nsw i32 %z1, %z0
  %m2 = call i32 @cq_measure_si32(i32 %amux)
  %s2 = add nsw i32 %s1, %m2
  ret i32 %s2
}
