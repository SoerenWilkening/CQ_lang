; control_inplace_ry_reject_diagonal_alias.ll — DECLINE: the rotated register is
; a DIAGONAL ALIAS of the condition register (`a = cq_phi(q, ·)`; bd
; test_C_libtooling-drbq).
;
;     int q = cq_theta(0,.5); int a = cq_phi(q, .2);
;     if (q > 5) a = cq_theta(a, .9);
;
; `%a` and `%q` are DIFFERENT SSA VALUES and the SAME PHYSICAL WIRE: rotation
; lowering RAUWs a `cq_phi` and its operand to the one `cqrt_alloc` handle. So
; SSA disjointness is not wire disjointness — the exact distinction
; `diagonalAliasHit` was written for on the value path, and the reason the
; in-place rotation arm's R4 fence is a RAIL closure and not an identity test.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %at = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  br label %merge
merge:
  %am = phi i32 [ %at, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %am)
  ret i32 %m
}
