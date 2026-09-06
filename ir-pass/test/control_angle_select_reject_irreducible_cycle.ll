; control_angle_select_reject_irreducible_cycle.ll — DECLINE (S7, the CYCLE
; prong): the consumer, the select and the compare all sit in a block on an
; IRREDUCIBLE cycle, which `LoopInfo` cannot see.
;
; ROUND-1 RULE-13 REVIEW FINDING (bd drbq Inc 2b, lens L3-1 = the S7 half of the
; cross-lens synthesis). S7 shipped spelled ONLY as `LI->getLoopFor(...)`, which
; is a NATURAL-loop question. `entry` branches to BOTH `A` and `B`, so the cycle
; `A -> B -> A` has two entries and is IRREDUCIBLE: `getLoopFor` returns null for
; every block in it and S7 was VACUOUS. The angle select ACCEPTED here.
;
; THE TWO TWINS THAT DECLINE, WHICH IS WHY THE ACCEPT WAS WRONG:
;   * the MANUAL by-difference diamond (`r = R(r,B); if (q==5) r = R(r,A-B);`)
;     over the same cycle declines `control flow inside a loop body` — the d8jl
;     `regionEntryInLoop` walk in `ControlDetect.cpp` is a pure CFG successor
;     reachability and is reducibility-INDEPENDENT, so it sees this cycle;
;   * the plain UNCONTROLLED rotation in the same cycle declines
;     `cq uncompute: tainted handle live range crosses a loop backedge`.
; Every guard that adjudicates a cycle downstream (`LoopLowering`'s Case-A rail
; analysis, `markIfIterationLocal`, `FreePoint`'s back-edge live-range reject) is
; `LoopInfo`-gated, so accepting here put a controlled rotation and a
; mint/strip/free quadruple inside a cycle whose second iteration NOBODY checks —
; and the freeze suppresses the spine's own diagnostics, so the pre-existing loud
; Rule-6 reject became SILENCE.
;
; THE FIX asks the SAME question the siblings ask: S7 now ORs the `LoopInfo`
; clause with `blockOnCycle` (the walk `regionEntryInLoop` is built from, exported
; from `ControlDetect.cpp` — Rule 14, one walk) applied to each of `Cond`, `Sel`
; and `T`'s block, plus the rail-closure prong (see
; `control_angle_select_reject_loop_rail_exit_block.ll`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %cls, i32 %cls2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %r = mul i32 %p, 5
  %e0 = icmp eq i32 %cls, 0
  br i1 %e0, label %A, label %B
A:
  br label %B
B:
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %e1 = icmp eq i32 %cls2, 0
  br i1 %e1, label %A, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
