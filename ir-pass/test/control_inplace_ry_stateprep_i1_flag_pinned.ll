; control_inplace_ry_stateprep_i1_flag_pinned.ll — ACCEPT.
;
; ⚠ THIS FILE WAS `control_inplace_ry_reject_stateprep_i1_flag_pinned.ll`
; AND WAS A DECLINE UNTIL THE 2026-09-11 OWNER RULING. It is a `git mv`
; with the **IR BYTE-UNCHANGED** — only the RUN lines, the assertions and
; this header moved — so the module below is still, character for
; character, the one the four drbq Inc-4 adversarial rounds argued over.
;
;     _Bool r = <false>;  if (q == 5) { r = false; cq_theta(&r, .9); }  // the i1 SEED
; collides with the FLAG
;
; ---- WHY IT IS AN ACCEPT NOW (bd `drbq.14`; F2's `CondWire` narrowing)
;
; OWNER RULING 2026-09-11, verbatim: *"WE DO NOT WANT TO WRITE `int b1`.
; also WE DO NOT WANT ANOTHER cq function. it should just be an
; application of gates … I dont see the need for the over-decline."* The
; trade below was put to the owner plainly and was not vetoed.
;
; F2 no longer treats a pinned value that lies on the CONDITION'S OWN
; BACKWARD WIRE as a collider. The pin here was **%c (the branch's own compare
; result, an i1)**, found on the
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
; The UNFOLDED spelling of that same rival is `probes/alt/b_i1_flag_pinned.ll`
; in this
; increment's scoping record (`inc1-records/session-f2-i1/`), and it
; DECLINES `condition data use neither escaped nor measured`
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
; control_inplace_ry_reject_stateprep_i1_flag_pinned.ll — DECLINE, and it is the
; WHOLE `i1` STATE-PREP WIDTH.
;
; ⚠ THIS FILE WAS `control_inplace_ry_stateprep_i1.ll` — AN ACCEPT — UNTIL THE
; ROUND-3 Rule-13 fix, AND THE IR IS UNCHANGED. It is renamed rather than edited
; in place so the flip is visible, exactly as Inc 3 re-homed
; `control_inplace_ry_reject_in_loop.ll`. Nothing about the emitter changed; F2
; became SEMANTIC and started asking about a register the three syntactic
; generations never had in their set: THE BRANCH CONDITION ITSELF.
;
; WHY EVERY `i1` SEED COLLIDES, structurally rather than by coincidence. The
; branch condition is an `i1` TAINTED value, and on the two edges of its own
; branch it is pinned to exactly `true` and `false`. An `i1` seed is one of
; those
; two constants. So for a `true`-successor arm: seed `true` collides on the ARM
; edge, seed `false` collides on the MERGE edge — and symmetrically for a
; `false`-successor arm. There is no `i1` spelling left in the accept class.
;
; BOTH HALVES ARE GENUINE AMBIGUITIES, and one of them is MEASURED REACHABLE
; from plain C:
;
;   * ARM edge — `..._i1_arm_flag.ll` (source `$S/fix3/q/z02_i1_flag_arm.c`):
;     `_Bool c = (q==5); _Bool r = 1; if (c) { r = c; cq_theta(&r, 0.9); }` reaches the
;     pass as `cq_theta_i1(i1 true, …)`, i.e. `clang -O1` FOLDED the flag. That
;     is an in-place Ry on the CONDITION register, the shape R4 forbids, and the
;     shipped type gate (compare literal `i32 5`, seed `i1 true`) skipped all of
;     F2 for it.
;   * MERGE edge — THIS file. `%c` is pinned to `false` on the straight-through
;     edge and the seed is `i1 false`, so the source could have been
;     `_Bool r = c; if (c) { r = …; cq_theta(&r, …); }` with `-O1` folding the φ's Pred
;     incoming. Inc 4 RAUWs the merge φ to the PREPPED rail, so on the ¬f branch
;     downstream would read a fresh unentangled |0> rail where the source names
;     the flag's rail.
;
; ⚠ HONESTY ABOUT THE MERGE HALF, because the two halves are NOT equally
; reachable. Three plain-C spellings of "the straight-through value IS the flag"
; were written (`q/z01_i1_flag_straight.c`, `q/z03_i1_ifelse_flag.c`) and THIS
; clang folds NONE of them — it keeps `phi i1 [%4,%arm],[%2,%entry]`, whose
; tainted Pred incoming F1 refuses with `state prep merged with a quantum
; register`, and `condDataUseDisposition` refuses it one layer earlier again.
; So the merge half is an over-decline AT THIS CLANG. It is kept because
; (i) "absence of evidence is not a fence" is this review's own standard, and
; (ii) carving the condition out of the test set would re-open the ARM half,
; which IS reachable — measured, not argued.
;
; THE MERGE EDGE IS NOT ITSELF SPECULATIVE. `q/z05_merge_edge_fold.c` and
; `q/z06_merge_edge_fold2.c` are plain-C programs where the straight-through
; incoming IS a live measured register that `-O1` folds to the seed on the merge
; edge (`int t = q&1; int r = t; if (t) { r = 0; cq_theta(&r,θ); }` →
; `phi i32 [%5,%arm],[0,%entry]`). Both decline. That is why F2 asks both edges
; at all.
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
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i1 @cq_theta_i1(i1 false, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i1 [ %rt, %arm ], [ false, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i1 @cq_measure_i1(i1 %rm)
  ret i32 0
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[H_CMP]], i32 %[[H1]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
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

