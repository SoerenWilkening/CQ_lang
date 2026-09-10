declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare i32 @ext_f(i32)
define i32 @main() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  br i1 %b, label %arm, label %merge
arm:
  %c = call i32 @ext_f(i32 7)
  br label %merge
merge:
  %p = phi i32 [ %q, %entry ], [ %c, %arm ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
