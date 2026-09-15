; o3 — a MIXED condition tree: one phi leaf CROSS-BLOCK behind an EMPTY gap block
; (so the bd hcrg alias edge cannot fire for its prep — the adjacency is broken),
; and one phi leaf IN `Pred` (whose prep DOES get the alias edge). This is the
; case where P's "ONLY THE CROSS-BLOCK LEAVES ARE RECORDED" choice has to compose
; with the alias edge inside one region: ONE edge from the plan, ONE from the
; pre-flight, both pointing kickback-before-prep.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm1, label %m1
arm1:
  %t1 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %m1
m1:
  %p1 = phi i1 [ %t1, %arm1 ], [ false, %entry ]
  br label %gapA
gapA:
  br label %pre2
pre2:
  br i1 %b0, label %arm2, label %m2
arm2:
  %t2 = call i1 @cq_theta_i1(i1 false, double 9.000000e-01)
  br label %m2
m2:
  %p2 = phi i1 [ %t2, %arm2 ], [ false, %pre2 ]
  %and = select i1 %p1, i1 %p2, i1 false
  br i1 %and, label %ph, label %done
ph:
  call void @cq_phi(double 3.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %p1)
  ret i1 %m
}
