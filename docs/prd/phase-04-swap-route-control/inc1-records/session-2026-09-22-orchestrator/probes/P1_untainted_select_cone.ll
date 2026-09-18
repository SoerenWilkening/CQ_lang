@k = global i32 0
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)
define i32 @example(i32 %u0, i32 %v0, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %cc = icmp slt i32 %n, 3
  %sel = select i1 %cc, i32 11, i32 22
  %v1 = add i32 %p, %sel
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
