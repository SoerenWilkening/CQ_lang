; control_swap_reject_nested_inner_derived.ll — DECLINE: depth-2 nest whose inner
; condition reads a SINGLE-register but VALUE-DERIVED operand built in `Mid`
; (`%d = add %g, 1`) — the verify-clean silent miscompile the §8 adversarial review
; caught at WI-3 (2026-06-12), a REAL bug the green suite missed.
;
; `if (q>5) { q = rz(q,b); if ((q + 1) < 9) { q = rz(q,a); } }`. The inner condition
; is a function of ONLY the routed value %g and a constant — so criterion-4
; RAUW-collapse passes (all merge edges %q-lineage) AND criterion-5's LEAF check
; passes (the sole quantum leaf %g IS in %g's diagonal-alias closure; the `add` is
; a non-quantum intermediate). The OLD criterion-5 therefore wrongly ACCEPTED it,
; and the emitter (a) minted the inner flag `icmp(rail1,9)` — DROPPING the `+1`, a
; wrong predicate (rail1 holds %g, not %g+1); AND (b) left the `add` live in `Mid`,
; so `flattenRegionTree` erasing `Mid` was a use-after-free on %g (SIGSEGV under
; Guard Malloc). Criterion 5 STRENGTHENED: the inner compare's tainted operand must
; be a DIRECT member of the rail closure (a diagonal `cq_phi`/Rz alias whose basis
; value equals rail1's), NOT a value-derived offshoot. `%d = add %g, 1` is not in
; the closure → decline `nested control flow`. 4.3 does not replay an in-`Mid`
; derivation onto the rail; the sound disposition is the Prime Directive over-decline.
;
; A criterion-5 regression that re-accepted + emitted this would flip opt to exit 0
; (failing the `not` wrapper) and re-introduce the UAF / wrong-predicate pair.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %g  = call i32 @cq_phi_si32(i32 %q, double %b)
  %d  = add nsw i32 %g, 1
  %c2 = icmp slt i32 %d, 9
  br i1 %c2, label %arm, label %merge
arm:
  %h  = call i32 @cq_phi_si32(i32 %g, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %h, %arm ], [ %g, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; CHECK: error{{.*}}nested control flow under quantum control
