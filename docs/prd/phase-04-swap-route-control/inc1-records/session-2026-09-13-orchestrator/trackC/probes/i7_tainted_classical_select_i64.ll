declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)
define i64 @example(i64 %u, i1 %c) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u, double 5.000000e-01)
  %s = select i1 %c, i64 %q, i64 %q
  %r = call i64 @cq_measure_sll(i64 %s)
  ret i64 %r
}
