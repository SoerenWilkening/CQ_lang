# REVIEW — Track P, ADVERSARIAL ROUND 1 (Rule 13), bd `3qps` + bd `4aiu`

**Reviewer:** independent; did not write this code. **Date:** 2026-09-14.
**Verdict: CLEAR-WITH-ITEMS.** No over-ACCEPT and no silent miscompile found. Six items, all
documentation / record-accuracy / hygiene / scope. **Round 2 is warranted** (§8).

---

## 0. FIRST ACT — binary identity (PASS)

```
$ shasum -a 256 /Users/sorenwilkening/Desktop/CQ_phiphase/build/ir-pass/{cq-opt,libCQPass.so}
283e3b3322a9a94c206eb94471e519e5c9e4ffd60c0917743519ae895a0b2daf  cq-opt          == brief
fa563f6941280d3d1dc181116b380621e4bc63108f366f09826a9af004d931c5  libCQPass.so    == brief
$ shasum -a 256 /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/{cq-opt,libCQPass.so}
f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc  cq-opt (ORACLE) == brief
f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d  libCQPass.so    == brief
```

All four match `REVIEW_BRIEF_P_R1.md` character-for-character. Subject worktree at
`98951fa1`, working tree clean. **Every verdict below is a fact about those two binaries.**

Probes live in `trackP/review_r1_probes/` in the MAIN checkout; runner `review_r1_probes/run.sh`
(compiles with `-O1 -g`, refuses a zero-byte stage-1 before measuring — the passthrough-accept trap).
Nothing was written under `ir-pass/ include/ runtime/ tests/ tools/` of either checkout; no build,
no full suite, no corpus sweep, no twin matrix; **one** lit invocation (§7).

---

## 1. The two verdicts the brief asked me to verify independently

### 1.1 Row 9 (`classifyPhaseKickback`'s `Prov` seed, `IsTree` arm) — **CONFIRMED, with a witness**

The record's claim: omitting `for (PHINode *P : Tree.RailPhiLeaves) condProvenance(P, Taint, Prov);`
is "the whole increment's over-accept". I did not take this on the comment. **Witness: probe `r06`.**

```c
int q = cq_theta(0, 0.7);  bool b0 = cq_theta((bool)0, 0.5);  bool r = cq_theta((bool)0, 0.7);
if (b0) { r = cq_theta(r, 0.3); }          /* the arm theta is CHAINED on r */
if (r && q > 3) cq_phi(0.3);               /* phi leaf at an INTERIOR position */
```
```
SUBJECT : r06_chained_tree.c:8:11 … condition predates a non-diagonal gate
ORACLE  : r06_chained_tree.c:8:11 … control flow
```

The decline can come from only one place, and that is read off the measured stage-1
(`r06_chained_tree.s1.ll`): the kickback's `Pred` is block `%6`, whose whole contents are
`%7 = phi i1`, `%8 = icmp sgt`, `%9 = select i1 %7, %8, false`, `br`. **There is no `cq_theta_` call
in `Pred` at all**, so neither `scanForward(%7)` nor `scanForward(%8)` in the `IsTree` positional loop
can fire, and `%7->getParent() == Region.Pred` so the in-`Pred` conjunct passes. The only remaining
decline site for that string is step 6's `condWireDisposition(Region, Taint, Prov, DT)`.

And `%7` enters `Prov` through **no clause but row 9's**: `Tree.RailLeaves` is empty (`b0` is not a
leaf of this tree), and `condProvenance(%8)` reaches only `{%8, %1}` — the `q` wire. Without row 9,
`wireGainsNonDiagonalGate` never looks at `r`'s wire, returns `None`, and the program **ACCEPTS with
the kickback riding a register the chained Ry moved**. Row 9's verdict stands, independently.

Sufficiency, read from `condProvenance`: it walks operand edges and stops at each `cq_theta`, so a φ
contributes `{φ, each incoming theta}` — the same closure step 5c's rung (ii) walks. One closure, two
rungs (L2), as claimed.

### 1.2 Row 20 (`emitCondNetwork`'s `Out.RootIsRail`) — **verdict right, narrative WRONG** (finding F-P1-4)

Unreachable-today: **confirmed, by a stronger argument than the record gives.** `collectCondTree`
records a φ root as a leaf and `continue`s, so `Tree.Nodes` is empty ⇒ `IsTree` false ⇒ the kickback's
`emitCondNetwork` (`SwapRouteEmit:1896`, inside `if (IsTree)`, `CopyRailRoot=false`) is not called.
I enumerated **every** `emitCondNetwork` call site:

| site | tree built by | `AllowRailPhi` | can carry a φ? |
|---|---|---|---|
| `SwapRouteEmit:1896` (flat kickback) | `SwapRouteEmit:1789` | **true** | yes — but only inside `if (IsTree)`, so Root is an `and`/`or`/`xor` node |
| `SelectMergeEmit:291` | `SelectMergeEmit:171` | default **false** | no |
| `SwapRouteEmit:2256` / `:2276` (depth-2 nest) | `SwapRouteEmit:2166/2167` | default **false** | no |

So of the three `isRailFlag` uses in `CondTreeEmit.cpp`, **only the in-walk `FlagOf[V] = V` has a φ
subject.** `CopyRoot` (`CopyRailRoot && isRailFlag(Root)`) and `Out.RootIsRail` have none.

The narrative is off in one more way that understates the unreachability: the record says a φ root
reaching the function "would return `RootIsRail=false` and the kickback would `cqrt_x`-BRACKET the
user's register". It could not — `emitPhaseKickbackRegion` computes
`FlagIsRail = IsTree ? Net.RootIsRail : (RailCond != nullptr || RailPhiCond != nullptr)`, and a φ root
takes the `!IsTree` arm, which never reads `Net.RootIsRail`.

**Rule 7, MEASURED rather than argued** — every shipped φ accept, lowered on the subject binary:

```
$ for f in ir-pass/test/control_phase_kickback_mergephi_*.ll \
           ir-pass/test/control_phase_kickback_rail_after_prep.ll \
           ir-pass/test/control_swap_accept_select_mergephi_*.ll; do … grep -c 'call void @cqrt_x(' …
```
| family | files | `cqrt_x` count |
|---|---|---|
| PHASE kickback φ accepts | 10 | **0, every one** |
| SELECT φ accepts | 11 | non-zero — and on the two NEW ones (`…_tree_leaf`, `…_two_tree_leaves`) every `cqrt_x` targets `%g`, the network's fresh `cqrt_alloc_i1(0)` root ancilla, verified by reading the full gate stream. The prepped registers `%h2`/`%h3` appear only in `cqrt_toffoli` CONTROL slots and are never freed. |

Same result on every probe I generated (r08/r09/r10/r11/r23/r24 traces): zero `cqrt_x`, every user
register left allocated, every ancilla LIFO-restored to `|0⟩` before its free, stage 2b STRICT clean
(`0 violation(s), 0 unproven`) throughout.

---

## 2. The six not-widened rows — reachability, one by one

| row | site | reachable with a φ? | verified how |
|---|---|---|---|
| 8 | step 5b `RailLeaves` loop | **no subject** — a φ is not a `CallInst`; step 5c is the twin and I checked it asks all three rungs | read + r03/r05 measured |
| 10 | `Prov` seed, `!IsTree` arm | **reachable**; for a φ root `Region.Condition` IS the φ, so `condProvenance(Region.Condition)` == `condProvenance(φ)` by construction | read; r05 declines, r09 accepts |
| 12 | wire ternary `RailCond ? rail… : cond…` | **reachable on every φ-root accept**; `RailCond` is a `CallInst *` so a φ falls to the strictly-more-conservative `condWireDisposition`. Both of its extra prongs have a live subject: the cross-block prong is what supplies the in-`Pred` premise for a φ ROOT (`Cond->getParent() != R.Pred → DeclineNow`, `ArmClassify.cpp:2048`), and the positional scan runs the φ→`br` window | read + r05 (DeclineNow), r09 (ProvenPostRegion accepts), r18 (cross-block declines) |
| 13 | `classifyPhaseKickbackNest` | **no subject** — both nest `collectCondTree` calls (detect `ArmClassify:5827/5829`, emit `SwapRouteEmit:2166/2167`) use the DEFAULT `AllowRailPhi=false`, so a φ fails the walk and falls to `recoverRegion`'s loud decline. ⚠ NOTE: I could not reach the nest from C — `-O1` flattens `if (b1) { if (q>3) … }` into the flat `b1 && q>3` tree (probe `r14` is a NEW ACCEPT, 17 lines, which is bd `4aiu`'s intended widening). Row 13 rests on the hand-IR fixture, which does fire | read both call sites + `…_reject_mergephi_nest.ll` exit 1 |
| 14 | `classifyAngleSelect` | **reachable** — probe `r12` (`if (b1) cq_phi(.3); else cq_phi(.7);` on a prep φ) declines `rotation angle`, **byte-identical on both binaries**. See F-P1-2 for its anchor | r12 both binaries |
| 15 | `Specialization.cpp` | **vacuous** — it calls `collectCondTree(SI->getCondition(), Tree)` with default flags, so `Tree.RailPhiLeaves` is always empty and the `!RailPhiLeaves.empty()` conjunct never fires. Track M's defence in depth, still with no subject | read `Specialization.cpp:303` |
| 16/17 | `SelectMergeEmit` re-derivation + `RailLadderProven` backstop | **reachable only in the backstop direction.** The `PrepRegionIdxs` edge forces prep-first, so M-β has turned the φ into a `cq_theta_i1` call and `isCondRailLeaf` fires — `RailLeaves` non-empty keeps row 17 consistent with detection's `!RailLeaves.empty() \|\| !RailPhiLeaves.empty()`. If M-β did not run, the walk fails and the H-1 backstop declines LOUDLY | read |
| 21 | `RegionFlatten`'s φ guard | **still no subject, and I can say why**: all three sites (`RegionFlatten.cpp:107`, `:204`, `:209`) guard on `Cond->use_empty()`, and a φ-conditioned kickback always leaves a live use — the emitted `cqrt_rz_i1(φ, θ)` or the node `cqrt_toffoli`. The implementer's negative counterfactual is consistent with that | read all 3 sites + traces |
| 22/23 | `MergePhiPeel` P7b, `AngleSelectEmit` | no subject (the peel decides about a *merge* φ before detection; `AngleSelectEmit` is reached only through row 14, which refuses) | read |

---

## 3. Findings

### F-P1-1 — IMPL §9.1's stated reason for "at most ONE φ leaf in `Pred`" is FALSE (measured counterexample) · severity: **documentation / record accuracy**, and it is load-bearing

**Claim under review** (IMPL §9.1, and brief item 7): *"at the KICKBACK at most ONE φ leaf can ever
satisfy the in-`Pred` requirement, because two distinct diamonds have two distinct merge blocks."*

**Probe `r07_two_phi_fused.c`.** `-O1` FUSES two same-condition preps into **ONE** diamond whose merge
block carries **TWO** prep φs — bd `b6ap`'s own construct:

```c
if (b0) { b1 = cq_theta(b1, 0.5); b2 = cq_theta(b2, 0.9); }
if (b1 && b2) cq_phi(0.3);
```
```
r07_two_phi_fused.s1.ll:
  br i1 %1, label %2, label %5          ; ONE diamond
5:  %6 = phi i1 [ %3, %2 ], [ false, %0 ]   ; TWO prep phis, ONE block
    %7 = phi i1 [ %4, %2 ], [ false, %0 ]
    br i1 %8, …                              ; the kickback's Pred IS block %5
```

**Both φ leaves are in the kickback's `Pred`.** The stated reason is therefore false as written.

The **conclusion** nevertheless holds, via an invariant the record does not state:
`preppedRailPhiRegionIdx` requires `R.Merge == P`, and a `BranchRegion` has exactly **one** `Merge`
field — so a fused diamond's second φ fails rung 0 whatever its block, and step 5c declines the whole
tree. Today an even earlier fence absorbs the shape (`nested control flow`, **identical on both
binaries**, because `soleMergePhi` refuses a 2-φ merge and the region is never recovered).

**Why it matters.** The false reason is what licenses two design decisions: (a) "the kickback records
NOTHING in `PrepRegionIdxs`", and (b) "the per-leaf `RailPhiLeaves` loop is effectively single-leaf
there today". Both are correct — but a future agent checking them will check the stated reason, find
`soleMergePhi` widened or `MergePhiPeel`'s entry gate relaxed, and conclude the premise still holds
because "two diamonds, two merge blocks" is trivially true. This is L7 exactly.

**Minimal fix (docs only).** Restate the reason as the `R.Merge`-is-one-field argument, and record the
retirement trigger: *the day `soleMergePhi` admits a multi-φ merge, or `MergePhiPeel`'s entry gate
peels an arm-defined incoming, re-derive this — two φ leaves in one `Pred` is a measured shape
(`review_r1_probes/r07`), not a hypothetical.*

### F-P1-2 — the F-P2 `PhiAnchor` repair is LOCAL to `classifyPhaseKickback`; the class re-check is incomplete · severity: **fixture/record hygiene** (Rule 1 diagnostic quality)

The brief asked me to re-check the CLASS, compiled with `-g`. Inside `classifyPhaseKickback` the repair
**is complete** — I enumerated every `diagnoseUnderControl` in the function (lines 5142, 5238, 5266,
5283, 5296, 5303, 5314, 5329, 5337, 5361, 5366, 5451, 5455, 5463, 5491, 5506, 5534, 5552, 5556, 5560,
5631, 5667, 5673, 5695) and checked reachability with a φ ROOT: `Tree.Leaves`, `Tree.RailLeaves` and
`Tree.Nodes` are all empty and `Cmp` is null, so every `declAnchor`-anchored site is vacuous and the
only reachable ones anchor at `BI`, at `PhiAnchor` (== `BI`), or at a gate. **Measured, with `-g`:**

