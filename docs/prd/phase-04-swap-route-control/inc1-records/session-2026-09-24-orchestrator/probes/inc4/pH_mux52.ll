; classical table value MUXED under the quantum condition against a classical constant
@c = constant [4 x i32] [i32 11, i32 22, i32 33, i32 44], align 16
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i64 %i) {
entry:
  %j = and i64 %i, 3
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %Z = call i32 @cq_theta_si32(i32 5, double 2.500000e-01)
  %c = icmp sgt i32 %q, 2
  br i1 %c, label %arm, label %merge
arm:
  %gz = getelementptr inbounds [4 x i32], ptr @c, i64 0, i64 %j
  %z = load i32, ptr %gz, align 4
  %Z1 = sub i32 %Z, 1
  br label %merge
merge:
  %v  = phi i32 [ 7, %entry ], [ %z, %arm ]
  %Zn = phi i32 [ %Z, %entry ], [ %Z1, %arm ]
  %t  = add i32 %Zn, %v
  %m1 = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m1
}
