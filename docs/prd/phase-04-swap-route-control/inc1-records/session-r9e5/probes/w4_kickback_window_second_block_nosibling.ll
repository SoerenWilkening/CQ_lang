; w4 — w3 with the SIBLING deleted: the same round-2 window, nothing else on the
; register. ACCEPTS on BOTH binaries and the lowered modules are BYTE-IDENTICAL
; (`diff` on the two `-S` outputs), which is the kickback-side discriminator that
; the fix is a RE-VERIFICATION and not a refusal of the window. Shipped as the
; fixture `control_phase_kickback_rail_round2_window_accept.ll`.
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @f(i32 %a) #0 { %s = add i32 %a, 100  ret i32 %s }
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 4)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %keep = call i32 @cq_measure_si32(i32 %y)
  br label %second
second:
  %x = trunc i32 %y to i1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  br i1 %b, label %ph, label %join
ph:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %mm = call i1 @cq_measure_i1(i1 %b)
  %zz = zext i1 %mm to i32
  %t = add i32 %zz, %keep
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }
