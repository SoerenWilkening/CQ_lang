; control_inplace_ry_stateprep_eqfold_derived_cond.ll — ACCEPT.
;
; ⚠ THIS FILE WAS `control_inplace_ry_reject_stateprep_eqfold_derived_cond.ll`
; AND WAS A DECLINE UNTIL THE 2026-09-11 OWNER RULING. It is a `git mv`
; with the **IR BYTE-UNCHANGED** — only the RUN lines, the assertions and
; this header moved — so the module below is still, character for
; character, the one the four drbq Inc-4 adversarial rounds argued over.
;
;     int a = q & 6;  int r = 2;  if (a == 2) { r = 2; cq_theta(&r, .9); }
;
; ---- WHY IT IS AN ACCEPT NOW (bd `drbq.14`; F2's `CondWire` narrowing)
;
; OWNER RULING 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`.
; also WE DO NOT WANT ANOTHER cq function. it should just be an
; application of gates … I dont see the need for the over-decline."* The
; trade below was put to the owner plainly and was not vetoed.
;
; F2 no longer treats a pinned value that lies on the CONDITION'S OWN
; BACKWARD WIRE as a collider. The pin here was **%a = and %q, 6**, found on the
; **arm edge**; it is in `CondWire` =
; `{Region.Condition} ∪ ⋃ railWireClosure(condProvenance(Region.Condition))`,
; the set built at the caller by calling R4's own helper.
;
; THE READING THE IR NOW GETS — the drbq Inc-4 state-prep stream, unchanged:
;   `i32 @cqrt_alloc_i32(i32 2)` at the hoisted theta (a FRESH rail,
;   carrying the SEED, never |0> unless the seed is), then one
;   `cqrt_ry_i32_controlled(f, %h1, 9.000000e-01)`, the ordinary flag
;   mint / `_unc` strip / free, and the prepped rail **FROZEN** — never
;   uncomputed and never freed, because a controlled gate's adjoint needs
;   its control and the flag is freed inside the region. The condition
;   register is not touched by the region at all.
;
; THE RIVAL IT SILENTLY ABSORBS (alpha reading): the source rotated the
; CONDITION'S OWN register IN PLACE — `cq_theta(&<the pinned register>, θ)` —
; and `-O1` const-folded arg-0 to the literal on the edge where the equality
; is a theorem.
; ⚠ SAY IT IN THOSE WORDS: a program that was LOUDLY REFUSED before this
; ruling now receives the circuit for the OTHER reading, with no
; diagnostic. That is the trade, and it is disclosed rather than fenced —
; no fence exists, because after `-O1` the two sources are ONE module.
;
; WHAT MAKES IT ADMISSIBLE — the rival has no lowering to be robbed of.
; The UNFOLDED spelling of that same rival is
; `probes/alt/eqfold_derived_cond.ll` in this
; increment's scoping record (`inc1-records/session-f2-i1/`), and it
; DECLINES `condition predates a non-diagonal gate`
; — MEASURED 2026-09-11 **on the narrowed binary**, not merely on `main`,
; so the narrowing did not quietly open it.
; The theorem behind the ruling: `railWireClosure` inserts its seed BEFORE
; any gate, so `RotBase` is always in `BaseWireOrder`, so
; `RotBase in CondRails => R4 declines` for EVERY chained (register-arg-0)
; rotation arm. The only way past R4 is `StatePrep` — the folded case, where
; the register is no longer in the module at all. So the alternative reading
; is not merely unimplemented, it is UNREACHABLE while R4 stands. (In
; practice a fence EARLIER than R4 fires first — see the measured string
; above — which is SCOPE H-4 and is why the retirement trigger in
; `f2SeedPinnedByLiveRegister`'s header names R4 and 2c together.)
;
; ⚠ THE NARROWING IS THE **WIRE** AND NOTHING WIDER. A register that is
; NOT in the condition's backward cone still collides and still declines:
; `control_inplace_ry_reject_stateprep_range_forward_add.ll` (a FORWARD
; user of a cone member — the F-R1-1 class) and `..._sideways_sdiv.ll` (a
; SIBLING, reached by neither direction) are both untouched, as are all
; 21 of the class-B fixtures. `..._reject_stateprep_nonwire_still_collides.ll`
; is the minimal discriminator written for this ruling.
;
; ---- HISTORY — the header this file carried as a DECLINE, VERBATIM ----
; Kept rather than deleted: it is the measured record of why the fence
; existed, and the ruling changes the DISPOSITION, not the facts.
;
; control_inplace_ry_reject_stateprep_eqfold_derived_cond.ll — DECLINE (F2),
; on a
; case PRD §14.2b's prose does not enumerate and its SPELLING already covers
; (measured 2026-09-05, from plain C; bd test_C_libtooling-drbq Inc 4).
;
;     int r = 2;  if ((q & 6) == 2) { r = q & 6; cq_theta(&r, .9); }
;
; `-O1` proves `(q & 6) == 2` on the arm edge, folds the arm's `q & 6` to the
; literal `2`, and DELETES the second `and`. The module that reaches the pass is
; the one below: an `icmp eq` whose non-constant operand is the DERIVED value
; `%a`, an arm theta seeded with the compare literal, and a pred incoming of the
; same literal. Byte-identical, therefore, to a genuine `int r = 2; if
; ((q&6)==2)
; { r = 2; cq_theta(&r, .9); }`.
;
; ⚠ THE CONDITION REGISTER F2 IS PROTECTING HERE IS NOT `q` — IT IS `%a`, a rail
; the flag mint's template chain creates. §14.2b's text says "a TAINTED operand
; and a `ConstantInt` k", and *that* is the load-bearing word: it is not "the
; register the arm rotates" and not "the theta's source". An in-place Ry on `%a`
; is forbidden for exactly R4's reason — the strip recomputes `(q & 6) == 2`
; over
; a register the arm relabelled — and this fold makes that program textually
; indistinguishable from a fresh-rail prep of |2>.
;
; It is committed because the natural reading of F2 ("the seed equals the
; literal
; the user compared `q` against") would have missed it: nothing here compares
; `q`
; to anything. The fence asks about the compare's own tainted operand, whatever
; it is, and that is what makes it complete over derived conditions.
;
; ⚠ CONTRAST with `control_inplace_ry_stateprep_cond_derived.ll`, which is THE
; SAME CONDITION with seed `0` and ACCEPTS. The discriminator is the seed's
; value
; against the compare literal — 0 != 2 there, 2 == 2 here — so F2 is silent by
; VALUE and not by shape, and the derived-condition accept is not a hole in it.
;
; ⚠ THAT CONTRAST IS BETWEEN THE TWO `.ll` FILES, NOT BETWEEN TWO C PROGRAMS
; (corrected 2026-09-05, round-1 Rule-13 review, lens L2 finding F-L2-7). The C
; program a reader would infer for the accept — `int r = 0; if ((q&6)==2) { r = q&6;
; cq_theta(&r, .9); }` — does NOT produce that fixture: `-O1` folds the arm's
; `q & 6` to `2` there as well, and it then declines on **F1** (seed 2 vs pred
; incoming 0). The accept fixture's C has a source-written `0` in the arm.
;
; ⚠ AND SINCE THE ROUND-1 RANGE REWRITE, "0 != 2 there" IS NO LONGER THE WHOLE
; TEST: F2 now also asks whether either EDGE pins `%a` to the seed. It does not
; here — `and %q, 6` has range `[0,7)`, the `eq` edge is `{2}` and the `ne` edge
; is a six-element set — which is why `..._cond_derived.ll` still accepts and
; why
; it is the one-token control for
; `control_inplace_ry_reject_stateprep_range_mask1.ll`, whose mask `1` DOES pin.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT    < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = and i32 %q, 6
  %c = icmp eq i32 %a, 2
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 2, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 2, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[H]], i32 6)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H_OP]], i32 2)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[H_CMP]], i32 %[[H1]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H_OP]], i32 2)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[H_OP]], i32 %[[H]], i32 6)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_OP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H1]])

; ---------------------------------------------------------------------
; NEGATIVES — WHOLE-FILE AND PURE (the drbq Inc-4 round-1 lesson: a
; POSITIVE `-COUNT-n` inside a prefix WINDOWS every negative after it, so
; every count lives in its own CNT prefix and NOROUTE carries none).
; The counts are the INJECTION MATRIX's answer for this increment: an
; extra uncontrolled `cqrt_ry` on the CONDITION register moves RYCNT, an
; extra `cqrt_free` moves FCNT, and a `_controlled` on the WRONG flag
; breaks the CHECK capture (the flag handle is captured, never typed).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: = phi
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi
; THE FREEZE: no `cqrt_free` may ever name the PREPPED rail.
; NOROUTE-NOT: call void @cqrt_free(i32 %h1)
; …and the arm gate must not become UNCONDITIONAL (that fires the
; rotation on BOTH branches — the wrong unitary). Named by handle AND
; angle together, since an unconditional gate at a DIFFERENT angle is a
; legitimate post-region user elsewhere in the family.
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h1, double 9.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-NOT:     call void @cqrt_x(
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; CCNT-COUNT-1: call void @cqrt_ry_i32_controlled(
; CCNT-NOT:     call void @cqrt_ry_i32_controlled(

