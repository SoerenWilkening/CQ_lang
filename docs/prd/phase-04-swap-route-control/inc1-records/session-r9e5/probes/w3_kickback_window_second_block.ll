; w3 — w1 with ONE `br label %second` inserted, so the rail theta and its branch
; live in their own block. THE WINDOW IS NOW REACHABLE FOR THE KICKBACK: on
; f8d29e8 this ACCEPTS at rc=0, verify-clean, STRICT stage 2b `1 verified,
; 0 violation(s)`, emitting
;     cqrt_ry_i1(%h_cast, 0.5); cqrt_ry_i1(%h_cast, 0.9);
;     cqrt_rz_i1(%h_cast, 0.7), !cq.branchphase
; i.e. the branch phase applied AFTER the sibling moved the register, while the
; branch condition names the pre-sibling label. After the fix it DECLINES
; `condition predates a non-diagonal gate`. Shipped as the fixture
; `control_phase_kickback_reject_rail_round2_sibling_theta.ll`.
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
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  br i1 %b, label %ph, label %join
ph:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %zz = zext i1 %mm to i32
  %t = add i32 %zz, %keep
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }
