; lowering_control_switch_gated_distinct_varangle.ll — Phase 4.x (test_C_libtooling-5bl §9),
; POSITIVE (MUX-EXCH, gate G5 dominating-variable widening). Base qx's prep angle is a
; COMPUTED value `%a = fadd double %u, %v` — NOT a ConstantFP. The original npu.5/.6 gate
; admitted only a ConstantFP prep angle (over-decline-safe deferral); 5bl widens G5 to also
; admit a non-constant angle whose def DOMINATES the merge uncompute anchor. `%a` is computed
; in `entry` (the switch block), which dominates `merge`, so the merge-boundary uncompute
; `cqrt_ry_i32_controlled_inv(¬f_qx, qx, %a)` references a live value — and Ry(%a) / Ry†(%a)
; cancel exactly. The rest is the standard distinct-base MUX-EXCH (case0→qx, case1→qy,
; default-BLOCK→qx with a ¬OrAll gate). An ARM-LOCAL (non-dominating) computed angle still
; DECLINES — see lowering_control_switch_gated_distinct_varangle_armlocal.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; The variable angle %a survives in entry and is the prep angle of qx:
; CHECK:     %[[A:[a-zA-Z0-9_.]+]] = fadd double %u, %v
; CHECK:     %[[QX:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[QX]], double %[[A]])
; CHECK:     %[[QY:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y0)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; The MUX-EXCH body: fresh regOut, per-base controlled-SWAP MOVE (default base qx on the
; complemented flag), then per-non-selected-source Ry† — qx's uncompute uses the SAME %a:
; CHECK:     %[[REGOUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[REGOUT]], i32 %[[QY]])
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[REGOUT]], i32 %[[QX]])
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_ry_i32_controlled_inv(i32 %[[F1]], i32 %[[QY]], double 5.000000e-01)
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_ry_i32_controlled_inv(i32 %[[F1]], i32 %[[QX]], double %[[A]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[REGOUT]], double 1.500000e+00)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[REGOUT]])
; CHECK-NOT: switch
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %s0, i32 %x0, i32 %y0, double %u, double %v) {
entry:
  %a = fadd double %u, %v                       ; computed angle in entry — dominates merge
  %s = call i32 @cq_theta_si32(i32 %s0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %x0, double %a)
  %qy = call i32 @cq_theta_si32(i32 %y0, double 5.000000e-01)
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
