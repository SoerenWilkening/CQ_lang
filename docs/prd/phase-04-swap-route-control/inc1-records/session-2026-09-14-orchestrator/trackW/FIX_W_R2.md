# Track W — FIX round 2 (bd `wx8g`, session 2026-09-14)

Round 2 returned **CLEAR-WITH-ITEMS**: both round-1 over-ACCEPTs held under every attack, and no new
over-ACCEPT is attributable to this increment. This pass is **one code item + one lifetime narrowing +
four record repairs + three disclosures**.

**Binary.** `1dee47e2` / `cq-opt` `40edde36678c7dd4…` (verified before the first edit) →
**`d47297cfe72e7fa3d47502ecbbeef9ffb62b4db0fa131937b448abcdb254699e`**, `libCQPass.so`
**`55c83c4a1c2d0ec26713c97f3714459cd96fe27238a5815349c9631dd74867c1`**. ⚠ **THE BINARY MOVED**, and
not only because of item 1: the F-W2-4 narrowing (`isa<BinaryOperator>` on the `InPlaceRailOps`
exclusion) and the conjunct-1 anchor test (`getDebugLoc()` → `anchorIsLocated`) are code too. Every
row in `GATES.md`'s round-2 block is `ran:` on `d47297cf` unless it says `cited:`.

**Probes.** `trackW/fix_r2_probes/` — `fx.sh` (the two-TU `llvm-link` 6.5 recipe with `-g`, mirroring
`tests/e2e/run_slice_multi.sh`), `anchor_sweep.sh` + `corpus/` (85 `.c`, the round-2 review corpus
plus this track's own probes, every one compiled `-O1 -g` and run through **both** binaries),
`twins.sh`, `disclose.sh`. Every `.ll` the harnesses produce is `-s`-checked before use.

---

## 1. F-W2-5 — FIXED. The anchorless 2c decline, and it was HALF a class

**What was measured, on `40edde36` (reproduced independently before touching anything):**

```
$ ./fx.sh sub w2i2_h1_round2 w2i2_lib
w2i2_h1_round2|fxsub|DECLINE|… condition predates a non-diagonal gate …|ANCHOR=<unknown>:0:0
$ ./fx.sh ora w2i2_h1_round2 w2i2_lib
w2i2_h1_round2|fxora|DECLINE|… control flow inside a loop body …|ANCHOR=./w2i2_h1_round2.c:16:18
```

**The site, by BREAKPOINT BACKTRACE and not by inference** (`lldb -b`, breakpoint on
`cq::diagnoseUnderControl`, both probes):

```
frame #1  cq::classifyPhaseKickback(...)          ← the 2c wire fence, ArmClassify.cpp
frame #2  cq::detectControlRegions(...)
frame #3  cq::repropagateControlMerges(...)       ← ROUND 2
frame #4  cq::CQLoweringPass::run(...)
```

and the anchor, by the in-tree `CQ_CTRL_DBG` lever: `%3 = icmp sgt i32 %out, 50` — **no `!dbg` at
all**, because `-O1` LICM had hoisted the loop-invariant compare out of the loop and DROPPED its debug
location. `declAnchor` returned it verbatim.

**The fix.** `declAnchor` (`ArmClassify.cpp`) now prefers a **located** anchor, in this order: the
tainted condition → the merge φ → **the region's own `br i1`** → (nothing located) the ORIGINAL choice,
verbatim. It can only fire where the old spelling produced `<unknown>:0:0` or `:0:0`, so no located
diagnostic moves, and it never returns null where the old one returned an instruction
(`diagnoseUnderControl` dereferences its argument).

**⚠ The second failure form is why a null test is half a fix.** A `!dbg` whose LINE IS 0 is non-null
and still prints `file:0:0` — `clang -O1` stamps `!DILocation(line: 0, …)` on merge φs and on promoted
locals' scopes (this probe's own `!30`, `!36`, `!42`). The test is therefore
`static_cast<bool>(DL) && DL.getLine() != 0`, spelled ONCE as **`anchorIsLocated`**, declared in
`ControlPlan.h` beside `diagnoseUnderControl` and defined in `ControlDetect.cpp` (Rule 14 — one owner).
Its second caller is **conjunct 1's own fallback**, which shipped in round 1 as
`Esc->getDebugLoc() ? Esc : I` and was exactly that half-fix.

