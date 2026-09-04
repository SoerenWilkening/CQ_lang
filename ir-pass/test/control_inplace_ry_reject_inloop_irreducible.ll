; control_inplace_ry_reject_inloop_irreducible.ll — DECLINE (PRD §13.2 row L-a):
; an in-loop control-in-place Ry arm carried by an IRREDUCIBLE cycle.
;
; `%entry` branches into the cycle at TWO places (`%head` and `%latch`), so
; `LoopInfo` names no natural loop and `flatRegionRollableInLoop` gate (A)
; refuses before `Region.InLoop` is ever set — Increment 3's clauses (b)/(b') are
; never even reached.
;
; THE IRREDUCIBLE HALF IS KEPT FOR A REASON THAT IS NOT THE FLATTEN. Since bd dugh
; `RegionFlatten` repairs the dangling header phi. What cannot see an irreducible
; cycle is the LAYER BELOW: `LoopLowering`'s rail analysis, `markIfRailLocal` and
; `FreePoint`'s back-edge reject are ALL `LoopInfo`-gated, so admitting one would
; flatten a region into a cycle whose second iteration nobody checks. For an Ry arm
; the stake is higher than for the phase path — the register is RELABELLED once per
; trip and the rail-record fence is exactly the machinery that would be blind.
;
; ⚠ THE EXIT-BLOCK MEASURE READS THE **POST**-REGION VALUE, ON PURPOSE (bd drbq
; Inc 3, round-1 lens L6, F-L6-2). All three CFG-gate fixtures in this family
; first read the loop HEADER phi there — the PRE-region name — which is the
; `premark` stale-record shape that R6's `recordLivePerActivation` refuses on its
; own. Measured then: with the CFG defect REMOVED the file still declined, on
; R6's message, so the fixture could not tell you whether the gate it is named
; for is live at all. Reading the post-region value removes that second refusal,
; and the shape now declines on THIS gate and nothing else — verified by the
; mutation recorded below.
; MUTATION, AND IT DOES **NOT** RED THIS FILE — measured, whole corpus, 2026-09-04.
; With gate (A) turned into `return true` the ONLY red is the Rz sibling
; `control_swap_reject_inloop_diamond_irreducible.ll`. This file keeps declining,
; with a byte-identical message, because `L` is then null all the way down to
; `ArmClassify`'s R7-loop clause (b)/(b'), whose `LHdr` is null too, so `Rollable`
; is false and it prints the SAME string. So gate (A) IS pinned — by the phase
; family, not by this file — and this file cannot ISOLATE it, because a second
; wall stands behind it wearing the same message. Recorded rather than
; engineered around: the alternative would be inventing a distinguishing
; diagnostic for a decline that is correct either way.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %n, i32 %e) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c0 = icmp eq i32 %e, 0
  br i1 %c0, label %head, label %latch
head:
  %r = phi i32 [ %r0, %entry ], [ %rl, %latch ]
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  br label %pred
pred:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %pred ]
  br label %latch
latch:
  %rl = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %ii = phi i32 [ 0, %entry ], [ %i, %merge ]
  %inext = add i32 %ii, 1
  %lt = icmp slt i32 %inext, %n
  br i1 %lt, label %head, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %rl)
  ret i32 %m
}
