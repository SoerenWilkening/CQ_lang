; r15 — the 4.4 DATA SELECT twin of r14: a negated rail leaf in the select's
; condition tree.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %b = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  %nb = xor i1 %b, true
  %c = icmp sgt i32 %q, 3
  %a = and i1 %nb, %c
  %s = select i1 %a, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %s)
  %mm = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %mm to i32
  %t = add i32 %m, %z
  ret i32 %t
}
