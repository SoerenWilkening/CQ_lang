; w6 — w5 minus the SIBLING: the same round-2 window, the same conjunction read,
; nothing else on the register. ACCEPTS on BOTH binaries with BYTE-IDENTICAL
; lowered modules — the nest-side discriminator that the fix re-verifies the
; ladder rather than refusing the window. Shipped as
; `control_phase_nest_rail_round2_window_accept.ll`.
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @f(i32 %a) #0 { %s = add i32 %a, 100  ret i32 %s }
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 3
  br i1 %c0, label %arm, label %merge
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
  br i1 %b, label %mid, label %join
mid:
  %ci = icmp sgt i32 %q, 7
  br i1 %ci, label %inner, label %join
inner:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %mm = call i1 @cq_measure_i1(i1 %b)
  %zz = zext i1 %mm to i32
  %t = add i32 %zz, %keep
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }
