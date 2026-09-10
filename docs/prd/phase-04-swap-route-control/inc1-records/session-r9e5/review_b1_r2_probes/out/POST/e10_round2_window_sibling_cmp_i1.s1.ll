; e10 — the compare twin at i1 width (the closest possible compare spelling of
; e04: same rail type, same trunc, an `icmp eq i1` instead of the bare rail).
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
  %x = trunc i32 %y to i1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %cc = icmp eq i1 %b, true
  %a = select i1 %cc, i32 2, i32 5
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %zz = zext i1 %mm to i32
  %m = call i32 @cq_measure_si32(i32 %a)
  %t = add i32 %m, %zz
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }
