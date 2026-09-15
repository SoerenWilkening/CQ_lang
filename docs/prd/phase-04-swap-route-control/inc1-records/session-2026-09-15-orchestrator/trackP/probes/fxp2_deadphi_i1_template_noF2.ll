; fxp2 — the isolating CONTROL for the fxp1c crash: identical except `%u` is
; `xor i1 %MB, true` (NOT provably equal to the seed on either edge), so F2 has no
; witness on ANY binary and the prep is accepted everywhere. If this crashes on the
; ORACLE too, the defect is pre-existing and F' only adds customers.
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
  %u = xor i1 %MB, true
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
