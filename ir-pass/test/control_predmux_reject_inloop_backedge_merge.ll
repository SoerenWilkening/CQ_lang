; control_predmux_reject_inloop_backedge_merge.ll — DECLINE (bd fn1q increment 3,
; E2's in-loop admission). Clause (c) of `regionStrictlyInsideLoopBody`: the
; region's MERGE is the enclosing loop's HEADER, so the entry->merge edge that
; the flatten makes UNCONDITIONAL is the loop's BACK EDGE. Flattening it would
; make `%body`'s tainted branch stop choosing between the arms and instead jump
; unconditionally to `%head` — a loop whose two arms carried different induction
; steps would lose one of them outright.
;
; WHAT IT PINS, AND WHAT IT DOES NOT. The DBG line pins `gate=E2-loopbackedge` by
; name, so it fails if the region is refused for any OTHER reason as well as if
; it is admitted.
;
; ⚠ IT DOES NOT PIN THAT CLAUSE (c) IS WHAT MAKES THIS SAFE, AND AN EARLIER
; VERSION OF THIS HEADER CLAIMED EXACTLY THAT ("without clause (c) this region
; reaches the flatten"). Rule-13 round 2 falsified it on a single-clause mutant:
; with (c) disabled this module declines at `E3-mergepred`, same diagnostic, and
; it must — `preds(%head) = {entry, armA, armB}` and `%entry` can never be in a
; region rooted inside the loop. `PredMuxFlatten.cpp` already made that argument
; in its W6 block. Clause (c) is defence in depth here; it buys the gate name
; this fixture reads.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
;
; DBG: CQ_PREDMUX_DBG: leave @probe entry=body merge=head gate=E2-loopbackedge
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; ⚠ THIS FIXTURE CARRIES NO IR-TEXT NEGATIVE LINES, DELIBERATELY. It is a `not`
; pipe over a DECLINE, which writes 0 BYTES to stdout and no runtime-symbol text
; to stderr (both measured). A negative against that cannot fail — CLAUDE.md
; Rule 12 (b) verbatim. What pins the decline is the `not` inversion on the RUN
; line; what pins WHICH CLAUSE fired is the debug-prefix line above. Rule-13
; round 2 found six such vacuous lines in this fixture family, in the very change
; that removed two of them from the accept fixtures.
;
; ⚠ AND THE NOTE THAT REPLACED THEM CREATED TWO REAL DIRECTIVES ON ITS FIRST
; DRAFT, because it spelled the directive names out. Naming a FileCheck directive
; in prose CREATES one — a lesson this bead had already paid for once. Do not
; write directive keywords in a comment here.

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %ia, %armA ], [ %ib, %armB ]
  %g = icmp eq i32 %i, 7
  br i1 %g, label %exit, label %body
body:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %armA, label %armB
armA:
  %ia = add i32 %i, 1
  br label %head
armB:
  %ib = add i32 %i, 2
  br label %head
exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
