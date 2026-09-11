; control_inplace_ry_stateprep_eqfold_coincidence_ne.ll — ACCEPT.
;
; ⚠ THIS FILE WAS `control_inplace_ry_reject_stateprep_eqfold_coincidence_ne.ll`
; AND WAS A DECLINE UNTIL THE 2026-09-11 OWNER RULING. It is a `git mv`
; with the **IR BYTE-UNCHANGED** — only the RUN lines, the assertions and
; this header moved — so the module below is still, character for
; character, the one the four drbq Inc-4 adversarial rounds argued over.
;
;     int r = 5;  if (q != 5) r = cq_theta(5, .9);   // the pin is on the
; STRAIGHT-THROUGH edge
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
; **straight-through edge**; it is in `CondWire` =
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
; THE RIVAL IT SILENTLY ABSORBS (beta reading): the source's STRAIGHT-THROUGH
; value was that live register — `int r = <the pinned register>;` — and `-O1`
; folded the merge phi's Pred incoming to the literal, so what F1 sees is a
; Constant where the source wrote a quantum-data MUX.
; ⚠ SAY IT IN THOSE WORDS: a program that was LOUDLY REFUSED before this
; ruling now receives the circuit for the OTHER reading, with no
; diagnostic. That is the trade, and it is disclosed rather than fenced —
; no fence exists, because after `-O1` the two sources are ONE module.
;
; WHAT MAKES IT ADMISSIBLE — the rival has no lowering to be robbed of.
; The UNFOLDED spelling of that same rival is `probes/alt/b_coincidence_ne.ll`
; in this
; increment's scoping record (`inc1-records/session-f2-i1/`), and it
; DECLINES `state prep merged with a quantum register`
; — MEASURED 2026-09-11 **on the narrowed binary**, not merely on `main`,
; so the narrowing did not quietly open it.
; Why the beta rival is not a lost unitary, from the state vector: on the
; edge that carries the pin, the register is pinned to the seed by a SOUND
; edge fact (LVI answers a SUPERSET of the reachable values; a singleton
; therefore means `V == seed` on every execution taking that edge). In
; quantum terms the flag's subspace for that edge is spanned by basis states
; on all of which `V`'s rail reads |seed>, i.e. within that subspace the rail
; is the PRODUCT basis state |seed> and carries no superposition. The rival's
; only reversible realisation is a controlled copy of `V` into a fresh |0>
; rail, which on that subspace yields |seed> tensor |seed> — exactly what
; preparing |seed> yields. The two readings therefore AGREE on that edge, and
; they already agreed on the other one (the arm's seed is a literal in both).
; No clone of a superposition occurs, so Rule 8 is not what is being traded
; away; what is traded away is F1's loud refusal of the UNFOLDED spelling,
; which still stands (measured above).
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
; control_inplace_ry_reject_stateprep_eqfold_coincidence_ne.ll — DECLINE (F2,
; the A2 reading and the OTHER polarity): the STRAIGHT-THROUGH edge is the one
; that proves the equality.
;
;     int r = 5;  if (q != 5) r = cq_theta(5, .9);       // probe `p23b`, from C
;
; Here `-O1` folds the merge φ's PRED INCOMING, not the arm's arg-0, so the
; program this is byte-identical to is
;
;     int r = q;  if (q != 5) r = cq_theta(5, .9);       // `p23d`
;
; — an ALIAS of the quantum register muxed against a fresh rail, which
; no-cloning
; forbids (Rule 8). F1 forces seed == Pred incoming, so seed == k again, and
; F2's
; single test catches it with NO successor test at all. This fixture and its
; `eq`
; sibling are the pair that make the polarity-freeness a measurement rather than
; a claim: the arm is the FALSE successor here and the TRUE successor there.
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
  br i1 %c, label %merge, label %arm
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
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[H_CMP]], i32 %[[H1]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[H_CMP]])
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
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; CCNT-COUNT-1: call void @cqrt_ry_i32_controlled(
; CCNT-NOT:     call void @cqrt_ry_i32_controlled(

