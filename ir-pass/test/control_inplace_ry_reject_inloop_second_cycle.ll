; control_inplace_ry_reject_inloop_second_cycle.ll — DECLINE (PRD §13.2 row L-e):
; the in-loop Ry arm whose region entry sits on a SECOND cycle that `LoopInfo`
; does not name.
;
; Gates (A) and (B) both PASS — the region is inside a natural outer loop at one
; depth — and that is the whole point of gate (D): `LI.getLoopFor(Pred)` being
; non-null says the block is inside SOME natural loop, never that the cycle
; THROUGH THE REGION is that loop's. The walk re-runs the `regionEntryInLoop`
; reachability with `L`'s back edges and exits cut; reaching `Pred` again means an
; irreducible sub-cycle nested inside a reducible loop, and every downstream
; loop-aware guard is blind to it.
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
; MUTATION, AND IT DOES RED THIS FILE — measured, whole corpus, 2026-09-04, and
; it is the ONE of the three CFG-gate fixtures that isolates its gate. With gate
; (D)'s second-cycle refusal removed, this shape gets PAST detection and is
; refused much later and elsewhere, at `cq loop lowering: loop-carried tainted
; value crosses iterations` — a different owner and a different string, so the
; `CHECK` above fails. (The Rz sibling `control_swap_reject_inloop_second_cycle.ll`
; reds too; those two are the whole corpus delta.) ⚠ THE ISOLATION ONLY EXISTS
; SINCE THE PREMARK READ ABOVE WAS FIXED: with the header-phi read still in the
; file, R6 refused first and the mutation changed nothing.
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
  br label %head
head:
  %r = phi i32 [ %r0, %entry ], [ %rx, %olatch ]
  %i = phi i32 [ 0, %entry ], [ %inext, %olatch ]
  %ec = icmp eq i32 %e, 0
  br i1 %ec, label %pred, label %x
pred:
  %rp = phi i32 [ %r, %head ], [ %rj, %x ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %rp, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %rp, %pred ]
  br label %x
x:
  %rj = phi i32 [ %r, %head ], [ %rm, %merge ]
  %d = phi i32 [ 0, %head ], [ 1, %merge ]
  %dc = icmp sgt i32 %d, 0
  br i1 %dc, label %pred, label %olatch
olatch:
  %rx = phi i32 [ %rj, %x ]
  %inext = add i32 %i, 1
  %done = icmp slt i32 %inext, %n
  br i1 %done, label %head, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %rx)
  ret i32 %m
}
