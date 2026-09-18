; control_predmux_reject_inloop_tainted_exit.ll — DECLINE (bd fn1q increment 3,
; E2's in-loop admission). Clause (d), MERGE half: the region's post-dominator
; `%exit` lies OUTSIDE the loop, which is how a TAINTED LOOP-EXIT branch
; presents. Flattening it would make the exiting branch unconditional and
; DELETE a quantum-bounded exit — the thing `LoopLowering`'s Q1 decline exists
; to refuse — before Q1 is ever consulted.
;
; ⚠ THE FIRST PROBE WRITTEN FOR THIS CLAUSE NEVER REACHED IT. A single-block
; tainted-exit loop leaves at `gate=W-witness` (no claim witness fires), so the
; clause was untested and the comment that described it was an assertion. This
; spelling adds the NESTED tainted terminator in `%mid` so the W witness DOES
; fire and clause (d) is the gate that refuses — which is what the DBG line
; below pins. Do not "simplify" this fixture back to one block: that deletes
; the only thing it measures (bd `46oo`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
;
; DBG: CQ_PREDMUX_DBG: leave @probe entry=head merge=exit gate=E2-loopstraddle
; CHECK: error{{.*}}cq loop lowering: multiple early-break sites
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
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %inext = add i32 %i, 1
  %c1 = icmp sgt i32 %q, %inext
  br i1 %c1, label %mid, label %exit
mid:
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %latch, label %exit
latch:
  br label %head
exit:
  %p = phi i32 [ 1, %head ], [ 2, %mid ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}
