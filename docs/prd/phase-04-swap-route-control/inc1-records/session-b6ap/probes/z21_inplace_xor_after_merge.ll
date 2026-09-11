; H-5b: an in-place xor on the condition wire sitting IN THE MERGE, after the
; phis. The peel inserts its clone at getFirstNonPHI, i.e. BEFORE that xor, so
; the clone must read the PRE-mutation state exactly as the branch did.
; SCOPE H-5: a peeled select whose CLONE sits on a condition wire that an
; in-place `cqrt_xorc` is mutating (the `control_..._inplace_xor_bridge` family,
; flat). The peel widens the population of TAINTED COMPARES ON A CONDITION WIRE,
; and at least four predicates are computed over that closure.
define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %x = xor i32 %q, 9
  %c = icmp eq i32 %x, 1
  br i1 %c, label %merge, label %arm
arm:
  %t = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %merge
merge:
  %amux = phi i32 [ 5, %arm ], [ 2, %entry ]
  %b1 = phi i32 [ %t, %arm ], [ 0, %entry ]
  %x2 = xor i32 %x, 3
  %m0 = call i32 @cq_measure_si32(i32 %x2)
  %m1 = call i32 @cq_measure_si32(i32 %b1)
  %ma = call i32 @cq_measure_si32(i32 %amux)
  %s1 = add nsw i32 %m0, %m1
  %s2 = add nsw i32 %s1, %ma
  ret i32 %s2
}
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
