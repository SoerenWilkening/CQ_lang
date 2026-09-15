; o1 — ONE prep merge phi read by TWO consumers with OPPOSITE emission-order
; obligations: a 4.4 DATA SELECT (bd boi6 F-M1: "prep BEFORE select") and a
; CROSS-BLOCK phase KICKBACK (Track P': "kickback BEFORE prep"). The select comes
; first in the CFG. Both edges now live on the same field, keyed on Kind.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %M = phi i1 [ %t, %arm ], [ false, %entry ]
  %s = select i1 %M, i32 2, i32 5
  br label %gap
gap:
  br label %pred2
pred2:
  br i1 %M, label %ph, label %post
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %post
post:
  %m = call i32 @cq_measure_si32(i32 %s)
  %mb = call i1 @cq_measure_i1(i1 %M)
  %z = zext i1 %mb to i32
  %r = add i32 %m, %z
  ret i32 %r
}
