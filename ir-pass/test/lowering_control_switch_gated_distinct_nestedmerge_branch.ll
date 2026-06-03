; lowering_control_switch_gated_distinct_nestedmerge_branch.ll — Phase 4.x (test_C_libtooling-5bl),
; DECLINE (cross-region safety guard, branch-merge variant). REGRESSION TEST: the G4 direct-default
; widening also newly admits a distinct-base empty-direct-default mux (switch #2) sitting in a
; TAINTED `if`-diamond's merge block %m1 (`region#2.Pred == region#1.MergeBB`, where region #1 is a
; BranchRegion, not a SwitchRegion). The branch region's linearization ERASES %m1, which IS the mux
; switch's `Pred` — lowering the mux next dereferences the freed block (use-after-free SIGSEGV on
; valid input). The nested-merge guard keys on EVERY region's merge (branch + switch), so the inner
; mux declines LOUDLY here rather than crash. Companion to ..._nestedmerge.ll (switch-in-switch-merge).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}under quantum control
; CHECK-NOT: cqrt_cswap
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %c0, i32 %g0, i32 %x0, i32 %y0) {
entry:
  %qc = call i32 @cq_theta_si32(i32 %c0, double 5.000000e-01)   ; tainted scrutinee/cond
  %qg = call i32 @cq_theta_si32(i32 %g0, double 3.000000e-01)   ; gated handle (if-arm)
  %qx = call i32 @cq_theta_si32(i32 %x0, double 5.000000e-01)
  %qy = call i32 @cq_theta_si32(i32 %y0, double 5.000000e-01)
  %cmp = icmp eq i32 %qc, 1                                     ; tainted condition
  br i1 %cmp, label %then, label %m1
then:
  %gg = call i32 @cq_phi_si32(i32 %qg, double 9.000000e-01)     ; gate body (true arm)
  br label %m1
m1:                                                            ; BranchRegion merge AND mux switch Pred
  %pg = phi i32 [ %gg, %then ], [ %qg, %entry ]
  switch i32 %qc, label %m2 [ i32 0, label %e0                 ; direct-default distinct mux
                              i32 1, label %e1 ]
e0:
  %r0 = call i32 @cq_phi_si32(i32 %qx, double 1.000000e-01)
  br label %m2
e1:
  %r1 = call i32 @cq_phi_si32(i32 %qy, double 2.000000e-01)
  br label %m2
m2:
  %r = phi i32 [ %qx, %m1 ], [ %r0, %e0 ], [ %r1, %e1 ]
  %z = call i32 @cq_phi_si32(i32 %pg, double 1.500000e+00)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
