; control_predmux_reject_xor_shielded_select_operand.ll — DECLINE (bd 3c6m.67),
; AND IT IS THE FIXTURE FOR A MEASURED OVER-ACCEPT THE RULE-13 ROUND CAUGHT.
;
; A clang poison-shielded short-circuit `&&` — `select i1 %sa, i1 %sb, i1 false`
; — as an OPERAND of the newly-admitted two-operand `xor i1`. E6
; (`isSupportedCondTree`) admits that select spelling in every other position, so
; the FIRST draft of the 3c6m.67 widening admitted it here too. That draft was
; wrong, and wrong in the project's signature way.
;
; *** WHAT WENT WRONG, MEASURED, HEAD (34b7995) vs the draft. *** HEAD DECLINES
; this module. The draft ACCEPTED it and emitted, before the real region:
;   %h_cmp14 = call i32 @cq_template_icmp_slt_i32_hl(i32 %h, i32 9)   <- never
;                                                 uncomputed, never freed
;   %out     = call i32 @cqrt_alloc_i1(i1 false)                      <- never
;   %selop   = call i32 @cqrt_alloc_i1(i1 false)                         freed
;   two `cqrt_copy_i1_controlled` into %out, which is NEVER READ
; — a whole DEAD 4.4 select merge, with an ENTANGLED flag rail left dangling
; (Rules 6/8). The real region then started over with freshly re-minted compares.
;
; CAUSE: `buildNegation`'s xor arm had to route the KEPT operand through
; `canonicalizePred` to rewrite the shield into `and`, and `canonicalizePred`
; did not `track()` the node it replaced — so the original `select` was
; STRANDED with zero uses and `lowerOps`/the 4.4 path lowered it anyway. That is
; the bd `kqqv` orphan class, made newly REACHABLE by this widening.
;
; *** NEITHER SHIPPED GATE COULD SEE IT. *** `opt -verify` is clean — the module
; is well-typed. `free_pairing_check.py` reports "0 violation(s), 0 unproven",
; because it counts `cqrt_alloc_*` mints and an orphan compare flag is
; TEMPLATE-minted (bd `1739`). A green suite would have shipped it. It was found
; by four independent adversarial reviewers, three of whom reproduced it against
; a separately-built HEAD plugin to establish causation rather than assert it.
;
; THE FIX WAS NARROWING, NOT REPAIR, and the choice was deliberate. Making
; `canonicalizePred` track is the durable fix for the orphan CLASS — and it is bd
; `kqqv`, which was left to its own red-green pair and its own Rule-13 round
; rather than folded in here under cover of a smaller change. Instead E6 carries
; a `Strict` sub-grammar under an xor node: no shielded select, no i1 phi, no i1
; constant — exactly `collectCondTree`'s grammar, inherited all the way down, so
; a shield nested three `and`s deep under an xor is refused too. It costs nothing
; measurable: the four census cells this increment exists for
; (`src/s_nextafterl.c:55` and siblings) carry plain compare leaves. Rule 17's
; carve-out verbatim — the decline belongs to inputs OUTSIDE the target shape.
;
; *** bd kqqv HAS SINCE SHIPPED (`trackCondCone(V)` at the top of
; `canonicalizePred`), AND THIS FIXTURE STILL DECLINES — DELIBERATELY. *** The
; orphan the CAUSE paragraph describes can no longer happen, so this decline now
; rests on grammar conservatism alone rather than on a live defect. That is a
; reason to re-scope the refusal in its own increment (with its own probe family
; and its own Rule-13 round, plus a fresh proof that ¬(a⊕b) = a ⊕ ¬b stays safe
; when the kept operand must be REWRITTEN rather than passed through) — it is not
; a reason to relax it as a follow-on. Over-declining a shape nothing measured
; wants is still correct; widening an accept predicate on this surface is the one
; move the Prime Directive polices hardest.
;
; RED-GREEN: replacing `%sh` with a plain compare makes this exact CFG ACCEPT
; (that is control_predmux_accept_xor_negation.ll), so the fence sits precisely
; on the shielded operand and not on the xor or on the surrounding region.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}under quantum control
; the orphan signature must not appear: no dead merge, no un-freed flag rail
; CHECK-NOT: cqrt_copy_i1_controlled
; CHECK-NOT: cqrt_alloc_i1
; CHECK-NOT: cq_template_icmp
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %sa = icmp sgt i32 %q, 1
  %sb = icmp slt i32 %q, 9
  %sh = select i1 %sa, i1 %sb, i1 false        ; poison-shielded && — off-grammar under an xor
  %cd = icmp ne i32 %q, 4
  %cc = xor i1 %sh, %cd
  br i1 %cc, label %inband, label %merge
inband:
  %v1 = add i32 %q, 1
  %c2 = icmp eq i32 %q, 6
  br i1 %c2, label %six, label %merge
six:
  %v2 = add i32 %q, 12
  br label %merge
merge:
  %rm = phi i32 [ %q, %entry ], [ %v1, %inband ], [ %v2, %six ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
