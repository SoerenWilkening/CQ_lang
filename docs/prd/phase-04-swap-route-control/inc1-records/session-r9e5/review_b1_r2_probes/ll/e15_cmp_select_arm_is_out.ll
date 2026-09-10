; e15 — the COMPARE TWIN of e14: the select's condition is an icmp on an
; UNRELATED tainted register, so it too is tainted at round 1 while `%out` is not.
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
  %p = call i32 @cq_theta_si32(i32 1, double 2.500000e-01)
  %cc = icmp eq i32 %p, 1
  %z = select i1 %cc, i32 %y, i32 99
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }
