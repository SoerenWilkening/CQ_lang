; control_swap_reject_select_badcond.ll — DECLINE: a non-tree tainted-i1
; condition (4.4 WI-1 gate 2, tree grammar since 3c6m.12). The condition must
; be a lowerable `CmpInst` or — since the L4 compound widening — an `and i1`/
; `or i1` TREE over tainted HL `CmpInst` leaves. Any other tainted i1 (here a
; `trunc i32→i1`; also a phi, a call result, an argument) has no flag-mint
; shape and declines GENERIC `control flow` — NOT `control condition has no
; template` and NOT the §3c clobber string: a select has no straight-through
; edge, so the clobber proof obligation can never be met, and branding the
; shape any narrower would be the over-claim §8.3 warns against
; (IMPLEMENTATION-4.4 §0). The original `and i1` shape this fixture pinned
; pre-L4 is now the ACCEPT `control_swap_select_and2.ll` (deliberate Rule-12
; re-pin, compound-cond-select-PRD §5).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c   = trunc i32 %q to i1               ; tainted i1 that is NOT a compare/tree
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
