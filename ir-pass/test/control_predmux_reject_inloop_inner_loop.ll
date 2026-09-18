; control_predmux_reject_inloop_inner_loop.ll — DECLINE (bd fn1q increment 3,
; E2's in-loop admission). Clause (d), BLOCK half: one arm of the region is an
; INNER LOOP, so its blocks report the subloop rather than `L`. The region is
; therefore not "strictly inside one loop body" — flattening it would hoist a
; whole loop's body into the outer loop's straight-line prefix.
;
; This is the probe that proves clause (d) has two independent halves: the
; merge test alone (pinned by …_reject_inloop_tainted_exit.ll) would admit this
; one, because `%latch` IS in `L`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
;
; DBG: CQ_PREDMUX_DBG: leave @probe entry=head merge=latch gate=E2-loopstraddle
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
  %i = phi i32 [ 0, %entry ], [ %in, %latch ]
  %in = add i32 %i, 1
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %inner, label %armB
inner:
  %j = phi i32 [ 0, %head ], [ %jn, %inner ]
  %jn = add i32 %j, 1
  %jd = icmp eq i32 %jn, 4
  br i1 %jd, label %latch, label %inner
armB:
  br label %latch
latch:
  %v = phi i32 [ 7, %inner ], [ 8, %armB ]
  %w = phi i32 [ 1, %inner ], [ 2, %armB ]
  %s = add i32 %v, %w
  %d = icmp eq i32 %in, 3
  br i1 %d, label %exit, label %head
exit:
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}