**Verified, post-fix, on BOTH binaries — `-g`-compiled C, never a hand-written `.ll`:**

| probe (two-TU, `-O1 -g`, `llvm-link`) | SUBJECT `d47297cf` | ORACLE `f7b65d8c` |
|---|---|---|
| `w2i2_h1_round2` | DECLINE `condition predates a non-diagonal gate` @ **`./w2i2_h1_round2.c:18:13`** | DECLINE `control flow inside a loop body` @ `./w2i2_h1_round2.c:16:18` |
| `w2i3_h1_cmpcond` | DECLINE `condition predates a non-diagonal gate` @ **`./w2i3_h1_cmpcond.c:18:13`** | DECLINE `control flow inside a loop body` @ `./w2i3_h1_cmpcond.c:17:15` |

`:18:13` is `if (y > 50) cq_phi(0.3);` — the line the fence is actually refusing and the line the user
has to change.

### 1.1 The class is bigger than the two modules, and it was PRE-EXISTING at that fence

`anchor_sweep.sh` over **85 `-O1 -g` probes × 2 binaries** (single-TU recipe; SUBJECT 59 ACCEPT /
26 DECLINE):

* **SUBJECT unlocated anchors: 1.** **ORACLE unlocated anchors: 5.**
* The four the SUBJECT now locates and the ORACLE does not are all the **same 2c fence**:
  `w_c_compare_invariant` → `:10:42`, `w_e_iterlocal_base_cmp` → `:12:13`,
  `w_f_iterlocal_prep_cmp` → `:11:13`, `w_h_iterlocal_escape` → `:12:13` (ORACLE `<unknown>:0:0`
  on all four). So the anchorless 2c decline **was already reachable on the pre-increment binary** —
  the widening routed more traffic to it, it did not create it — and the repair fixes six modules, not
  two.
* **The one remaining unlocated anchor is a DIFFERENT owner and is identical on the ORACLE**: see §6.

### 1.2 The control that no located anchor MOVED

I did not keep a pre-fix binary, so the control is the reviewer's own recorded SUBJECT anchors on
`40edde36` (REVIEW_W_R2 §7/§8), re-measured on `d47297cf`: `w2a_twoloop_pass_fail` `:18:31`,
`w2a_twoloop_fail_pass` `:8:31`, `w2j_threefn_fail_third` `:19:31`, `w2l_inplace_plus_chain` `:12:20`,
`w2e3_xor_on_rotated` `:9:14` (`cq opcode lowering: operand predates a non-diagonal gate`) — **all five
character-for-character unchanged.** Together with the code (the rungs are unreachable when rung 0 is
located) that is the "nothing regressed" evidence.

---

## 2. F-W2-1 — the `InPlaceRailOps` finality claim and its mis-aimed trigger, RE-STATED

The reviewer is right and the measurement is worse than reported: it is **two** insert sites after
`lowerLoops`, not one. `markInPlaceRailOp` has four call sites; two of them are reached from
`collapseFlattenedLoopRails`, and so is the erase:

| site | function | reached from |
|---|---|---|
| `LoopLowering.cpp:1766` | `emitBreakForward` | `lowerLoops` |
| `:2349` | `tryCaseA` | `lowerLoops` |
| **`:2747`** | `collapseRailPhisIn` | **`collapseFlattenedLoopRails`** |
| **`:3152`** | `commitOutOfLoopInPlaceOps` (via `invariantRegisterRootsImpl`) | **`collapseFlattenedLoopRails`** |
| **`:3479`** (erase) | `invariantRegisterRoots`' rollback | **`collapseFlattenedLoopRails`** |

and `collapseFlattenedLoopRails` runs at `CQLoweringPass.cpp:473` (round 1) **and as the LAST STATEMENT
of `repropagateControlMerges`** (`TaintPropagation.cpp:1816`) — which is its only call in the second
entry point. So the trigger's precondition ("a site after `lowerLoops`") is **already met at HEAD,
twice, one of them at round 2**: a trigger that reads as UNARMED when it is armed, L8 inverted.

**The corrected statement, now in `LoopLowering.cpp`'s `bodyHasSpineDischargeCandidate` header
(verbatim, the operative sentences):**

> **THE SET IS FINAL HERE, BUT NOT FOR THE REASON THIS COMMENT GAVE FOR ONE REVIEW ROUND** … TWO of
> `markInPlaceRailOp`'s four call sites and the one `erase` are reached from
> `collapseFlattenedLoopRails`, NOT from `lowerLoops` … **WHAT IS TRUE, and it is all the exclusion
> needs: the LAST writer is that round-2 `collapseFlattenedLoopRails`, and
> `declineUnmarkedRolledIterLocal` — this predicate's ONLY caller — runs THREE STATEMENTS later in
> BOTH entry points** (`repropagateControlMerges` → `reverifyRailCondReads` → `reverifyCmpCondReads` →
> here: `CQLoweringPass.cpp:489/510/519/532` and `:961/967/970/983`). **THE MARGIN IS THREE STATEMENTS,
> NOT A STAGE.**
> **⚠ RETIREMENT TRIGGER, RE-AIMED AT THAT MARGIN:** a `markInPlaceRailOp` or `InPlaceRailOps.erase`
> site added ANYWHERE BETWEEN the round-2 `collapseFlattenedLoopRails` and
> `declineUnmarkedRolledIterLocal`, or either of those two reordered past the other, makes this read a
> set that is still moving.

The conclusion survives; the margin is three statements.

---

## 3. F-W2-2 — the "by construction" claim was BROKEN, not confirmed

The brief said *break it or confirm it*. **Broken**, and `w2b_sameloop_mixed.c` is the counter-example:
ONE loop carrying BOTH a (b′) grant and a (c) grant, **ACCEPT 22, byte-identical to its hand-unrolled
twin, ORACLE DECLINE** (re-measured on `d47297cf`, §7). Accepting requires (c3) to have held — (c3) is
`iterationLocalTaintEscape(L, Taint) == nullptr`, a **∀ over the whole loop**, not over one register —
while the (b′) carried register is a tainted header φ defined in `L` whose only users (the arm's
`cq_theta`, the merge φ, a `cq_measure`) are all **inside** `L`, and `iterationLocalTaintEscape` has no
φ exemption. **"Carried ⇒ read outside `L`" is not a theorem.** A loop-carried accumulator measured
every trip is an ordinary shape.

**The corrected statement, now at all three sites (`LoopLowering.cpp` conjunct 1, the
`RolledLoopRegionGates` contract in `TaintPropagation.h`, and `FIX_W_R1.md` as an ERRATUM) — the
operative sentences verbatim:**

> **⚠ NOT ASKED OF A (b)/(b′) ENTRY, AND THE REASON IS ABOUT PREMISES, NOT ABOUT WHAT "CARRIED"
> MEANS.** … **THE TRUE REASON — conjunct 1 re-asks a premise that ONLY CLAUSE (c) EVER HAD.** (c3) is
> clause (c)'s own third conjunct, asserted by the classifier at ROUND-1 taint; this is that same
> clause re-asked at FINAL taint, i.e. the L1 PREDICATE discharge for (c) and for nothing else.
> Clause (b′) never asserted (c3). ITS premise is that the rail's header φ will be CLAIMED by the
> round-2 collapse — and that premise has its own round-2 re-ask, namely the collapse itself, which
> declines loudly with `kMsgCrossIter` when the φ is not claimable. Asking (c)'s premise of a (b′)
> entry would be asking a question (b′) never answered.
> The SECOND half of the old sentence is NOT falsified and is kept: asking it there would **also**
> decline every shipped drbq Inc-3 in-loop arm.

The code is unchanged — it was right for a reason nobody had written down. A wrong reason that reaches
a right conclusion is the L7 shape, and that is the whole point of the repair.

---

## 4. F-W2-3 — the one-line scope correction ONLY (the leak itself is its own P1 bead)

Not fixed here, by instruction. The contract sentence *"the record must be at EVERY grant site"* now
reads **"every R7-LOOP grant site"** in `TaintSet::RolledLoopRegionGates`, with the reason attached:

> **⚠ READ "EVERY GRANT" AS "EVERY R7-LOOP GRANT" AND NOT AS "EVERY IN-LOOP GRANT"** — the leak
> mechanism conjunct 2 exists to catch is `markIfRailLocal` REFUSING the marking, and that refusal is
> REGION-INDEPENDENT: its "accumulating loop-invariant tainted input" clause fires with no tainted
> control flow in the module at all. Three measured programs leak 2–4 per-trip template rails against
> their hand-unrolled twins with no record and no re-ask — an in-loop PHASE region 30 vs 38, an in-loop
> 4.4 DATA SELECT 44 vs 48, and a loop with NO tainted control flow whatsoever 16 vs 20 — and all three
> are BYTE-IDENTICAL on the pre-increment ORACLE … **The R7 slice this container covers is a STRICT
> SUBSET of that class.**

Same correction in `FIX_W_R1.md` (conjunct-2 bullet) and `IMPL_W.md` §2.1a.

---

## 5. F-W2-4 — the third level: one NARROWED, one ARGUED, both with triggers

### 5a. `taint.InPlaceRailOps` — **NARROWED (code)**

The new consumer (`bodyHasSpineDischargeCandidate`) used membership to **suppress a safety check**, and
the set is never scrubbed. The narrowing is exact and byte-neutral: **`markInPlaceRailOp` takes a
`BinaryOperator *`** at all four call sites (`LoopLowering.cpp:192`), so every genuine member is a
`BinaryOperator` and a membership hit on anything else **can only be a recycled address**. The exclusion
is now `isa<BinaryOperator>(&I) && taint.InPlaceRailOps.count(…)`.

That closes the half `lowerOps` does not cover. The other half — a recycled address landing on a live
tainted `BinaryOperator` — is covered by the **total disposition the exclusion already rests on**, and I
re-derived it against `OpcodeLowering.cpp` rather than against the comment: `lowerOps` re-asks **every**
`BinaryOperator` member under FINAL taint — (1b) `classifyInPlaceReassignment` for a
`PreLoopCommittedInPlaceOps` member (`:345-357`), the eqpx tripwire
(`inPlaceValueRailOperand` + the `InPlaceRailIdx` agreement) for every other (`:444-461`) — and either
**DECLINES LOUDLY** or lowers the op in place, which mints no rail for the spine to discharge. The
exclusion is right whichever way that re-ask goes. Trigger: a wider type on `markInPlaceRailOp`, or
`lowerOps` ceasing to cover every `BinaryOperator` member.

### 5b. `taint.IterationLocalBlocks` — **ARGUED, and the argument is a measurement**

A false positive needs a **live** `BasicBlock` at the address of an **erased** one, i.e. a BasicBlock
**allocated** between the marking and the read. `RegionFlatten` does erase blocks in that window (both
rounds) — but **nothing in the pass creates one**. Exhaustive scan of the block-creating APIs over
`ir-pass/{src,include,tools}` — `BasicBlock::Create`, `splitBasicBlock`, `SplitBlock`, `SplitEdge`,
`SplitBlockPredecessors`, `SplitCriticalEdge`, `CloneBasicBlock`, `CloneFunctionInto`, `InlineFunction`,
`UnrollLoop`, `simplifyLoop`, `formLCSSA` — finds **exactly four owners**, every one outside the window
in **both** entry points:

