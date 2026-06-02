; lowering_control_switch_gated_multihandle.ll — Phase 4.x WP18 follow-on
; (test_C_libtooling-6qg), POSITIVE — the multi-handle "pattern C" from the
; `-aht.3` spike. A gated `switch` whose arms gate DIFFERENT handles: case 1
; rotates handle `u`, case 2 rotates handle `v`, the default rotates BOTH. The
; merge carries TWO N-way φ (one per handle); the WP18 multi-φ dissolution
; (step 4 iterates `MergeBB->phis()`) handles them — each φ RAUWs to its own
; in-place handle. This locks that the per-handle dispatch lowers correctly (no
; cross-handle leak, every gate controlled on the right eq-flag).
;
; case 1 → `cqrt_rz_i32_controlled(f1, u, 0.1)`; case 2 → `(f2, v, 0.2)`; default
; (¬(f1∨f2)) → `(¬OR, u, 0.9)` AND `(¬OR, v, 0.8)`. Both handles measured after.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     %[[HU:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[HVV:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ:[a-zA-Z0-9_.]+]], i32 1)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 2)
; CHECK:     %[[FO:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[FO]])
; Default (¬OR) gates BOTH handles; cases gate one handle each on their own flag:
; CHECK:     call void @cqrt_x(i32 %[[FO]])
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[FO]], i32 %[[HU]], double 9.000000e-01)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[FO]], i32 %[[HVV]], double 8.000000e-01)
; CHECK:     call void @cqrt_x(i32 %[[FO]])
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[HU]], double 1.000000e-01)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[HVV]], double 2.000000e-01)
; CHECK:     call void @cqrt_toffoli_inv(i32 %[[F1]], i32 %[[F2]], i32 %[[FO]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[HU]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[HVV]])
; CHECK-NOT: switch
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %w0, i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %w0, double 5.000000e-01)
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  switch i32 %q, label %dflt [ i32 1, label %c1
                               i32 2, label %c2 ]
c1:
  %u1 = call i32 @cq_phi_si32(i32 %u, double 1.000000e-01)
  br label %merge
c2:
  %v2 = call i32 @cq_phi_si32(i32 %v, double 2.000000e-01)
  br label %merge
dflt:
  %ud = call i32 @cq_phi_si32(i32 %u, double 9.000000e-01)
  %vd = call i32 @cq_phi_si32(i32 %v, double 8.000000e-01)
  br label %merge
merge:
  %um = phi i32 [ %u1, %c1 ], [ %u, %c2 ], [ %ud, %dflt ]
  %vm = phi i32 [ %v, %c1 ], [ %v2, %c2 ], [ %vd, %dflt ]
  %mu = call i32 @cq_measure_si32(i32 %um)
  %mv = call i32 @cq_measure_si32(i32 %vm)
  %s = add i32 %mu, %mv
  ret i32 %s
}