| probe | ORACLE | SUBJECT | location |
|---|---|---|---|
| `r03` measure, φ root | `branch phase on a bare i1 condition` @ **9:9** | `condition measured before the control route` @ **9:9** | preserved |
| `r04` measure, φ tree leaf | `control flow` @ **9:12** | `condition measured before the control route` @ **9:12** | preserved |
| `r05` chained, φ root | `branch phase on a bare i1 condition` @ **8:9** | `condition predates a non-diagonal gate` @ **8:9** | preserved |
| `r06` chained, φ tree leaf | `control flow` @ **8:11** | `condition predates a non-diagonal gate` @ **8:11** | preserved |
| `r15` loop-carried `_Bool` header φ (bd `boi6`) | `branch phase on a bare i1 condition` @ **8:13** | **byte-identical** | F-P2 closed, confirmed on a C spelling |
| `r18` two prep diamonds conjoined | `control flow` @ **10:12** | `condition predates a non-diagonal gate` @ **10:12** | preserved |
| `r13` `(b1 && q>3) ? 2 : 5` | `control flow` @ **11:9** | **byte-identical** | orthogonality intact |

**What the repair does NOT cover**, all measured with `-g`, all **identical on both binaries** (so
none is a Track P regression — but each is a live φ-conditioned construct in the class):

- `r12` — `rotation angle` at **`<unknown>:0:0`**. `-O1` folds the if/else into
  `%6 = select i1 %5, double 3.0e-01, double 0x3FE6…` with **no `!dbg`**, and `classifyAngleSelect`
  anchors there. This is row 14's own subject, and row 14's "measured identical on both binaries
  (`d_angle`, `d_angle_ry`)" was measured with hand-written `.ll` probes, which carry no debug info at
  all — so the location was **structurally unobservable** by that measurement.
- `r16` — the in-place-ARM φ (Track M's pinned F-M3): `control flow` at **`r16_inplace_arm_phi.c:0:0`**.
  Note the form: a *file* with **line 0**, not `<unknown>`. A merge φ can carry a `!dbg` whose
  `DILocation` line is 0 (`-O1` stamps them that way), so step 5c's comment premise — *"a merge φ
  carries no `!dbg`"* — is only half of it; the other half is a line-0 location, and it produces an
  equally unusable message.
- `r22` — a kickback and a data select fused on one prep φ: `control flow` at **`…c:0:0`**.

- **Newly-populated site, unreached but now reachable in principle:** `lowerControlRegions`'
  `declineRegion` anchors on `dyn_cast_or_null<Instruction>(A.Condition)`. Before this increment the
  only region kind whose `Condition` was a φ was `SelectRegion`, which the alias pre-flight cannot see
  (null block fields). A φ-conditioned **`PhaseKickback` has real block fields**, so if
  `sequentialChainAlias` ever refuses one, the module declines at line 0. I could not construct that
  shape and do not claim it is reachable; I claim only that the population is new.

  Conversely, `emitPhaseKickbackRegion`'s `anchor()` is **safe** and the H-1 hardening is what makes it
  safe: it now reads `CondV = BI->getCondition()`, which in the drift case is the live RAUW'd theta
  call (with a real `!dbg`), not the freed φ.

**Minimal fix.** None required for correctness. Record the three residual sites, and record the
structural lesson the increment half-learned: **no hand-written `.ll` fixture in this tree can ever pin
a diagnostic's location**, which is why F-P2 survived 1946 fixtures, a 0-MISSED matrix and a
byte-identical 288-file family. A `-g`-compiled `.c` probe per decline string is the only instrument
that can. (Track P's own `probes/run.sh` already compiles with `-g` — the gap is that the `d_angle`
family was `.ll`.)

### F-P1-3 — IMPL §3's 23-row table is not a complete enumeration; four leaf-enumerating sites are missing, one of which changes the accept shape · severity: **documentation**, with one unargued/unpinned accept

L2's whole method is "enumerate, then decide every row". Reading `ir-pass/src` at the tip, these
leaf-enumerating sites are **not in the table**:

- **(a)** `classifyPhaseKickback` step 5a's `for (CmpInst *Leaf : Tree.Leaves)` — the six per-leaf gates
  (predicate lowerable, Q+Q, `compareFlagMintable`, tainted, i1-operand, in-`Pred`). Correct that a φ
  needs none of them; step 5c is its twin. Unstated.
- **(b)** `condCmpMeasuredBeforeReadPoint(Tree.Leaves, …)` at `ArmClassify:5489`. The φ twin is 5c's
  rung (ii). Unstated.
- **(c)** step 6's `TreeSet` **"condition used outside the branch"** fence (`ArmClassify:5528-5539`).
  `TreeSet` is built from `Tree.Leaves` + `Tree.Nodes` only — **neither `RailLeaves` nor
  `RailPhiLeaves`.** So a φ leaf may have arbitrary out-of-branch data uses. **The asymmetry is
  measured:**

  | probe | shape | verdict |
  |---|---|---|
  | `r25` | a **COMPARE** leaf with a use outside the branch | `condition used outside the branch` @ 9:15 |
  | `r08` | a **φ** leaf with a use outside the branch (`int z = (int)b1 + q;`) | **ACCEPT**, 21 trace lines, 2b STRICT `4 mints / 3 left allocated, 3 free sites: 3 verified, 0 violations, 0 unproven` |

  I read `r08`'s full stream and it is **sound**: the φ's data use lowers to
  `cq_template_zext_i1_to_i32(h2) -> h5; cq_template_add_i32(h0,h5) -> h6` followed by the `_unc` and
  `cqrt_free(h5)`, while the kickback's reads of `h2` are the diagonal `cqrt_toffoli` control and
  nothing else — the register's basis label is never disturbed, so the data use reads the right value.
  It is exactly the sanction step 5b's own header already grants a RAIL leaf (*"its OTHER users are
  ordinary… so the tree-wide 'used outside the branch' fence deliberately excludes rail leaves"*).
  **But it is not stated for a φ, not in the table, and not fixture-pinned.** An accept shape nobody
  wrote down is how the next widening loses it.
- **(d)** `emitPhaseKickbackRegion`'s post-flatten cascade erase — `for (Instruction *N :
  llvm::reverse(Tree.Nodes))` / `for (CmpInst *Leaf : llvm::reverse(Tree.Leaves))`. Correctly NOT
  widened, and the stake is high: erasing a φ leaf here would free the prep region's `Merge` before the
  prep is emitted. Unstated.

**Minimal fix.** Add rows (a)–(d) with their verdicts; state the (c) sanction in step 5b's header
alongside the rail one; add one `ir-pass/test` fixture for the (c) accept (an `r08`-shaped module) so
the shape is pinned rather than incidental.

### F-P1-4 — row 20's hazard narrative is wrong · severity: **documentation**

See §1.2. The `!IsTree` arm of `FlagIsRail` never reads `Net.RootIsRail`, so the stated miscompile
(*"the kickback would `cqrt_x`-BRACKET the user's register"*) could not have occurred through that
field. Two of the three `isRailFlag` uses in `CondTreeEmit.cpp` have no φ subject at all; only the
in-walk `FlagOf[V] = V` is load-bearing. **Fix:** restate; the widening itself is correct and should
stay.

### F-P1-5 — `reverifyRailCondReads` SILENTLY SKIPS a `PHINode` record under a justification that covers only a nulled one · severity: **defence-in-depth / record accuracy** (L1's "no third path")

```cpp
// A NULLED handle is SKIPPED, and the direction is the argument: a read that
// no longer exists is not a live control read …
auto *Rail = dyn_cast_or_null<CallInst>(E.first);
…
if (!Rail || !Read || …) continue;
```

A live `PHINode` is **not** a nulled handle; for it, rungs (ii) and (iii) are simply not re-asked, with
no diagnostic. **This increment is the first to put φs into `RailCondReads`** — `emitKickbackGroup`'s
`markRailCondRead(taint, Ctl, G)` fires because `CtlIsRail` is true for a φ root, and `emitCondNode`'s
`record` was widened to `isCondRailPhiShape`.

**Not reachable today**, and I checked rather than assumed: every `return` in
`emitInPlaceRotationRegion` (`SwapRouteEmit:667…`) is preceded by a `diagnoseUnderControl`, which exits
on the first `DS_Error` (bd `br4a`), and the only structurally silent path
(`!CondI && !MergePhi`) cannot occur for a `BranchRegion` (its `Merge` is always set). So M-β always
runs, the `WeakTrackingVH` follows the RAUW, and `dyn_cast<CallInst>` succeeds.

**Related, same site:** row 19 justifies the shape test with *"over-recording only ever declines more —
`reverifyRailCondReads` re-asks rungs (ii)/(iii) and can only DECLINE more."* That is **false for a
value that stays a `PHINode`**: it records nothing that is ever read. It is harmless in fact, because
`N.L`/`N.R` can only be a `PHINode` when it is a `RailPhiLeaves` member (`FlagOf[V] = V` is the only
path that maps a value to itself), so shape ≡ membership at that site — but the reason given is not the
reason it works.

**Minimal fix.** Split the `continue`: a null handle skips (with today's argument); a **live value of
the wrong type** is a LOUD decline, or at minimum an explicitly-stated third case with the RAUW
premise named as its retirement trigger.

### F-P1-6 — scope: the in-loop φ kickback declines where the in-loop φ SELECT accepts · severity: **over-decline** (file, do not fix here)

`r21`: prep **outside** a bounded loop, `if (b1) cq_phi(0.3);` **inside** it.

```
SUBJECT : r21_inloop_phi_kickback.c:10:13 … condition predates a non-diagonal gate
ORACLE  : r21_inloop_phi_kickback.c:10:13 … branch phase on a bare i1 condition
```

String moves, disposition does not. The SELECT twin is a **shipped accept**
(`control_swap_accept_select_mergephi_inloop_outside_prep.ll`). Same `condWireDisposition`
cross-block family as IMPL §9.1's named over-decline, and it is the shape a rolled Grover phase
kickback on a bool-controlled prep would take — worth filing beside §9.1 rather than inside it.

Also recorded, **pre-existing and identical on both binaries** (not Track P's, but it is the
composition the F-M1 cycle argument is about): `r22` — a kickback and a data select on ONE prep φ
DECLINES, because `-O1` fuses them into a single region carrying both a phase gate and a value merge φ,
and `MergePhiPeel`'s ≥2-φ entry gate does not fire on a merge with exactly one φ. The three-region
chain the record describes (kickback → prep → select) is therefore reachable only in the spellings
`-O1` declines to fuse.

---

## 4. Brief items answered

**Item 2 — flag orthogonality: HOLDS.** `classifySelectRegion:906` still passes
`AllowLogicalSelect=false`; `r13` (`a = (b1 && q > 3) ? 2 : 5;` from plain C) declines `control flow`
at **11:9, byte-identical on both binaries** — on the logical-select NODE, not on the φ.
`isCondRailLeaf` was not widened and `RailPhiLeaves` was not retyped; the element type is still the
enforcement, and `emitCondNetwork`'s `isRailFlag` asks **membership** of `Tree.RailPhiLeaves`, which is
what keeps the three `AllowRailPhi=false` consumers at their `Malformed` decline.

**Item 3 — H-1: the theorem is SOUND, and stronger than stated.** I attacked the argument, not the
hardening, and could not break it:
`P->getParent() == Region.Pred` ∧ `preppedRailPhiRegionIdx(P) = j` ⟹ `P` is `Regions[j].Merge`, which
lives in `Regions[j].MergeBB` ⟹ `kickback.Pred == prep.MergeBB` ⟹ `MergeBB ∈ doomedBlocks(prep)` ⟹ the
`Aliases` test fires ⟹ **either** `sequentialChainAlias` returns true (edge added,
`Precedes[kickback] = {prep}`, kickback emitted FIRST with the φ live) **or** `declineRegion` fires and
the module lowers nothing. There is no third outcome. The in-`Pred` premise is supplied for a TREE by
the new positional loop's `P->getParent() != Region.Pred` conjunct and for a φ ROOT by
`condWireDisposition`'s `Cond->getParent() != R.Pred → DeclineNow` (`ArmClassify.cpp:2048`) — I read
both and measured both (`r18`, `…_reject_mergephi_cross_block.ll`).

**Item 4 — "would close a cycle": TRUE for every kickback, not only the probed ones.** It follows from
the theorem above: the hcrg edge `Precedes[kickback]={prep}` is present for **every** φ kickback that
lowers, so an F-M1-style `Precedes[prep]={kickback}` would always be a 2-cycle. There is no φ kickback
that lowers without the hcrg edge. (I also checked `Precedes` direction at the source:
`Precedes[a].push_back(b)` means *A first*, and `sequentialChainAlias`'s `A.Pred == B.MergeBB` is the
kickback-as-A case.) The `SelectRegion`-is-a-sink argument holds: the F-M1 loop is the only way a
select acquires an edge and every such edge points into it.

**Item 5 — "no taint growth": VERIFIED, not restated.**
`grep -c "Tainted.insert\|adjudicateTaintDelta" /tmp/trackP_src.diff` → **0**. The increment admits an
existing tainted value as a leaf and manufactures none, unlike `MergePhiPeel`. L1's other two premises
checked at source: the plan is fresh per round (`TaintPropagation.cpp:1431`
`ControlPlan plan2 = detectControlRegions(M, wd, taint);`) and round 2 cannot introduce a prep region
(`TaintPropagation.cpp:1653` `if (taint.UntaintedMergeRails.empty()) return;` — a prep diamond's merge
φ is neither a 6.5 nor a 4.5 `%out`).

**Item 7 — the "single-leaf at the kickback" claim:** see **F-P1-1**. Conclusion right, reason wrong,
counterexample measured.

**Item 8 — must keep declining: all sampled, all firing on the subject binary.**

```
control_phase_kickback_reject_mergephi_chained_arm    exit=1  condition predates a non-diagonal gate
control_phase_kickback_reject_mergephi_cross_block    exit=1  condition predates a non-diagonal gate
control_phase_kickback_reject_mergephi_measure_before exit=1  condition measured before the control route
control_phase_kickback_reject_mergephi_nest           exit=1  control flow
control_phase_kickback_reject_mergephi_three_incoming exit=1  branch phase on a bare i1 condition
control_phase_kickback_reject_mergephi_unclaimed      exit=1  branch phase on a bare i1 condition
control_phase_kickback_reject_mergephi_value_arm      exit=1  bare i1 register condition
```
Plus the C spellings: `p5`-class CHAINED arm (`r05`/`r06`) declines on both; the depth-2 nest keeps its
decline (row 13); the Ry-stem angle select keeps `rotation angle` (`r12`, both binaries).

**bd `3d8q` — does it change a verdict here?** No verdict changes, **one note owed.** IMPL §9.3 warns:
*"do not 'fix' [the in-place-ARM φ] by narrowing the φ's rung-(iii) seed to the arm theta alone — that
cone is the only thing refusing the `3d8q` class."* For the shape I could build (`r16`: a second
in-place Ry arm conditioned on a prep φ) that is **not** what refuses it — the region carries no
`cq_phi`, so `classifyPhaseKickback` returns `NotApplicable` and the ARM classifier declines
(`control flow`, identical on both binaries). Track P's rung (iii) is not holding that line for this
spelling, and §9.3 should say which spelling it *is* about. The forward-looking point: **if `3d8q`
lands and flips the in-place-ARM φ to an accept, its region enters the plan as
`ClassArm == InPlaceRotation` with a non-empty `Shadow` — i.e. it starts matching Track P's rung 0** —
and step 5c's ladder becomes the only thing between that new population and a φ kickback accept. Track
P should carry that as an explicit retirement trigger; it currently does not.

---

## 5. Hygiene checks I ran that the record deferred

**L8 duplicate-body scan (IMPL §7.5 defers this to the merge gate — I ran it).** SHA-256 over each
fixture's non-comment, non-blank lines, all 1946 files in the subject worktree:

```
fixtures scanned: 1946   duplicate-body groups: 9
```

**No `mergephi` fixture is duplicated** — the `git mv` of `control_swap_reject_select_mergephi_tree_leaf.ll`
→ `…accept…` is clean and there is no resurrection risk from this branch. The 9 pre-existing groups,
for the merge agent's information (none is Track P's, and at least two look deliberate):

```
control_predmux_reject_selectform_rotation_{hop_chained,poison_arg}.ll
spec_reject_callbr.ll / spec_overaccept_probe_callbr_visible.ll
control_angle_select_reject_cond_{alias,register}.ll
control_swap_diamond{,_derived}.ll
control_inplace_ry_reject_stale_diag_alias_{backward,forward}.ll
control_swap_reject_nested_{inner_clobber,value_mixed}.ll
lowering_measure_round2_sixfive_handle.ll / control_classical_call_arm_accept.ll
control_swap_ifelse{,_derived}.ll
control_angle_select_{phase_constants,rz_cond_register}.ll
```

**Fixture hygiene on the flipped file** (`control_swap_accept_select_mergephi_tree_leaf.ll`): one
`%cq-opt … > %t.cqd0.ll` reused across six `--check-prefix` runs (spawn-frugal, per the Build & Test
note); a full `CHECK-NEXT` chain pinning the whole stream; counts in their own whole-file prefixes
(`FCNT`/`TOFCNT`/`XCNT`) with pure `-NOT` negatives after them — **no Rule-12(a) windowing defect.**
Note that `XCNT-COUNT-2` pins the *count* but not the *target*; the target is pinned by the main
`CHECK-NEXT: call void @cqrt_x(i32 %[[G]])`, which is what makes the `x-on-user-register` mutation
catchable.

---

## 6. Commands (exact, reproducible)

```bash
# binary identity (FIRST ACT)
shasum -a 256 /Users/sorenwilkening/Desktop/CQ_phiphase/build/ir-pass/{cq-opt,libCQPass.so}
shasum -a 256 /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/{cq-opt,libCQPass.so}

