; lowering_control_diamond_shared_merge.ll — Family B, NEGATIVE safety lock
; (test_C_libtooling-ehf, adversarial-review regression lock). TWO tainted
; one-content-arm `if`-diamonds reconverging on ONE shared merge block `%m`:
; `entry -[%sel]-> {pA, pB}`, then `pA -[%a]-> {armA, m}` and
; `pB -[%b]-> {armB, m}`, whose 4-way merge φ has incomings from
; `armA, pA, armB, pB`. Each diamond would build a `BranchRegion` with the SAME
; `MergeBB = %m`. `lowerControlledRegions` lowers regions SEQUENTIALLY, and the
; first region's linearization ERASES the shared merge; lowering the second then
; dereferences the freed block — a deterministic use-after-free SIGSEGV on VALID
; (verify-clean) input (0 diagnostics).
;
; `matchDiamond`/`matchSymmetricDiamond` now carry the extra-merge-predecessor
; check the gated-switch path (`tryBuildGatedSwitchRegion`) already had: `%m`'s
; predecessors exceed any single diamond's own {Pred, Arm}, so BOTH diamonds
; DECLINE and the WP12 fallback diagnoses "control flow under quantum control" —
; never mislowered, never crashed. The `not` RUN line proves the pass exits
; cleanly with the diagnostic (exit 1) instead of SIGSEGV-ing (exit 139); as with
; the gated-switch extra-pred lock (lowering_control_switch_gated_extrapred.ll), a
; diagnosed region emits NO module, so there is nothing further to verify — the
; absence of any controlled-gate emission (CHECK-NOT) confirms nothing lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_phi_i32_controlled
; CHECK-NOT: cqrt_rz_i32_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, i1 %sel) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  br i1 %sel, label %pA, label %pB
pA:
  %a = icmp sgt i32 %q, 5
  br i1 %a, label %armA, label %m
armA:
  %g0 = call i32 @cq_phi_si32(i32 %v, double 1.000000e-01)
  br label %m
pB:
  %b = icmp slt i32 %q, 20
  br i1 %b, label %armB, label %m
armB:
  %g1 = call i32 @cq_phi_si32(i32 %v, double 2.000000e-01)
  br label %m
m:
  %r = phi i32 [ %g0, %armA ], [ %v, %pA ], [ %g1, %armB ], [ %v, %pB ]
  %mm = call i32 @cq_measure_si32(i32 %r)
  ret i32 %mm
}
