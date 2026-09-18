@c = constant [4 x i32] [i32 11, i32 22, i32 33, i32 44], align 16
declare i32 @cq_theta_si32(i32, double)
define i32 @probe() {
entry:
  %q  = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %Z  = call i32 @cq_theta_si32(i32 5, double 2.500000e-01)
  %idx = zext i32 %q to i64
  %j  = and i64 %idx, 3
  %g   = getelementptr inbounds [4 x i32], ptr @c, i64 0, i64 %j
  %z   = load i32, ptr %g, align 4
  %Z1  = sub i32 %Z, %z
  ret i32 %Z1
}
