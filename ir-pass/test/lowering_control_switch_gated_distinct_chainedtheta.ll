; lowering_control_switch_gated_distinct_chainedtheta.ll — Phase 4.x (test_C_libtooling-u5f),
; POSITIVE (MUX-EXCH, gate G2 WIDENED). A distinct-base mux φ (case0→qx, case1→qy,
; default→qx) whose base qy is a CHAINED theta-of-theta `cq_theta(cq_theta(y0,.3),.7)`
; — TWO uncontrolled `cqrt_ry` on ONE handle. The interim G2 decline (a single Ry†
; would leave residual Ry) is replaced by the u5f REVERSE-ORDER multi-op Bennett
; uncompute: the forward prep is [ry(qy,.3), ry(qy,.7)], so the disentangle of the
; non-selected qy is the reversed inverse chain
;   [ry_inv(qy,.7), ry_inv(qy,.3)]   (U† undoes U innermost-last),
; controlled on ¬f_qy (the self-inverse `cqrt_x` bracket). qx is the single-Ry
; default base (positive OtherCaseOr control). 0.7 prints as 0x3FE6666666666666.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; The chained-theta qy prep lowers to two uncontrolled Ry on one handle:
; CHECK:     %[[QY:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[QY]], double 3.000000e-01)
; CHECK:     call void @cqrt_ry_i32(i32 %[[QY]], double 0x3FE6666666666666)
; The MUX-EXCH body: fresh regOut, per-base controlled-SWAP MOVE:
; CHECK:     %[[REGOUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F1:[a-zA-Z0-9_.]+]], i32 %[[REGOUT]], i32 %[[QY]])
; The qy disentangle is the REVERSED inverse chain (.7 BEFORE .3), bracketed on ¬f_qy:
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_ry_i32_controlled_inv(i32 %[[F1]], i32 %[[QY]], double 0x3FE6666666666666)
; CHECK:     call void @cqrt_ry_i32_controlled_inv(i32 %[[F1]], i32 %[[QY]], double 3.000000e-01)
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK-NOT: switch
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %s0, i32 %x0, i32 %y0) {
entry:
  %s = call i32 @cq_theta_si32(i32 %s0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %x0, double 5.000000e-01)
  %qyi = call i32 @cq_theta_si32(i32 %y0, double 3.000000e-01)
  %qy = call i32 @cq_theta_si32(i32 %qyi, double 7.000000e-01)
  switch i32 %s, label %dflt [ i32 0, label %c0
                               i32 1, label %c1 ]
c0:
  %r0 = call i32 @cq_phi_si32(i32 %qx, double 1.000000e-01)
  br label %merge
c1:
  %r1 = call i32 @cq_phi_si32(i32 %qy, double 2.000000e-01)
  br label %merge
dflt:
  %rd = call i32 @cq_phi_si32(i32 %qx, double 4.000000e-01)
  br label %merge
merge:
  %r = phi i32 [ %r0, %c0 ], [ %r1, %c1 ], [ %rd, %dflt ]
  %out = call i32 @cq_phi_si32(i32 %r, double 1.500000e+00)
  %m = call i32 @cq_measure_si32(i32 %out)
  ret i32 %m
}
