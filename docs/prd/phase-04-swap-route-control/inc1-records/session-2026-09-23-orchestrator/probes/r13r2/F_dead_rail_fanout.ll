; The dead rail %r is the arg-0 SEED of a SECOND theta, so the rail handle has a
; forward consumer besides the (erased) branch.  %r itself is then live...
; instead: make %r dead but its SEED %s0 shared by two thetas -> fan-out.
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @probe() {
entry:
  %s0 = call i1 @cq_theta_i1(i1 false, double 1.000000e-01)
  %r  = call i1 @cq_theta_i1(i1 %s0, double 5.000000e-01)
  %t  = call i1 @cq_theta_i1(i1 %s0, double 9.000000e-01)
  br i1 %r, label %arm, label %merge
arm:
  br label %merge
merge:
  %p1 = phi i1 [ false, %arm ], [ false, %entry ]
  %z1 = zext i1 %p1 to i32
  %mt = call i1 @cq_measure_i1(i1 %t)
  %z2 = zext i1 %mt to i32
  %s  = add i32 %z1, %z2
  ret i32 %s
}
