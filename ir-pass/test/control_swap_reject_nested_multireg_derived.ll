; control_swap_reject_nested_multireg_derived.ll — DECLINE: depth-2 nest whose
; DERIVED inner condition mixes the routed value %g with a SECOND quantum
; register %r (the mint-from-rail OVER-ACCEPT the §8 adversarial review caught,
; 2026-06-12).
;
; `if (q>5) { q = rz(q,b); if ((q + r) < 9) { q = rz(q,a); } }` (real clang -O1).
; The merge is all %q-lineage so criterion 4 (RAUW-collapse) PASSES, and %g IS in
; the inner condition's provenance — so a single-hit mint-from-rail test (the
; original bug) wrongly ACCEPTS it. But the inner predicate (g+r)<9 depends on the
; OFF-RAIL register %r: minting the inner flag `icmp(rail1,k)` from rail1 (which
; holds only %g) cannot evaluate it → a verify-clean wrong predicate. Criterion 5
; now requires CONTAINMENT — every quantum-register leaf of the inner cond's
; provenance must lie in %g's diagonal-alias closure; %r (a cq_theta) does not, so
; this declines `nested control flow`. The dependency-direction twin of
; control_swap_reject_nested_multireg.ll; pins the over-accept door shut (a
; criterion-5 regression that re-accepted+emitted this would flip opt to exit 0
; and fail the `not` wrapper).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r  = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  %d  = add nsw i32 %q, %r
  %c2 = icmp slt i32 %d, 9
  br i1 %c2, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
; CHECK: error{{.*}}nested control flow under quantum control
