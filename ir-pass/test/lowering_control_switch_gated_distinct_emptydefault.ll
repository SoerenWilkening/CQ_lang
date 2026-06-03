; lowering_control_switch_gated_distinct_emptydefault.ll — Phase 4.x (test_C_libtooling-5bl §9),
; POSITIVE (MUX-EXCH, gate G4 direct-default widening). A distinct-base mux (case0→qx,
; case1→qy) whose default edge is routed STRAIGHT to the merge (an empty `default:`,
; SwitchDefaultDirect) — the φ has an `entry`(switch-block) incoming carrying the default-
; selected base. The original npu.5/.6 gate DECLINED `DefaultDirect` for a distinct-base mux
; (the default base had no `¬OrAll` control); 5bl widens G4 to lower it: the default base's
; control is the `¬OtherCaseOr` COMPLEMENT bracket the mux already emits (the partition
; identity — exactly one arm fires), and the default base rides the `region.Pred` φ edge
; (mirroring `reduceAngleSwitchPhi`'s unconditional-base asymmetry). Here the default edge
; carries qx (== case0's base), so qx fires on ¬f_qy and qy on f_qy — no default GATE Rz is
; emitted (there is no default block). A direct default with a genuinely default-ONLY third
; base is exercised by lowering_control_switch_gated_distinct_emptydefault_distinctbase.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     %[[QX:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x0)
; CHECK:     %[[QY:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y0)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; The two case-arm gate bodies lower to controlled Rz on their own eq-flags; there is NO
; default-gate Rz (an empty default applies no gate) — only the case0/case1 gates appear:
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[QX]], double 1.000000e-01)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[QY]], double 2.000000e-01)
; The MUX-EXCH body: fresh regOut, per-base controlled-SWAP MOVE (default base qx on the
; complemented case-1 flag via the cqrt_x bracket), then per-non-selected-source Ry†:
; CHECK:     %[[REGOUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[REGOUT]], i32 %[[QY]])
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[REGOUT]], i32 %[[QX]])
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_ry_i32_controlled_inv(i32 %[[F1]], i32 %[[QY]], double 5.000000e-01)
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_ry_i32_controlled_inv(i32 %[[F1]], i32 %[[QX]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[REGOUT]], double 1.500000e+00)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[REGOUT]])
; CHECK-NOT: switch
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %s0, i32 %x0, i32 %y0) {
entry:
  %s = call i32 @cq_theta_si32(i32 %s0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %x0, double 5.000000e-01)
  %qy = call i32 @cq_theta_si32(i32 %y0, double 5.000000e-01)
  switch i32 %s, label %merge [ i32 0, label %c0
                                i32 1, label %c1 ]
c0:
  %r0 = call i32 @cq_phi_si32(i32 %qx, double 1.000000e-01)
  br label %merge
c1:
  %r1 = call i32 @cq_phi_si32(i32 %qy, double 2.000000e-01)
  br label %merge
merge:
  %r = phi i32 [ %qx, %entry ], [ %r0, %c0 ], [ %r1, %c1 ]   ; entry edge = direct default
  %out = call i32 @cq_phi_si32(i32 %r, double 1.500000e+00)
  %m = call i32 @cq_measure_si32(i32 %out)
  ret i32 %m
}
