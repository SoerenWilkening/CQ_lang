; lowering_control_switch_gated_distinct_postmergelive.ll — Phase 4.x (test_C_libtooling-u5f),
; DECLINE (G6 — PERMANENT safety boundary). LOCKS the no-cloning / which-path hazard the
; u5f G2/G3 widening must NOT leak. The merge carries a distinct-base mux φ %r (bases qx,
; qy); base qy is ALSO read DIRECTLY after the merge by `%live = cq_phi(qy, .6)`. Because
; `cqrt_cswap` is a DESTRUCTIVE MOVE (it empties the selected source to |0>), the
; post-merge use of qy would read garbage. This is NOT a capability gap that a bigger
; uncompute could close — it is a genuine destructive-move hazard the trace runtime cannot
; detect, so it stays PERMANENTLY declined (docs/npu6-mux-exch-gate-spec.md §9). The
; widened G3a still rejects it: every chain-node user must be a chain node, an in-arm gate
; body, or the mux φ — the post-merge `%live` is none of these → WP12 decline. (Companion
; of _crossphi_alias.ll, which locks the cross-φ-shared-base variant of the same boundary.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
; CHECK-NOT: cqrt_cswap
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
  %r1 = call i32 @cq_phi_si32(i32 %qy, double 2.000000e-01)
  br label %merge
dflt:
  %rd = call i32 @cq_phi_si32(i32 %qx, double 4.000000e-01)
  br label %merge
merge:
  %r = phi i32 [ %r0, %c0 ], [ %r1, %c1 ], [ %rd, %dflt ]    ; mux: qx / qy
  %out = call i32 @cq_phi_si32(i32 %r, double 1.500000e+00)
  %live = call i32 @cq_phi_si32(i32 %qy, double 6.000000e-01)  ; qy read AFTER the destructive move
  %m1 = call i32 @cq_measure_si32(i32 %out)
  %m2 = call i32 @cq_measure_si32(i32 %live)
  %sum = add i32 %m1, %m2
  ret i32 %sum
}
