# bd `fn1q` increment 5a — Rule-13 ROUND 3 (independent agent, on the **M4 FIX**, bd `test_C_libtooling-41g3`)

**VERDICT: `CLEAR-WITH-ITEMS` — 0 P1, 3 P2, 7 P3.**

M4 does what it claims where it matters. It restores the ORACLE's verdict, the ORACLE's
diagnostic string **and the ORACLE's whole `CQ_PREDMUX_DBG` gate trace byte-for-byte** on
round 2's P1 exhibit; it closes **four** measured instances of the P1 class, not one; it keeps
the owner's program byte-identical with a byte-identical golden; over all 2155 committed
fixtures the net of increment 5a + M4 against HEAD is **one mover — the increment's own accept
fixture** — and the narrowing on its own is **one mover, the increment's own decline fixture**;
and `lit ir-pass/test` is **2155 / 2154 passed / 1 XFAIL** on a binary I built from the landing
source and whose provenance I checked. **I found no wrong accept, no wrong unitary, no crash,
and no decline that became silence.**

**What it does not do is establish its own stated invariant.** The comment says the arm
admits a rail φ *"ONLY where this flatten will NOT convert it"*. That sentence is false
twice over: `R.Merge` is admitted and **is** converted (F-R3-2), and a **later region's**
flatten converts a φ this region legitimately did not (F-R3-1, measured firing on M4). Both
are closed today — the first by a dominance argument written nowhere, the second by
`collectCondTree` refusing the resulting shape, which round 2 already named *"a downstream
accident, not a fence"*. Neither is a behavioural defect at HEAD. Both are the exact ground
on which the P1 was built, and neither is recorded.

---

## Binaries — `shasum -a 256` re-run immediately before every verdict below

| role | sha-256 (first 16) | what |
|---|---|---|
| ORACLE | `9b9664170fb33f95` | `wt-oracle2`, git HEAD `a9a227e4`, no patch |
| SUBJECT | `5fd7183282ee0d38` | `wt-subject`, HEAD + increment 5a (the DEFECTIVE one) |
| **M4** | **`fe5805a41df2e173`** | `wt-m4`, the subject of this review |
| ASSERTS | `e26fdfed38493013` | `wt-subject/build-asserts`, Debug, DEFECTIVE |
| **PRIMARYSRC** | **`fe5805a41df2e173`** | **my own build of the PRIMARY working tree (the source that LANDS)** — see F-R3-3 |
| INSTR | `41731c01657c562b` | M4 sources + my admission log, `wt-r3-instr-ADMITLOG` |

Every tree I built into is named for what it is (`wt-r3-instr-ADMITLOG`, `wt-r3-PRIMARYSRC`).
I did not build in, write to, or delete the primary `build/`, and I did not touch
`wt-oracle2`, `wt-subject` or `wt-5b`. The only mutation I made to `wt-m4` was **additive**:
copying the increment's three untracked fixtures into its `ir-pass/test/` so `lit` could see
2155 — which is how F-R3-3 surfaced.

**Instrument controls, both directions, run before any row below was believed.**

| control | result |
|---|---|
| A/B harness NULL (M4 vs M4, all 2155) | **0 movers** |
| A/B harness POSITIVE (SUBJECT vs M4 over 22 probes, 4 known rc-flips) | **10 movers, all 4 rc-flips caught, all in the expected direction** |
| admission-log NULL (`env -u CQ_R3_ADMITLOG`) | **0 events** |
| admission-log NULL 2 (a module with no φ) | **0 events** |
| admission-log POSITIVE (`acc_true.ll`) | **2 events, the expected refuse/admit pair** |
| INSTR ≡ M4 (19 probes: rc, stderr, emitted IR) | **19 identical, 0 divergent** |
| fixture-pin mutation NULL (`gate=E3-mergepred` line alone) | **no match (correct)** |
| landing-source build vs M4 | **BIT-IDENTICAL** |

Every sweep got its own `mktemp -d`. I never ran two of mine concurrently against a shared
path. (The orchestrator's `ab5b.sh` was running alongside mine; different scratch, CPU
contention only.)

⚠ **Two of my own instruments lied before they told the truth, and both were caught by their
controls, not by reading them.** (1) My first whole-corpus admission sweep reported **0 events
over 2155** while the positive control fired — `export -f` is a bashism and the login shell is
zsh, so the worker function never existed. (2) My first admission null control was
`CQ_R3_ADMITLOG= <binary>`, which sets the variable to the **empty string**, and `getenv`
returns non-NULL for that — it reported 2 events where it had to report 0. Both re-run with
`env -u` and a real script file. An implausible row re-run is the only reason this report is
not built on a zero.

---

## P2 — `F-R3-1`: the placement conjunct is a **POINT-IN-TIME** property, and a **LATER REGION'S** flatten converts the φ it admitted. Measured firing on M4.

### What the conjunct actually promises

`run()` converts the phis of `(R.InRegion \ {R.Entry}) ∪ {R.Merge}`, unconditionally —
`convertPhis` ends `P->replaceAllUsesWith(Acc); P->eraseFromParent();` with no per-φ escape.
M4 admits when `RPB == S->Entry || !S->InRegion->count(RPB)`. For **the region being claimed**
that is very nearly right (F-R3-2 is the gap). For **the module** it is not right at all,
because `flattenPredMuxRegions` claims **one region per call** inside a
`while (flattenPredMuxRegions(...))` fixpoint, and nothing re-asks E6 about a region that has
already been emitted.

### The measured exhibit — `$S/r3/probes/x3_outer_declines_then_claims.ll`, no block reordering

An outer region **B** holds the rail-φ block **A** as an *interior* block, so M4 correctly
refuses B at E6. A then claims — its φ is at **A's own entry**, which M4 admits — and
flattens. A's terminator is now `br label %Am`, i.e. **unconditional**, so on the next
fixpoint pass B's E6 loop (which only walks *conditional* terminators) no longer sees the rail
φ at all. B claims, and `convertPhis(A)` converts the very φ that A's already-emitted
predicate tree was built from.

| binary | rc | stderr | DBG leaves |
|---|---|---|---|
| ORACLE | 1 | 389 B, `nested control flow under quantum control` | 3 (`entry=entry` E6, `entry=Bt` W-witness, `entry=A` E6) |
| SUBJECT | **0** | **0 B** | none — 66-call circuit, another instance of the P1 class |
| **M4** | 1 | 279 B, `control flow under quantum control` | **2** — `entry=A` is absent, i.e. **region A CLAIMED**, and no further leave prints for B, i.e. **B CLAIMED TOO** |

`leave()` always prints under `CQ_PREDMUX_DBG`, and `recoverRegion` returns false only through
`leave`. M4 prints no leave for `entry=entry` on the second pass, so B was claimed. **The
composition fires on the shipping fix.**

### Why it is P2 and not P1

It lands on a **loud** decline. I could not turn it into a wrong unitary and I believe it
cannot be, analytically: `convertPhis`' RAUW is **value-preserving** (`select(EP, v_i, …)` is a
faithful path-predicated encoding of the φ), so every consumer of the φ keeps its semantics.
The one unsound path — `buildNegation`'s select arm — requires the conversion to happen
**before** the negation, which only ever happens **inside one region's own flatten**. That is
exactly the P1, and exactly what M4 closes. In the cross-region case `buildNegation` already
ran on the raw φ and produced an exact `xor φ, true`; after the RAUW that is
`xor (select …), true`, which `collectCondTree` refuses because it refuses an `xor` with a
constant operand. **That refusal is round 2's "downstream accident, not a fence", verbatim.**

### It also costs an ACCEPT the ORACLE had

`$S/r3/probes/x1_entryphi_converted_later.ll` — same mechanism, forced by block order (block A
textually before its dominator `top`, which decides claim order because the driver iterates
`for (BasicBlock &BB : F)`): **ORACLE rc=0 (66 gate calls), SUBJECT rc=1, M4 rc=1.** An A→D
introduced by increment 5a and not addressed by M4. With natural block order
(`$S/r3/probes/x2_naturalorder.ll`) all three are **byte-identical**, so block order is the
whole trigger and `clang -O1` is unlikely to produce it. ⚠ **I did not verify that the
ORACLE's x1 circuit is correct**, so I cannot say the lost accept was a correct compile.

**Disposition.** Not blocking. Owed: (a) the comment must say *"the flatten CURRENTLY being
emitted will not convert it"*, not *"this flatten will not convert it"*; (b) this is **L1's
shape one stage over** — a premise checked once, falsifiable by a later claim — and CLAUDE.md's
standing cure is to RECORD the question and RE-ASK it after the fixpoint, not to rely on a
downstream grammar; (c) x1/x3 belong in the tree as probes (they are on disk).

