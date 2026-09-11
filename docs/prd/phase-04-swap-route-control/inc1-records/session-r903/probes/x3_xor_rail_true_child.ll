; HAND IR (r903 probe x3) — `and i1 (xor i1 %b, true), %c`: the NOT node as a
; BinaryOperator child of an in-grammar AND (what -O1 emits, modulo the select
; spelling of the AND).
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @main(i1 %u0, i1 %u1) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %c = call i1 @cq_theta_i1(i1 %u1, double 3.000000e-01)
  %nb = xor i1 %b, true
  %s = and i1 %nb, %c
  br i1 %s, label %arm, label %merge
arm:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %m = call i1 @cq_measure_i1(i1 %b)
  %n = call i1 @cq_measure_i1(i1 %c)
  %z = zext i1 %m to i32
  %y = zext i1 %n to i32
  %r = add i32 %z, %y
  ret i32 %r
}
