; r1_mbeta_drift.ll — THE F-F1-5 CONSTRUCTION.
;   region C : 6.5 classical-call arm -> %out  (CLASSICAL at round 1)
;   region B : `icmp eq %out, 13` STATE PREP, seed 0  -> classified in ROUND 2, M_B = %MB
;   region A : `icmp eq %q, 7` IN-PLACE Ry whose BASE IS %MB -> classified ROUND 1,
;              M-beta RAUWs %MA to the arm theta %ta.
;   collider : %z, a select whose CONDITION reads %MA and whose two value operands
;              both fold to 0 == B's seed on B's TRUE edge.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal fastcc i32 @f(i32 %x) unnamed_addr #0 {
  %a = mul nsw i32 %x, 3
  %b = add nsw i32 %a, 1
  ret i32 %b
}

define i32 @example() {
entry:
  %kp = alloca i32, align 4
  store volatile i32 4, ptr %kp, align 4
  %k = load volatile i32, ptr %kp, align 4
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c1 = icmp eq i32 %q, 1
  br i1 %c1, label %arm1, label %m1
arm1:
  %r = call fastcc i32 @f(i32 %k) #1
  br label %m1
m1:
  %out = phi i32 [ %r, %arm1 ], [ 0, %entry ]
  %c2 = icmp eq i32 %out, 13
  br i1 %c2, label %armB, label %mB
armB:
  %tb = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %mB
mB:
  %MB = phi i32 [ %tb, %armB ], [ 0, %m1 ]
  %c3 = icmp eq i32 %q, 999999
  br i1 %c3, label %armA, label %mA
armA:
  %ta = call i32 @cq_theta_si32(i32 %MB, double 2.500000e-01)
  br label %mA
mA:
  %MA = phi i32 [ %ta, %armA ], [ %MB, %mB ]
  %d = add i32 %out, -13
  %e = sub i32 %out, 13
  %cs = icmp sgt i32 %MA, 2
  %z = select i1 %cs, i32 %d, i32 %e
  %x0 = call i32 @cq_measure_si32(i32 %q)
  %x1 = call i32 @cq_measure_si32(i32 %MA)
  %x2 = call i32 @cq_measure_si32(i32 %z)
  %s1 = add nsw i32 %x0, %x1
  %s2 = add nsw i32 %s1, %x2
  ret i32 %s2
}
attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind willreturn memory(none) }