---

## P2 — `F-R3-2`: the conjunct is **NOT** the set `run()` skips — `R.Merge` is admitted and **IS** converted

The brief asks whether the conjunct describes **exactly** the set `run()` skips. It does not,
and the gap is one block. I checked both directions.

**Direction "in `InRegion`, not `Entry`, yet NOT converted" — provably empty.** `run()` walks
`R.Topo` skipping only `R.Entry`; `topoOrderRegion` pushes each `InRegion` block at most once
and `recoverRegion`'s tail is `return topoOrderRegion(R);`, which fails the claim unless
`R.Topo.size() == R.InRegion.size()` — so on any claimed region `Topo` is a permutation of
`InRegion`. And `convertPhis` converts **every** φ of the block it is given, with no per-φ
escape (`P->replaceAllUsesWith(Acc); P->eraseFromParent();`). Nothing survives.

**Direction "outside `InRegion` yet IS converted" — exactly `{R.Merge}`.** `recoverRegion`
builds `InRegion` as *"everything reachable from E without crossing Mg"* and explicitly
excludes the merge (`if (B == Mg || !R.InRegion.insert(B).second) continue;`). So
`R.Merge ∉ R.InRegion`, and M4's `!S->InRegion->count(RPB)` disjunct **admits a φ whose parent
is `R.Merge`** — while `run()` calls `convertPhis(R.Merge)` and converts it. That is the P1's
mechanism exactly.

**It is unreachable at the claim scope today, by an argument that appears nowhere in the file.**
E3-sideentry forces every non-entry region block's predecessors into the region and
E3-mergepred forces every `preds(Mg)` into the region — and both run **before** E6. Therefore
every path to `Mg` enters the region at `E`, so `E` dominates `Mg`, so `Mg` dominates no region
block, so a φ defined in `Mg` can never be an operand of a region block's branch condition in
a module that verifies. (`cq-opt` **does** verify its input — measured: an earlier draft of my
x3 probe was rejected with `input module is broken!`, rc=1, on all three binaries.)

**Measured, whole corpus.** I built `INSTR` (`41731c01657c562b`, M4 + an admission log,
behaviourally identical to M4 on 19 probes) and logged every evaluation of the conjunct over
all 2155 fixtures:

```
22 admission-decision events, in 18 distinct modules
  17  isEntry=0 inRegion=1 ADMIT=0     <- the interior φ M4 now refuses
   4  isEntry=1 inRegion=1 ADMIT=1     <- the shipped accept (φ at the region entry)
   1  isEntry=0 inRegion=0 ADMIT=1     <- the ONLY use of the !InRegion disjunct
```

The single `!InRegion` admission is `control_phase_kickback_mergephi_two_leaves_cross_block`,
`phiblk=m1`, `depth=1` — and it is a **W6-witness** scope (`MergeOnly = {Mg}`), not a claim
scope. **Zero corpus modules reach the `R.Merge` cell at a claim scope.**

**W6 is inert for a rail φ on all three binaries, and M4 makes it *more* honest, not less.**
The two W6 scopes share `InRegion` and differ only in `Entry`, so for any φ outside `{Mg}` both
answer the same and `Convertible && !Downstream` is false; for a φ **in** `Mg`, M4 gives
`Convertible = false` (it falls through to `isConvertiblePhiCond`, which a `cq_theta_i1` CALL
incoming fails) and `Downstream = true` (that φ would sit at the entry of the region rooted at
`Mg`) — both honest answers, conjunction still false. On SUBJECT both were vacuously **true**;
on the ORACLE both were vacuously **false**. Measured on `p7_and_tree.ll`: all three decline
the prep region at `gate=W-witness`, and on the committed cross-block fixture all three emit
**identical gate histograms**.

**Disposition.** Not blocking; behaviour is sound today. Owed: state the equality correctly
(`(InRegion \ {Entry}) ∪ {Merge}` is what `run()` converts), record the dominance argument at
the conjunct, and write the **retirement trigger**: *the day `PhiCondScope` carries the merge,
or E3-mergepred / E3-sideentry is relaxed, this disjunct becomes a live over-accept of the P1's
own class.* ⚠ Note the asymmetry that makes this worth writing down: `isConvertiblePhiCond`
reads the **same** `PB == S->Entry || !S->InRegion->count(PB)` test and fails **closed** on it;
M4 reads it and fails **open**.

