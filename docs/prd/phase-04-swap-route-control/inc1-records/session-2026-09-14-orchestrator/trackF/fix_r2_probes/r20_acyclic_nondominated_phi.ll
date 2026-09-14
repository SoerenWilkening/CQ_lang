; r20 — DOES THE BACK-EDGE NARROWING OVER-NARROW IN AN **ACYCLIC** CFG?
; %p is a phi in block %J, which %mB does NOT dominate (a classical branch bypasses
; the region).  %p uses the M-descendant %u on its %mB edge, folds to {0} == the seed,
; and DOMINATES NOTHING relevant.  Pre-fix it is excluded; post-fix the dominance
; narrowing drops it from the set, so it becomes a collider again (a DECLINE, i.e.
; the safe direction — but a behaviour change outside the back-edge family).
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

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
  %x2 = call i32 @cq_measure_si32(i32 %p)
  %s = add nsw i32 %mp, %x2
  ret i32 %s
}
