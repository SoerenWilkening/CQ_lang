; x2 — a chained theta on ANOTHER register sits in the gap between the prep's
; merge phi and the kickback's branch. The CFG-bounded scan must see it (that is
; what the positional prong is for: a gate the wire walk never sees).
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

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
  %z2 = call i1 @cq_theta_i1(i1 %z, double 7.000000e-01)
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
