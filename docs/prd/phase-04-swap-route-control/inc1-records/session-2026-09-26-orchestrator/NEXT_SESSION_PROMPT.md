# NEXT SESSION — bd `woa0`'s round, then 0fly, then 5b

Read, in this order:
```
CLAUDE.md                                    (§4j is this session; §5's fn1q paragraph was
                                              STALE BY THREE LANDINGS and is corrected there)
docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-26-orchestrator/
    NEXT_SESSION_PROMPT.md   <- this file
    MEASUREMENT_WOA0.md      <- what landed and every number behind it; §6 and §9 are the
                                two sections worth reading twice
    probes/woa0/
docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-orchestrator/
    REVIEW_R13_R3_M4.md      <- F-R3-1 is what this session built; its OTHER items are
                                mostly still unfiled-and-now-filed, see bd `4hnu`
    MEASUREMENT_INC5B_SCOPE.md <- task 3, unchanged since last session
```
Then `bd prime`, `bd show test_C_libtooling-fn1q`, and `u460`, `0fly`, `41g3`, `4hnu`.

---

## 0. ⚠ WHAT IS DIFFERENT FROM LAST SESSION'S BRIEF

**The owner's `example/grover/grover_oracle_uncompute.c` COMPILES**, and `CLAUDE.md` said
otherwise until today. Measured on two binaries: exit 0, **0 bytes of stderr**, 124 lowered
lines (130 for the e2e slice), stage 2b STRICT `3 verified, 0 violation(s), 0 unproven`,
88 trace lines matching the golden. Increments 1–5a of bd `fn1q` have all landed. If you read a
sentence in this tree saying that program does not compile, it is stale — **check the date and
re-measure before acting on it**, which is the whole reason this paragraph is first.

⚠ **AND THE LANDING THAT MADE IT TRUE (2026-09-24, 2026-09-25) NEVER WROTE ITSELF A `CLAUDE.md`
§4 SECTION.** That is how a three-landing-old falsehood survived in the operating manual. If you
land something, write the section.

---

## 1. STATE

```
HEAD      18fcc51e   (357f2528 the fix + the sealed labreport 018)
cq-opt    15adcac40d4455a7       build/ir-pass/cq-opt
libCQPass bab2a8b70c57c6b0
ORACLE for woa0 (pre-fix): git 18d18728 -> fe5805a41df2e173
fixtures 2157 · goldens 412 · ctest 479
full ctest -j6: 479/479 in 795.22 s, load 248 -> 13 (NOT a quiet-box figure)
LLVM = /usr/local/opt/llvm@19/bin (NOT on PATH; `lit` is)
```
⚠ `shasum -a 256 build/ir-pass/cq-opt` before believing any decline you see by hand.
⚠ `git worktree list` shows FOUR extra worktrees. THREE are mine and are left deliberately, so
every measurement in `MEASUREMENT_WOA0.md` is reproducible: `wt-oracle-woa0` (the oracle),
`wt-woa0-INSTR-COMMITLOG` (the commit census), `wt-woa0-MUTANTS` (three env-gated mutants in one
binary). Each is named for what it is; remove them when you no longer need the numbers. **The
fourth, `…/0f0bbbb6-…/scratchpad/oracle` at `4db66534`, belongs to a DEAD session and its
directory still exists — do not `git worktree prune` without checking.**

---

## 2. YOUR TASKS, IN ORDER

### (1) bd `test_C_libtooling-u460` — the Rule-13 round this change owes. BUDGET TWO.

A new fence in the Rule-13 lowering core is not cleared by a green suite. The bead carries an
eight-item attack list written by the implementer, i.e. by someone with a motive to have missed
things; treat it as a floor. The two items I would attack first:

* **the `AtFn` raw pointer.** `Leaves` is a `WeakVH` set precisely because a recorded φ can die;
  `AtFn` is a raw `const Function *` whose safety is an ARGUED window ("nothing between the
  conversion and the re-ask erases a function"). The argument and its retirement trigger are at
  the field in `PredMuxFlatten.h`. An argued window is what this whole bead family is about.
* **the pre-emptive slot.** The re-ask runs before `detectSpecializations` so the diagnostic owns
  the decline instead of inheriting `collectCondTree`'s. `LLVMContext::diagnose` EXITS on the
  first `DS_Error`, so that placement also means this owner now pre-empts anything downstream
  that would have declined such a module for an UNRELATED reason. Measured zero such cells in the
  corpus; **not proved absent**.

### (2) bd `test_C_libtooling-0fly` — still open, and read BOTH words in its new note

The observation COVERS the `{R.Merge}` cell (a conversion there is now a loud named decline).
**Covered is not closed.** 0fly asks for the unwritten E3-derived dominance argument to be
written down AT THE CONJUNCT or for the conjunct to be fenced, and **the conjunct is unchanged** —
it still reads the same test `isConvertiblePhiCond` reads and fails CLOSED on, while this one
fails OPEN. New measurement in the bead: over all 2157 fixtures plus the owner's program, **every
commit is the ENTRY-φ cell and the `!InRegion` disjunct has zero customers anywhere**. Cheap bead;
do not let "covered" turn into "closed" in a summary.

### (3) Increment 5b — unchanged, still scoped and unbuilt

`MEASUREMENT_INC5B_SCOPE.md` is untouched by this session and every warning in it still stands:
it is TWO customers; 5b-i has a SECOND wall (the uncompute spine does not recognise the promoted
φ as a handle user, so "5b-i is one promotion" is FALSE); the promoted value must be a fresh
`cqrt_alloc`, never the literal 0; and the most important question it has to answer is whether
`lowering_reject_classical_mux_phi_measured.ll` flipping to ACCEPT is its retirement trigger
firing or a boundary violation — **undetermined**, settleable only by showing every consumer of
the promoted φ reads it as a handle.

### (4) bd `test_C_libtooling-4hnu` — six round-3 record corrections, none of them filed until today

Round 3 on the M4 fix returned `CLEAR-WITH-ITEMS` with seven P3s. **Only one of them (`juck`) had
a bead.** The rest lived solely in a review file, which is precisely the failure mode
`CLAUDE.md`'s L7-with-a-twist names. Two are partly overtaken by this session (the "only within
one pass" clause; the call-site count) and the remainder are not. None changes behaviour; all six
are sentences a future agent will read as true, in the file where this project's last two P1s
lived.

### (5) Still worth doing, still unowned: the `+Asserts` build

The tree has never had one, because building one aborts on **four committed ACCEPT fixtures**, all
pre-existing. That is the structural reason the unchecked-`cast<>` family in `PredMuxFlatten.cpp`
has no gate at all — and 5a's P1 came from that family, as does the `cast<PHINode>` this session
added a caller to. Unfiled as a bead; the brief before this one listed it as task 5 and it stayed
task 5.

---

## 3. HOW TO LAND ANYTHING — not negotiable

Rule-12 red-green (the fixture FIRST, watched failing) + a mutation check in **both** directions ·
**its own Rule-13 round by an agent that did not write it, and BUDGET TWO** · the standing
rolled-vs-unrolled probe with a trailing non-diagonal gate on every register the condition reads ·
corpus A/B with a **null control AND a positive control** · full `ctest -j6` reported **with its
load** · a tracked fixture AND an e2e slice.

---

## 4. LESSONS THIS SESSION PAID FOR

1. ⚠ **MUTATION IS NOT CONFIRMATION — IT IS THE ONLY THING THAT FOUND A MISSING FIXTURE.** Two of
   three mutants pinned what I expected. The third said "this conjunct is UNPINNED" (0 movers of
   2156 with it deleted), and chasing that produced a shipped ACCEPT fixture for a cell no corpus
   sweep could ever have shown me. **Run the mutant that you expect to prove nothing.**
2. ⚠ **A CONTROL THAT REPORTS A PASS WITHOUT REPORTING ITS DENOMINATOR IS NOT A CONTROL.** My
   mutant null control printed `divergent=0 of 1` — under **zsh** an unquoted `$FILES` is ONE
   WORD, so the loop ran once and "0 divergent" was true and worthless. Only the printed
   denominator caught it. Round 3 paid for the same class one shell feature over (`export -f`).
   Print the denominator in every control you write.
3. ⚠ **A PROBE CAN CONTAIN HALF ITS SHAPE.** My first `!BoolAlg` witness RECORDED the φ and never
   converted it: the outer region left at `gate=W-witness`. The verdict looked like a clean
   negative. Reading the DBG trace is what showed the probe never reached the mechanism. bd `46oo`
   again, and the fix was one extra merge φ.
4. **AN "ARGUED" NULL CONTROL THAT FIRES ANYWAY IS WORTH RECORDING.** I rebuilt the oracle from
   `18d18728` purely to have one, and it came out **bit-identical** to the hash the incoming brief
   recorded. That is a build null control nobody planned, and it is the cheapest evidence in the
   whole record that the brief's numbers were real.
5. **A NON-DIVERGENCE MEASURED AT THE WRONG WALL IS NOT A CLEARANCE.** The G-13 standing probe ran
   and both spellings declined identically on both binaries — at `taint escape` and `control
   flow`, neither of them this change's fence. Reported as "ran, found nothing, and could not have
   found anything", not as "cleared".
6. **`CLAUDE.md` ENFORCES ITS OWN BUDGET AND SOMEBODY HAS TO DO IT.** The file was at 151.7 k
   before this session and its own rule is to ARCHIVE a landing section verbatim rather than cut a
   paragraph. §4 and §4i went to `docs/CLAUDE-HISTORY.md`, with the two oldest counts links, each
   replaced by a pointer naming what survives inline and why. 0 dangling `§4`/`§4i` references,
   checked.
