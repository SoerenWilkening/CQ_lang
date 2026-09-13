declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)
define i64 @example(i64 %u, i1 %c) {
entry:
  %q = call i64 @cq_theta_sll(i64 %u, double 5.000000e-01)
  br i1 %c, label %a, label %b
a:
  br label %m
b:
  br label %m
m:
  %p = phi i64 [ %q, %a ], [ %q, %b ]
  %r = call i64 @cq_measure_sll(i64 %p)
  ret i64 %r
}
