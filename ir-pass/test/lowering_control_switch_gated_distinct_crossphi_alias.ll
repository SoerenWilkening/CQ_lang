; lowering_control_switch_gated_distinct_crossphi_alias.ll — Phase 4.x (npu.5/.6),
; DECLINE (gate G6 / G3). The merge carries a distinct-base mux φ %r (bases qx, qy)
; AND a uniform handle φ %sm whose base is ALSO qy, read downstream. `cqrt_cswap` is
; a DESTRUCTIVE move (empties the selected source to |0>), so %sm RAUW'd to a moved
; qy would be garbage. The gate rejects any cross-φ sharing / post-merge-live use of
; a mux base → WP12.
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
  %sa = call i32 @cq_phi_si32(i32 %qy, double 9.000000e-01)
  br label %merge
c1:
  %r1 = call i32 @cq_phi_si32(i32 %qy, double 2.000000e-01)
  %sb = call i32 @cq_phi_si32(i32 %qy, double 8.000000e-01)
  br label %merge
dflt:
  %rd = call i32 @cq_phi_si32(i32 %qx, double 4.000000e-01)
  %sd = call i32 @cq_phi_si32(i32 %qy, double 7.000000e-01)
  br label %merge
merge:
  %r = phi i32 [ %r0, %c0 ], [ %r1, %c1 ], [ %rd, %dflt ]    ; mux: qx / qy
  %sm = phi i32 [ %sa, %c0 ], [ %sb, %c1 ], [ %sd, %dflt ]   ; uniform base qy
  %out = call i32 @cq_phi_si32(i32 %r, double 1.500000e+00)
  %m1 = call i32 @cq_measure_si32(i32 %out)
  %m2 = call i32 @cq_measure_si32(i32 %sm)
  %sum = add i32 %m1, %m2
  ret i32 %sum
}
