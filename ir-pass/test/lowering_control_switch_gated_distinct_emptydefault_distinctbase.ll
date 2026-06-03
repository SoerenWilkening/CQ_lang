; lowering_control_switch_gated_distinct_emptydefault_distinctbase.ll — Phase 4.x
; (test_C_libtooling-5bl §9), POSITIVE (MUX-EXCH, gate G4 direct-default widening, the
; genuinely default-ONLY base sub-case). A distinct-base mux (case0→qx, case1→qy) with an
; empty `default:` routed straight to the merge whose `entry`(switch-block) φ edge carries a
; THIRD distinct handle qz — a base selected ONLY when no case matches (it is never a case
; base). qz's control is the `¬OtherCaseOr` complement = ¬(f_qx ∨ f_qy) — materialized as the
; OR-fold `f_conj`, the SAME ¬OR the distinct-block default uses (so the cswap MOVE fires on
; no-match and the Ry† uncompute fires when a case matched). This exercises the direct-default
; `region.Pred` edge for a base distinct from every case base. opt -verify clean.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     %[[QX:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x0)
; CHECK:     %[[QY:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y0)
; CHECK:     %[[QZ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %z0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[QZ]], double 7.500000e-01)
; The default base's ¬OtherCaseOr control is the OR-fold of the two case flags (De Morgan):
; CHECK:     %[[FCONJ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; The MUX-EXCH body: both case bases MOVE on their own eq-flags; the default-only base qz
; MOVEs on the complemented OR-fold (cqrt_x bracket), and uncomputes on the positive OR-fold:
; CHECK:     %[[REGOUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[REGOUT]], i32 %[[QX]])
; CHECK:     call void @cqrt_cswap(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[REGOUT]], i32 %[[QY]])
; CHECK:     call void @cqrt_x(i32 %[[FCONJ]])
; CHECK:     call void @cqrt_cswap(i32 %[[FCONJ]], i32 %[[REGOUT]], i32 %[[QZ]])
; CHECK:     call void @cqrt_x(i32 %[[FCONJ]])
; CHECK:     call void @cqrt_ry_i32_controlled_inv(i32 %[[FCONJ]], i32 %[[QZ]], double 7.500000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[REGOUT]], double 1.500000e+00)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[REGOUT]])
; CHECK-NOT: switch
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %s0, i32 %x0, i32 %y0, i32 %z0) {
entry:
  %s = call i32 @cq_theta_si32(i32 %s0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %x0, double 5.000000e-01)
  %qy = call i32 @cq_theta_si32(i32 %y0, double 5.000000e-01)
  %qz = call i32 @cq_theta_si32(i32 %z0, double 7.500000e-01)   ; default-only base
  switch i32 %s, label %merge [ i32 0, label %c0
                                i32 1, label %c1 ]
c0:
  %r0 = call i32 @cq_phi_si32(i32 %qx, double 1.000000e-01)
  br label %merge
c1:
  %r1 = call i32 @cq_phi_si32(i32 %qy, double 2.000000e-01)
  br label %merge
merge:
  %r = phi i32 [ %qz, %entry ], [ %r0, %c0 ], [ %r1, %c1 ]   ; entry edge = qz (default-only)
  %out = call i32 @cq_phi_si32(i32 %r, double 1.500000e+00)
  %m = call i32 @cq_measure_si32(i32 %out)
  ret i32 %m
}
