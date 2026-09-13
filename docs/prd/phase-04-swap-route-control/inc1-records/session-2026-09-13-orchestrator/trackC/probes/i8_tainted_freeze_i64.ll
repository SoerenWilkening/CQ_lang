declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)
define i64 @example(i64 %u) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u, double 5.000000e-01)
  %f = freeze i64 %q
  %r = call i64 @cq_measure_sll(i64 %f)
  ret i64 %r
}
