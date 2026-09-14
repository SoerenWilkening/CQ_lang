; r11 — peel region's content arm is a STATE PREP: THE PEEL-MANUFACTURED DESCENDANCY ATTEMPT: DOES THE PHI-DESCENDANT EXCLUSION FIRE IN **ROUND 2** AT ALL?
;   region C : 6.5 classical-call arm -> %out (CLASSICAL at round 1, tainted at round 2)
;   region B : `icmp eq %out, 13` STATE PREP, seed 0 -> classified in ROUND 2
;   collider : %zm = mul %MB, %d  — a DIRECT user of B's own merge phi %MB, whose
;              range folds to {0} == the seed because %d is pinned to 0 on the TRUE edge.
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
  %cp = icmp eq i32 %MB, 3
  br i1 %cp, label %armP, label %mP
armP:
  %tp = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  br label %mP
mP:
  %P1 = phi i32 [ %tp, %armP ], [ 0, %mB ]
  %P2 = phi i32 [ 7, %armP ], [ 9, %mB ]
  %dz = zext i32 %out to i64
  %dd = add i64 %dz, -13
  %mz = zext i32 %P2 to i64
  %pm = mul i64 %dd, %mz
  %zm = trunc i64 %pm to i32
  %x0 = call i32 @cq_measure_si32(i32 %q)
  %x1 = call i32 @cq_measure_si32(i32 %P1)
  %x2 = call i32 @cq_measure_si32(i32 %zm)
  %s1 = add nsw i32 %x0, %x1
  %s2 = add nsw i32 %s1, %x2
  ret i32 %s2
}
attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind willreturn memory(none) }
