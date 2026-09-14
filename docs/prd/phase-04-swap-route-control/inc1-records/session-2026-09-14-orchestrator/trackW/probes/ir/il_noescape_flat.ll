; il_noescape_flat.ll — the HAND-UNROLLED twin of il_noescape_rolled.ll at 2 trips.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %rl0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %sh0 = lshr i32 %q, 0
  %an0 = and i32 %sh0, 1
  %c0 = icmp eq i32 %an0, 1
  br i1 %c0, label %arm0, label %merge0
arm0:
  %rt0 = call i32 @cq_theta_si32(i32 %rl0, double 9.000000e-01)
  br label %merge0
merge0:
  %rm0 = phi i32 [ %rt0, %arm0 ], [ %rl0, %entry ]
  %mm0 = call i32 @cq_measure_si32(i32 %rm0)
  %rl1 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %sh1 = lshr i32 %q, 1
  %an1 = and i32 %sh1, 1
  %c1 = icmp eq i32 %an1, 1
  br i1 %c1, label %arm1, label %merge1
arm1:
  %rt1 = call i32 @cq_theta_si32(i32 %rl1, double 9.000000e-01)
  br label %merge1
merge1:
  %rm1 = phi i32 [ %rt1, %arm1 ], [ %rl1, %merge0 ]
  %mm1 = call i32 @cq_measure_si32(i32 %rm1)
  ret i32 %mm1
}
