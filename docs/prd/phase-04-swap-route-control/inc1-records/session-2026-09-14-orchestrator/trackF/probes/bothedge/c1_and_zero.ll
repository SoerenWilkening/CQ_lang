; Track F CONTROL C1 — a BOTH-EDGE pin.  `%t = and %q, 0` is provably the seed 0
; on BOTH edges of the branch, so R-2' must LEAVE IT DECLINING.  The companion
; c1_and_zero.W.ll moves the branch constant (TEST W): F2 must PERSIST, which is
; what proves TEST W discriminates one-edge from both-edge rather than always
; saying "one edge".
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %t = and i32 %q, 0
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s  = add i32 %mr, %mt
  ret i32 %s
}
