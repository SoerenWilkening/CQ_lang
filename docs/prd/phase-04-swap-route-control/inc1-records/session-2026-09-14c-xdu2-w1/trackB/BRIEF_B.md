# Track B — IMPLEMENTATION brief: the PER-ACTIVATION PROMOTER (bd `xdu2` / L-1a, clause C5)

Worktree `/Users/sorenwilkening/Desktop/CQ_xdu2B`, branch `railbank-promoter` (off `main` `6db48142`).
Records: `$SES/trackB/` **in your worktree**. `$SES` =
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/`;
`$SESP` = `…/session-2026-09-14-orchestrator/`; `$PREV` = `…/session-2026-09-13-orchestrator/`.

**READ FIRST, in this order:** `$SES/PROTOCOL.md` (**binding**), `$SES/DECISIONS.md`,
`$SES/trackA/BRIEF_A.md` **§0 (the staging constraint — it governs you too)**, `CLAUDE.md` (Prime
Directive; Rules 1, 2, 3, 5, 6, 8, **9**, **11**, 12, **13**, **14**, **17**, 19; CORRECTNESS RISK §3
**L1** especially the TAINT-GROWTH species, **L6**), `$SESP/trackL/SCOPE_L1a.md` (**§0 H3 — the
measurement that makes your piece necessary — §2 clause C5, §3(a) the slot, §4.4(D) the `armWritesMemory`
row**), `ir-pass/src/MergePhiPeel.cpp` **and its header in full** (your structural model),
`bd show xdu2`, `bd show b6ap`.

---

## 0. The staging constraint, and what it means for you

Read `$SES/trackA/BRIEF_A.md` §0. Summary as it bears on you: **W1's accept does not land this
session.** Track A ships the classifier whose `Bank` verdict still falls through to `kMsgStore`; you
ship the normaliser. The taint rule, the type rewrite and the D5 allow-list are deliberately deferred.

**Consequence you must verify and state in `IMPL_B.md`:** after your promotion the program still
declines `cq taint escape: tainted value stored to memory` — at the **one surviving store per
activation**, at a possibly different source column. Your observable blast radius is therefore confined
to **programs that decline `kMsgStore` today**, because you fire **only** on an alloca Track A's
predicate recognises as a rail bank (which requires a *tainted stored value*, clause C3). **Measure that
confinement; do not assert it.** A corpus row that moves for any other reason is a FINDING.

---

## 1. What you build, and why the naive thing is wrong

**SCOPE_L1a §0 H3 is the measurement that defines your piece.** bd `xdu2` clause 5 says *"the alloca's
element type is rewritten to the handle type and the `store`/`load` pair carries handles."* **Measured,
that is not sufficient**, because in the raw customer the cell is read **twice** per trip and the second
read is **partially available**:

```llvm
; a_loop_n3.c at -O1 (verbatim, blocks 8 and 14)
8:   %9  = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %5
     %10 = load i8, ptr %9                      ; the SEED  (cell never written yet)
     %11 = trunc nuw i8 %10 to i1
     %12 = tail call zeroext i1 @cq_theta_i1(i1 %11, double 5.000000e-01)
     %13 = zext i1 %12 to i8
     store i8 %13, ptr %9                       ; ← W1 fires HERE
14:  %15 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %5   ; SAME address
     %16 = load i8, ptr %15                     ; handle on the arm edge, SEED on the pred edge
     %17 = trunc nuw i8 %16 to i1
     %19 = select i1 %17, i32 %18, i32 %6
```

A naive element-type rewrite makes `%16` load **`0` as a handle** on the pred edge — and `h0` is a
**real rail** in this runtime. The correct reading of `%16` is **the region's merge φ**.

**So the carve must FORWARD THE CELL TO SSA WITHIN ONE ACTIVATION**, which yields exactly what `-O1`
emits for the equivalent source (`$SESP/trackL/probes/L1_promoted_store.c`, verbatim):

```llvm
10:  %11 = phi i1 [ %9, %8 ], [ false, %4 ]     ; the MERGE φ Track M's leaf grammar wants
     %13 = select i1 %11, i32 %12, i32 %6
     %14 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %5
     %15 = zext i1 %11 to i8
     store i8 %15, ptr %14                      ; EXACTLY ONE store per trip, at the trip's end
