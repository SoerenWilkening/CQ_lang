; control_predmux_reject_inloop_irreducible.ll — DECLINE (bd fn1q increment 3,
; E2's in-loop admission). Clause (e): an IRREDUCIBLE cycle `%C` <-> `%D` lying
; wholly inside the loop body, entered from BOTH of `%head`'s edges.
;
; WHY THE LOOP TESTS CANNOT SEE IT: `LoopInfo` does not model an irreducible
; cycle at all, so `%C` and `%D` both report the ENCLOSING natural loop `L` and
; clauses (b), (c) and (d) all PASS. Only an acyclicity proof refuses it, which
; is why `E2-regioncycle` is the gate the DBG line below pins.
;
; ⚠ TWO CLAIMS THAT STOOD IN THIS HEADER ARE RETRACTED (Rule-13 round 2, R2-4).
; (1) "THIS IS THE CLAUSE THAT CANNOT BE DROPPED AS REDUNDANT … delete the
; `E2-regioncycle` call and this module is CLAIMED" — false: on that mutant this
; module still DECLINES, at `E3-sideentry`, from the unconditional
; `return topoOrderRegion(R)` at the tail of `recoverRegion` and from E3. The E2
; call site buys the GATE NAME, not the refusal. (2) The sibling fixture's header
; said this one's cycle is "entered from OUTSIDE the region". It is not — see the
; `br i1 %c, label %C, label %D` below. Both fixtures were mis-described, in the
; same change, in opposite directions.
;
; ⚠ SO WHAT IS THE SIBLING FOR? `…_irreducible_inregion.ll` differs in its
; JOIN structure, not in how its cycle is entered, and under the mutant BOTH fall
; to `E3-sideentry`. Neither exhibits a shape that ONLY acyclicity can refuse,
; and nobody has constructed one. Keep both as gate-name pins; do not cite either
; as proof that clause (e) is load-bearing.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
;
; DBG: gate=E2-regioncycle
; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
; (No IR-text negatives: a decline writes 0 bytes to stdout — Rule 12 (b).)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %in, %join ]
  %in = add i32 %i, 1
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %C, label %D
C:
  %cc = icmp slt i32 %q, 3
  br i1 %cc, label %D, label %join
D:
  %dd = icmp sgt i32 %q, 9
  br i1 %dd, label %C, label %join
join:
  %v = phi i32 [ 1, %C ], [ 2, %D ]
  %w = phi i32 [ 3, %C ], [ 4, %D ]
  %s = add i32 %v, %w
  %d2 = icmp eq i32 %in, 3
  br i1 %d2, label %exit, label %head
exit:
  %m = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}
