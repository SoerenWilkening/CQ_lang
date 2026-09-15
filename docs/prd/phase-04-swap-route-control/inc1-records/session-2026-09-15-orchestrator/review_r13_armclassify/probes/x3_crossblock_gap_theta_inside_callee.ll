; x3 — bd test_C_libtooling-1yeu's structural gap, aimed at P's CFG-bounded scan.
; The chained theta that should close the gap sits inside a CALLEE reached from the
; gap block, not in the gap block itself. `chainedThetaBetweenDefAndBranch` matches
; `CallInst` callees whose NAME starts with "cq_theta_", so an intervening user
; function is not a name it matches. Does anything else refuse it?
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define internal i1 @helper(i1 %x) {
  %r = call i1 @cq_theta_i1(i1 %x, double 7.000000e-01)
  ret i1 %r
}

define i1 @example(i1 %u0, i1 %u1) {
entry:
  %z = call i1 @cq_theta_i1(i1 %u1, double 3.000000e-01)
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %M = phi i1 [ %t, %arm ], [ false, %entry ]
  br label %gap
gap:
  %z2 = call i1 @helper(i1 %z)
  br label %pred2
pred2:
  br i1 %M, label %ph, label %post
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %post
post:
  %mm = call i1 @cq_measure_i1(i1 %M)
  %m2 = call i1 @cq_measure_i1(i1 %z2)
  %r = xor i1 %mm, %m2
  ret i1 %r
}