---

## P2 — `F-R3-3` (process, not code): the review kit's M4 binary was **not built from `wt-m4`'s sources**

```
wt-m4/build/CMakeCache.txt : CMAKE_HOME_DIRECTORY:INTERNAL=.../scratchpad/wt-oracle
wt-m4/build/.../PredMuxFlatten.cpp.o.d : .../scratchpad/wt-oracle/ir-pass/src/PredMuxFlatten.cpp
ls .../scratchpad/wt-oracle : ABSENT
```

`wt-m4/build` was configured against `wt-oracle` — round 2's reused mutant tree, since deleted.
The sources sitting at `wt-m4/ir-pass/src/` are a **copy** that was never compiled, no rebuild
in that tree is possible, and its `lit.site.cfg.py` still points into the missing directory
(which is how I found it: my `lit` run died with `FileNotFoundError`, not with a test failure).
`wt-subject` and `wt-oracle2` are self-consistent; only the review subject is not.

This is the brief's own warning — *"a measurement's inputs are mutable and something else owns
them"* — still half-present in the kit handed to round 3, and round 2's incident was the same
tree.

**Resolved, by building rather than by arguing.** The PRIMARY working tree's
`PredMuxFlatten.cpp` also **differs** from `wt-m4`'s (a much longer comment block, and
`llvm::BasicBlock` → `BasicBlock`), so "the source I read" and "the source that lands" were two
more distinct things. I copied the three primary source files into a fresh worktree named
`wt-r3-PRIMARYSRC`, configured and built it, and the result is **`fe5805a41df2e173` —
bit-identical to M4**, with its own depfile witness pointing inside itself. So: the code
change that lands is exactly the code change I reviewed, and the only difference is comments.

**Disposition.** Nothing to fix in the compiler. Re-point or delete `wt-m4/build`, and record
that a worktree's `build/` must be checked with `CMAKE_HOME_DIRECTORY` before it is quoted — a
matching binary hash does **not** prove which sources produced it, and here it would have hidden
the divergence.

---

## P3 findings

| # | finding | disposition |
|---|---|---|
| `F-R3-4` | **`SelectClassify.h`'s claim is measurably FALSE on M4, and its own `.cpp` forbids the sentence.** The header (`:167`) says a φ it admits *"can still be refused downstream, **with the verdict and the string unchanged**"*; `SelectClassify.cpp:679` says *"say 'verdict preserved', never 'string preserved'"*. Measured on my `x3`: ORACLE `nested control flow under quantum control` → **M4 `control flow under quantum control`**. Round 2's `R5aR2-2` asked for correction *"at all four sites **in the same change as the fix**"*; the fix landed with `PredMuxFlatten.cpp:969` corrected and **`PredMuxFlatten.cpp:956`, `SelectClassify.cpp:672` and `SelectClassify.h:167` not** | **CORRECT ALL THREE.** §4i's *"a corrected record that is not applied to the source is not a correction"* — third round running on this one sentence, and the first with a measured counterexample on the **shipping** binary |
| `F-R3-5` | **`buildNegation` still states the premise the P1 falsified.** `PredMuxFlatten.cpp:4224` (primary): *"a rail φ fails its conditions by CONSTRUCTION, not by accident — **the φ sits at the region ENTRY** (it fails `PB != S->Entry`)"*. The P1 exhibit is a rail φ at a region-**interior** block; M4 exists because that sentence is false. Unchanged by M4, ~3250 lines from the fix, and it is the comment the next editor of `buildNegation`'s rail arm will read | **RE-DERIVE IT AT THE SOURCE.** L7-with-a-twist. The fix is 30 lines of new comment at E6 and none of it reaches the place that taught the wrong model |
| `F-R3-6` | **`cast<PHINode>(V)` is unchecked and its coupling crosses a translation unit.** It is sound only because `isStructuralRailPhi` — in `SelectClassify.cpp`, a different TU — opens `dyn_cast_or_null<PHINode>`. Neither the M4 comment nor `SelectClassify.h`'s declaration says a caller may assume PHINode-ness. `dyn_cast<PHINode>` costs nothing and removes the coupling entirely. The P1 being fixed **was an unchecked `cast<>` in this same function family**, and `F-R3-11` is why no build in this tree could ever catch a third one | **SPELL IT `dyn_cast`, or write the coupling at both ends.** Not a defect today; it is the same class as the thing being fixed, introduced by the fix |
| `F-R3-7` | **The detached-φ spelling inverts safety direction between the two siblings, and the callee's own retirement trigger was not read in that direction.** `PhiCondScope`'s comment tells the next editor that `PB == S->Entry` makes a **detached** φ (null parent) read as *fenced* under a null `Entry` — *"the safe direction (both scopes then answer false and W6 cannot fire)"* — and asks a future refinement to keep that case alive. M4 reuses the identical spelling with the opposite polarity: under the W6 `Convertible` scope (`Entry = nullptr`), `RPB == S->Entry` for a detached φ is **true** and the conjunct **admits**. Unreachable (a terminator-condition φ in a verified module is parented) and M4 does not dereference `Entry`, so the letter of the trigger is met | **STATE THE DIRECTION.** CLAUDE.md's L3-mirror verbatim: *"when you ADD A CALLER to a shared predicate, read the callee's RETIREMENT TRIGGER and state which direction you are using it in"* |
| `F-R3-8` | **The new fixture's gate pin does not identify WHICH region left at E6.** The module prints **two** `gate=E6-condtree` leaves (`br i1 %16` — the rail φ — and `br i1 %14`). Verified by mutation: feeding FileCheck the `%14` line **alone** satisfies the `DBG` directive; null control (`gate=E3-mergepred` alone) correctly does not. The header claims the gate pin proves *"the region was LEFT AT E6, pre-claim"*; it proves *a* region was. If a future change re-opened the P1 while leaving `%14` at E6, the `DBG` half would stay green and only the `not` inversion would carry the fixture | **TIGHTEN TO THE BRANCH.** The needed text (`at:   br i1 %16,`) is already in the output. Both directions otherwise verified by hand: SUBJECT **FAILS** both prefixes at rc=0, M4 and ORACLE **PASS** both at rc=1 |
| `F-R3-9` | **Round 2's L1 clearance rests on a stale, undercounted record.** `PredMuxFlatten.cpp`'s own note — in a paragraph opening *"every line number in the old text was stale"* — says *"there are FIVE `flattenPredMuxRegions` call sites, not two: `CQLoweringPass.cpp:194`, `:218`, `:515`, `:531` and `Specialization.cpp:484`"*. Every one of those numbers is now stale and the count is **SEVEN**: `CQLoweringPass.cpp:374/:398/:427/:1124/:1140/:1158` and **`Specialization.cpp:531`**. The seventh is `lowerCloneControl`'s `claimAll=true` fixpoint, reached from `specialize()` — which runs **AFTER** `detectControlRegions` (`:590`) and **AFTER** `repropagateControlMerges` (`:624`). So round 2's *"all five call sites run strictly before `detectControlRegions`, so PredMux is not inside the round-2 window at all"* is **false as stated** | **RE-DERIVE THE COUNT AND DROP THE LINE NUMBERS.** ⚠ The **conclusion survives**: M4's conjunct asks only block identity, and `isStructuralRailPhi` asks only whether an incoming is a `cq_theta_i1` CALL or an `i1` constant — both taint-stable (Rule 3), so round 2 has no premise to falsify. The only shape that reaches the conjunct inside a clone is the **all-constant** 2-incoming `i1` φ — verified, not assumed: `SpecializeReject.cpp`'s `buildIntrinsicSets` rejects a candidate whose body holds any `taint.{Theta,Phase,Measure}Calls` pointer, so `isCondRailLeaf` can never be true there — and the M4 fall-through handles it correctly. But the *reason of record* is wrong, which is how this file got its last three L7 filings |
| `F-R3-10` | **Round 2's `R5aR2-3` is unfixed, and M4 removes its only known producer without removing the hole.** `buildNegation`'s select arm still does `auto *TC = cast<ConstantInt>(Sel->getTrueValue()); (void)TC;` where `canonicalizePred`'s twin (`:3955`) tests `TC->isOne()`. I re-derived reachability rather than inheriting it: `isSupportedCondTree` admits a `select i1` **only** when `FalseValue` is a zero constant (→ arm 1, correct) or `TrueValue` is one (→ arm 2, correct), so every E6-validated select negates correctly; `select(c, false, X)` and `select(c, X, Y)` are both refused at E6. The **only** producer of a general select at `buildNegation` is a φ that `convertPhis` select-chained inside the same region — precisely what M4 now prevents. So the standing invariant is *"every `i1` φ inside an E6-validated condition tree is either RECORDED (→ boolean algebra) or not converted"*, and **nothing asserts it** | **FIX INDEPENDENTLY**, as round 2 said. M4 turns a live hole into a latent one; that is an improvement and not a closure |
| `F-R3-11` | **Item 8 confirmed, independently.** All four committed **ACCEPT** fixtures abort under `+Asserts` (rc=**134**): `loop_carried_handle_accept_narrow_width` → `All operands to PHI node must be the same type as the PHI node!`, and `spec_accept_qrom_read_arm_{coherent_escape,provable_index,two_tables}` → `Invalid operands for select`. All four are **PRE-EXISTING and unrelated to 5a/M4**: ORACLE and M4 both exit **0** on each and emit **byte-identical** IR. This is the structural reason the whole unchecked-`cast<>` family (round 1's `cast<BinaryOperator>`, round 2's `cast<ConstantInt>`, `F-R3-6`'s `cast<PHINode>`) has no gate in this tree at all | **FILED, NOT 5a's.** A bead is owed: make the four assertion-clean, then a Debug `cq-opt` becomes usable and this family gets caught by construction |

---

## The LOST ACCEPT SURFACE, enumerated (attack item 4) — **it is empty of correct compiles**

The brief asks what C now declines that the defective binary compiled *correctly*, and notes
nobody had enumerated it. Measured, over round 2's six interior φ-incoming variants plus my own:

| φ incomings, at a region-INTERIOR block | SUBJECT | M4 | was SUBJECT's accept correct? |
|---|---|---|---|
| `[%rail, true]` | **ACCEPT** | decline | **NO — this is the P1, a wrong unitary** |
| `[%rail, false]` | decline | decline | n/a |
| `[true, %rail]` | decline | decline | n/a |
| `[false, %rail]` | decline | decline | n/a |
| `[%rail1, %rail2]` | decline | decline | n/a |
| `[true, false]` / `[false, true]` (all-constant) | accept | **accept** | unchanged, byte-identical to the ORACLE |

**M4 loses exactly one accept relative to SUBJECT, and that accept was the silent wrong
unitary.** Every other interior shape SUBJECT already declined — three of them, as round 2
showed, on *wrong predicates* that `collectCondTree` happened to refuse. So the "over-decline"
M4 correctly files is relative to a **hypothetical** correct lowering (record the φ so
`convertPhis` cannot select-chain it), not relative to anything that has ever worked. The
lost-correct-compile surface is **empty** — with the one exception outside the interior
population, `F-R3-1`'s `x1`, whose correctness I did not verify.

---

## What I attacked and did NOT break

* **The P1 itself, and its whole class.** Round 2's exhibit `c13.c` (ordinary `CQ.h` C,
  `clang -O1`, no `volatile`): ORACLE rc=1/115 B, SUBJECT rc=**0**/**0 B**, M4 rc=1/115 B. And
  M4's `CQ_PREDMUX_DBG` gate trace is **byte-identical to the ORACLE's** — same three leaves,
  same order, same offending branches — so M4 does not merely restore the verdict, it restores
  the decision path, with **no claim-then-decline**.
* **The class is closed at the interior position, not just its reachable instance** (attack item
  5). Round 2's six φ-incoming variants at an interior block — `[%rail,true]` (the P1),
  `[%rail,false]`, `[true,%rail]`, `[false,%rail]`, `[%rail1,%rail2]`, and the all-constant pair
  — **every one** returns the ORACLE's verdict **and the ORACLE's string** (`nested control
  flow under quantum control`) on M4. The two wrong-predicate rows round 2 said were *"saved
  downstream"* are no longer relying on that: E6 refuses them before they are built. And the
  `[false,%rail]` / `[%rail1,%rail2]` predicates cannot be reached from the **entry** position
  either, because there `buildNegation` takes the **rail arm** (`xor V, true`, exact) and never
  the select arm.
* **The fall-through (the M3 regression) is genuinely gone.** `v_true_false` and `v_false_true`
  — all-constant 2-incoming `i1` φs at a region-interior block — accept at rc=0 on **all three**
  binaries. This is the case that makes `return false` wrong and the fall-through right, and it
  is real: `isBooleanCondTree` admits an `i1` `ConstantInt`, so `isConvertiblePhiCond` records
  such a φ and `convertPhis` takes the BoolAlg path.
* **Four accept→decline flips, all P1-class.** `p4_jlast`, `p6_nomeasure`, `p9_twofunc` (round
  2's) and my `x3` all go SUBJECT rc=0 → M4 rc=1. Every M4 decline in this review is loud,
  non-zero and carries a diagnostic; **I found no decline that became silence.**
* **The owner's program, end to end, by hand.** `slice_grover_oracle_uncompute.c`: ORACLE
  **rc=1** (so 5a is what makes it compile at all); SUBJECT and M4 both rc=0, **0 bytes of
  stderr**, 130 lowered lines, and the two lowered modules are **BYTE-IDENTICAL**. Stage 2b
  STRICT: `3 verified, 0 violation(s), 0 unproven`. Linked, ran, **88 trace lines, byte-identical
  to the committed golden**. ⚠ I ran the *stages*, not the ctest entry — see MY OWN BOUNDARY.
* **Whole-corpus A/B, both directions, 2155 fixtures.**
  * **ORACLE vs M4** — the net of the entire increment against HEAD — is **1 mover:
    `control_predmux_accept_rail_phi_cond`, RC(1→0), the increment's own new accept fixture.**
    `A→D = 0`, crash-flips `= 0`, IR/stream moves `= 0`, decline-string moves `= 0`.
  * **SUBJECT vs M4** — the narrowing on its own — is **1 mover:
    `control_predmux_reject_rail_phi_interior_convertible`, RC(0→1), the increment's own new
    decline fixture.** The narrowing moves **nothing else in the corpus**, in verdict, string
    or emitted IR.

  ⚠ **A clean A/B on a NARROWING is weak evidence in the accept direction by construction**,
  and this one doubly so: the admission log above shows the shape M4 refuses is reached by 17
  events in the corpus and **none of them was ever an accept**.
* **`lit ir-pass/test` over all 2155, on the landing-source binary** (`fe5805a41df2e173`,
  `wt-r3-PRIMARYSRC`, whose provenance I verified rather than assumed): **2155 discovered,
  2154 passed, 1 XFAIL**, `Testing Time 114.53 s`. ⚠ Quoted with its load per Rule 19: load was
  ~20–36 at the start and **~300** by the end (the orchestrator's own gates came up under it);
  the figure is not comparable with a quiet-box one. This is one fixture **more** than the
  orchestrator's 2154 — theirs predates the new decline fixture landing in the primary tree.
* **W6 (`StrandedCondPhi`).** Proved symmetric for rail φs (the two scopes differ only in
  `Entry`; every branch of M4's conjunct gives `Convertible && !Downstream == false`) and
  measured inert on `p7_and_tree.ll` and on the one committed fixture that reaches it. M4 makes
  both W6 answers **honest** where SUBJECT made them vacuously true and the ORACLE vacuously
  false — the conjunction hid a wrong `Convertible = true` on the defective binary.
* **No vanishing user gate from the conversion.** `convertPhis` erases every φ it converts
  unconditionally, bypassing `sweepDead`'s `isCondRailLeaf || isCondRailPhiShape` exclusion —
  but the rail **call** survives as an operand of the select chain: `x2` keeps its
  `cqrt_alloc_i1` and `cqrt_ry_i1` on all three binaries, byte-identical.
* **The `S == nullptr` path (attack item 2) has no caller.** `isSupportedCondTree` is file-local
  (anonymous namespace, `PredMuxFlatten.cpp:132`–`:4684`); its three top-level call sites
  (`:3177`, `:3178`, `:3294`) all pass a real scope, and every recursive call threads `S`
  through. M4 does change the behaviour of the **default argument** — a null-scope caller now
  falls through to `isConvertiblePhiCond` and **declines** every rail φ, where SUBJECT admitted
  every one — but that is the safe direction and nothing reaches it. Worth one sentence at the
  declaration; not a finding.
* **The new fixture is non-vacuous in both directions**, verified by running FileCheck myself
  rather than by re-reading the prefixes: SUBJECT rc=0 and **FAILS both prefixes**; M4 and
  ORACLE rc=1 and pass both.

---

## ⚠ MY OWN BOUNDARY — what I did NOT do

* **No simulation, no statevector** (Rule 2). Every correctness claim here is analytic or
  trace-level: emitted gate streams, gate histograms, `CQ_PREDMUX_DBG` traces, basis-state
  reasoning about the source.
* **I did not run a full `ctest`**, `e2e-loop-twin-matrix`, the quarantine selftest,
  `free_pairing_check_test.py`, or `cq-opt-equivalence` on any binary. I ran
  `e2e-slice-grover-oracle-uncompute` **by hand** — stage 1, 2, 2b, 3, 4 and the golden diff —
  **not** as the ctest entry and **not** against the primary `build/`, which I left alone as
  instructed. If that entry is red for a **harness** reason, nothing I ran would see it. So:
  **lit green (2155) and the owner's slice green by hand — not "the suite passes".**
* **My first `lit` attempt produced no verdict at all**, dying on `F-R3-3`'s missing config
  path. The green above is from `wt-r3-PRIMARYSRC`, built and provenance-checked by me. I have
  not re-run the orchestrator's `2154 / 2153 / 1 XFAIL`, which I quote as **theirs**.
* ⚠ **My A/B compares exit code, the normalised stderr and the emitted IR. It does NOT
  evaluate any fixture's `RUN`/`CHECK` directives.** "1 mover of 2155" means *no module's
  verdict, message or emitted module changed* — it is not "lit is green".
* **I did not verify that the ORACLE's `x1` circuit is correct**, so `F-R3-1`'s A→D is *an
  accept lost*, not demonstrably *a correct compile lost*.
* **I did not exhaustively prove the cross-region composition (`F-R3-1`) can never yield a wrong
  unitary.** The argument is analytic (RAUW is value-preserving; the unsound negation path is
  intra-region only). I constructed two instances; both decline loudly. A third shape I
  reasoned about but did not build is a **phase** region (a `cq_phi` arm), where
  `AllowLogicalSelect=true` would admit the post-RAUW `select(c, X, false)` as a logical AND —
  I convinced myself the resulting predicate is *correct* (`EP ∧ rail` is exactly what the φ
  meant) but **I did not build it**.
* **I did not build a `+Asserts` binary of M4.** I used the supplied Debug **SUBJECT** for
  `F-R3-11`; its four aborts are pre-existing and I verified that by ORACLE/M4 byte-identity in
  Release, not by a Debug ORACLE.
* **I did not attack increments 3, 4, `cfmv`, or 5b**, and I did not re-derive round 1's or
  round 2's mutant attributions (M2a/M2b). My oracle contains all of those, which is what makes
  the 5a+M4 delta clean, and that is all I used them for.
* **I did not run the injection matrix** over the increment's accept fixtures (Rule 12 hygiene
  (c)); `F-R3-8` is a single hand mutation of one directive, not a matrix.
* **Load and timing.** Load was ~7 when I started and rose to **~20–36** during the sweeps, with
  the orchestrator's own sweep running alongside. **No row above is a timing**, and I re-ran the
  two implausible rows (the 0-event admission sweep; the empty-string null control) before
  recording anything.
* **Everything is on disk and reproducible.** Probes `$S/r3/probes/{x1,x2,x3}*.ll`; harness
  `$S/r3/ab3.sh` + `$S/r3/admit_one.sh`; the corpus admission log `$S/r3/admit_corpus.txt`;
  sweeps `$S/r3/ab_{oracle_vs_m4,subject_vs_m4}.txt`; the instrumented and landing-source trees
  `$S/wt-r3-instr-ADMITLOG` and `$S/wt-r3-PRIMARYSRC` (both named for what they are, both with
  self-consistent `CMAKE_HOME_DIRECTORY`).
* **I have not tried to fool my own instruments beyond the controls tabled above** — one null
  and one positive per harness, plus the INSTR≡M4 equivalence check and the fixture-pin null.

**State of the tree on exit.** All six binary hashes are **unchanged** from the values recorded
at the top of this report, re-run immediately before the verdict. The primary working tree's
`git status` is byte-for-byte the session-start set; I neither built in, wrote to, nor deleted
the primary `build/`. I added two git worktrees, `wt-r3-instr-ADMITLOG` and `wt-r3-PRIMARYSRC`
(both detached at `a9a227e4`), and left them in place so every measurement above is
reproducible; whoever owns cleanup should `git worktree remove` them. The only change I made to
a supplied tree was copying the increment's three untracked fixtures into `wt-m4/ir-pass/test/`
(additive, no source or binary touched).
