; D3 — D2's rival with the collider MEASURED before the prep region, to see whether the
; fence that declined D2 (`condition data use neither escaped nor measured`) can be
; satisfied while R6 still cannot see the br.  An ACCEPT here is a HOLE.
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare void @cq_phi(double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %x = icmp slt i32 %q, -2147483648
  br i1 %x, label %a2, label %m2
a2:
  call void @cq_phi(double 7.000000e-01)
  br label %m2
m2:
  %mx = call i1 @cq_measure_i1(i1 %x)
  %c = icmp sgt i32 %q, 100
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ %x, %m2 ]
  %mr = call i1 @cq_measure_i1(i1 %rm)
  %z1 = zext i1 %mx to i32
  %z2 = zext i1 %mr to i32
  %s  = add i32 %z1, %z2
  ret i32 %s
}
