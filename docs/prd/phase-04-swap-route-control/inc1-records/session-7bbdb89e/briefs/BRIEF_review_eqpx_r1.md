# BRIEF_review_eqpx_r1 — ADVERSARIAL LENS, round 1, on the eqpx fix (READ-ONLY on the subject tree)

Agent name: `review_eqpx_r1`. Progress file: `$SP/progress/review_eqpx_r1.md`. Work dir: `$SP/progress/review_eqpx_r1_work/`
(set `W=` when calling the harness; copy it). Read `$SP/briefs/BRIEF_common.md` FIRST, then `BRIEF_fix_eqpx.md` (what the
implementer was asked to build), then the implementer's hand-back `$SP/progress/fix_eqpx.md` WHOLE.

SUBJECT: worktree `$SP/wt/eqpx`, branch `eqpx-fix` at **1333278** (base `main` 0b402d6). BUILT by the implementer —
verify currency yourself (`find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` EMPTY, `git status --porcelain`
EMPTY) before trusting its binary. You do NOT edit it, rebuild it, or run `git` mutations in it. You MAY build your own
MUTANT copies under `$W/` (`git worktree add --detach $W/mut 1333278`, edit, build) to test that a fence is a fence.
BINARIES: `main` = `$SP/bin/main-16b15b3/` (pre-fix), `orac` = `$SP0/wt/pre-3qlq` (52d7764), `fix` = the subject.

## What you are reviewing (the claim)
`OpcodeLowering.cpp` Phase 1 gained a SECOND predicate after the (1b) block: for every `taint.InPlaceRailOps` member not
in `PreLoopCommittedInPlaceOps`, re-ask G2 ALONE (`inPlaceValueRailOperand(BO, taint) != nullptr`) under FINAL taint and
decline `cq loop lowering: in-place rail op no longer provable at lowering`; possibly also the STRONGER FORM (a rail-operand
INDEX recorded at each of the four writers and consumed by `rewriteInPlaceValueRail`). Claimed: 8 decline fixtures RED on
`main` / GREEN on the fix; 7 accept controls byte-identical; 0 golden churn; 0 RCDIFF/DIAGDIFF/OUTDIFF over 1691 fixtures.