# the probe family (SUBJECT), from /Users/sorenwilkening/Desktop/CQ_lang
P=docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackP/review_r1_probes
zsh $P/run.sh $P                      # compiles -O1 -g, refuses a 0-byte stage-1, links + runs

# the same probes on the frozen ORACLE
for f in $P/*.c; do n=$(basename $f .c); \
  /usr/local/opt/llvm@19/bin/clang -Iinclude -include CQ.h -O1 -g -emit-llvm -S $f -o /tmp/rp_oracle/$n.s1.ll; \
  ./build/ir-pass/cq-opt -load-pass-plugin ./build/ir-pass/libCQPass.so -passes=cq-lowering \
      -S /tmp/rp_oracle/$n.s1.ll -o /tmp/rp_oracle/$n.s2.ll 2>/tmp/rp_oracle/$n.err; done

# Rule-7 sweep over every shipped phi accept (subject worktree)
cd /Users/sorenwilkening/Desktop/CQ_phiphase
for f in ir-pass/test/control_phase_kickback_mergephi_*.ll \
         ir-pass/test/control_phase_kickback_rail_after_prep.ll \
         ir-pass/test/control_swap_accept_select_mergephi_*.ll; do … grep -c 'call void @cqrt_x(' …; done

# the seven must-keep-declining fixtures
for f in ir-pass/test/control_phase_kickback_reject_mergephi_*.ll; do \
  ./build/ir-pass/cq-opt -load-pass-plugin ./build/ir-pass/libCQPass.so -passes=cq-lowering -S $f -o /dev/null; done

# the ONE lit invocation
cd /Users/sorenwilkening/Desktop/CQ_phiphase/build && lit ir-pass/test --filter 'mergephi'
#   -> 35 of 35 PASS, 1.70 s, Total Discovered Tests: 1946

# L8 duplicate-body scan (sha-256 over non-comment lines, all 1946 fixtures) — inline python3, §5
```

Probe index: `r01`–`r25` in `trackP/review_r1_probes/`, each with its `.s1.ll`, `.s2.ll`, `.err` and
(for accepts) `.trace`. Every generated `.ll` was size-checked before measurement.

---

## 7. What I did NOT examine

- **No build, no `ctest`, no corpus sweep, no twin matrix** (forbidden by the brief). **One** lit
  invocation, spent on the 35-fixture `mergephi` family in the subject worktree.
- I did **not** mutate `stripCondNetwork`'s inverse network with a φ leaf. I read it and confirmed a φ
  leaf is never added to `Out.Leaves` and therefore never stripped or freed, but I ran no injection.
- I did **not** exercise the loop layer (`staleRailRecordRead`, `collapseRailPhisIn`,
  `invariantRegisterRoots`) against a φ condition beyond `r21`, which declined. A φ condition inside a
  rolled loop is the largest unexamined surface.
- I did **not** reach `classifyPhaseKickbackNest` with a φ from C (`-O1` flattens); row 13 rests on the
  hand-IR fixture plus my reading of both `collectCondTree` call sites.
- I did **not** examine the four e2e slices, their goldens, the `inject_p.py` harness, or
  `vacuity_p.py`. The IMPL's 0-MISSED matrix is unverified by me.
- I did **not** test `-O2`/`-O3`, multi-function modules, or any width other than `i1`/`i32`.
- Reachability of `lowerControlRegions`' `declineRegion` with a φ-conditioned `PhaseKickback` is
  **unproven in both directions** — I could not construct it and do not claim it is unreachable.

---

## 8. Verdict

# CLEAR-WITH-ITEMS

No over-ACCEPT and no silent miscompile. The core mechanism is sound where it matters: row 9 is
load-bearing and I have an independent witness for it; row 20 is unreachable and the widening is
correct in direction; H-1's theorem survives attack and is stronger than stated; the "would close a
cycle" claim is true for every kickback, not just the probed ones; the flag orthogonality holds
byte-identically; no taint is grown; Rule 7 is measured (0 `cqrt_x` on every φ PHASE accept, ancillas
only on the SELECT ones) and Rule 6 is clean on every probe under STRICT stage 2b.

Items, by severity:

1. **F-P1-1** (documentation, load-bearing) — the "one φ leaf in `Pred`" reason is false; measured
   counterexample `r07`; conclusion survives on a different invariant that must be written down.
2. **F-P1-3** (documentation + one unpinned accept) — four leaf-enumerating sites missing from the
   23-row table, including the `TreeSet` fence, whose φ exemption is a **measured accept asymmetry**
   (`r08` accepts, `r25` declines) that is sound but unargued and unpinned.
3. **F-P1-2** (hygiene) — the `PhiAnchor` repair is complete *inside* `classifyPhaseKickback` (verified
   by enumeration) and incomplete outside it; three φ-anchored sites still emit `<unknown>:0:0` or
   `file:0:0`, all pre-existing; the structural lesson is that **no `.ll` fixture can pin a location**.
4. **F-P1-5** (defence in depth) — `reverifyRailCondReads` silently skips a live `PHINode` record under
   a nulled-handle argument; unreachable today, but this increment created the population.
5. **F-P1-4** (documentation) — row 20's hazard narrative is wrong; only one of three `isRailFlag` uses
   has a φ subject.
6. **F-P1-6** (over-decline, file) — the in-loop φ kickback declines where the in-loop φ select
   accepts; plus the `-O1`-fused kickback+select composition (`r22`), pre-existing.

Also owed, and Track P should carry it: a **retirement trigger for bd `3d8q`** — the day the
in-place-ARM φ becomes an accept, its region starts matching Track P's rung 0 and step 5c's ladder
becomes the sole fence in front of a new population.

## Round 2: WARRANTED

Rule 13's budget guidance applies (7.4 break: 13 holes over three rounds; 3qlq Inc 1: 8 over six).
Round 1 found an incomplete L2 enumeration and one accept shape that was never argued — both are
"the next round finds something" signals. Scope round 2 at:
1. the leaf-enumerating sites **not** in the table, especially the `TreeSet` fence and the post-flatten
   cascade erase, with a mutation matrix rather than reading;
2. **the loop layer × φ condition** — `staleRailRecordRead`, `collapseRailPhisIn`, the rolled form —
   which round 1 touched only through `r21`;
3. the **emitter** side (`CondTreeEmit::emitCondNetwork`/`stripCondNetwork` with an interior φ) under
   injection, which round 1 read but did not attack;
4. **bd `3d8q` as landed**, against step 5c's rung 0.