| owner | where | vs `declineUnmarkedRolledIterLocal` (`:532` / `:983`) |
|---|---|---|
| `LoopUnrollPrepass` (`UnrollLoop`/`simplifyLoop`/`formLCSSA`) | before `lowerLoops` | **before the first marking** |
| `Specialization` (`BasicBlock::Create` `:483`, `CloneFunctionInto` `:663`, `SpecializeClone:234`) | reached only from `specialize` | `:654` / `:1010` — **after** |
| `BreakReversePlay` (`splitBasicBlock` + `BasicBlock::Create`) | `lowerBreakReversePlay` | `:666` / `:1016` — **after** |

An address freed in the window can therefore only be re-occupied by a non-block allocation, which
`L->blocks()` never yields. No scrub, and a `WeakTrackingVH` would not even apply (it tracks `Value`s;
a `BasicBlock` erase does not null a `SmallPtrSet` key). Trigger, and it is a short list to re-check:
**any block-creating stage moved or added between `lowerLoops` and `declineUnmarkedRolledIterLocal` in
either entry point** ⇒ this read needs a real scrub at `RegionFlatten.cpp`'s erase sites.

⚠ **Not a clean bill for the SET** — see §6 (D-3).

---

## 6. Disclosures — for the orchestrator to file

**D-1 (= F-W2-6) — a NEW CUSTOMER for bd `a3z7`, dated.** `w2c_inplace_rail` is ORACLE DECLINE →
SUBJECT **ACCEPT 14**, and it **DIVERGES from its hand-unrolled twin** at 14 = 14 on the M-C
in-place/out-of-place decision (`cqrt_addc_i32(h1,3)` + `measure(h1)` rolled vs
`cq_template_add_i32_hl(h1,3) -> h3` + `measure(h3)` flat, ×2). **Dated, so it is not this increment's
defect:** the control `w2c_noregion_inplace` (`for (k<2) { q = q+3; s += cq_measure(q); }`, **no control
region at all**) shows the IDENTICAL substitution at 6 = 6 on **BOTH** binaries, and its rolled and flat
traces are **SUB == ORA byte-identical**. bd `a3z7` class B, pre-existing and arm-class-independent. The
ROLLED side is the better circuit here (the flat twin leaves two template rails unreversed), so this is
**not** an over-accept — it is a new customer for a quarantined divergence, and `FIX_W_R1.md` did not
mention it.

**D-2 (= F-W2-7) — `d3`'s residual is an over-DECLINE and is now filed.** Re-measured on `d47297cf`:
`w2g_mut_d3_invread` **DECLINES** on both binaries while its hand-unrolled twin **ACCEPTS at 34** on
both — so under the owner's 2026-09-11 ruling (*"our end-goal is to not decline any code that will lead
to a valid quantum circuit"*) the residual is an **over-decline**, because the twin proves a valid
circuit exists. The one-token sibling `w2g_mut_d1_no_invread` is SUBJECT **ACCEPT 32, twin-identical**
(ORACLE DECLINE), so the fixture's verdict is caused by exactly the token it claims (mutation control,
Rule 12(c)). `FIX_W_R1.md` filed `d4` against bd `1m5p` and did not file `d3`. ⚠ Fixing
`markIfRailLocal`'s refusal (the F-W2-3 bead) retires this too.

**D-3 — NEW, measured here, PRE-EXISTING: the same Rule-1 anchor class at a second owner.**
`w2h_select_inloop_invread` declines `cq loop lowering: loop-carried tainted value crosses iterations`
at **`<unknown>:0:0` on BOTH binaries**. `kMsgCrossIter`'s two emit sites
(`LoopLowering.cpp:2136`, `:2579`) both anchor on a **`PHINode`**, and a loop header φ routinely
carries no `!dbg` (or a line-0 one). **Not fixed here**: it is a fence this increment does not touch,
it is identical on the ORACLE, and the right fallback anchor there is a choice with no measured basis
yet — picking one unreviewed is the kind of widening this project punishes. Filed instead.

