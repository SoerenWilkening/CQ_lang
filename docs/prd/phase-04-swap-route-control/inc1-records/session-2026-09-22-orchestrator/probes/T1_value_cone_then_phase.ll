@k = global i32 0
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm1, label %m1
arm1:
  %kk = load i32, ptr @k, align 4
  %kx = mul i32 %kk, 3
  %v1 = add i32 %p, %kx
  br label %m1
m1:
  %pm = phi i32 [ %v1, %arm1 ], [ %p, %entry ]
  %c2 = icmp eq i32 %q, 2
  br i1 %c2, label %arm2, label %m2
arm2:
  call void @cq_phi(double 3.140000e+00)
  br label %m2
m2:
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
