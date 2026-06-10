; control_swap_reject_value_stalecond.ll — guard-composition probe: the 4.1
; stale-condition guard covers VALUE regions for free (4.2 WI-3; PRD Part II
; §8.7; IMPLEMENTATION-4.2 §3 "arm-class independent").
;
; `if (q > 5) { p = p + 3; }` with a chained Ry on %q between the compare and
; the branch: the flag is minted at the BRANCH, so it would read the post-Ry
; basis while the SSA condition denotes the pre-Ry value — the wrong arm fires
; and icmp_inv cannot strip the flag (MINT_AT_COMPARE.md: permanent decline).
; The guard runs BEFORE arm classification, so the value-arm leg never sees
; this region — pinning that 4.2's new classification did not reorder or
; weaken the 4.1 pre-guards.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: value-arm swap-route
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  %q2 = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)  ; chained Ry after the compare
  br i1 %c, label %arm, label %merge
arm:
  %p1 = add i32 %p, 3
  br label %merge
merge:
  %pm = phi i32 [ %p1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
