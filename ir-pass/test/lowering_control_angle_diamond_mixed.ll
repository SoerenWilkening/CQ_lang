; lowering_control_angle_diamond_mixed.ll — Family B2, MIXED gate+angle diamond,
; POSITIVE (test_C_libtooling-byx, cwk fix (b)). The REALISTIC shape: the arm has
; a GATE side-effect (`cq_phi` on %v) — which is WHY `-O1` cannot fold the diamond
; to a `select` — AND the merge carries a classical-angle `φ` (%ang) feeding a
; rotation on %u. So the merge has BOTH a tainted gate-handle `φ` (%vm, dissolved
; by RAUW) and a classical-angle `φ` (%ang, lowered by reduceAngleDiamondPhi).
;
; LOCKS the mixed-φ plumbing (cwk fix (b) C3): the gate-handle φ dissolution runs
; FIRST (so the consumer's arg-0 is the live handle), the arm gate is lowered
; CONTROLLED on the flag, the angle is lowered base + controlled-difference on the
; same flag, and the SINGLE compare/uncompute bracket spans all of it — the flag
; uncompute landing AFTER the angle's controlled-difference (the C1 anchor must
; survive the consuming rotation's erasure), before the measures. Verify-clean.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[HU:[a-zA-Z0-9_.]+]], i32 5)
; The arm gate fires controlled on the flag (on %v's handle, not %u's):
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F:[a-zA-Z0-9_.]+]], i32 %{{[a-zA-Z0-9_.]+}}, double 2.500000e-01)
; The angle base + controlled-difference on %u's handle:
; CHECK:     call void @cqrt_rz_i32(i32 %[[HU]], double %b)
; CHECK:     %[[D:[a-zA-Z0-9_.]+]] = fsub double %a, %b
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[HU]], double %[[D]])
; Single uncompute, AFTER the controlled-difference, BEFORE the measures:
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[HU]], i32 5)
; CHECK:     call i32 @cqrt_measure_i32
; CHECK-NOT: phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a, double %b) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  br i1 %c, label %arm, label %merge
arm:
  %vg = call i32 @cq_phi_si32(i32 %v, double 2.500000e-01)   ; gate side-effect
  br label %merge
merge:
  %vm = phi i32 [ %vg, %arm ], [ %v, %entry ]                ; gate-handle φ (tainted)
  %ang = phi double [ %a, %arm ], [ %b, %entry ]             ; angle φ (classical)
  %r = call i32 @cq_phi_si32(i32 %u, double %ang)
  %mv = call i32 @cq_measure_si32(i32 %vm)
  %mr = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %mv, %mr
  ret i32 %s
}