**D-4 — NEW, measured here, PRE-EXISTING: §5b's argument does NOT extend to the set's other
consumers.** `taint.IterationLocalBlocks` is also read by `FreePoint` and `Uncomputation`, at
`uncompute` (`:690` / `:1023`) — i.e. **after** `lowerBreakReversePlay` creates blocks — and in the same
relaxing direction (*"a block NOT in this set keeps both guards"*). That exposure is pre-existing and
is recorded rather than silently inherited; a sentence to that effect is in the source beside §5b's
argument so nobody quotes the window proof out of its window.

---

## 7. Gates — every line `ran:` on `d47297cf` unless marked

| gate | result |
|---|---|
| `ran:` binary hash verify BEFORE the first edit | `40edde36678c7dd4…` + `e82fe15c…` — matches the brief exactly |
| `ran:` `cmake --build build -j8` (BOTH targets, never `--target CQPass` alone) | `BUILD exit=0`, 63.8 s → `cq-opt` **`d47297cf…`**, `libCQPass.so` **`55c83c4a…`**. ⚠ The binary MOVED: item 1 is not the only code change (see the header) |
| `ran:` F-W2-5 two-TU `-g` probes, BOTH binaries | `w2i2_h1_round2`: SUB `<unknown>:0:0` → **`./w2i2_h1_round2.c:18:13`**; `w2i3_h1_cmpcond`: → **`:18:13`**. ORACLE unchanged (`:16:18` / `:17:15`, its own earlier decline) |
| `ran:` decline-site identification by `lldb` breakpoint backtrace, both probes | `classifyPhaseKickback` ← `detectControlRegions` ← **`repropagateControlMerges`** (round 2) — measured, not inferred |
| `ran:` `anchor_sweep.sh`, 85 `-O1 -g` probes × 2 binaries | SUBJECT **59 ACCEPT / 26 DECLINE, 1 unlocated anchor**; ORACLE **5 unlocated**. The 4 extra ORACLE ones are the same 2c fence and are now located on the SUBJECT. The 1 remaining is D-3, identical on both |
| `ran:` anchor non-regression control (5 anchors the reviewer recorded on `40edde36`) | `:18:31` / `:8:31` / `:19:31` / `:12:20` / `:9:14` — **all unchanged character-for-character** |
| `ran:` the **8 twin pairs** (+ `w_l`) re-diffed | **9/9 BYTE-IDENTICAL** at 8 / 10 / 12 / 9 / 11 / 27 / 17 / 14 / 22 — identical to IMPL_W §1 and to the round-1 fix record |
| `ran:` K-independence, 5 slices, K=3 vs K=1000, no `-g` | **81/81, 66/66, 85/85, 83/83, 105/105** — identical to IMPL_W §1.2 |
| `ran:` **`ctest -R ir-pass-lit`** (ONCE, as the brief directs) | `1/1 Test #8: ir-pass-lit … Passed 54.41 sec`, `100% tests passed` |
| `ran:` `lit ir-pass/test` (full, for the count) | **1940 passed / 1 expectedly failed of 1941**, 0 failed |
| `ran:` D-1 / D-2 re-measurement on both binaries (`disclose.sh`) | as §6 |
| `cited:` ORACLE-vs-SUBJECT corpus sweep | ⚠ still `95a33b2e` (PRE-FIX, two binaries ago). ⚠ **The merge gate's one sweep per session MUST run against `d47297cf`, not against a cited older binary** — the reviewer's instruction, and it now covers a second binary move |
| **NOT RUN** (brief) | full `ctest -j6`, the `^e2e-` layer, `cq-opt-equivalence-full`, `tools/loop_twin_matrix.py`, a corpus sweep |