## Your ONE question — is the tripwire a FENCE, and did the fix INTRODUCE anything?
The C-1 history on this function: 8 findings over 6 rounds, TWO INTRODUCED BY A FIX (F-C1B-1, F-C1C-1). Budget on the
assumption that a ninth is here. Attack in this order; every claim MEASURED on named binaries, with a clean control and
a known-bad control before any conclusion (BRIEF_common's harness rules).

1. **Is G2-alone the right predicate, and is "FINAL taint" actually final where it is asked?** Phase 1 runs over the
   whole module BEFORE Phase 2's `promote()` mutates `Tainted`. Can a Phase-2 rewrite of an EARLIER op in program order
   taint an operand of a LATER marked op between the Phase-1 re-ask and its `rewriteInPlaceValueRail`? (Think: an
   immediate that is the RESULT of another tainted op lowered in Phase 2 — e.g. `w = y & 7` where `y` is `%out`: `%w` is
   already in `Tainted` at Phase 1, fine; but construct one where the immediate's taint is ONLY established by a
   Phase-2 `promote`.) If the stronger form shipped, does it close this? If not, is there a plain-C reach?
2. **Does the re-ask cover every writer?** `grep -n 'InPlaceRailOps.insert' ir-pass/src/*.cpp` — is it still 4, and
   is there any OTHER route into `rewriteInPlaceValueRail` (`InPlaceReassign`, the M-C route) whose immediate can
   turn tainted between its Phase-1 classification and Phase 2? (M-C's own `classifyInPlaceReassignment` asks G2 at
   Phase 1 too — same window.) Build a plain-C program if you can.
3. **W1 after the `continue`**: `n15`/`n16` and the break family — does `lowerBreakReversePlay` crash, emit a HALF-
   reversed chain, or free anything after our Phase-1 decline? Read `emitOneBreak` (`BreakReversePlay.cpp:707`) and
   MEASURE the stderr + the output module. A second diagnostic is fine; a free or a partial emission is not.
4. **Over-decline, the widening direction**: run the FULL 43-program census on `main` and `fix` (two-TU ones with
   `tu_extf.c`); `cmp` every accept's trace. Then write ≥20 NEW attack programs around the accept boundary — the
   k01/k02/k03 class (Argument, volatile load, a `select` of two constants, a classical `phi`, a loop-variant classical
   immediate under W1 `q ^= i`, a `zext`'d classical, a classical call result NOT under quantum control, a `switch`-
   folded classical), every stem (`add`/`xor`, `sub` for the decline check), widths i8/i16/i64, rolled AND hand-unrolled
   twins, and the mixed C-1 shapes (`slice_control_phase_perbit_loop_mixed*.c` sources in `tests/e2e/`). Any program
   that ACCEPTS on `main` with `imm=0` and DECLINES on the fix is an OVER-DECLINE finding (grade it: capability lost, or
   correct refusal of a shape that was wrong for another reason). Any program that accepts on BOTH with a trace DIFF is
   a finding of the worst kind.
5. **Over-accept, the direction that matters**: ≥15 attack programs trying to get a rail into the immediate slot PAST
   the tripwire: the 4.5 switch data-mux as producer from plain C (the investigation could not — try `switch` shapes
   `-O1` will not fold to `select`: ≥3 sparse cases, a `default` that stores); an immediate derived from `%out` through a
   CAST (`(short)y`, `(long)y`, `(unsigned char)y`) — casts are out of place, is the cast result tainted before Phase 1?;
   through a CURATED INTRINSIC (`__builtin_bswap32(y)`); through a SECOND onward region (round-2's `%out2`); an
   immediate that is the merge `%out` of a 6.5 arm INSIDE the loop body; a W1 break loop with the derived immediate
   used ALSO in the break condition; a rail op whose BOTH operands become tainted (Q+Q) vs NEITHER (does an op whose
   RAIL operand loses taint exist? — it cannot, but check the `TL == TR` false branch of G2: both classical). Run
   `immcheck.py` on every accept's `.s2.ll` on the fix — ANY `railInImm ≥ 1` is a CONFIRMED MISCOMPILE finding.
6. **Mutant validation (a fence nobody tried to fool is a fence nobody should trust)**: build a mutant with the new
   block deleted; all 8 decline fixtures must go RED (accept with imm=1) and nothing else must move. If the stronger
   form shipped, build a second mutant with ONLY the index consumption reverted; find the fixture that discriminates it
   (if none does, that is a finding — the index is then decoration).
7. **Fixture integrity**: for each new accept fixture, inject (a) a `cqrt_xorc_i32(%h, %h_op)` with a rail immediate,
   (b) an extra `cq_template_xor_i32` out-of-place, (c) an extra `cqrt_free` — each must be caught by a named prefix.
   `grep -n 'NOROUTE-COUNT' <new fixtures>` must be EMPTY. Confirm the 8 decline fixtures' `CHECK-NOT`s would catch a
   silent out-of-place fallback (mutate the fix to fall back instead of decline; the fixtures must go red).
8. **The 8h7d.5 question, asked of THIS widening**: the tripwire narrows nothing, but if the stronger form records an
   INDEX at the writers — what OTHER consumer reads the writer's rail pick? (`railValueConsumerDisposition`,
   `collectRailGates`, `peelInPlaceStep`, `staleRailRecordRead`'s skip set, the break machinery's `RailOps`.) Do any of
   them now disagree with the recorded index under final taint? Measure with a program, not an argument.
9. **Record truth**: every count in the hand-back reproduces by command (lit total, fixture names, e2e 357, goldens 323
   unchanged — `git status`/`git diff --stat main -- tests/e2e` EMPTY, `runtime/` `tools/opcode_table.yaml` `include/`
   EMPTY). The four writers named in `TaintPropagation.h` and notes §2/§3.16 are the four `insert` sites by line. The
   §3.12 ADD row is marked falsified, not deleted.

## Verdict
`CLEAR` / `CLEAR-WITH-ITEMS` (doc/fixture items only) / `BLOCK` (a confirmed over-accept, a confirmed introduced
miscompile, a crash, or a golden moved). Findings numbered `F-E1-<n>`, each with: the reproducer (path), the binaries it
was run on, the measured status/lines/imm on each, and the grade (CONFIRMED-MISCOMPILE / OVER-DECLINE / DOC / CLEAR).
Anything contradicting a PRD §2 decision or the owner ruling → `## OWNER QUESTION`. End with a "WHAT I RAN" table like
`review_c1e.md`'s and a "NOT run" row.

## Two items the implementer handed back that you must ADJUDICATE (added by the orchestrator after the hand-back)
**(A) OWNER QUESTION 1 — the stronger form is measured INERT.** With both halves of the operand-index plumbing disabled
(`$SP/bin/eqpx-m23/`, two `false &&` inserts at `OpcodeLowering.cpp`'s `IdxDisagrees` and `ArithLowering.cpp`'s
`InPlaceRailIdx.find`), all 1707 fixtures are green and the two binaries differ on 0 fixtures. Its inertness ARGUMENT:
with the tripwire in place G2 returns non-null ⇒ exactly one operand tainted at Phase 1, and no Phase-2 event can flip
WHICH one (an untainted operand is never RAUW'd and never joins `Tainted`; `promote` inserts only the new handle of an
op that was itself tainted and collected). Your job: try to BREAK that argument with a program (item 1 above is the
attack surface — a Phase-2 `promote` or RAUW that changes an operand's taint AFTER the Phase-1 re-ask). If you cannot,
say so and grade the stronger form `DOC` (argued defence-in-depth, unpinned — record the argument in-source). If you CAN,
that is a CONFIRMED finding and the index is what catches it — pin it with a fixture.
**(B) OWNER QUESTION 2 — the `n02`/`n03` loop vanishes in the LOWERED module (parity-correct, pre-existing, byte-
identical on the oracle).** The implementer could not name the stage. The orchestrator's candidate: the Lever-B
static-K FORCE-UNROLL pre-pass `ir-pass/src/LoopUnrollPrepass.cpp` (bd 3c6m.55 Inc 2, ticket lf8s; gates U1–U8 in
`LoopUnrollPrepass.h`; wired at `CQLoweringPass.cpp:252`), whose fence U4 refuses a loop that HAS in-place rail
structure (`loopHasInPlaceRailStructure`, `LoopPlan.h`) — and in `n02` the immediate is the 4.4 select-merge `%out`,
tainted at ROUND 1, so `r ^ w` is Q+Q, G2 is null, U4 admits the unroll, and the unrolled `r^w^w^w` folds to `r^w`.
CONFIRM or REFUTE by measurement (the prepass's own debug/diagnostic, or a mutant with it disabled). Then ask the
eqpx question of THAT stage: can the prepass unroll a loop whose immediate is classical at round 1 (so a writer WOULD
have marked it) — no, by U4, but MEASURE the decline direction and say whether the unrolled body's ops then reach
`lowerOps` with a round-2-tainted operand as an ORDINARY out-of-place op (correct) rather than an in-place one.
