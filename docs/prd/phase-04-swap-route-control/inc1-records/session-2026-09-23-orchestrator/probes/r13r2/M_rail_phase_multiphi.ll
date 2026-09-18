; A rail-conditioned MULTI-PHI diamond whose arm ALSO carries a branch phase.
; PredMux must refuse the claim (E4-dataflow on the cq_phi call) and leave the
; region to the phase-kickback owner.
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %b, label %arm, label %merge
arm:
  call void @cq_phi(double 3.140000e+00)
  br label %merge
merge:
  %p1 = phi i32 [ 2, %arm ], [ 5, %entry ]
  %p2 = phi i32 [ 2, %arm ], [ 6, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %p1)
  %m2 = call i32 @cq_measure_si32(i32 %p2)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %mq
  ret i32 %s2
}