```

⚠ **`clang -O1` produced that module from C** — it is the stock `-O1` shape of the same program, **not
a hand construction**. Your job is to move the raw spelling onto it. Everything after the promotion is
SSA and the existing control chain applies unchanged.

**The contract, per activation:**
1. replace the **seed** load with the proven initializer constant;
2. replace every intra-activation load with the dominating store's value — **an SSA merge φ where the
   store is conditional**;
3. leave **exactly ONE** store per activation, at the activation's end.

⚠ **Owner ruling D1** (`$SES/DECISIONS.md`): an uninitialized `bool b0[3];` is admitted, and its
per-cell seed normalizes to the type's **concrete zero at the allocation** — the same rule bd `z9t1`
ships for a scalar `undef` seed (`normalizeUndefRotationSeed`, `RotationLowering.cpp`). So step 1's
"proven initializer constant" is `Constant::getNullValue` for the uninitialized bank too. ⚠ `z9t1`'s
**retirement trigger (ii)** — *the clause rewrites anything that is not `isa<UndefValue>`, or `undef`
stops being uniqued per type* — is load-bearing for the composition; read it (`CLAUDE.md` §4c) and
carry it.

## 2. The slot — and why it makes the round-2 answer TRIVIAL rather than fragile

**Inside the existing `-O1`-repair normaliser fixpoint, `CQLoweringPass.cpp:217-314`** — the
`while (X(M, taint)) taint = propagate(M, wd);` family (`promoteVolatileScalarLocals` `:217-218`,
`promoteFp80Union` `:235-236`, `flattenPredMuxRegions` `:259-260`) — i.e. **before
`detectSpecializations` `:329` and before `declineTaintEscapes` `:338`**. **Mirror it at `:835-892` for
the `runOnFunction` entry point.** Verify both line ranges yourself (Rule 11; they are as of `607b6fe4`).

**Why that slot:** you are a **NORMALISER**, not a lowering (Rule 14 / L6). The idiom re-runs
`propagate` **from scratch** after every change, which is strictly stronger than a taint delta — so
**`adjudicateTaintDelta` is NOT owed** and no consumer guard has run yet.

⚠ **L1's TAINT-GROWTH species is the one to argue with, and you must argue with it explicitly.**
`MergePhiPeel` *manufactures* tainted values ~90 lines **after** the guards that adjudicate consumers of
tainted values, and the cure was `adjudicateTaintDelta` — five plain-C escapes of a rail HANDLE
compiled at exit 0 (bd `b6ap` F-B6-1). Your claim is that the *slot* discharges it. **Prove the slot,
in `IMPL_B.md`, by reading the fixpoint in both entry points and naming every stage between your
insertion point and the first taint consumer.** If any stage in that window reads taint and is not
re-run, you owe `adjudicateTaintDelta` after all.

## 3. Reuse — CALL, never re-derive (Rule 14)

* **Track A's predicate.** You consult `railBankCarveVerdict` / `isRailBankAlloca` (strawman in
  `$SES/trackA/BRIEF_A.md` §1; A publishes the real signature to `$SES/trackA/SIGNATURE.md` in its first
  hour and the orchestrator will relay it). **You never re-derive the carve.** A second spelling of a
  predicate the tree owns is the **drbq Inc-3 (b′) defect**, filed by name. Until A's signature lands,
  code against the strawman behind one adapter function and swap it.
* **Structural model: `MergePhiPeel.cpp`** — a pre-detection NORMALISER, entry gate, collect-then-mutate,
  no in-loop peel, explicit refusals. Read its header in full; it is the closest shipped analogue.
* **Mutation discipline: `QramLowering.cpp:2034-2120`** — collect-then-mutate.
  ⚠ **bd memory `DCE-under-block-iterator-loopphi-uaf`**: an inline `RecursivelyDelete` under
  `make_early_inc_range` crashes across a loop-φ back edge. **Use a collect-then-mutate
  `WeakTrackingVH` worklist.** You are operating inside a loop body; this is your exact hazard.
* **SSA construction.** Do not hand-roll φ placement. LLVM ships `SSAUpdater` /
  `PromoteMemToReg`-adjacent machinery; say which you used and why, and pin the resulting φ shape
  against the `-O1` target above.

## 4. The obstacle that clears itself — verify it, do not assume it

`armWritesMemory` (P10, `MergePhiPeel.cpp:154`, called `:377-378`) **silently refuses to peel**
`if (a>=3) b[i] = cq_theta(...)`, because its arm holds a store; its header `:139-141` says the stage
*"today knows nothing about memory at all"* and *"a merge whose arm WRITES MEMORY belongs to the 7.5
owners"*. **Your promotion runs BEFORE `MergePhiPeel`** (`:217-314` vs `:451`), and after it **the arm
holds no store**, so P10 stops refusing.

⚠ **Verify this by measurement on your subject binary and amend that header** — a header that
contradicts the shipped code is exactly the L7-with-a-twist defect that was ruled wrong three times on
one sentence and kept being read off the source (bd `z9t1`). **Fix the comment in the same change.**

## 5. Rule 12 — fixtures FIRST, red-green

Positives (the promotion happened, pinned on the IR): the rolled array at N=2/3/8; **the promoted-store
shape as a hand-IR pin** (the shape `-O1` emits, pinned so a `clang` bump is visible); `int` cells; the
bank with the value arm deleted; the bank with an unconditional prep; the uninitialized bank (D1).
Negatives: every shape you refuse to promote — and each must mirror its diagnostic
character-for-character **or** be pinned as an explicit no-op (`CHECK` that the store survives
unchanged), never left implicit.

⚠ **A no-op refusal is the vacuity trap.** If your promoter declines to fire, the module is
byte-identical to not having you at all — so a fixture that only checks the unchanged `kMsgStore` pins
**nothing**. Pin refusals against the *promoted* shape's absence **plus** a debug anchor, the same
requirement Track A carries for its `Bank` verdict.

Hygiene: counts in their **own whole-file prefix**; a `DS_Error` decline writes 0 bytes to stdout so
IR-text `CHECK-NOT`s in a decline fixture are vacuous; a bare `-NOT: <word>` can match the module's own
path line (bd `qta2`); run `$PREV/trackM/probes/impl/vacuity.py` over the accept batch; reuse one
`%cq-opt … > %t.cqd0.ll` for extra prefixes (`ir-pass-lit` is SPAWN-bound).
⚠ **A 0-byte `.ll` module ACCEPTS** through the passthrough early-out (bd memory
`empty-module-accepts-vacuity-trap`; the cause was `sed X.s1.ll > X.S1.ll` on a case-insensitive
filesystem). Check your fixtures are non-empty.

## 6. Rule 13 and the attack surface

Four rounds are budgeted for the increment (SCOPE_L1a §6.5); round 1 is scoped to SCOPE_L1a §4's fence
enumeration. You do not run the review. `IMPL_B.md` must hand the reviewer a written **ATTACK SURFACE**:
the mutation you perform stated as a precondition→postcondition pair, the L1 slot proof, every LLVM
utility you called and its preconditions, the `armWritesMemory` measurement, and **the three programs
you think are most likely to be the next hole**.

## 7. Gates you own — PROTOCOL §matrix, do not exceed it

Configure + build once per edit batch; **NEVER `--target CQPass` alone** (false-green trap: 100% pass on
a knowingly broken pass, then 49 reds). Record `shasum -a 256 build/ir-pass/cq-opt` in
`$SES/trackB/GATES.md` after **every** rebuild, in the PROTOCOL line format. Inner loop = `lit --filter`
+ single slices. **ONCE at hand-off:** `ctest -R ir-pass-lit`, one ORACLE-vs-SUBJECT corpus sweep →
`$SES/trackB/probes/corpus_<hash16>.txt`, one injection matrix with MISSED reported. **NEVER** the full
suite, `^e2e-`, the equivalence sweep, or the twin matrix.

⚠ **ORACLE** (frozen, read-only): the primary checkout's `build/ir-pass/cq-opt` sha256
`5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8`, `libCQPass.so`
`5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4`. Verify before your first probe; if
it differs, **STOP and report**. The primary `build/` is READ-ONLY; never relink under a running
measurement; never `pkill` by pattern.

⚠ **Expected corpus movers: NONE in verdict.** Your piece changes IR shape inside programs that decline
either way, so expect **DECLINE→DECLINE with the same string** (possibly a moved `!dbg` column — say so
if it moves; a **lost** `!dbg` is a regression, and 0 lost locations over 2060 decline rows was the
2026-09-14 gate's standard). Any **ACCEPT** row is a FINDING that stops you.

## 8. Deliverables

`$SES/trackB/{IMPL_B.md, GATES.md, probes/}`: the promotion contract as shipped, the L1 slot proof
naming every stage in the window, the `armWritesMemory` measurement + the header amendment, the
SSA-construction choice, the fixture table, the corpus movers (with `!dbg` column deltas), the mutation
MISSED count, the vacuity-check output, and the attack surface.

Commit on your branch (**no push, never touch `main`, never write outside your worktree**), message
`feat(taint): bd xdu2 — …` with the two `CLAUDE.md` trailers. Report back: branch tip, binary hash,
gate lines in the PROTOCOL format, the fixture table, and **anything you could not do**. **Rule 19:
report only what you ran.**
