; control_predmux_reject_inloop_irreducible_inregion.ll — DECLINE (bd fn1q
; increment 3). Clause (e), second spelling: an irreducible 2-cycle `%P` <-> `%Q`
; inside the loop body, reached through two distinct arm blocks `%X`/`%Y` and
; joining at a 2-phi `%join`.
;
; ⚠ THIS FILE WAS ADDED ON A FALSE PREMISE AND IS KEPT ON A TRUE ONE. It was
; added by Rule-13 round 1 (F-5) as "the shape clause (e) actually exists for",
; on the claim that its sibling `…_irreducible.ll` had its cycle "entered from
; OUTSIDE the region" while this one has both entries in-region. Round 2
; measured both: the sibling's cycle is ALSO entered from in-region blocks, and
; on a mutant with E2's acyclicity call disabled BOTH modules decline at
; `E3-sideentry`. The stated discriminator does not distinguish them.
;
; WHAT IT IS ACTUALLY WORTH: a second, structurally different route into
; `E2-regioncycle` (two arm blocks and a 2-phi join rather than a direct
; two-way branch), so the gate name is pinned by more than one CFG shape. That
; is a real but modest thing and is all it should be cited for.
;
; ⚠ NOBODY HAS CONSTRUCTED AN IRREDUCIBLE IN-REGION CYCLE THAT ONLY THE
; ACYCLICITY PROOF REFUSES. That is an absence of a probe, not a proof that none
; exists — and it is the thing to build if clause (e) ever needs defending.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
;
; DBG: gate=E2-regioncycle
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; (No IR-text negatives: a decline writes 0 bytes to stdout — Rule 12 (b).)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %in, %latch ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %X, label %Y
X:
  br label %P
Y:
  br label %Q
P:
  %k1 = icmp slt i32 %q, 3
  br i1 %k1, label %Q, label %join
Q:
  %k2 = icmp sgt i32 %q, 7
  br i1 %k2, label %P, label %join
join:
  %v = phi i32 [ 1, %P ], [ 2, %Q ]
  %w = phi i32 [ 3, %P ], [ 4, %Q ]
  br label %latch
latch:
  %in = add i32 %i, 1
  %d = icmp eq i32 %in, 3
  br i1 %d, label %exit, label %head
exit:
  %m1 = call i32 @cq_measure_si32(i32 %v)
  %m2 = call i32 @cq_measure_si32(i32 %w)
  %s = add i32 %m1, %m2
  ret i32 %s
}
