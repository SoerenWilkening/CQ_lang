; e08 — the COMPARE TWIN of e04: same round-2 window, same two siblings, but the
; select's condition is an `icmp` on an i32 register. If this accepts on the
; PRE binary the hole is PRE-EXISTING (the 4.4 compare path on `main`).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
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
  %b = call i32 @cq_theta_si32(i32 %y, double 5.000000e-01)
  %b3 = call i32 @cq_theta_si32(i32 %y, double 9.000000e-01)
  %cc = icmp eq i32 %b, 1
  %a = select i1 %cc, i32 2, i32 5
  %mm = call i32 @cq_measure_si32(i32 %b3)
  %m = call i32 @cq_measure_si32(i32 %a)
  %t = add i32 %m, %mm
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }
