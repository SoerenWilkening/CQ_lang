; control_predmux_reject_inloop_header_nonentry.ll — DECLINE (bd fn1q increment 3,
; E2's in-loop admission). Clause (b): the loop HEADER enters the region as a
; NON-ENTRY block, so it carries reaching edges (the preheader's and two latches')
; that the flatten does not predicate.
;
; ⚠ THIS FIXTURE EXISTS BECAUSE THE INCREMENT'S OWN RECORD CLAIMED THIS CLAUSE WAS
; UNREACHABLE. It said "no probe reaches this clause AS THE SOLE REFUSAL, and the
; argument says none can" — derived on a SINGLE-latch construction, where the
; header is also the post-dominator and clause (c) fires first. Rule-13 round 1
; falsified it with the MULTI-LATCH shape below: entry `%A` is a non-header block,
; `%L1a`/`%L1b` both branch back to `%H`, and `%H` is therefore a non-entry region
; block. Measured `gate=E2-loopheader`.
;
; ⚠ AND THE HONEST OTHER HALF, WHICH THIS FIXTURE CANNOT SHOW: clause (b) is
; FIRST-FIRING, not load-bearing. On a mutant binary with clause (b) deleted this
; module still declines, at `E2-regioncycle`, and no shipped fixture changes
; verdict. Do not read a green run here as "clause (b) is what makes this safe".
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
;
; DBG: gate=E2-loopheader
; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
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
  br label %H
H:
  %i = phi i32 [ 0, %entry ], [ %i1, %L1a ], [ %i2, %L1b ], [ %i3, %L2 ]
  br label %A
A:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %L1, label %L2
L1:
  %cl = icmp slt i32 %q, 3
  br i1 %cl, label %L1a, label %L1b
L1a:
  %i1 = add i32 %i, 1
  br label %H
L1b:
  %i2 = add i32 %i, 2
  br label %H
L2:
  %i3 = add i32 %i, 3
  %d = icmp sgt i32 %i3, 9
  br i1 %d, label %exit, label %H
exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
