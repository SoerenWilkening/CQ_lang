; r34 — brief item 1, "two rail leaves in ONE node": `and i1 %b, %d` with BOTH
; children bare rails on two different round-2 wires, and a sibling on the
; SECOND one only. `emitCondNode`'s record loops over both `N.L` and `N.R`,
; so the toffoli must be recorded against BOTH rails.
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
  %x2 = icmp sgt i32 %y, 1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %d = call i1 @cq_theta_i1(i1 %x2, double 3.000000e-01)
  %d3 = call i1 @cq_theta_i1(i1 %x2, double 7.000000e-01)
  %a = and i1 %b, %d
  br i1 %a, label %then, label %join
then:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %mm = call i1 @cq_measure_i1(i1 %d3)
  %zz = zext i1 %mm to i32
  %t = add i32 %zz, %keep
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }
