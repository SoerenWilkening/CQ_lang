# bd `test_C_libtooling-woa0` — Rule-13 **ROUND B** (independent agent, on `357f2528`, the cross-claim RE-ASK)

**VERDICT: `CLEAR-WITH-ITEMS` — 0 P1, 2 P2, 6 P3.**

I found **no over-accept, no wrong unitary, no crash, no abort and no decline that became
silence.** The fence does what it says in the direction that matters: every module I could
build where a later claim select-chains a recorded rail φ declines loudly, on both the shipped
binary and a `+Asserts` build I made for this review, and the owner's program is byte-identical
across the change on an independently re-derived stage-1.

**What it does NOT do is hold its own central safety sentence.** The source says the fence
*"can neither over-decline a φ that survives nor miss one that does not"* and, one line up,
*"that is the whole reason it cannot be wrong in either direction"*. It **can** be wrong in one
direction, and I have it twice by measurement: a recorded φ whose conversion is provably
harmless because **the emitted predicate tree never read it**. On both spellings the ORACLE
compiles at `rc=0` with 0 bytes of stderr and the SUBJECT declines. That is an A→D by the
2026-09-11 owner ruling, and the same file's own opening non-negotiable —
`PredMuxFlatten.cpp:8-11`, whose clause at `:11` reads *"PredMux can only widen the accept
surface"* — is now measurably false and was **not** corrected by the change that corrected its
sibling header.

---

## Binaries — `shasum -a 256` re-run before any verdict below was believed

| role | sha-256 (first 24) | what |
|---|---|---|
| SUBJECT | `15adcac40d4455a7f2d9f785` | primary `build/ir-pass/cq-opt`, git `90e79229` (= `357f2528` + doc-only commits) |
| ORACLE | `fe5805a41df2e173fdfa572b` | `<S9>/wt-oracle-woa0/build/ir-pass/cq-opt`, git `18d18728`, pre-fix |
| INSTR | `ec14ef9caa628f2855a37263` | `<S9>/wt-woa0-INSTR-COMMITLOG/...`, env `CQ_WOA0_COMMITLOG` |
| MUTANTS | `edc6b21389e6dd9fbeed8277` | `<S9>/wt-woa0-MUTANTS/...`, env `CQ_WOA0_MUT_*` |
| **FIX** | **`c3b7a5961771a56af012d6b4`** | **mine** — `wt-rb-usefix`, SUBJECT source + a ONE-LINE candidate fix (below) |
| **ASSERTS** | **`7125fc972421d65a897589d9`** | **mine** — `wt-rb-asserts`, HEAD, `CMAKE_BUILD_TYPE=Debug -DLLVM_ENABLE_ASSERTIONS=ON` |

`<S9>` = the kit scratchpad named in the brief. All four supplied hashes matched the brief
exactly. My two trees are `git worktree add --detach HEAD` under **my own** scratchpad, each
named for what it is, each configured against itself; I built in neither the primary tree nor
any supplied tree, and I never relinked anything under a running measurement (my builds and my
measurements are strictly interleaved).

⚠ **Load disclosure (Rule 19).** Another agent was sweeping the same corpus concurrently for
the whole session (its harness is visible at `<Smine>/scratchpad/ra/`, which I did not touch).
**No number below is a timing**, and every sweep prints its DENOMINATOR.

**Instrument controls, each run BEFORE the measurement it controls.**

| control | result |
|---|---|
| A/B harness NULL — SUBJECT vs SUBJECT, whole corpus | **`DENOMINATOR=2157 MOVERS=0`** |
| A/B harness POSITIVE — ORACLE vs SUBJECT over 1 known mover + 3 known non-movers | **`DENOMINATOR=4 MOVERS=1`**, the known one |
| A/B harness NULL on the same four | **`DENOMINATOR=4 MOVERS=0`** |
| injection-matrix boundary control 1 — unmutated lowered output | **`ALL-PASS`** |
| injection-matrix boundary control 2 — one injected `cqrt_x` | **FAIL**, `got=7 want=6` |
| commit-log NULL — `env -u CQ_WOA0_COMMITLOG` on the owner's program | **0 events** (`env -u`, never `VAR=`) |
| commit-log POSITIVE — env set, owner's program | **1 event**, `phi=%cq.bank1` |
| MUTANTS NULL — all three env vars unset, on the new accept fixture | **rc=0 and byte-identical to SUBJECT** |
| `+Asserts` build sanity — the four fixtures round 3 named | **all four rc=134**, the two named assertions |

---

## P2 — `F-RB-1`: the fence **over-declines a harmless conversion**, and the change's central safety sentence is false in that direction. MEASURED, two independent spellings.

### The claim under attack

`PredMuxFlatten.h:86-87`, verbatim:

> ⚠ IT OBSERVES, IT DOES NOT PREDICT, and that is the whole reason **it cannot be wrong in
> either direction**: it fires on the SELECT-CHAIN conversion of a φ the record holds, not on a
> re-derivation of where that φ lives.

That sentence is **false**. Its two siblings — `PredMuxFlatten.cpp:5161-5162` (*"it cannot
over-decline a φ that was never converted, and it cannot miss one that was"*) and `CLAUDE.md:1197-1198`
(*"it can neither over-decline a φ that survives nor miss one that does not"*) — are each
literally TRUE and yet answer the wrong question: in both exhibits below the φ **was** converted
and did **not** survive, so both sentences are satisfied, and the decline is still spurious.
That is why the gap survived three careful re-readings.

The inference has a gap. *"A recorded φ was select-chained"* and *"a recorded φ that an emitted
predicate tree actually READS was select-chained"* are different predicates, and the record
holds the **first**. `R.RailPhiLeaves` is populated at the **E6 ADMISSION**, i.e. for every rail
φ that appears in any in-region conditional terminator's condition tree. `RegionFlattener::run()`
only materialises an edge predicate **lazily**, from `convertPhis` → `edgePred` → `literal`. If
no merge φ ever needs one, **no predicate referencing the rail φ is ever emitted** — and the φ
is then left DEAD but ALIVE, because `sweepDead`'s `isCondRailLeaf || isCondRailPhiShape`
exclusion refuses to erase it. A later claim's `convertPhis` then performs a **vacuous RAUW on a
use-empty value**, and the fence declines the module for it.

### Spelling 1 — degenerate merge phis (`rb3_recorded_but_unread.ll`)

Region `A` (entry `%A`, merge `%Am`) claims on the `NumMergePhis >= 2` witness; both merge phis
have IDENTICAL incomings, so `convertPhis`' own `if (In[I].second == Acc) continue;`
short-circuit fires and `edgePred` is never called. Then the outer region claims and
`convertPhis(%A)` converts `%rp`.

```
$ORACLE  -passes=cq-lowering -S rb3_recorded_but_unread.ll -o rb3.ORACLE.ll   -> rc=0, stderr 0 B
$SUBJECT -passes=cq-lowering -S rb3_recorded_but_unread.ll -o /dev/null       -> rc=1
   error: … cq controlled lowering: emitted predicate tree's rail phi converted by a later flatten
$FIX     -passes=cq-lowering -S rb3_recorded_but_unread.ll -o rb3.FIX.ll      -> rc=0, and
   diff rb3.ORACLE.ll rb3.FIX.ll  -> IDENTICAL
```

The probe **contains the shape its name claims** (bd `46oo` discipline — read from the DBG
trace, not the verdict):

```
$ CQ_PREDMUX_DBG=1 $SUBJECT … rb3_recorded_but_unread.ll
CQ_PREDMUX_DBG: leave @probe entry=entry merge=Bm gate=E6-condtree at:   br i1 %rp, …
CQ_PREDMUX_DBG: leave @probe entry=Bt   merge=A  gate=W-witness
CQ_PREDMUX_DBG: converted recorded rail phi @probe blk=A phi=%rp
```

The ORACLE's compile is **correct, not merely accepted**: `%rp` is semantically irrelevant in
that program (both arms of `A` produce the same values), the flatten leaves
`%1 = select i1 %0, i32 7, i32 2` / `%2 = select i1 %0, i32 8, i32 3` over a plain compare, and
the emitted stream is two `cq_template_icmp_sle_i32_hl` flags, four `cqrt_copy_i32_controlled`,
four `cqrt_x`, two `_unc` + `cqrt_free`, and three measures. No rail is left dirty by the
conversion because the conversion touched nothing.

### Spelling 2 — a merge with NO phis at all (`rb9_nophi_merge.ll`)

This one needs no degenerate values. Region `A` claims on the **`NestedTainted`** witness (its
arm `%Aarm` ends in a second tainted conditional `br`), and its merge `%Am` has **zero** phis, so
`convertPhis(%Am)` does nothing and — again — no edge predicate is ever built.

```
ORACLE   rc=0 (0 B stderr)   SUBJECT  rc=1 (the new string)   FIX rc=0
diff rb9.ORACLE.ll rb9.FIX.ll -> IDENTICAL
CQ_PREDMUX_DBG (SUBJECT): converted recorded rail phi @probe blk=A phi=%rp
```

### The candidate fix, built and measured rather than proposed

One line, at the observation site in `PredMuxFlatten.cpp`:

```c++
-      if (!BoolAlg && Rec && recordHoldsRailPhiLeaf(*Rec, P)) {
+      if (!BoolAlg && !P->use_empty() && Rec && recordHoldsRailPhiLeaf(*Rec, P)) {
```

`FIX` (`c3b7a5961771a56af012d6b4`) measured:

| check | result |
|---|---|
| `rb3` / `rb9` | **rc=0, lowered module BYTE-IDENTICAL to the ORACLE's** |
| `control_predmux_reject_rail_phi_converted_by_later_claim.ll` | still declines; **both prefixes PASS under real `FileCheck`** (main and `DBG`, run by hand, not re-read) |
| `control_predmux_accept_recorded_railphi_boolalg_converted.ll` | rc=0, all ten exact counts PASS, byte-identical to SUBJECT |
| owner's `example/grover/grover_oracle_uncompute.c` and `tests/e2e/slice_grover_oracle_uncompute.c` | rc=0, 0 B stderr, **byte-identical to the ORACLE's** |
| whole-corpus A/B, **SUBJECT vs FIX**, 2157 fixtures | **`DENOMINATOR=2157 MOVERS=0`** |

⚠ **Read that last row the right way round.** `MOVERS=0` says the gate has **no corpus
customer** — which is exactly why the implementer's clean A/B could not have found `F-RB-1`,
and it is the same caveat their own §5 attaches to their sweep. It is evidence the candidate
fix is inert on everything shipped, **not** evidence that the class is empty: the class is
"a recorded φ the emission never read", the census shows all five committed commits are φs the
emission DOES read, and the two exhibits are hand-written.

⚠ **It is a CANDIDATE, not a recommendation I have cleared.** `use_empty()` is the exact
predicate for the two spellings above and it is **not** the general one: a recorded φ read only
by an emitted predicate that is itself already dead would still have a use and would still
fire. The principled version is to commit at the E6 admission only those φs the **emission
actually read** (i.e. record from `literal()`/`edgePred`, not from `isSupportedCondTree`), which
is a bigger change and owes its own Rule-13 round. I did not run `lit` on `FIX`.

### The corrections owed **at the source**, and one of them is in the file this change edited

1. **`PredMuxFlatten.h:86-87`** — *"it cannot be wrong in either direction"* is false. It cannot
   **miss** a select-chain conversion; it **can** over-decline one that was harmless. Say which.
   The two sibling sentences (`PredMuxFlatten.cpp:5161-5162`, `CLAUDE.md:1197-1198`) are literally
   true and should be re-scoped to say *"it cannot miss"*, because as written they read as a
   two-sided guarantee and are quoted as one.
2. **`PredMuxFlatten.cpp:11`** — the file's opening non-negotiable — still reads *"Over-declining
   stays safe; PredMux can only widen the accept surface, never replace a decline with
   silence."* The second clause is still true. **The first is now measurably false** and this is
   the very file whose sibling header the change corrected *"because a correction not applied to
   the source is not a correction"*. L7-with-a-twist: one of two headers was fixed.
3. `CLAUDE.md:1195-1200` (§4j) carries the same framing.

### Reachability, stated honestly

Both spellings are **hand-written IR**, like the committed decline fixture, and I could **not**
produce either from `CQ.h` C at the `-O1` floor: `clang -O1` folds a degenerate `if (c) x=2;
else x=2;` and deletes an arm with no observable effect, which is exactly what both spellings
need. So this is an A→D **on valid IR that `cq-opt` verifies**, not a demonstrated lost C
compile. It is still a defect by the 2026-09-11 ruling, and the record's claim that the fence
cannot over-decline is false independently of reachability.

**Disposition.** Not blocking. Land the correction at all three sites in the same change as any
fix (L7). Take the `use_empty` gate only with its own probe family, or do the principled
record-at-emission version.

---

## P2 — `F-RB-2`: the new ACCEPT fixture's *exact-count stream pin* is **6 of 12 vacuous** to injection — including `cqrt_rz`, `cqrt_cnot` and `cqrt_cswap`

`control_predmux_accept_recorded_railphi_boolalg_converted.ll` is the tree's **only** witness for
the `!BoolAlg` conjunct, and for THAT purpose it is sound — I re-measured it independently:

```
MUTANTS, all env unset, on the fixture          -> rc=0, byte-identical to SUBJECT   (null control)
CQ_WOA0_MUT_NOBOOLALG=1, same fixture           -> rc=1, "… rail phi converted by a later flatten"
CQ_WOA0_COMMITLOG=1 (INSTR), same fixture       -> commit fn=probe phiblk=J phi=%cphi entry=J merge=Am
env -u CQ_WOA0_COMMITLOG (INSTR), same fixture  -> 0 events
```

So the file genuinely RECORDS and genuinely CONVERTS, and the conjunct is what keeps it an
accept. That half of §6 of `MEASUREMENT_WOA0.md` reproduces exactly.

**The other half does not.** Its header asserts *"⚠ THE COUNTS ARE EXACT AND ARE THE
ASSERTION"*, and cites round-1's F3 (a sibling fixture measured **7 of 8 vacuous** by an
injection matrix). No injection matrix was run on this one. I ran one — twelve single-line
injections into the lowered output, then the file's own ten `grep … | count N` RUN lines plus
both `FileCheck` prefixes, exactly as lit would:

```
DENOMINATOR = 12 mutations
CAUGHT  = 6   (ry_i1_extra, free_extra, measure_extra, alloc_i1_extra, toffoli_extra, copy_i32_ctrl_x)
MISSED  = 6   (rz_i1, cnot, cswap, copy_i1_ctrl, template_add_hl, template_xor_qq)
```

The module's emitted families are `alloc_i32 · free · x · copy_i32_controlled · toffoli ·
alloc_i1 · icmp_sgt_i32{,_hl}{,_unc} · measure_i32 · ry_i32 · ry_i1 · measure_i1`. It contains
**no** `cqrt_rz`, `cqrt_cnot` or `cqrt_cswap`, and its `NEG` prefix names none of them — so an
injected phase gate, an injected CNOT and an injected Fredkin all pass the whole file. The
sibling it was modelled on, `control_predmux_accept_rail_phi_cond.ll`, counts `cqrt_cnot` and
carries `NEG-NOT: cqrt_rz`; this one dropped both. `cqrt_rz` is the single family CLAUDE.md
flags hardest (§0: a restored tensored Rz is what made every shipped Grover golden the
identity).

**Disposition.** Add `NEG-NOT: cqrt_rz`, `NEG-NOT: cqrt_cnot`, `NEG-NOT: cqrt_cswap`,
`NEG-NOT: cqrt_copy_i1` and an exact `cq_template_` family count, then re-run the matrix and
record the MISSED count in the header (Rule 12 hygiene (c) — *validate by mutation, record the
MISSED count, not by re-reading the prefixes*). Note the file's own retirement trigger says
*"re-derive this file from scratch"*, so the counts will be read as a complete stream pin by
whoever does that.

---

## P3 findings

### `F-RB-3` — the stated PRE-FENCE MECHANISM is measurably FALSE on the committed module: there is no `xor`

Six places say the composition *"landed on a loud decline ONLY because `collectCondTree` refuses
the resulting `xor`-of-`select`"*: the commit message, `PredMuxFlatten.cpp:1053`,
`CQLoweringPass.cpp:447`, the decline fixture's header (`:24`), `MEASUREMENT_WOA0.md` §1, and
`CLAUDE.md:1187` (§4j). Measured on the ORACLE, on the committed fixture's own module:

```
$ CQ_SPEC_DBG=1 $ORACLE -passes=cq-lowering -S control_predmux_reject_rail_phi_converted_by_later_claim.ll
  …
  %0 = and i1 %c, %c2
  %1 = select i1 %0, i1 %b, i1 false      <- the converted rail phi
  %2 = select i1 %1, i32 2, i32 5         <- a 4.4 DATA select
  %3 = select i1 %1, i32 3, i32 6
  %4 = icmp sle i32 %q, 9                 <- the negation, folded onto the COMPARE
  …
error: … cq controlled lowering: control flow under quantum control
```

**There is no `xor` anywhere in the post-flatten module**, on either binary, and the same holds
for the incoming-order-swapped twin (`rb5`, which produces a byte-identical post-flatten module
because `convertPhis`' *"¬c IS AN ARM SWAP, NOT AN `xor` NODE"* fold normalises it). Feeding that
exact post-flatten IR back in by hand (`rb4`) reproduces the decline, so the owner is reached
from the flattened module — and the only off-grammar node in it is a **`select i1` condition on
a 4.4 DATA select**, which `SelectClassify` refuses because the data-select grammar does not
carry `AllowLogicalSelect`. Round 3's F-R3-1 text (*"buildNegation already ran on the raw φ and
produced an exact `xor φ, true`"*) is what the six sites inherited; it does not describe this
module.

⚠ The fixture's **retirement trigger is unaffected and I checked it rather than assuming**:
substituting the boolean-algebra residue `%1 = and i1 %0, %b` into that same post-flatten module
(`rb8`) gives **rc=0 on both binaries**, so bd `41g3`'s route really would turn this file into an
accept.

**Disposition.** Correct the mechanism at all six sites (it is the sentence the next agent will
grep for), or say *"the downstream owner was `SelectClassify`'s data-select grammar"*, which is
what is measured.

### `F-RB-4` — the PRE-EMPTIVE slot MASKS a genuine source-level decline. Constructed.

The implementer's item 5 records *"measured 0 such cells in the corpus; not proved absent"*.
Here is one. `rb6_preempt_escape.ll` = the committed decline fixture plus one line,
`store i32 %q, ptr @g` in the merge block:

```
ORACLE   rc=1  error: … cq taint escape: tainted value stored to memory
SUBJECT  rc=1  error: … cq controlled lowering: emitted predicate tree's rail phi converted by a later flatten
```

`LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`), so the Rule-3 violation the
user must actually fix is **never reported**; they are shown an internal PredMux message with
`<unknown>:0:0`. Both are declines, so this is a diagnostic-quality regression, not a
correctness one — but it is the acknowledged risk, now exhibited. (`rb7` is the same experiment
on the `F-RB-1` module; there the `FIX` binary restores the escape message, which is a second,
independent reason to prefer not firing on a harmless conversion.)

⚠ **And the debug lever you would use to diagnose this fence is disabled by it.** The re-ask sits
immediately BEFORE the `CQ_SPEC_DBG` module dump, so on exactly the modules the fence fires on:

```
CQ_SPEC_DBG=1 $ORACLE  … x3 | grep -c CQ_SPEC_DBG  ->  1
CQ_SPEC_DBG=1 $SUBJECT … x3 | grep -c CQ_SPEC_DBG  ->  0
```

**Disposition.** Move the re-ask **below** the `CQ_SPEC_DBG` block (a pure env-gated dump, no
behaviour) so the lever survives; that costs nothing and keeps the ownership argument intact.
The masking of `declineTaintEscapes` is an owner question, not mine to settle: it is the price
of the ownership the slot buys, and it should be written down rather than left as "0 cells
measured".

### `F-RB-5` — `AtFn`'s window is UNDERSTATED and the retirement trigger names the WRONG null failure mode. The conclusion survives.

`PredMuxFlatten.h:110` says *"Its window is the few statements between the conversion and
the re-ask"*. It is not. The window is the remainder of the **current** flatten call, then the
rest of the top-level PredMux fixpoint, then the entire `unrollConstTripLoops` fixpoint with its
nested PredMux fixpoint, then the entire `recognizeCtlzIdiomLoops` fixpoint with its nested
PredMux fixpoint — potentially hundreds of claims and re-propagations, which the same comment
block elsewhere (correctly) calls out as *"threaded through all THREE fixpoints"*.

**The conclusion is nevertheless sound and I verified it rather than inheriting it:**

* `PredMuxFlatten.cpp` has 7 `eraseFromParent()` sites; every one is an `Instruction` or a
  `BasicBlock`. No `Function` mutation of any kind (`deleteBody`, `removeFromParent`, list
  splice) appears in the file.
* `TaintPropagation.cpp` has 4; all `Instruction`, and all in `foldIdentityBitcasts` /
  `declineTaintEscapes` / `deleteGlobalPhases` / `liftOneRegisterMergePhi` — none of which is
  reachable from `propagate()`, whose body is `resolveSources` + `collectAndSeed` +
  `propagateWorklist`. The comment's *"`propagate` is pure analysis"* holds.
* `CtlzIdiomPrepass.cpp` has 6 `eraseFromParent()` sites, all `Instruction`.
  `LoopUnrollPrepass.cpp` has none of its own and drives LLVM's unroller, which rewrites and
  erases blocks inside one function and never touches the function list.
* `eraseDeadDecls` / `lowerLateReassignments` erase only DECLARATIONS and run long after.
* `AtFn` is always a definition (`D->getParent()` for a block in a claimed region).

**And the `WeakVH` choice is right**, checked against the LLVM 19 header rather than the
comment: `WeakVH` *"nulls itself out if that value is deleted"*; `WeakTrackingVH` is the one that
*"tries hard to point to a Value, even across RAUW operations"*. `AtLoc` is a `DebugLoc` holding
a `TrackingMDNodeRef` to a context-owned `DILocation`, so it safely outlives the φ, and
`promoteRailBankCells` propagates the source φ's `!dbg` onto the manufactured `%cq.bank` φ
(`RailBankPromote.cpp:760`), so the blame location is as good as the source's.

**What IS a defect is the null case.** The trigger says *"the null case then needs a loud
diagnostic that does not take a `Function &`, because returning true without a message is Rule
1's 'third path'"*. The shipped code is

```c++
if (!Rec.Converted || !Rec.AtFn)
  return false;
```

— i.e. a null `AtFn` produces **no decline at all**, which is a strictly worse third path than
the one the comment describes (an observed violation would be silently accepted). Unreachable
today; the comment should describe the code it guards.

**Disposition.** Restate the window as *"three nested fixpoints"* and fix the trigger's null-case
sentence. Both at the source.

### `F-RB-6` — `runOnFunction` returns `false` where every other post-mutation decline in it returns `true`, and the parity comment elides that the two entry points return OPPOSITES

`CQLoweringPass.cpp:1203-1204` is `if (declineConvertedRailPhiLeaves(railPhiRec)) return false;`
under a comment that says *"Same slot by the same argument. See run()."* `run()` returns
`PreservedAnalyses::none()` — "everything changed"; `runOnFunction` returns `false` — "nothing
changed" — after the module has already been flattened, possibly unrolled, and had its ctlz
loops rewritten. The only other `return false` in that function (`:1063`) is the genuine
no-op early-out; the three other post-mutation declines (`:1409`, `:1436`, `:1440`) all return
`true`. Harmless — `Plugin.cpp` registers only `run()`, so the shim has **zero** callers and is
documented as AXIS-F dead — but a reviver inherits a lie.

**Disposition.** `return true`, or one sentence saying why `false`.

### `F-RB-7` — *"the only place in the pass where that conversion happens"* is over-broad

`PredMuxFlatten.cpp:4484` says the `convertPhis` site *"is the only place in the pass where that
conversion happens"* (and `PredMuxFlatten.h:82` calls it *"the only converter"*). Within
`PredMuxFlatten` that is true. Pass-wide it is not:
`MergePhiPeel::peelIndependentMergePhis` (`MergePhiPeel.cpp:568`,
`SelectInst::Create(CondV, TV, FV, "cq.peel.mux", IP)` followed by
`Phi->replaceAllUsesWith(Sel)`) also replaces a φ with a `select`. Its gate `phiPeelable`
(`MergePhiPeel.cpp:261`) asks for exactly 2 incomings over the region's two edges, a muxable
type, a live φ, distinct incomings, no `undef`, and dominance — every one of which an
`isStructuralRailPhi` φ can satisfy. And it runs at `CQLoweringPass.cpp:614` / `:1264`, i.e.
**after** the re-ask at `:456` / `:1203`, so such a conversion is unobserved.

**ARGUED, NOT CONSTRUCTED.** I did not build a module in which the φ a PredMux-emitted predicate
tree reads is also a peelable merge φ, and the hazard there is weaker than the one woa0 fixes
(`buildNegation` has finished by then, so the failure mode is the downstream decline, not the
5a wrong unitary). It is a scope statement, not a hole: say *"the only place in `PredMuxFlatten`"*,
and if the peel is meant to be out of scope, say why.

### `F-RB-8` — G-13: the stated reason the standing pair lands short is not the operative one, and a rolled-vs-unrolled divergence at THIS fence is structurally possible

`MEASUREMENT_WOA0.md` §8 concludes *"The obligation's real target is an accept-direction widening
of a condition fence; this change is decline-direction and adds no accept, which is why the pair
lands short."* The first clause is right. The inference is not, because **the record is
deliberately threaded through the unroll and ctlz pre-pass fixpoints** (`CQLoweringPass.cpp:383 /
:407 / :436` all share one `railPhiRec`, and the comment says so). That is exactly the structure
a rolled-vs-unrolled probe exists to attack: an inner region can record a rail φ on the FIRST
fixpoint, the unroll pre-pass can then make an enclosing region acyclic and therefore claimable,
and the post-unroll claim can convert the φ — a decline the ROLLED spelling never reaches. So
G-13 is **not vacuous here by construction**; it is unreached.

I built **two** such pairs, each differing only in whether the trip count is a constant or the
runtime `%u`: `g13_unrolled.ll` / `g13_rolled.ll` (an in-place `%acc = add %acc, 1`
accumulator) and `g13b_unrolled.ll` / `g13b_rolled.ll` (a non-in-place `mul`/`add` body, written
to get past the 799w/dtzb clause I suspected of blocking the first). **All four decline
identically on both binaries** at `nested control flow under quantum control`, and the
`CQ_SPEC_DBG` dump shows **why**: in both "unrolled" spellings the loop is still there
(`grep -c '^loop:'` = 1 in the post-fixpoint module), i.e. `unrollConstTripLoops` did not claim
it, so the enclosing region stays at `gate=E2-cycle` on every pass and the record is never
re-entered. **Two attempts that did not reach the fence, not a clearance** — the same class of
result the implementer reported for their own pair, and I did not read the U1–U8 fence to find a
loop shape that would qualify.

**Disposition.** Either build a pair whose loop satisfies the U1–U8 fence (then measure), or
record at the source that the record spans three fixpoints and that the rolled/unrolled axis is
open on it.

---

## What I attacked and did NOT break

* **The fence's own job.** Every construction I could make in which a later claim select-chains
  a recorded rail φ declines LOUDLY and non-zero, on SUBJECT and on my `+Asserts` build:
  `x3`, `x1`, `rb3`, `rb9`, `rb13`, `rb6`, `rb10` (two functions). I found **no** conversion of a
  recorded φ that escaped the observation.
* **The `!BoolAlg` exclusion is exactly right and is not a hole.** I re-derived it rather than
  inheriting it. `convertPhis` takes the BoolAlg path only when `P` is `i1` with >1 unique
  incoming block AND (`R.BoolAlgPhis.count(P)` OR every incoming passes `isBooleanCondTree`).
  `isBooleanCondTree` has **no `CallInst` arm** (`PredMuxFlatten.cpp:1260-1300`), so a
  `cq_theta_i1` incoming fails it; and `isConvertiblePhiCond` — the only writer of
  `BoolAlgPhis` — asks the same question of every incoming, so a rail-call-carrying φ can never
  be in that set either. Its placement test `PB == S->Entry || !S->InRegion->count(PB)` is the
  exact **complement** of M4's, so one φ can never be in both sets for one region. The split is
  therefore total: an all-constant structural rail φ → boolean algebra → not flagged; a
  rail-call-carrying one → select chain → flagged.
* **The clone-driver disjointness (bead item 4), verified in code rather than argued.** Both
  `seedClone` (`SpecializeSeed.cpp:40`) and `reseedCloneTaintFromParams`
  (`Specialization.cpp:447`) filter with `I->getFunction() != Clone`, so `ct.Tainted` holds only
  clone-local values; `flattenPredMuxRegions` skips any function with no `isTaintedCtrlTerm`
  under the set it is given, so the `claimAll=true` driver cannot claim outside the clone and
  cannot convert a φ the module record holds. **The residual is real and worth writing down:**
  the module-level record is out of scope after its re-ask, so if that argument ever fails,
  the violation is observed by NOBODY — the clone's fresh record cannot see a module φ. The
  `return false` is the caller's existing decline+retarget path (`Specialization.cpp:856`), the
  same one `Clone.size() != 1` uses, so it is consistent.
* **The re-ask's slot, both entry points.** Nothing runs between the last PredMux fixpoint and
  the re-ask in either `run()` or `runOnFunction`. `flattenPredMuxRegions` has exactly **seven**
  call sites — `CQLoweringPass.cpp:383/:407/:436` (three, one record) and `:1157/:1173/:1191`
  (three, a second record in the dead shim), plus `Specialization.cpp:552` (the clone's own) —
  and **neither** parameter has a default, so a new caller must decide rather than inherit a
  hole. That structural guard is good and I could not get around it.
* **`+Asserts`, item 2 — and the answer is better than "the tree cannot have one".** I built
  one (`7125fc972421d65a897589d9`, ~10 minutes in a worktree) and swept the whole corpus:
  `DENOMINATOR=2157 ABORTS=4`, and the four are **exactly** the four round 3 named
  (`loop_carried_handle_accept_narrow_width` → *All operands to PHI node must be the same type*;
  the three `spec_accept_qrom_read_arm_*` → *Invalid operands for select*). **woa0 adds no new
  abort**: the two new fixtures, all five recording modules, my six probes and the owner's
  program all run clean under it. The `cast<PHINode>(V)` in the M4 conjunct is sound today
  because `isStructuralRailPhi` opens `dyn_cast_or_null<PHINode>` and returns false for a
  non-φ — I re-read both ends; the cross-TU coupling holds, and it is round 3's F-R3-6 (bd
  `4hnu`), not woa0's, since the cast line is unchanged by this commit. So `F-R3-11`'s bead is
  the whole cost of a permanently usable Debug `cq-opt`: **four fixtures**, not a structural
  impossibility.
* **The owner's program, independently re-derived from `.c` rather than taken from the record.**
  `clang -O1 -Iinclude -include CQ.h` on both `example/grover/grover_oracle_uncompute.c` (124
  lowered lines) and `tests/e2e/slice_grover_oracle_uncompute.c` (130): ORACLE, SUBJECT and FIX
  all rc=0 with **0 bytes of stderr** and **byte-identical** lowered modules. And it is a LIVE
  customer, not an inert pass-by: `CQ_WOA0_COMMITLOG=1` gives one `commit … phi=%cq.bank1`,
  `env -u` gives zero.
* **The commit census, re-measured on the family that matters.** `CQ_WOA0_COMMITLOG=1` over all
  289 `control_predmux_*` + `control_phase_kickback_*` fixtures: **5 modules commit**
  (`accept_rail_phi_cond`, `accept_recorded_railphi_boolalg_converted`, `reject_rail_phi_cond`,
  `reject_rail_phi_converted_by_later_claim`, `reject_rail_phi_false_edge`) and **every one is
  the ENTRY-φ cell** (`phiblk == entry`). That independently reproduces §5's *"the `!InRegion`
  disjunct (bd `0fly`) has no commit customer"* for this family, from the other side.
* **`cq-opt` vs stock `opt` + plugin** on both new fixtures: same exit code, byte-identical
  stderr, byte-identical stdout. The first PredMux diagnostic does not break the equivalence
  gate's premise.
* **Whole-corpus A/B, ORACLE vs SUBJECT, all 2157 fixtures:** **`DENOMINATOR=2157 MOVERS=1`**,
  and the one mover is a decline-STRING move on the increment's **own new decline fixture**
  (`control_predmux_reject_rail_phi_converted_by_later_claim`, `control flow under quantum
  control` → the new string). **0 A→D, 0 D→A, 0 IR moves.** That reproduces
  `MEASUREMENT_WOA0.md` §7 exactly, independently. Null control `DENOMINATOR=2157 MOVERS=0`,
  run FIRST; positive control 1 of 4, run second.
  ⚠ My harness compares exit code, stderr and the emitted IR; it does **not** evaluate any
  fixture's `RUN`/`CHECK` directives.
* **The record's containers.** `Leaves` is deduped on commit, never cleared, and a nulled
  `WeakVH` can never match a live `PHINode *`, so a freed-and-reused Instruction slot cannot
  manufacture a decline. The W6 witness scopes construct `PhiCondScope` with three initialisers,
  leaving `RailLeaves` null, so a witness walk records nothing — I checked both
  (`PredMuxFlatten.cpp:3280-3281`) and confirmed the E6 scope (`:3351`, consumed at `:3401`) is
  the only site that records.
* **A cross-claim residue that is IN GRAMMAR downstream.** Round 3 left this unbuilt and I built
  three variants (`rb2`, `rb11`, `rb13`). None produced an A→D: the deep ones die at `branch
  phase condition tree too deep` on BOTH binaries (a boundary control I ran, and which is why
  `rb2`'s "both decline" would otherwise have been meaningless), and `rb13` — where the recorded
  φ IS read and the residue is a depth-1 `select i1 %c, i1 %b, i1 false` — still declines on the
  ORACLE at `control flow under quantum control`. ⚠ That residue **is** acceptable in isolation
  (`rb12_sel`: `br i1 (select i1 %c, i1 %b, i1 false)` over a `cq_phi` arm is **rc=0** on the
  ORACLE, as is the `and` twin), so the class is not closed by grammar — I simply could not
  compose it. **Reported as "I could not construct it", not as "it cannot exist".**

---

## ⚠ WHAT I DID NOT ATTACK

* **No simulation, no statevector** (Rule 2). Every correctness statement here is a verdict, a
  string, a byte-diff, a gate-family count or an analytic argument over the emitted stream.
* **I did not run `ctest`, `e2e-loop-twin-matrix`, the quarantine selftest,
  `free_pairing_check_test.py`, `cq-opt-equivalence-full`, or the e2e slices as ctest entries.**
  I ran `e2e-slice-grover-oracle-uncompute`'s **stage 1 and stage 2 only**, by hand; I did not
  link, run, diff the golden, or run stage 2b. If that entry is red for a harness reason,
  nothing I ran would see it. **So: corpus A/B green and the owner's slice byte-identical
  through stage 2 — not "the suite passes".**
* **I did not run `lit` on any binary**, not on SUBJECT and not on my FIX. My A/B compares exit
  code, normalised stderr and the emitted IR; it does **not** evaluate any fixture's
  `RUN`/`CHECK` directives. "0 movers of 2157" means *no module's verdict, message or emitted
  module changed* — it is **not** "lit is green". I ran `FileCheck` by hand on exactly three
  fixtures (the two new ones and the BoolAlg accept's ten counts).
* **I did not re-run the implementer's whole-corpus commit census.** I reproduced it over 289
  `control_predmux_*`/`control_phase_kickback_*` fixtures and by hand on the owner's program; the
  other ~1870 fixtures I took on their measurement.
* **I did not attack increments 1–5a themselves**, bd `41g3`'s residual, bd `0fly`'s conjunct, bd
  `cfmv`, or 5b. My ORACLE contains all of them, which is what makes the woa0 delta clean, and
  that is all I used them for.
* **I did not build a G-13 pair that reaches the fence** (F-RB-8) — one attempt, and it stopped
  at `E2-cycle` because the unroll pre-pass did not claim my loop. I did not read the U1–U8 fence
  to find a loop shape it would claim.
* **I did not construct F-RB-7's `MergePhiPeel` composition.** The argument is structural: the
  peel creates a `select` from a φ it RAUWs, it can match an `isStructuralRailPhi` shape, and it
  runs after the re-ask. I did not show a module where the peeled φ is one a PredMux-emitted tree
  reads.
* **I did not attack the `{R.Merge}` cell (bd `0fly`) directly.** Round 3 proved it unreachable at
  a claim scope by an E3 argument; my commit census over 289 fixtures reproduces "no `!InRegion`
  commit customer", but I did not try to build one.
* **I did not exhaust the "recorded but unread" class.** I found two spellings (no edge predicate
  built at all). A third — the predicate is built but the whole cone is dead-swept before the
  later claim — would defeat the `use_empty` candidate fix, and I reasoned about it without
  building it.
* **I did not verify `ValueHandleBase::ValueIsRAUWd`'s `Weak` arm** in LLVM's `Value.cpp` (not
  shipped in the Homebrew install). I verified the two classes' documented contracts in
  `ValueHandle.h` and observed that the distinction is immaterial inside the window, because the
  only RAUW of a recorded φ there is `convertPhis`', which erases immediately afterwards.
* **I did not test a host with a non-exiting diagnostic handler.** Every claim about "`opt`
  exits" is inherited from bd `br4a`; the `return false` paths in `runOnFunction` and
  `lowerCloneControl` are only reachable on such a host, and I have not exercised one.
* **Load and timing.** Another agent swept the same corpus concurrently for the whole session.
  **No row above is a timing.** Every sweep prints its DENOMINATOR, every control was run before
  the measurement it controls, and I re-ran nothing on an implausible result because none of my
  rows was implausible — the one that would have been (`ab_null` silent for seven minutes) was
  resolved by reading `ps -o etime`, not by assuming.
* **I have not tried to fool my own harnesses beyond the controls tabled above** — one null and
  one positive for the A/B, two boundary controls for the injection matrix, a null and a
  positive for the commit log, and a null for the MUTANTS binary.

**State of the tree on exit.** The primary working tree is unchanged except for this one file; I
did not build in, write to, or delete the primary `build/`, and every binary hash in the table
above was re-run at the end and is unchanged. I added two git worktrees under my own scratchpad,
`wt-rb-usefix` (the one-line candidate fix) and `wt-rb-asserts` (the `+Asserts` build); both are
detached at `90e79229`, both have self-consistent `CMAKE_HOME_DIRECTORY`, and whoever owns
cleanup should `git worktree remove` them. All probes are on disk at
`<Smine>/scratchpad/probes/rb*.ll`, `g13_*.ll` and `g13b_*.ll`; the harnesses are `ab.sh`, `ab_list.sh`,
`assweep.sh` and `checkfix.sh` beside them.

---

## Appendix — the two `F-RB-1` exhibits, inline

Recorded here rather than only on disk, because a finding recorded without its probe is
not reproducible (bd `5zwz`'s lesson) and my scratchpad is session-scoped. The primary
tree was not otherwise touched, so these are **not** committed as fixtures; whoever acts on
`F-RB-1` should land them as a red-green pair with the fix (Rule 12).

### `rb3_recorded_but_unread.ll` — ORACLE rc=0 / SUBJECT rc=1 / FIX rc=0

```llvm
; rb3 — a rail phi RECORDED at E6 by region A's claim whose
; emitted predicate tree NEVER READS IT (both of A's merge phis are degenerate,
; so `select(EP,x,x)=x` short-circuits and edgePred is never built). The phi
; survives sweepDead only because of the isCondRailPhiShape exclusion. A later
; claim (region B) then converts it.
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)
define i32 @probe(i32 %u) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b  = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c  = icmp sgt i32 %q, 9
  br i1 %c, label %Bt, label %Bm
