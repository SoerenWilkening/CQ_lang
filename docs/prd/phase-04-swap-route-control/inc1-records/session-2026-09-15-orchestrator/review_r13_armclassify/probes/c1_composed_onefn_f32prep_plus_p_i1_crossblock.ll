; c1 — THE COMPOSED ACCEPT, in ONE function. Two independent state preps:
;   (A) the i32 prep of Track F's own acc1 — its only F2 witness reaches the seed
;       through a DEAD, NON-DOMINATED join phi %p. Needs F' (the slot test) or F2
;       fires. At i32 the dead phi does NOT hit the broken-module defect, because
;       lowerOps RAUWs the tainted i32 op to an i32 handle: types agree.
;   (B) an i1 prep whose merge phi %M2 conditions a phase kickback ACROSS an empty
;       gap block. Needs P' (the CFG-bounded scan) or the P4 cross-block bail fires.
; A decline is module-wide, so this module lowers ONLY on a binary carrying BOTH.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_theta_i1(i1, double)
declare i1  @cq_measure_i1(i1)
declare void @cq_phi(double)

define i32 @example(i32 %arg) {
entry:
  %g = icmp sgt i32 %arg, 100
  br i1 %g, label %pre, label %Y
pre:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %q, 7
  br i1 %c, label %armB, label %mB
armB:
  %tb = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %mB
mB:
  %MB = phi i32 [ %tb, %armB ], [ 0, %pre ]
  %dz = zext i32 %q to i64
  %dd = add i64 %dz, -7
  %mz = zext i32 %MB to i64
  %pm = mul i64 %dd, %mz
  %u = trunc i64 %pm to i32
  %m0 = call i32 @cq_measure_si32(i32 %MB)
  br label %J
Y:
  br label %J
J:
  %p = phi i32 [ %u, %mB ], [ 0, %Y ]
  %mp = phi i32 [ %m0, %mB ], [ 0, %Y ]
  %q2 = call i1 @cq_theta_i1(i1 false, double 4.000000e-01)
  br i1 %q2, label %arm2, label %m2
arm2:
  %t2 = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %m2
m2:
  %M2 = phi i1 [ %t2, %arm2 ], [ false, %J ]
  br label %gap
gap:
  br label %pred2
pred2:
  br i1 %M2, label %ph, label %post
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %post
post:
  %m2r = call i1 @cq_measure_i1(i1 %M2)
  %z = zext i1 %m2r to i32
  %s = add i32 %mp, %z
  ret i32 %s
}
