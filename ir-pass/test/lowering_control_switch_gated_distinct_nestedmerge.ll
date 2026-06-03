; lowering_control_switch_gated_distinct_nestedmerge.ll — Phase 4.x (test_C_libtooling-5bl),
; DECLINE (cross-region safety guard). REGRESSION TEST for the adversarial-review finding: the
; G4 direct-default widening newly admits a distinct-base empty-direct-default mux (switch #2)
; that sits DIRECTLY in another gated switch's merge block (`region#2.Pred == region#1.MergeBB`
; == %m1) — the shape clang -O1 emits for back-to-back `switch` statements. `lowerControlledRegions`
; lowers regions sequentially and `linearizeSwitch` ERASES region#1's merge block %m1, which IS
; region#2's `Pred`; lowering region#2 next would dereference the freed block — a hard
; use-after-free SIGSEGV (NOT a silent miscompile, but a compiler crash on valid input). The
; nested-merge guard in `detectControlRegions` declines the inner switch LOUDLY (the always-safe
; WP12 over-decline) while every block is still valid, so the pass NEVER crashes. (This also fixes
; the pre-existing same-shape crash for two UNIFORM-base nested switches.) A future increment may
; lower these by inner-first ordering / region re-discovery.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
; CHECK-NOT: cqrt_cswap
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %s0, i32 %t0, i32 %x0, i32 %p0, i32 %q0) {
entry:
  %s = call i32 @cq_theta_si32(i32 %s0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %x0, double 5.000000e-01)
  switch i32 %s, label %d1 [ i32 0, label %c0          ; switch #1 (uniform-base, region #1)
                             i32 1, label %c1 ]
c0:
  %r0 = call i32 @cq_phi_si32(i32 %qx, double 1.000000e-01)
  br label %m1
c1:
  %r1 = call i32 @cq_phi_si32(i32 %qx, double 2.000000e-01)
  br label %m1
d1:
  %rd1 = call i32 @cq_phi_si32(i32 %qx, double 4.000000e-01)
  br label %m1
m1:                                                     ; region#1 merge AND region#2 Pred
  %r = phi i32 [ %r0, %c0 ], [ %r1, %c1 ], [ %rd1, %d1 ]
  %qp = call i32 @cq_theta_si32(i32 %p0, double 6.000000e-01)
  %qq = call i32 @cq_theta_si32(i32 %q0, double 7.000000e-01)
  switch i32 %r, label %m2 [ i32 0, label %e0          ; switch #2 (distinct mux, DIRECT default)
                             i32 1, label %e1 ]
e0:
  %s0v = call i32 @cq_phi_si32(i32 %qp, double 1.100000e-01)
  br label %m2
e1:
  %s1v = call i32 @cq_phi_si32(i32 %qq, double 2.100000e-01)
  br label %m2
m2:
  %r2 = phi i32 [ %qp, %m1 ], [ %s0v, %e0 ], [ %s1v, %e1 ]
  %m = call i32 @cq_measure_si32(i32 %r2)
  ret i32 %m
}
