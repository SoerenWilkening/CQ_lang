@m = global i32 7, align 4
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %Z = call i32 @cq_theta_si32(i32 5, double 2.500000e-01)
  %P = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 2
  br i1 %c, label %arm, label %merge
arm:
  %z = load i32, ptr @m, align 4
  %Z1 = sub i32 %Z, %z
  %P1 = add i32 %P, %z
  br label %merge
merge:
  %Zn = phi i32 [ %Z, %entry ], [ %Z1, %arm ]
  %Pn = phi i32 [ %P, %entry ], [ %P1, %arm ]
  %m1 = call i32 @cq_measure_si32(i32 %Zn)
  %m2 = call i32 @cq_measure_si32(i32 %Pn)
  %s = add i32 %m1, %m2
  ret i32 %s
}
