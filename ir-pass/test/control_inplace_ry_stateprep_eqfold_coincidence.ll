; control_inplace_ry_stateprep_eqfold_coincidence.ll — ACCEPT.
;
; ⚠ THIS FILE WAS `control_inplace_ry_reject_stateprep_eqfold_coincidence.ll`
; AND WAS A DECLINE UNTIL THE 2026-09-11 OWNER RULING. It is a `git mv`
; with the **IR BYTE-UNCHANGED** — only the RUN lines, the assertions and
; this header moved — so the module below is still, character for
; character, the one the four drbq Inc-4 adversarial rounds argued over.
;
;     int r = 5;  if (q == 5) r = cq_theta(5, .9);
;
; ---- WHY IT IS AN ACCEPT NOW (bd `drbq.14`; F2's `CondWire` narrowing)
;
; OWNER RULING 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`.
; also WE DO NOT WANT ANOTHER cq function. it should just be an
; application of gates … I dont see the need for the over-decline."* The
; trade below was put to the owner plainly and was not vetoed.
;
; F2 no longer treats a pinned value that lies on the CONDITION'S OWN
; BACKWARD WIRE as a collider. The pin here was **%q**, found on the
; **arm edge**; it is in `CondWire` =
; `{Region.Condition} ∪ ⋃ railWireClosure(condProvenance(Region.Condition))`,
; the set built at the caller by calling R4's own helper.
;
; THE READING THE IR NOW GETS — the drbq Inc-4 state-prep stream, unchanged:
;   `i32 @cqrt_alloc_i32(i32 5)` at the hoisted theta (a FRESH rail,
;   carrying the SEED, never |0> unless the seed is), then one
;   `cqrt_ry_i32_controlled(f, %h1, 9.000000e-01)`, the ordinary flag
;   mint / `_unc` strip / free, and the prepped rail **FROZEN** — never
;   uncomputed and never freed, because a controlled gate's adjoint needs
;   its control and the flag is freed inside the region. The condition
;   register is not touched by the region at all.
;
; THE RIVAL IT SILENTLY ABSORBS (alpha reading): the source rotated the
; CONDITION'S OWN register IN PLACE — `cq_theta(<the pinned register>, θ)` —
; and `-O1` const-folded arg-0 to the literal on the edge where the equality
; is a theorem.
; ⚠ SAY IT IN THOSE WORDS: a program that was LOUDLY REFUSED before this
; ruling now receives the circuit for the OTHER reading, with no
; diagnostic. That is the trade, and it is disclosed rather than fenced —
; no fence exists, because after `-O1` the two sources are ONE module.
;
; WHAT MAKES IT ADMISSIBLE — the rival has no lowering to be robbed of.
; The UNFOLDED spelling of that same rival is
; `probes/alt/eqfold_coincidence.ll` in this
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
; control_inplace_ry_reject_stateprep_eqfold_coincidence.ll — DECLINE (F2, the
; A1 reading): the seed EQUALS the compare literal, on the ARM edge.
;
;     int r = 5;  if (q == 5) r = cq_theta(5, .9);       // probe `p06a`, from C
;
; ⚠ THIS MODULE IS BYTE-IDENTICAL (slice-body diff at `-O1`, measured
; 2026-09-04) TO TWO PROGRAMS CQ MUST DECLINE:
;     int r = 5; if (q == 5)      r = cq_theta(q, .9);   // `p08e` — an in-place
;                                                        // Ry on the CONDITION
;                                                        // register: R4
; forbids it
;     int r = 5; if (q > 4 && q < 6) r = cq_theta(q, .9); // `p08c` — the same,
;                                                        // via a singleton
; range
; An Ry RELABELS the basis, so the strip `icmp_..._unc` would be computed over a
; register the arm moved and the flag would not return to |0>. There is no
; correct re-anchor for this stem (unlike Rz, which is diagonal — see §14.2d and
; `tryEqFoldArm`), so the only options are "accept as a fresh rail", which is
; WRONG whenever the source meant `q`, or "decline". F2 declines.
;
; THE COST IS A GENUINE OVER-DECLINE AND IT IS THE SHIPPED DISPOSITION (PRD
; §14.11 Q1): the source above is a well-formed, unambiguous state prep. The
; workaround is ONE CHARACTER — any seed other than the compare literal, e.g.
; `control_inplace_ry_stateprep_seed_nonzero.ll` (seed 7, k 5), which ACCEPTS.
; F2 — THE EQUALITY-FOLD AMBIGUITY (PRD §14.2b). `clang -O1` (IPSCCP with
; PredicateInfo) replaces every use of the condition handle by the literal `k`
; on
; the edge where `q == k` is a theorem — on BOTH edges of an `icmp eq`/`ne`
; diamond. The consequence, MEASURED: two programs CQ must decline arrive as a
; module BYTE-IDENTICAL to a genuine state prep whose seed is `k`. An Inc 4 that
; read the shape as state prep would turn TWO LOUD DECLINES INTO SILENCE — the
; class the Inc-2b clearance blocked on.
;
; THERE IS NO POLARITY CLAUSE, and that is a proof rather than a convenience (a
; polarity clause is exactly where bd `ogw2` put a wrong unitary): F2 asks the
; branch's predicate AND its inverse and declines if EITHER edge pins the
; condition's tainted operand to the seed's value, so there is no edge in the
; test to get backwards.
;
; ⚠ CORRECTED 2026-09-05 (round-1 Rule-13 review, lens L2 finding F-L2-5). This
; paragraph used to say "on an eq/ne diamond EXACTLY ONE successor is the edge
; on
; which the equality is a theorem, so there are exactly TWO physical readings,
; and given F1 both collapse to the single condition `seed == k`". The algebra
; was
; right and THE ENUMERATION WAS THE DEFECT: there is a THIRD reading (A3) in
; which
; an edge proves `H != k` and `H`'s own RANGE makes the surviving set a
; singleton
; whose value is NOT `k`. `int t = q & 1; int r = 1; if (t) r = cq_theta(t, θ);`
; is that reading, it is plain `clang -O1` C, and the literal test was silent on
; it BY DESIGN — a CONFIRMED silent miscompile at the Inc-4 hand-back. F2 is now
; RANGE-based on both edges; see
; `control_inplace_ry_reject_stateprep_range_mask1.ll`.
;
; 3qlq: migrated from register cq_phi (dead declare erased)
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
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 5, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 5, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[H_CMP]], i32 %[[H1]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 5)
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
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-NOT:     call void @cqrt_x(
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; CCNT-COUNT-1: call void @cqrt_ry_i32_controlled(
; CCNT-NOT:     call void @cqrt_ry_i32_controlled(

