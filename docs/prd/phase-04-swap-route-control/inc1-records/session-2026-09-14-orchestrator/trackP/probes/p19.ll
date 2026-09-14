; p19 — THE ORDER FENCE. The phase consumer's `br` is NOT in the prep's merge
; block: an unconditional block sits between them, so the kickback's `Pred` is not
; the prep's `MergeBB` and the bd `hcrg` sequential-chain edge does NOT fire —
; i.e. nothing guarantees the kickback is emitted while the phi is still live.
; It MUST decline rather than race the prep's M-beta.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare void @cq_phi(double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
define i32 @main() {
entry:
  %b0 = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br label %merge
merge:
  %p = phi i1 [ %t, %arm ], [ false, %entry ]
  br label %gap
gap:
  br i1 %p, label %ph, label %done
ph:
  call void @cq_phi(double 3.000000e-01)
  br label %done
done:
  %m1 = call zeroext i1 @cq_measure_i1(i1 zeroext %p)
  %z1 = zext i1 %m1 to i32
  ret i32 %z1
}
