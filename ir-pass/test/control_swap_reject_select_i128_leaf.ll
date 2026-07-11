; control_swap_reject_select_i128_leaf.ll — DECLINE (3c6m.12 design-review
; MAJOR — the per-leaf width fence): one leaf of a compound condition is an
; i128 compare (no `cq_template_icmp_*_i128`, the n0ui fence). With one flag
; per leaf the emitter's mint is NOT atomic, so this must decline at DETECTION
; (`compareFlagMintable`, the ziov.4 detect-before-mutate discipline) — an
; emit-time bail would leave the ALREADY-MINTED sibling flag dangling in the
; stream (no `_inv`, no free; a leaked dirty rail). NOTE (Rule-13 clearance,
; harness-honesty lens): on a nonzero-exit decline `opt` writes NO module to
; stdout, so the CHECK-NOTs below scan only the 2-line stderr — they pin the
; DIAGNOSTIC's cleanliness, not the absence of mutation (which stdout cannot
; observe); the detect-before-mutate property itself lives in the
; `compareFlagMintable` detection fence + the accept fixtures' full streams.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cq_template_icmp
; CHECK-NOT: cqrt_alloc_i1
; CHECK-NOT: cqrt_copy
declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)

define i64 @example(i64 %u0, i64 %x) {
entry:
  %q   = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %c1  = icmp sgt i64 %q, 5                ; mintable first leaf
  %qe  = zext i64 %q to i128               ; tainted i128 (whitelisted cast)
  %c2  = icmp sgt i128 %qe, 7              ; i128 leaf — NO compare template
  %c   = or i1 %c1, %c2
  %sel = select i1 %c, i64 %q, i64 %x
  %m   = call i64 @cq_measure_sll(i64 %sel)
  ret i64 %m
}
