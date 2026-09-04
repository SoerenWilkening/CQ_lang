; control_inplace_ry_reject_inloop_multilatch.ll — DECLINE (PRD §13.2 row L-d):
; the in-loop Ry arm in a MULTI-LATCH loop.
;
; `flatRegionRollableInLoop` gate (C) requires a single latch. Multi-latch is the
; unproven shape `tryCaseA` already refuses and the round-2 rail collapse reasons
; about one latch throughout (`collapseRailPhisIn` returns `NotClaimed` without
; `getLoopLatch()`), so the region is refused before `Region.InLoop` is set.
;
; The single-latch gate is also what makes R7-loop clause (b')'s ONE SEAM sound:
; `railPhiRootMint` finds the external incoming as "the one whose block is not in
; `L`", while `collapseRailPhisIn` spells it "not the latch". Under a single latch
; every in-`L` predecessor of the header IS the latch and the two name the same
; incoming; without one they could differ, which is exactly why neither caller is
; reached here.
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
; With gate (C) deleted the ONLY red is the Rz sibling
; `control_swap_reject_inloop_multilatch.ll`. This file keeps declining, with a
; byte-identical message, and the reason is STRUCTURAL rather than accidental: a
; multi-latch loop's header rail φ necessarily has one external incoming plus one
; per latch, i.e. THREE or more, while clause (b')'s `railPhiRootMint` requires
; EXACTLY TWO. So for the Ry family gate (C) is redundant with (b') in the same
; way, and for the same reason, that (b)'s `!= LHdr` half is — see the note at
; that clause. Gate (C) IS pinned, by the phase family; this file cannot ISOLATE
; it.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %n) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %head
head:
  %r = phi i32 [ %r0, %entry ], [ %rm, %la ], [ %rm, %lb ]
  %i = phi i32 [ 0, %entry ], [ %n1, %la ], [ %n2, %lb ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %head ]
  %sw = icmp slt i32 %i, 3
  br i1 %sw, label %la, label %lb
la:
  %n1 = add i32 %i, 1
  %d1 = icmp slt i32 %n1, %n
  br i1 %d1, label %head, label %exit
lb:
  %n2 = add i32 %i, 2
  %d2 = icmp slt i32 %n2, %n
  br i1 %d2, label %head, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
