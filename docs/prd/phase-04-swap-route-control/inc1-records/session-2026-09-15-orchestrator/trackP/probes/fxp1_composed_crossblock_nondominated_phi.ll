; fxp1 — the deliberate F' x P' COMPOSITION attempt (bd test_C_libtooling-hlhh).
; Track F' recovered `acc1_dead_nondominated_phi.ll` (a state prep whose only F2
; witness reaches the seed through a DEAD, NON-DOMINATED join phi). This is that
; shape at i1, with ONE extra block between the prep's merge and the phase
; kickback's branch — so the PREP needs F' and the LEAF needs P'.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i1 @example(i32 %arg) {
entry:
  %g = icmp sgt i32 %arg, 100
  br i1 %g, label %pre, label %Y
pre:
  %q = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %q, label %armB, label %mB
armB:
  %tb = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %mB
mB:
  %MB = phi i1 [ %tb, %armB ], [ false, %pre ]
  %u = and i1 %MB, %q
  br label %gapX
gapX:
  br i1 %MB, label %ph, label %post
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %post
post:
  %m0 = call i1 @cq_measure_i1(i1 %MB)
  br label %J
Y:
  br label %J
J:
  %p = phi i1 [ %u, %post ], [ false, %Y ]
  %mp = phi i1 [ %m0, %post ], [ false, %Y ]
  ret i1 %mp
}
