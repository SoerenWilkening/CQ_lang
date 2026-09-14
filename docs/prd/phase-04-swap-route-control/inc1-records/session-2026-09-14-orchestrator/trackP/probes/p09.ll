; p09 — the CHAINED arm theta at the PHASE consumer, with a TAINTED branch
; condition so the prep diamond IS claimed and rung 0 PASSES. The merge phi's two
; incomings are one wire (`%armv`'s arg-0 IS `%seed`), so rung (iii) must own it
; with `condition predates a non-diagonal gate` (bd drbq.7 / F-M3's analogue).
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare void @cq_phi(double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
define i32 @main(i32 %n) {
entry:
  %b0 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  %seed = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 9.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %armv = call zeroext i1 @cq_theta_i1(i1 zeroext %seed, double 2.000000e-01)
  br label %merge
merge:
  %p = phi i1 [ %armv, %arm ], [ %seed, %entry ]
  br i1 %p, label %ph, label %done
ph:
  call void @cq_phi(double 3.000000e-01)
  br label %done
done:
  %m1 = call zeroext i1 @cq_measure_i1(i1 zeroext %p)
  %z1 = zext i1 %m1 to i32
  ret i32 %z1
}