Bt:
  %c2 = icmp slt i32 %q, 100
  br i1 %c2, label %Bt2, label %A
Bt2:
  br label %A
A:
  %rp = phi i1 [ %b, %Bt2 ], [ false, %Bt ]
  br i1 %rp, label %Aarm, label %Am
Aarm:
  br label %Am
Am:
  %v  = phi i32 [ 2, %Aarm ], [ 2, %A ]
  %v2 = phi i32 [ 3, %Aarm ], [ 3, %A ]
  br label %Bm
Bm:
  %o  = phi i32 [ 7, %entry ], [ %v, %Am ]
  %o2 = phi i32 [ 8, %entry ], [ %v2, %Am ]
  %m1 = call i32 @cq_measure_si32(i32 %o)
  %m2 = call i32 @cq_measure_si32(i32 %o2)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
```

### `rb9_nophi_merge.ll` — ORACLE rc=0 / SUBJECT rc=1 / FIX rc=0

```llvm
; rb9 — the second, non-degenerate spelling of "recorded but never read":
; region A claims on the NestedTainted witness and its merge has NO phis at all,
; so no edge predicate is ever built and the recorded rail phi is unread.
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)
define i32 @probe(i32 %u) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b  = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c  = icmp sgt i32 %q, 9
  br i1 %c, label %Bt, label %Bm
