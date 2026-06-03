; lowering_control_switch_gated_distinct.ll — Phase 4.x (test_C_libtooling-npu.5/.6),
; POSITIVE (MUX-EXCH). A tainted-scrutinee GATED switch whose merge φ collects
; DISTINCT per-case quantum handles (case0→qx, case1→qy, default→qx) — a coherent
; quantum multiplexer. The interim npu.1 decline (silent-miscompile guard) is
; replaced by correct Bennett MUX-EXCH lowering: the φ passes the conservative
; G0–G7 gate (two clean single-Ry handles qx/qy, a ConstantFP prep angle, a
; distinct reconverging default BLOCK with a gate body, uniform width, disjoint
; dead-after-merge bases), so `lowerGatedSwitch`:
;   * mints `regOut = cqrt_alloc_i32(0)`;
;   * MOVES the selected source in per distinct base — `cqrt_cswap(f_qy, regOut,
;     qy)` on the case1 eq-flag, and `cqrt_cswap(¬f_qy, regOut, qx)` for the
;     default-selected base (its control is the COMPLEMENT of the other base's
;     case-flag, via the self-inverse `cqrt_x` bracket — the flags PARTITION the
;     scrutinee, so qx fires exactly when qy does not);
;   * UNCOMPUTES each non-selected source's single-Ry prep —
;     `cqrt_ry_i32_controlled_inv(¬f_qy, qy, .5)` and `(f_qy, qx, .5)` — so regOut
;     is not left entangled with the scrutinee (npu.6);
;   * RAUWs the merge φ → regOut; the downstream `cq_phi(r,1.5)` operates on the
;     muxed register, and the per-case gate flags uncompute reverse-LIFO AFTER the
;     mux body (so they are still live when the cswap / ry_inv consume them).
;
; No edge is dropped, opt -verify is clean, and the switch + φ are gone. A genuine
; MULTI-handle merge — distinct handles on SEPARATE φs, each uniform in its own
; base — still lowers by the cheap RAUW (lowering_control_switch_gated_multihandle.ll,
; unchanged). See docs/npu6-mux-exch-gate-spec.md + [[cwk-merge-phi-discriminator]].
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; Two clean single-Ry prep handles (qx from %x0, qy from %y0) and the case-1 eq-flag:
; CHECK:     %[[QX:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x0)
; CHECK:     %[[QY:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y0)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 1)
; The MUX-EXCH body: fresh regOut, per-base controlled-SWAP MOVE (default base on
; the complemented flag via the cqrt_x bracket), then per-non-selected-source Ry†:
; CHECK:     %[[REGOUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[REGOUT]], i32 %[[QY]])
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[REGOUT]], i32 %[[QX]])
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_ry_i32_controlled_inv(i32 %[[F1]], i32 %[[QY]], double 5.000000e-01)
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_ry_i32_controlled_inv(i32 %[[F1]], i32 %[[QX]], double 5.000000e-01)
; Downstream operates on the muxed register, not a dropped edge:
; CHECK:     call void @cqrt_rz_i32(i32 %[[REGOUT]], double 1.500000e+00)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[REGOUT]])
; CHECK-NOT: switch
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; switch(s) { case 0: r=cq_phi(qx,.1); case 1: r=cq_phi(qy,.2); default: r=cq_phi(qx,.4); }
; out = cq_phi(r, 1.5);  — the merge φ %r mixes base handles qx and qy.
define i32 @example(i32 %s0, i32 %x0, i32 %y0) {
entry:
  %s = call i32 @cq_theta_si32(i32 %s0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %x0, double 5.000000e-01)
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
  %r = phi i32 [ %r0, %c0 ], [ %r1, %c1 ], [ %rd, %dflt ]   ; distinct bases qx / qy
  %out = call i32 @cq_phi_si32(i32 %r, double 1.500000e+00)
  %m = call i32 @cq_measure_si32(i32 %out)
  ret i32 %m
}
