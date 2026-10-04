; control_inplace_ry_stateprep_range_i1_both_edges.ll — ACCEPT.
;
; ⚠ THIS FILE WAS `control_inplace_ry_reject_stateprep_range_i1_both_edges.ll`
; AND WAS A DECLINE UNTIL THE 2026-09-11 OWNER RULING. It is a `git mv`
; with the **IR BYTE-UNCHANGED** — only the RUN lines, the assertions and
; this header moved — so the module below is still, character for
; character, the one the four drbq Inc-4 adversarial rounds argued over.
;
;     _Bool b = u; cq_theta(&b,.5);  _Bool r = false;  if (b == 1) { r = false;
; cq_theta(&r, .9); }
;
; ---- WHY IT IS AN ACCEPT NOW (bd `drbq.14`; F2's `CondWire` narrowing)
;
; OWNER RULING 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`.
; also WE DO NOT WANT ANOTHER cq function. it should just be an
; application of gates … I dont see the need for the over-decline."* The
; trade below was put to the owner plainly and was not vetoed.
;
; F2 no longer treats a pinned value that lies on the CONDITION'S OWN
; BACKWARD WIRE as a collider. The pin here was **%q / %c (BOTH i1, and an i1
; equality pins on BOTH edges)**, found on the
; **straight-through edge**; it is in `CondWire` =
; `{Region.Condition} ∪ ⋃ railWireClosure(condProvenance(Region.Condition))`,
; the set built at the caller by calling R4's own helper.
;
; THE READING THE IR NOW GETS — the drbq Inc-4 state-prep stream, unchanged:
;   `i32 @cqrt_alloc_i1(i1 false)` at the hoisted theta (a FRESH rail,
;   carrying the SEED, never |0> unless the seed is), then one
;   `cqrt_ry_i1_controlled(f, %h1, 9.000000e-01)`, the ordinary flag
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
; The UNFOLDED spelling of that same rival is `probes/alt/b_i1_both_edges.ll`
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
; control_inplace_ry_reject_stateprep_range_i1_both_edges.ll — DECLINE (F2, the
; RANGE clause). AT `i1` EVERY EDGE OF AN `i1` EQUALITY IS A SINGLETON, so an
; `i1` seed under an `i1` condition is ALWAYS ambiguous.
;
; ⚠ THIS MODULE WAS THE SHIPPED Inc-4 ACCEPT FIXTURE
; `control_inplace_ry_stateprep_i1.ll`, VERBATIM. The round-1 Rule-13 review's
; range spelling of F2 (lens L2, F-L2-1) turned it into a decline, and that is
; CORRECT rather than collateral: `icmp eq i1 %q, true` proves `%q == false` on
; the straight-through edge, and the seed IS `false`, so the module is
; byte-identical to
;
;     i1 r = q;  if (q == true) { r = false; cq_theta(&r, θ); }
;
; — an ALIAS of the quantum register on the straight-through edge muxed against
; a prepared rail (Rule 8, no-cloning; the A2 reading). At `i1` there are only
; two values, so BOTH edges pin, and no `i1` seed can escape: the whole
; "`i1` condition + `i1` seed" class is ambiguous by arithmetic.
;
; ⚠ CORRECTED 2026-09-05 (round-3 Rule-13 review, lens R3 finding F-R3-8). THIS
; PARAGRAPH USED TO SAY "THE WIDTH CAPABILITY IS NOT LOST", pointing at
; `control_inplace_ry_stateprep_i1.ll` (the same `i1` prep under an `i32`
; condition) and resting on F2's same-type gate to keep it silent. THAT GATE IS
; GONE — it was skipping ALL of F2 for the whole cast family and was itself a
; CONFIRMED MISCOMPILE (F-R3-2) — and the semantic form asks about the BRANCH
; CONDITION, which is a tainted `i1` pinned to `true` on one edge and `false` on
; the other whatever width the compare is at. So the `i1` STATE-PREP WIDTH IS
; NOW OUT: that fixture is re-homed as
; `..._reject_stateprep_i1_flag_pinned.ll` and joined by
; `..._reject_stateprep_i1_arm_flag.ll` (the plain-C-reachable ARM half). This
; file keeps its own reason — the A2 alias reading above — and is unaffected.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT   < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT    < %t.cqd0.ll

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example(i1 %u0) {
entry:
  %q = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %c = icmp eq i1 %q, true
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 false, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ false, %entry ]
  %mq = call i1 @cq_measure_i1(i1 %q)
  %mr = call i1 @cq_measure_i1(i1 %rm)
  ret i32 0
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i1_hl(i32 %[[H]], i1 true)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H_CMP]], i32 %[[H1]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i1_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i1 true)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H]])
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H1]])

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
; NOROUTE-NOT: call void @cqrt_ry_i1(i32 %h1, double 9.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-NOT:     call void @cqrt_x(
; RYCNT-COUNT-2: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; CCNT-COUNT-1: call void @cqrt_ry_i1_controlled(
; CCNT-NOT:     call void @cqrt_ry_i1_controlled(

