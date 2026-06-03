; lowering_control_switch_gated_distinct.ll — Phase 4.x (test_C_libtooling-npu.1),
; NEGATIVE (INTERIM DECLINE). A tainted-scrutinee GATED switch whose merge φ
; collects DISTINCT per-case quantum handles (case0→qx, case1→qy, default→qx) was
; silently miscompiled: the per-arm controlled gates were correct, but step 4 of
; `lowerGatedSwitch` RAUW-collapsed the merge φ to its FIRST tainted incoming
; (qx), DROPPING the qy edge — so a downstream `cq_phi(r, 1.5)` lowered to
; `cqrt_rz_i32(qx, 1.5)` and ran on qx UNCONDITIONALLY (when s==1 the program
; operated on qx, not qy). opt -verify was CLEAN, exit 0, ZERO diagnostic.
;
; The merge-φ discriminator only checked that every incoming was TAINTED, never
; that they shared the SAME base handle (despite the surrounding comment asserting
; "every incoming the same in-place handle"). This fixture pins the ENFORCEMENT:
; `resolveGatedHandleBase` unwraps each incoming's `cq_phi` chain to its base
; handle and a φ with two distinct bases is declined to the WP12 'switch under
; quantum control' diagnostic.
;
; STAGING: this is the user-chosen INTERIM decline (over-decline-safe) that closes
; the silent miscompile now. Correct lowering of a distinct-handle quantum
; multiplexer is the DEFERRED Bennett MUX-EXCH / controlled-SWAP (cqrt_cswap)
; feature (npu.1 sub-tasks i–iii); when it lands, this fixture is replaced by the
; positive cqrt_cswap version. A genuine MULTI-handle merge — distinct handles on
; SEPARATE φs, each uniform in its own base — still lowers (see
; lowering_control_switch_gated_multihandle.ll, unchanged). See
; [[cwk-merge-phi-discriminator]] + [[tainted-arm-select-mux-no-new-primitive]].
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
; The distinct-handle merge must NOT be lowered (no per-arm OR downstream
; controlled rotation emitted) — the edge-dropping RAUW never runs.
; CHECK-NOT: cqrt_rz{{.*}}controlled
; CHECK-NOT: cqrt_rz_i32(i32 %{{.*}}, double 1.500000e+00)
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
