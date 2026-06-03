; lowering_control_switch_gated_distinct_multigatearm.ll — Phase 4.x (test_C_libtooling-bqs),
; POSITIVE (MUX-EXCH). A distinct-base mux where the qy-selecting arm c1 applies TWO
; LINEAR in-place gates — `%t = cq_phi(qy,.9)` then `%r1 = cq_phi(%t,.2)` — and the φ
; carries the chain end `%r1`. Both gates are real region body on the one qy register
; (qy -> t -> r1 is a linear consume-produce chain, the no-cloning contract), so BOTH
; controlled Rz fire on f_qy and the cswap moves the fully-gated handle into regOut.
;
; REGRESSION LOCK (bqs resolution): this is the WELL-FORMED shape that a "dead arm-local
; cq_phi on a mux base" would mimic. A dead clone (`%dead=cq_phi(qy,.9)` unused, `%r1=
; cq_phi(qy,.2)`, φ carries %r1) requires using the qy handle TWICE off the same SSA
; value — a no-cloning / linearity violation outside the compiler's input contract — and
; under the in-place handle model lowers BYTE-IDENTICALLY to this linear form (the gates'
; physical effect on the register is identical). So the mux path is correct on every
; well-formed (linear) input; the genuine cross-arm / post-merge cloning HAZARDS are
; declined by G3b (`_wrongarmmut*.ll`) and G6 (`_crossphi_alias.ll`, `_postmergelive.ll`).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; Both in-arm gates of the qy chain fire (controlled on f_qy), then cswap into regOut:
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[FQY:[a-zA-Z0-9_.]+]], i32 %[[QY:[a-zA-Z0-9_.]+]], double 9.000000e-01)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[FQY]], i32 %[[QY]], double 2.000000e-01)
; CHECK:     call void @cqrt_cswap(i32 %[[FQY]], i32 %[[REGOUT:[a-zA-Z0-9_.]+]], i32 %[[QY]])
; The non-selected qy prep is uncomputed (single-Ry prep, .5) on ¬f_qy:
; CHECK:     call void @cqrt_ry_i32_controlled_inv(i32 %[[FQY]], i32 %[[QY]], double 5.000000e-01)
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
  switch i32 %s, label %dflt [ i32 0, label %c0
                               i32 1, label %c1 ]
c0:
  %r0 = call i32 @cq_phi_si32(i32 %qx, double 1.000000e-01)
  br label %merge
c1:
  %t = call i32 @cq_phi_si32(i32 %qy, double 9.000000e-01)
  %r1 = call i32 @cq_phi_si32(i32 %t, double 2.000000e-01)
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