Bt:
  %c2 = icmp slt i32 %q, 100
  br i1 %c2, label %Bt2, label %A
Bt2:
  br label %A
A:
  %rp = phi i1 [ %b, %Bt2 ], [ false, %Bt ]
  br i1 %rp, label %Aarm, label %Am
Aarm:
  %d = icmp sgt i32 %q, 50
  br i1 %d, label %Aa2, label %Am
Aa2:
  br label %Am
Am:
  br label %Bm
Bm:
  %o  = phi i32 [ 7, %entry ], [ 2, %Am ]
  %o2 = phi i32 [ 8, %entry ], [ 3, %Am ]
  %m1 = call i32 @cq_measure_si32(i32 %o)
  %m2 = call i32 @cq_measure_si32(i32 %o2)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
```

### `rb6_preempt_escape.ll` (`F-RB-4`) — the committed decline fixture + `store i32 %q, ptr @g`

ORACLE reports `cq taint escape: tainted value stored to memory`; SUBJECT reports the new
PredMux string and the escape is never seen.

```llvm
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)
@g = global i32 0
define i32 @probe(i32 %u) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b  = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c  = icmp sgt i32 %q, 9
  br i1 %c, label %Bt, label %Bm
Bt:
  %c2 = icmp slt i32 %q, 100
  br i1 %c2, label %Bt2, label %A
Bt2:
  br label %A
A:
  %rp = phi i1 [ %b, %Bt2 ], [ false, %Bt ]
  br i1 %rp, label %Aarm, label %Am
Aarm:
  br label %Am
Am:
  %v  = phi i32 [ 2, %Aarm ], [ 5, %A ]
  %v2 = phi i32 [ 3, %Aarm ], [ 6, %A ]
  br label %Bm
Bm:
  %o  = phi i32 [ 7, %entry ], [ %v, %Am ]
  %o2 = phi i32 [ 8, %entry ], [ %v2, %Am ]
  store i32 %q, ptr @g
  %m1 = call i32 @cq_measure_si32(i32 %o)
  %m2 = call i32 @cq_measure_si32(i32 %o2)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
```
