; lowering_control_switch_gated_distinct_3way.ll — Phase 4.x (test_C_libtooling-npu.5/.6),
; POSITIVE (MUX-EXCH, 3 distinct bases). case0→qx, case1→qy, case2→qz, default(block)→qx.
; The default-selected base qx is ALSO a case base (case0), so its selecting flag is
; f_qx = f0 ∨ ¬OrAll = ¬(f1 ∨ f2) — the COMPLEMENT of the OR of the OTHER bases'
; case-flags (OtherCaseOr = f1 ∨ f2). lowerGatedSwitch builds OtherCaseOr once and
; controls qx's `cqrt_cswap` on its complement (cqrt_x bracket); the non-default bases
; qy/qz move on their own eq-flags. Each non-selected source's Ry prep is uncomputed:
; qy on ¬f1, qz on ¬f2, qx on OtherCaseOr (≡ ¬f_qx). opt -verify clean; switch + φ gone.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     %[[QX:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x0)
; CHECK:     %[[QY:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y0)
; CHECK:     %[[QZ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %z0)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HS:[a-zA-Z0-9_.]+]], i32 1)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HS]], i32 2)
; OtherCaseOr = OR(f1, f2); the default base qx fires on its complement:
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[FO:[a-zA-Z0-9_.]+]])
; CHECK:     %[[REGOUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[REGOUT]], i32 %[[QY]])
; CHECK:     call void @cqrt_cswap(i32 %[[F2]], i32 %[[REGOUT]], i32 %[[QZ]])
; CHECK:     call void @cqrt_x(i32 %[[FO]])
; CHECK:     call void @cqrt_cswap(i32 %[[FO]], i32 %[[REGOUT]], i32 %[[QX]])
; CHECK:     call void @cqrt_x(i32 %[[FO]])
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_ry_i32_controlled_inv(i32 %[[F1]], i32 %[[QY]], double 5.000000e-01)
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_x(i32 %[[F2]])
; CHECK:     call void @cqrt_ry_i32_controlled_inv(i32 %[[F2]], i32 %[[QZ]], double 5.000000e-01)
; CHECK:     call void @cqrt_x(i32 %[[F2]])
; CHECK:     call void @cqrt_ry_i32_controlled_inv(i32 %[[FO]], i32 %[[QX]], double 5.000000e-01)
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
  %qz = call i32 @cq_theta_si32(i32 %z0, double 5.000000e-01)
  switch i32 %s, label %dflt [ i32 0, label %c0
                               i32 1, label %c1
                               i32 2, label %c2 ]
c0:
  %r0 = call i32 @cq_phi_si32(i32 %qx, double 1.000000e-01)
  br label %merge
c1:
  %r1 = call i32 @cq_phi_si32(i32 %qy, double 2.000000e-01)
  br label %merge
c2:
  %r2 = call i32 @cq_phi_si32(i32 %qz, double 3.000000e-01)
  br label %merge
dflt:
  %rd = call i32 @cq_phi_si32(i32 %qx, double 4.000000e-01)
  br label %merge
merge:
  %r = phi i32 [ %r0, %c0 ], [ %r1, %c1 ], [ %r2, %c2 ], [ %rd, %dflt ]
  %out = call i32 @cq_phi_si32(i32 %r, double 1.500000e+00)
  %m = call i32 @cq_measure_si32(i32 %out)
  ret i32 %m
}
