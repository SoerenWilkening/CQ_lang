# SCOPE — bd `test_C_libtooling-b6ap`: the MULTI-PHI MERGE PEEL (a pre-classification normalisation that turns the merge phis a tainted region does NOT define into tainted-condition `select`s)

Session `01NHxGVinGBKbb499HFCuwhT`, 2026-09-11, measured on **`main` `0c7380c`** with the tree's own
`build/ir-pass/cq-opt` (`git status --porcelain` showed only this untracked directory, so every
measurement below is against the **landed** binary, not against an in-progress tree).

**READ-ONLY.** Nothing under `ir-pass/`, `include/`, `runtime/`, `tests/`, `tools/` or `example/`
was touched, nothing was committed, no `ctest` was run. Probes and their verdict table are
transcribed in `probes/` (46 files + `probes/README.md`); the working copies live in
`/private/tmp/.../scratchpad/b6ap/`, the earlier measurement agent's `V*`/`C*` in
`../ownerfile/`.

Companions: `session-r9e5/SCOPE_B2.md` (the style model and the sibling scoping for the same
customer's *other* walls), `session-l4x4/SCOPE_l4x4.md` (1b-C, the wall this increment does **not**
remove for the `bool` spelling). Every line number is as of `0c7380c`.

---

## 0. HEADLINE — three measurements, and the first two change what the increment *is*

### 0.1 There is NO plain-C "manually peeled twin". The peel is not a convenience — it is the ONLY spelling.

The obvious witness for this increment would be: write the owner's program with the data mux
already spelled as a C ternary, show that it compiles today, and gate the increment on byte
identity with it. **That program does not exist at `-O1`.**

MEASURED — `p20_peel_bool_sel_first.c` writes the mux as `int a2 = b0 ? 2 : 5;` *before* the prep
region, `p21` writes it *after*, `p22`/`p23` are the `int` twins. All four decline, and the reason
is not a compiler fence:

```
$ diff <(sed -n '/^define/,/^}/p' p01_owner_intb1.s1.ll) \
       <(sed -n '/^define/,/^}/p' p20_peel_bool_sel_first.s1.ll)   # BYTE-IDENTICAL BODIES
$ diff <(sed -n '/^define/,/^}/p' p09_owner_int.s1.ll) \
       <(sed -n '/^define/,/^}/p' p22_peel_int_sel_first.s1.ll)    # BYTE-IDENTICAL BODIES
```

`clang -O1` converts a `select` whose condition is the dominating branch's condition, sitting in a
2-predecessor merge block, straight back into a `phi`. The peeled source and the owner's fused
source are **the same module** by the time CQ sees either. So:

* the increment is a **restoration of a spelling `-O1` destroyed**, not a new capability class;
* the byte-identity witness must come from **hand IR** (a lit fixture pair), never from a C twin.
  §11 says what the e2e layer can and cannot assert instead.

### 0.2 The target lowering EXISTS TODAY, one normalisation away — but ONLY if the peeled select gets its OWN compare

MEASURED, `h09c_peel_owncmp.s1.ll` — `p09`'s own `-O1` output with `%6 = phi i32 [5,%arm],[2,%0]`
deleted and `%c2 = icmp eq i32 %b0, 1 / %amux = select i1 %c2, i32 2, i32 5` put in its place:

```
exit=0, 22 trace lines, free_pairing_check STRICT: 0 violation(s), 0 unproven
cqrt_alloc_i32(0) -> h0 ; cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_eq_i32_hl(h0, 1) -> h1 ; cqrt_x(h1)          <- region: flag mint
cqrt_alloc_i32(0) -> h2 ; cqrt_ry_i32_controlled(h1, h2, 0x1p-1)  <- the state-prep arm
cqrt_x(h1) ; cq_template_icmp_eq_i32_hl_unc(h1, h0, 1) ; cqrt_free(h1)
cq_template_icmp_eq_i32_hl(h0, 1) -> h3                        <- select: its OWN flag mint
cqrt_alloc_i32(0) -> h4 ; cqrt_alloc_i32(2) -> h5 ; cqrt_copy_i32_controlled(h3, h5, h4)
cqrt_x(h3) ; cqrt_alloc_i32(5) -> h6 ; cqrt_copy_i32_controlled(h3, h6, h4) ; cqrt_x(h3)
cq_template_icmp_eq_i32_hl_unc(h3, h0, 1) ; cqrt_free(h3)
cqrt_measure_i32(h0) ; cqrt_measure_i32(h2) ; cqrt_measure_i32(h4)
```

The same peel that **reuses** the region's compare value (`h09a` merge-placed, `h09b` pred-placed)
declines `cq controlled lowering: condition data use neither escaped nor measured` — the ziov
shared-flag fence, `ArmClassify.cpp:2441-2443`, reached because `condDataUseDisposition`
(`ArmClassify.cpp:2195-2294`) ends at its catch-all `ArmClassify.cpp:2292`:

```cpp
    return CondDataDisp::Unowned;  // unrecognized (store/opaque/cq_invert/phi/…)
```

A `SelectInst` is not in that walk's recognized set. **Design consequence (§6): the peel MUST
clone the compare, not share it.** The cost is one extra flag mint + strip + free per peeled phi
and it is measured (22 lines vs the 15/14-line region-only baselines).

### 0.3 The peel's population is much wider than the owner's file, and one member is a ROUND-2 region

MEASURED, every one a `-O1` diamond whose merge holds ≥2 phis, all declining `control flow` today
and all accepting when the peel is applied by hand:

| plain-C probe | today | peeled (hand IR) |
|---|---|---|
| `p09_owner_int` — state-prep arm + data mux | DECLINE `control flow` | `h09c` **ACCEPT 22** |
| `p60_phase_arm` — `cq_phi` arm + data mux (merge ends with **zero** phis) | DECLINE `control flow` | `h60` **ACCEPT 20** |
| `V4` (bool rail + `cq_phi` arm + data mux) | DECLINE `bare i1 register condition` | `h61` **ACCEPT 16** |
| `p71_call_arm_opaque` — 6.5 classical-call arm + data mux | DECLINE `control flow` | `h71` **ACCEPT 25** |
| `p31_three_phi` — **three** phis | DECLINE `control flow` | `h31` **ACCEPT 33** |
| `p90_qq_mux` — the extra phi is a **Q+Q** mux (`%p` vs `%p+3`) | DECLINE `control flow` | `h90` **ACCEPT 23** |
| `p87_fp_mux` — the extra phi is a real `double` mux, **phase** arm | DECLINE `control flow` | `h87c` **ACCEPT 21** (`cqrt_copy_f64_controlled`, kjd1) |
| `p80_round2_out_cond` — the fused diamond's condition reads a 6.5 `%out` | DECLINE `control flow` | `h80` **ACCEPT 33** |

Every accept above is STRICT-stage-2b `0 violation(s), 0 unproven`.

`p80` is the load-bearing one. Its region-2 branch is `%9 = icmp eq i32 %8, 13` where `%8` is the
6.5 arm's merge phi — **classical at round 1, tainted only after
`repropagateControlMerges`**. Its one-phi control `p81` ACCEPTS (22 lines, 2b clean), so the
round-2 machinery itself is fine and the 2-phi wall is what stops it. **The peel must therefore run
in BOTH rounds** (§8).

---

## 1. The wall, exactly

`p00_owner_bool.c` is `example/grover/grover_oracle_uncompute.c`'s `main()` verbatim. At `-O1`
(`clang 19.1.7`) the classical guard `a >= 3` is proven equivalent to `!b0`, the compare and the
intermediate `a` are deleted, and the two SOURCE regions fuse into ONE diamond on the bare rail:

```llvm
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br i1 %1, label %4, label %2                 ; ARM = %2 = the FALSE successor (Rule 9)

2:                                             ; preds = %0
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br label %4

4:                                             ; preds = %2, %0
  %5 = phi i32 [ 5, %2 ], [ 2, %0 ]            ; the `a` DATA MUX      <- peelable
  %6 = phi i1  [ %3, %2 ], [ false, %0 ]       ; the `b1` STATE PREP   <- the region's own
```

`CQ_CTRL_DBG=1` names the anchor:

```
CQ_CTRL_DBG: decline [control flow] at:   br i1 %1, label %4, label %2
error: … cq controlled lowering: control flow under quantum control
```

The path is exactly three hops and none of them is semantic:

* **`ControlDetect.cpp:240-250` `soleMergePhi`** — `if (Found) return nullptr; // more than one
  phi → off-pattern`. Called from the three diamond/if-else recognizers at `:298`, `:312`, `:333`.
* **`ControlDetect.cpp:352`** — `return RegionShape::OffPattern;` (nothing matched).
* **`ControlDetect.cpp:577-583`** — `case RegionShape::OffPattern: diagnoseUnderControl(BI,
  offPatternDisposition(BI, Taint));`, and `offPatternDisposition` (`:441-488`) falls to its
  catch-all **`:487` `return "control flow";`** because the shape is none of its partitioned rows.

`soleMergePhi`'s own comment already calls this a *"decline generic, never mis-lower"* — a
Prime-Directive over-decline, exactly the thing CLAUDE.md's hcrg bullet warns about: *"before
declining a shape, ask whether the thing you are protecting is the unitary or the emitter's
bookkeeping"*. Here it is the bookkeeping: `ControlRegion::Merge` is a single `PHINode *`
(`ControlPlan.h`), and every downstream classifier and emitter reads exactly one.

**Bool-independent.** `p09_owner_int` (int `b0` → `icmp eq i32 %1, 1` condition, int `b1`) declines
byte-identically at `br i1 %2, label %5, label %3`. `p01_owner_intb1` (bool cond, int `b1`) too.

---

## 2. WHERE the peel runs — the normalisation slot, and its siblings

`CQLoweringPass::run` (`ir-pass/src/CQLoweringPass.cpp`) already has a **pre-classification
normalisation family**, every member of it *accept-only*, mutating IR so the existing substrate can
see a shape it already lowers:

| stage | call site | what it rewrites | why there |
|---|---|---|---|
| `foldIdentityBitcasts` | `:158` | bitcast identities | before PredMux |
| `promoteFp80Union` | `~:220` | union → register | before PredMux |
| **`flattenPredMuxRegions`** (fixpoint) | **`:250-251`** | a WHOLE acyclic tainted region → block-predicate selects, **incl. multi-phi merges** | *"after taint settles … BEFORE every analysis guard — so the escape/stale guards, loop lowering, control detection, select classification, and uncompute all see the post-flatten IR through their normal entry points"* |
| `unrollConstTripLoops` | `:273-276` | const-trip loop → straight line | + a nested PredMux fixpoint |
| `recognizeCtlzIdiomLoops` | `:301-305` | shift loop → closed form | + a nested PredMux fixpoint |
| `detectSpecializations` | `:320` | — | reads settled taint |
| `lowerControlledIOSinks` | `:348` | pre-peels the merge-φ-less void-I/O diamond | *"Runs BEFORE `detectControlRegions`"* |
| `lowerLoops` | `:364` | — | before detection |
| **`detectControlRegions` / `lowerControlRegions`** | **`:376` / `:377`** | the region path | round 1 |
| `repropagateControlMerges` | `:410` | **re-runs detect+lower** (`detectAndLowerOnwardControl`, `TaintPropagation.cpp:1492+`) | round 2 |
| `reverifyRailCondReads` | `:431` | re-asks the rail ladder at FINAL taint | after the round-2 fixpoint |
| `declineClassicalMuxes` | `:534` | the loud owner of leftover muxes | after everything above |

**PredMux is the exact sibling, and the reason it does not already do this is measured.**
`PredMuxFlatten.h:1-20`: *"merge phis as chained selects … multi-phi and N-incoming merges"* — it
handles multi-phi merges **when it may claim the whole region**. Its E4 gate refuses a region whose
interior holds a non-speculatable instruction, and the owner's arm holds `@cq_theta_i1`. MEASURED
both ways:

* `p30_chain_2phi` / `h30_both_armdefined` — 2 phis, **both** arm-defined, arm fully speculatable:
  **ACCEPT 25 lines**, and the lowered IR has no `br i1` at all and the arm chain hoisted into the
  entry block. That is PredMux, not the region path.
* `h30b_armdefined_speculatable` — the same two phis with a `cq_theta` added to the arm: **DECLINE
  `control flow`**. E4 refuses; the region path then hits `soleMergePhi`.

So the peel is **not** a new PredMux witness. PredMux's contract is whole-region (it erases the arm);
this increment must leave the arm, the CFG and the region's own phi **exactly** where they are and
move only the phis the region does not define.

> **RECOMMENDED SLOT: a new accept-only normalisation `peelIndependentMergePhis(M, taint)`, called
> (a) immediately BEFORE `detectControlRegions` at `CQLoweringPass.cpp:376`, and (b) again inside
> `repropagateControlMerges`' round-2 path, immediately before its `detectAndLowerOnwardControl`.**
> Precedent for (a): `lowerControlledIOSinks` (`:348`) and `lowerLoops` (`:364`), both of which
> state *"Runs BEFORE `detectControlRegions`"* for the same reason. Precedent for (b) — and it is
> mandatory, not optional — is CLAUDE.md's own standing lesson **"a stage that runs ONCE has a
> round-2-FALSE premise"** (F-L3-1, F-R1-1, and F-B1R2-1 which is the PREDICATE species of the same
> defect). `p80` is the measured customer. See §8 for the two ways to spell (b).

**Not before PredMux.** Peeling first would hand PredMux a region whose merge has one phi where it
had two, changing which W witness fires (`PredMuxFlatten.cpp:2286` W5 and `:2312` W7 BOTH require
`NumMergePhis == 1`) — i.e. it could silently move a PredMux accept. Running after the PredMux
fixpoint means every region PredMux can claim is already gone, so the peel only ever sees shapes
that decline today. That containment argument is the same one W5/W7 make for themselves and it must
be **measured**, not asserted (§13, the corpus diff).

---

## 3. The PEEL PREDICATE, written as a decline partition

Let `BI` be a **tainted** conditional `br` in block `P`, with successors `S0`/`S1`, and let `M` be
the merge block. The peel is offered a candidate `(BI, M, Φ)` where `Φ` is one `PHINode` in `M`.

**PEEL `Φ` iff ALL of P1–P8 hold. Otherwise leave it, and if `M` still holds >1 phi the region
declines loudly exactly as it does today (`control flow` at `ControlDetect.cpp:583`).**

* **P1 — the shape is the one `recoverRegion` recognizes.** `M` has exactly **2** predecessors,
  `{P, Arm}` (diamond) or `{ArmTrue, ArmFalse}` (if-else); `Arm`/`ArmTrue`/`ArmFalse` are
  single-pred, single-succ blocks whose succ is `M`; `BI` is not `Claimed` by a nest. Anything else
  (3-pred merge, shared merge, a `switch`, an arm ending in a conditional `br`) is **NOT PEELED** —
  it is off-pattern for a different and already-partitioned reason and must keep its existing
  message.
* **P2 — `Φ` has exactly 2 incoming values.**
* **P3 — EVERY incoming of `Φ` is AVAILABLE AT `P`**: a `Constant`, an `Argument`, or an
  `Instruction` that **dominates `BI`**. (`DominatorTree` is already built lazily in
  `detectControlRegions`, `ControlDetect.cpp:762-777`; the peel needs its own since it runs
  earlier.) *This is the whole predicate.* An incoming defined **in an arm block** fails it.
  MEASURED `p88_two_preps` — two `cq_theta` calls in one arm, two arm-defined phis, **nothing is
  peelable and the program must keep declining `control flow`**; and `h30b`, where the sibling phi's
  arm incoming is a *speculatable* `mul` defined in the arm — **still not peelable**. The peel must
  **never hoist**: hoisting a tainted op out of an arm changes which gates run unconditionally, which
  is PredMux's E4-gated job, not this one's.
* **P4 — `Φ` is not the region's own merge.** After peeling, **exactly one** phi must remain in `M`
  (or zero — see §5). If two or more candidates pass P3, peel all but... *nothing*: peel **every**
  P3-passing phi and let the region take whatever is left. MEASURED `h31_threephi_peeled` — two
  muxes peeled, one prep phi left, **ACCEPT 33**. And `h60`/`h61` — the phase arm defines no value,
  so **all** phis are peelable and the merge ends **empty**, which is precisely the flat-kickback
  shape (`classifyPhaseKickback` asks `MergeBB->hasNPredecessors(2)`, not for a phi).
  ⚠ If **more than one** phi fails P3, the region is a genuine multi-value arm merge — **NOT PEELED**,
  decline unchanged (`p88`).
* **P5 — `Φ`'s type is `select`-able**: `isMuxableType(Φ->getType())` (the predicate PredMux already
  uses, `PredMuxFlatten.cpp` W5/W7). Vectors, aggregates, pointers, `x86_fp80` where no copy family
  exists → **NOT PEELED**.
* **P6 — the two incomings are DISTINCT.** An identity phi (`[%q,%arm],[%q,%P]`) is a live-range
  extender, not a mux; peeling it would mint a pointless flag and a pointless out-rail. It is also
  exactly the degenerate shape W5 fences for the same reason. → **NOT PEELED** (leave it; it is
  harmless and, if it is the only other phi, `soleMergePhi` still refuses — see OQ-3).
* **P7 — the condition is re-mintable at `M`.** Either (a) `BI->getCondition()` is a `CmpInst`
  defined in `P` whose operands all dominate `M` (so a clone is legal), or (b) it is a **rail leaf**
  (`isCondRailLeaf`, `SelectClassify.h`) — a `cq_theta_i1` result, which needs no clone at all
  because the register **is** the condition. Anything else — a `select i1` and/or tree, a `trunc`,
  a `zext`, an argument, a header phi — → **NOT PEELED**. (The and/or tree case is reachable and is
  OQ-4: `CondTreeEmit::collectCondTree` would accept it, but cloning a *tree* is a much bigger
  rewrite than cloning one compare.)
* **P8 — `Φ` is not `use_empty()`.** A dead phi has no mux to build; `declineClassicalMuxes`
  (`TaintPropagation.cpp:1243+`) already documents dead phis as benign.

**Nothing in P1–P8 asks about TAINT of the incomings**, and that is deliberate: a peeled select
whose condition is tainted is claimed by `SelectClassify` regardless of whether its *data* is
tainted (`p90`/`h90` — a Q+Q mux — and `h09c` — two `ConstantInt`s — both accept through the same
4.4 merge). §9 shows why this does not collide with `declineClassicalMuxes`.

---

## 4. Polarity (Rule 9) — the select operand order

`select i1 C, TrueVal, FalseVal` takes `TrueVal` when `C` is 1. So:

* if the **merge is the TRUE successor** (`BI->getSuccessor(0) == M`), then the `P`-edge incoming is
  the true value: `select C, Φ[P], Φ[Arm]`;
* if the **merge is the FALSE successor**, `select C, Φ[Arm], Φ[P]`.

The owner's file is the FIRST case and it is the one `-O1` produces from `if (u != k)`-style
sources (CLAUDE.md Rule 9): `br i1 %1, label %4(merge), label %2(arm)`, `%5 = phi i32 [5,%2],[2,%0]`
→ `select i1 %1, i32 2, i32 5`. Verified against the accepting hand peels (`h09c` emits
`cqrt_alloc_i32(2)` under the un-bracketed flag and `cqrt_alloc_i32(5)` under the `cqrt_x` bracket,
which is the 4.4 convention).

For an **if-else** region (`M`'s two preds are both arms) the incomings are `Φ[ArmTrue]` /
`Φ[ArmFalse]` and there is no `P` edge; P3 still asks both to dominate `BI`, which for an if-else
means neither is arm-defined — i.e. the whole thing was a cross-arm constant mux. Reachable only
from hand IR at `-O1`; keep it in the predicate, fixture it, do not build a special case.

---

## 5. What happens to the REGION after the peel

The merge is left with **exactly one** phi (or none), so `recoverRegion` matches and the region goes
to its ordinary owner. MEASURED, per arm class:

| arm class | merge after peel | verdict |
|---|---|---|
| `cq_theta` **state prep**, `i32` seed, compare condition | 1 phi | `h09c` **ACCEPT** (drbq Inc 4 path, `cqrt_ry_i32_controlled`) |
| `cq_theta` state prep, **bare rail** condition | 1 phi | `h01a`/`h01b` **DECLINE `bare i1 register condition`** — bd **`l4x4`** (1b-C), *not this increment* |
| `cq_phi` **phase**, compare condition | **0** phis | `h60` **ACCEPT** (kickback) |
| `cq_phi` phase, **bare rail** condition | **0** phis | `h61` **ACCEPT** (1b kickback on a rail) |
| **6.5 classical call** | 1 phi | `h71` **ACCEPT** |
| **value arm** (3qlq Inc 2 controlled-copy merge) | 1 phi | not separately probed — `-O1` folds short value arms to selects anyway (`SCOPE_B2.md` §0.1), so the reachable population is the ≥5-op chain; predicted accept, **must be fixtured** |
| arm **rotates the condition register** | 1 phi | `h85` **DECLINE `condition predates a non-diagonal gate`** — the wire fence fires as designed |

**An `i1`-seeded state prep still hits F2 by design** (`ArmClassify.cpp:3028-3036`,
`f2SeedPinnedByLiveRegister` at `:1195`): the branch condition is itself a tainted `i1` pinned to
`true` on one edge and `false` on the other, so *every* `i1` seed collides. CLAUDE.md records this
as **"THE `i1` STATE-PREP WIDTH IS OUT"** (drbq Inc 4, round-4 lens R4). That is the owner's `bool
b1` and it is bd `drbq.14` territory, **not** this increment's — §15.

---

## 6. The SHARED-COMPARE problem, and why the peel must CLONE

`h09a` (select in the merge, reusing `%c`) and `h09b` (select in the pred, reusing `%c`) both
decline:

```
cq controlled lowering: condition data use neither escaped nor measured under quantum control
```

`classifyArms` (`ArmClassify.cpp:2426-2447`) sees `HasDataUse` (a non-`BranchInst` user of the
condition) and asks `condDataUseDisposition` (`:2195`), whose walk recognizes `ReturnInst`, a
`Taint.MeasureCalls` member, a lowerable `CastInst`, a lowerable `CmpInst`, and a
`BinaryOperator`/`UnaryOperator` — and ends at `:2292`
`return CondDataDisp::Unowned; // unrecognized (store/opaque/cq_invert/phi/…)`. A `SelectInst` is
unrecognized.

**Two ways out; take the first.**

* **(A) CLONE the compare into `M`, immediately before the select.** No compiler change at all —
  `h09c` proves the emitted stream is already correct and STRICT-2b clean. The region and the
  select then each mint, strip and free their **own** flag on the same wire, which is precisely the
  shipped sequential-regions shape (two `cq_template_icmp_eq_i32_hl` / `_unc` / `cqrt_free` pairs in
  the `h09c` trace). Cost: one extra flag rail per peeled phi, transient, freed.
* **(B) Teach `condDataUseDisposition` to recognize a select that `SelectClassify` will claim.**
  A Rule-13-core widening of the ziov fence, whose whole disposition table (`ShareOk` /
  `MeasuredEarly` / `Unowned` / `Unlowerable`) was written before selects were region-claimable. It
  would save a flag but it asks the fence a question it has never been asked, and `ShareCondFlag`
  then means "the 4.4 merge and the region share one physical flag", which changes who strips it.
  **Out of scope; record as OQ-1.**

⚠ **The clone is a new tainted `icmp` on the condition wire, and the wire fences must be asked of
it.** They are, and they fire: `h85_v8int_peeled` (the arm rotates the condition register) declines
`condition predates a non-diagonal gate` — that is `SelectClassify`'s **gate 2c**
(`SelectClassify.cpp:855-900`), whose prong (a) is *position-free*: any off-ancestry theta on the
condition's provenance wire declines wherever it sits. So cloning cannot launder a stale condition.
For a **rail** root the ladder is `SelectClassify.cpp:816-852` — (i) tainted, (ii)
`railMeasuredBeforeReadPoint(Rail, Sel, taint, DT)`, (iii) gate 2c with the DT prong — plus the
round-2 re-verification `reverifyRailCondReads` (`CQLoweringPass.cpp:431`), which records
`(rail, first emitted read)` at four emission sites and re-asks rungs (ii)+(iii) at FINAL taint.

---

## 7. WHERE to put the select, and why it is the merge

`h09c` (clone + select at the phi's position in `M`) and `h09d` (clone + select in `P`, before the
branch) **both accept, both 22 lines, both 2b clean — and their traces DIFFER**: pred placement
emits the select's whole merge stream *before* the region's, merge placement after.

**Put it at the phi's position in `M`.** Three reasons:

1. minimum churn — the phi is *replaced in place*, so every use is already dominated and no RAUW
   ordering question arises;
2. it preserves source order (the region ran, then the mux was read), which is what a reviewer
   diffing a golden against `-O0` intuition expects;
3. pred placement puts a tainted `icmp` + `select` **before** the branch, which makes the select's
   condition a *live-on-the-edge* value and therefore visible to `f2SeedPinnedByLiveRegister`'s
   backward half — an entirely gratuitous new interaction with the state-prep fence (§10, H-4).

Both orders are the same unitary (the select reads only the condition, and P7+gate-2c guarantee no
gate moves that wire between the two mints), but only one of them is the minimal rewrite.

---

## 8. Round 1 vs round 2 — the peel must run TWICE

`repropagateControlMerges` (`TaintPropagation.cpp:1492`) is **not** a taint touch-up: it re-seeds
taint from `taint.UntaintedMergeRails` (the 6.5 / 4.5 `%out` rails) and then calls
`detectAndLowerOnwardControl`, i.e. *"`detectControlRegions`/`lowerControlRegions` (the same
machinery step 183/184 run)"*.

MEASURED: `p80_round2_out_cond` is a 6.5 classical-call region followed by a **fused 2-phi diamond
whose condition `%9 = icmp eq i32 %8, 13` reads that region's merge phi**. At round 1 `%8` is
classical, so region 2 is not a tainted branch at all; at round 2 it is, and it hits `soleMergePhi`.
Its one-phi control `p81` accepts (22 lines, 2b clean); `h80_round2_peeled` accepts (33 lines, 2b
clean).

Two spellings, and the second is the one to build:

* **(i) call the peel again from `repropagateControlMerges`**, immediately before
  `detectAndLowerOnwardControl`, on the round-2 taint. Direct, and it mirrors how the round-2 path
  already re-runs detection.
* **(ii) make the peel part of the ONE function both entry points call**, so there is no second
  spelling to forget. CLAUDE.md's `markBranchPhaseGate` lesson is explicit: *"a seventh emitter that
  forgets the call re-opens this with no diagnostic anywhere"*, and the r9e5 round-2 fix repeated it
  (`markRailCondRead` had to move INSIDE `emitCondNode`). Prefer whichever spelling makes the peel
  **impossible to skip**, and write the reason at the call site.

⚠ There are **two** entry points in `CQLoweringPass.cpp` (`run` at `:113-660` and the second at
`:700-910`); every stage appears in both. The peel must be added to both, and the fixture family
must contain at least one round-2 accept and one round-2 decline (§13).

⚠ **NOTES §2's stage table owes this increment a row.** The question that table asks —
*"does this stage compute something a LATER stage consumes, over a premise round 2 falsifies?"* —
is answered YES here: the peel's own P3 dominance proof and P7 clonability proof are computed
before detection and consumed by it. They are **structural**, not taint-keyed, so round 2 cannot
falsify them *for a region round 1 already saw* — but round 2 creates regions round 1 never saw, and
that is exactly what (i)/(ii) is for. Say that in the stage header, do not leave it implied.

---

## 9. `declineClassicalMuxes` — why a peeled select is never its customer

`declineClassicalMuxes` (`TaintPropagation.cpp:1243`) runs at `CQLoweringPass.cpp:534`, i.e.
**after** `lowerControlRegions` (`:377`) and `repropagateControlMerges` (`:410`). Its select arm is:

```cpp
        if (auto *Sel = dyn_cast<SelectInst>(&I)) {
          // Tainted condition → ControlDetect's, never ours …
          if (taint.Tainted.count(Sel->getCondition()))
            continue;
          if (taint.Tainted.count(Sel->getTrueValue()) || … )
            diagnoseEscape(Sel, kMsgClassicalSelect);
```

A peeled select's condition is by construction the region's **tainted** condition (P7 admits only a
tainted `CmpInst` clone or a rail), so it takes the `continue`. It is claimed earlier by
`SelectClassify::classifySelectRegion` inside `detectControlRegions` and erased by
`SelectMergeEmit`. Measured end-to-end on every accepting hand peel (`h09c`, `h31`, `h60`, `h61`,
`h71`, `h80`, `h87c`, `h90`) — none of them reaches `declineClassicalMuxes`.

**The residual risk is a peeled select that `SelectClassify` DECLINES**: the program exits non-zero
at that decline, so `declineClassicalMuxes` never runs. Still a loud decline, just possibly a
*different string* than the pre-peel `control flow`. §12 H-2.

---

## 10. `lowerControlRegions`' precedence graph (hcrg) — two consumers in one block

After the peel, `P`/`M` hosts both the region and one or more peeled selects. `SwapRouteEmit.cpp`'s
pre-flight (`:2239` `sequentialChainAlias`, `:2290-2313` the alias scan, `:2315+` Kahn) is keyed on
`doomedBlocks` (`:2146`):

```cpp
  auto doomedBlocks = [&](const ControlRegion &R) {
    SmallVector<BasicBlock *, 3> Doomed;
    Doomed.push_back(R.Arm);
    if (R.Kind != ControlRegion::GuardedStoreArm) {
      Doomed.push_back(R.ArmFalse); Doomed.push_back(R.MergeBB);
    }
    return Doomed;
  };
```

A `SelectRegion` has **no** `Arm`/`ArmFalse`/`MergeBB` (it erases only the `select` and, when dead,
its compare) — so it contributes **no** doomed block and generates **no** alias edge in either
direction. `reorderable` (`:2240-2243`) admits only `BranchRegion`/`PhaseKickback`, which is
consistent: a select never needs reordering because it never erases anything another region names.

⚠ **But the region DOES erase `MergeBB`, and that is where the peeled select lives.** `h09c`,
`h31`, `h60`, `h61`, `h71`, `h80`, `h87c`, `h90` all accept, so the flatten evidently splices the
select into `Pred` with the rest of `M`'s body — **verify this in the implementation and pin it**,
because it is a block-lifetime question of exactly the class CLAUDE.md's hcrg bullet is about. If it
turns out order-sensitive, the fix is `lowerControlRegions`' ORDER (emit the select's region before
the branch region's flatten), never a decline. §12 H-1.

---

## 11. THE WITNESS

**There is no plain-C twin (§0.1).** The three witnesses that ARE available:

1. **lit hand-IR pair (primary).** For each accept shape, commit BOTH the fused 2-phi module (as an
   ACCEPT fixture, RED on `0c7380c`) and the already-peeled module (as a second ACCEPT fixture), and
   assert the **same** `CHECK` stream on both. The `h*` files in `probes/` are ready-made: `h09c`,
   `h31`, `h60`, `h61`, `h71`, `h80`, `h87c`, `h90`. This is the byte-identity claim, and it is the
   real one — the peel is *defined* as "produce the module the second fixture already is".
2. **e2e goldens with a STATED reduction (the drbq Inc-4 precedent).** CLAUDE.md records that
   Inc 4 shipped *"byte identity between the SUBJECT golden and a REDUCTION of the TWIN golden"*,
   committing the twin as a slice in its own right so a reviewer can re-derive the reduction by
   hand. Do the same: ship `slice_control_fused_regions_bool.c` (the owner's file **verbatim**) and
   `slice_control_fused_regions_int.c`, and state in each header the line relationship to the
   **measured** region-only baseline. That baseline exists and is committed-able: `../ownerfile/C4.c`
   is `h09c`'s program with `cq_measure(a)` deleted (so the merge has ONE phi and it lowers today) —
   **11 trace lines**, against `h09c`'s **22**. The delta is exactly the peeled select's own stream,
   `+11` = 1 flag mint + 1 out-rail `cqrt_alloc` + 2×(`cqrt_alloc` + `cqrt_copy_i32_controlled`) +
   2 `cqrt_x` + 1 `_unc` strip + 1 `cqrt_free` + 1 extra `cqrt_measure`. A reviewer can re-derive
   that by hand from two committed files, which is the drbq Inc-4 discipline verbatim.
   **Do NOT add a `compare_files` gate between two goldens that are not provably identical** —
   the only e2e `compare_files` gate this increment can honestly add is the pair in (3).
3. **A rolled/unrolled or two-spelling `cmp` gate where one genuinely exists.** The one measured
   candidate is `h09c` vs `h09d` — and they are **NOT identical** (§7), which is itself the
   measurement that settles the placement question. Record it; do not gate on it.

---

## 12. HAZARDS — each with the measurement behind it

**H-1 — the peeled select lives in a block the region's flatten ERASES.** `RegionFlatten` splices
`MergeBB` into `Pred` and erases it (`doomedBlocks`, §10). Every accepting hand peel shows the
select surviving, but that is evidence about the *emitter*, not a proof about *this* rewrite. A
reviewer should probe: a peeled select in a merge shared by a coordinated 4.3 nest; a peeled select
in region 1's merge that is region 2's pred (the hcrg chain); a peeled select whose compare clone is
in `M` while the region's compare is in `P`. **This is the first thing to break.**

**H-2 — the peel turns one decline into a DIFFERENT decline.** Pre-peel every one of these programs
says `control flow`. Post-peel, `h01a` says `bare i1 register condition`, `h85` says `condition
predates a non-diagonal gate`, `h87` says `state prep seed is proven equal to the condition
register`. All are loud and all are Prime-Directive-safe, but **a decline fixture that mirrors a
string character-for-character (Rule 12) will flip**, and a reviewer must confirm each new string is
the *right* fence and not an accidental one. Measured: three strings move across nine probes.

**H-3 — the peel gives F2 a new instruction with an exactly-pinned `i1` operand, and F2's
conservative arm declines.** MEASURED, and this one is a real capability cost:

| probe | change from `h87_fp_peeled` | verdict |
|---|---|---|
| `h87_fp_peeled` | — (fp mux peeled, state-prep arm) | DECLINE `state prep seed is proven equal to the condition register` |
| `h87b` | seed `0` → `7` | DECLINE (same) — **so it is not a real seed collision** |
| `h87e` | clone compares against `99` | DECLINE (same) |
| `h87d` | fp select arms are CONSTANTS | **ACCEPT 25** |
| `h87f` | no select at all | **ACCEPT 15** |
| `h87c` | arm is `cq_phi` instead of a prep | **ACCEPT 21** |
| `h90` | the same shape with an **i32** mux | **ACCEPT 23** |

The pattern: `f2SeedPinnedByLiveRegister` evaluates forward over the tainted user graph with
`ConstantRange` (integer-only) + exact `ConstantFold*`; CLAUDE.md records its rule as *"a value it
cannot bound that HAS an exactly-pinned operand DECLINES"*. The peeled select's condition `%cc` IS
exactly pinned on both edges, and an **fp** select result cannot be bounded — so the conservative
arm fires. It is an **over-decline**, never a miscompile, and it costs exactly the
`fp mux + state-prep arm` cell. Options (present, do not decide): teach F2 to skip a select that
`SelectClassify` will claim; or accept the cell as declined and fixture it. **OQ-2.**

**H-4 — pred placement would widen H-3 to every type.** §7. Another reason the select goes in `M`.

**H-5 — the clone is a second tainted compare on one wire, and something downstream counts
compares.** Measured safe on every accept here (2b `0 violation(s)` throughout, and each clone is
stripped by its own `_unc` and freed). But `declineStaleRecordOps` (`OpcodeLowering.cpp`), the
`InPlaceRailOps` machinery, and `ChainWalk`'s rail closures all reason about *"the users that keep
mutating the same handle"* — a reviewer should probe a peeled select beside an in-place
`cqrt_addc`/`cqrt_xorc` on the condition's own rail (the `control_..._inplace_xor_bridge` family) and
inside a classically-bounded loop (the rolled/unrolled twin instrument).

**H-6 — round 2 (§8).** The peel must run in both rounds and in both `CQLoweringPass` entry points;
`p80` is the measured customer and the hand peel `h80` is the target. A round-1-only peel leaves
`p80` declining and nothing in the suite would notice.

**H-7 — the peel changes which PredMux witness fires if it runs too early.** §2. Mitigated by the
slot; must be *measured* by a whole-corpus diff, not argued.

**H-8 — a Q+Q peeled mux is a no-cloning question.** `p90`/`h90` peels `phi i32 [%p,%arm],[%p+3,%P]`
into `select i1 %c, i32 %p3, i32 %p` — two distinct tainted registers merged by two
`cqrt_copy_i32_controlled` into a fresh `|0⟩` out-rail. That is the shipped 4.4 accept shape and it
is 2b clean, but it is the first time the **peel** rather than the *source* creates one. A reviewer
should re-derive the Rule-8 argument for it explicitly rather than inheriting it.

**H-9 — an `undef`/`poison` incoming.** `LiteralIntegrity`'s guard 1 counts a literal `undef` in two
emitted gate slots. A phi with an `undef` incoming would peel into a select with an `undef` arm.
Not probed. Either exclude non-`Constant`-safe incomings in P3 or confirm the guard covers it.

---

## 13. FIXTURE AND SLICE FAMILIES (Rule 12: every accept ships with its decline)

**lit — ACCEPTS** (each RED on `0c7380c`; source = the `p*.s1.ll`, expected stream = the matching
`h*` hand peel):

* `control_peel_stateprep_datamux.ll` (`p09`/`h09c`) — the flagship compare shape.
* `control_peel_stateprep_datamux_peeled_control.ll` (`h09c` verbatim) — the byte-identity partner.
* `control_peel_phase_datamux.ll` (`p60`/`h60`) — merge ends with ZERO phis.
* `control_peel_phase_datamux_rail.ll` (`V4`/`h61`) — the bare-rail kickback + `CopyRailRoot` select.
* `control_peel_classical_call_datamux.ll` (`p71`/`h71`) — the 6.5 arm.
* `control_peel_three_phis.ll` (`p31`/`h31`) — two muxes peeled, one prep left.
* `control_peel_qq_datamux.ll` (`p90`/`h90`) — H-8.
* `control_peel_fp_datamux_phase.ll` (`p87`+phase arm/`h87c`) — the kjd1 fp family.
* `control_peel_round2_out_cond.ll` (`p80`/`h80`) — **the round-2 pin**; RED if the peel runs once.
* `control_peel_ifelse_constmux.ll` — the if-else orientation (§4), hand IR.

**lit — DECLINES** (mirrored character-for-character):

* `control_peel_reject_two_arm_defined.ll` (`p88`) — `control flow`; the decline that must survive.
* `control_peel_reject_arm_defined_speculatable.ll` (`h30b`) — `control flow`; **the peel must not
  hoist**.
* `control_peel_reject_rotated_cond.ll` (`p85`/`h85`) — `condition predates a non-diagonal gate`.
* `control_peel_reject_stateprep_rail.ll` (`p01`/`h01a`) — `bare i1 register condition`; flips when
  bd `l4x4` lands, and its header must say so (the 1b precedent).
* `control_peel_reject_fp_stateprep.ll` (`h87`) — H-3's over-decline, pinned so it cannot move
  silently.
* `control_peel_reject_nonmuxable_type.ll` — P5, hand IR.
* `control_peel_reject_cond_tree.ll` — P7's and/or-tree exclusion (OQ-4), hand IR.
* `control_peel_reject_three_pred_merge.ll` — P1; must keep its existing message.
* A **round-2 decline** whose peeled region declines for its own reason — pins that the round-2 call
  is not a silent accept.

**CONTROLS** (green on both binaries, so the widening is shown not to have reached them):

* `control_predmux_leave_*` — the existing PredMux pins; the corpus diff must show them byte-equal.
* `p30`/`h30` as an ACCEPT-AND-UNCHANGED control: PredMux, not the peel, owns it.
* the identity-phi shape (P6).

**e2e slices**: `slice_control_fused_regions_bool.c` (the owner's file **verbatim**, once bd `l4x4`
or the `int b1` spelling makes it accept) and `slice_control_fused_regions_int.c` (accepts with this
increment alone), both STRICT stage 2b, each with the reduction stated in its header (§11.2). A
`compare_files` gate **only** if two goldens are provably identical — none measured here.

**Corpus diff** (the mandatory containment measurement, the W7 precedent): run all
`ir-pass/test/*.ll` under both binaries and report `RCDIFF / DIAGDIFF / OUTDIFF`. The expectation is
0/0/0 outside the new family; anything else is a moved accept and must be explained, not regenerated.

---

## 14. COST

| item | estimate |
|---|---|
| new file `PeelMergePhis.{h,cpp}` (P1–P8 + the clone + the RAUW) | **~250–350 lines**, most of it the predicate's comment block |
| `CQLoweringPass.cpp` — two call sites (both entry points) + the slot rationale | ~30 lines |
| `TaintPropagation.cpp` — the round-2 call inside `repropagateControlMerges` | ~15 lines |
| `ControlDetect.cpp` | **0** — `soleMergePhi` is untouched; the peel makes its precondition true |
| `ArmClassify.cpp` / `SelectClassify.cpp` / `SelectMergeEmit.cpp` | **0** if option (A) (§6) |
| lit fixtures | ~19 (10 accept + 9 decline) + 3 controls |
| e2e slices | 2, **0** new goldens for existing slices expected |
| runtime / `opcode_table.yaml` / `CQ.h` | **0** — no new frozen symbol (the peel emits nothing) |
| adversarial rounds | **budget 3** (§15) |

The peel itself is small. The *review* is not: this is `ControlDetect`-adjacent, it is a new
normalisation in the PredMux family, and CLAUDE.md's record for this neighbourhood is eight findings
over six rounds on one function.

---

## 15. WHAT A REVIEWER SHOULD PROBE FIRST

1. **H-1 block lifetime** — a peeled select in a merge that another region's flatten erases, in
   every combination the hcrg precedence graph admits (sequential chain, coordinated nest, shared
   merge). The failure mode here is a SIGSEGV or a dangling use, i.e. loud; the *silent* failure
   mode is a select that gets spliced into the wrong block and therefore reads a different basis.
2. **H-6 round 2** — delete the round-2 call and confirm exactly the round-2 fixtures redden and
   nothing else. If more than the round-2 fixtures move, the slot is wrong.
3. **H-5 the clone on a wire something else is mutating** — the in-place `addc`/`xorc` bridge, the
   `InPlaceRailOps` families, and the rolled/unrolled loop twin. This is where the `8h7d.5`
   "when you widen a set, ask what OTHER set was computed over the same closure" lesson applies: the
   peel widens the population of *tainted compares on a condition wire*, and at least four
   predicates (`condDataUseDisposition`, gate 2c, `staleRailRecordRead`, `railWireNamesBackward`)
   are computed over that closure.
4. **P3's dominance proof under `-O1`'s actual output** — probe an incoming that dominates `BI` only
   through a `phi` in `P`, and one that is an `Argument` of a Phase-6 clone.
5. **Assume a fifth thing.** The r9e5 round-1 reviewer said that and round 2 found F-B1R2-1.

---

## 16. THE OWNER'S FILE — the plain answer

**With this increment PLUS `int b1`: YES, it compiles.** `p01_owner_intb1` is exactly the owner's
program with `bool b1` → `int b1`; its `-O1` module peels (by hand) to `h01a`, and `h01a`'s only
remaining decline is the **rail-condition state prep**, `bare i1 register condition` — because `b0`
is still `bool`. Change `b0` to `int` as well (`p09_owner_int`) and the peel alone is sufficient:
**`h09c_peel_owncmp` exits 0, 22 trace lines, STRICT stage 2b `0 violation(s), 0 unproven`.**

So, precisely:

| owner spelling | after this increment |
|---|---|
| `int b0`, `int b1` | **COMPILES** (measured, `h09c`) |
| `bool b0`, `int b1` | needs bd **`l4x4`** (1b-C: state prep / in-place Ry arm on a bare rail) — measured wall `h01a` |
| `bool b0`, `bool b1` (the file as written) | needs `l4x4` **and** the `i1` state-prep seed ruling |

**The `bool b1` residual is F2's `i1` collision, and it is a RULING, not a bug.** `ArmClassify.cpp:3028-3036`
declines `state prep seed is proven equal to the condition register` via
`f2SeedPinnedByLiveRegister` (`:1195`); CLAUDE.md (drbq Inc 4, round-4 lens R4) records the ground:
*"the branch condition is itself a tainted `i1` pinned to `true` on one edge and `false` on the
other, so every `i1` seed collides — the ARM half is plain-C reachable and was a live miscompile
behind the type gate"*, and *"THE `i1` STATE-PREP WIDTH IS OUT"*. The measured evidence is `V2`/`V6`
in `../ownerfile/`, which decline with that exact string today.

Ways out, **presented, not decided** (this is bd `drbq.14` / an owner ruling, not this increment):

* **(a) an explicit prep intrinsic with no register operand** — e.g. a header-level
  `cq_prep(θ)`-style source whose seed is not an SSA value at all, so there is nothing for F2 to
  prove equal. This is the same move `cq_phi`'s register-free redesign made (3qlq Inc 1 D1) and it
  has the same shape of argument: the collision exists because a *value* is being asked to carry
  information the *construct* should carry. It changes `CQ.h`, so it is a frozen-surface decision.
* **(b) the `int` workaround** — one token, `bool b1` → `int b1`, with the cost documented. Measured
  to work (`h01a` gets past F2; `h09c` all the way).
* **(c) narrow F2 for an `i1` seed whose pinned value is provably the OTHER edge's** — i.e. prove
  the collision is vacuous rather than refusing the width. CLAUDE.md's record says the ARM half was
  a **live plain-C miscompile** behind the old type gate, so any narrowing here is a Rule-13-core
  change with its own rounds, and the fixture that pins it
  (`..._reject_stateprep_i1_arm_flag.ll`) exists precisely to stop a casual widening.

---

## 17. OPEN QUESTIONS

* **OQ-1** — clone the compare (§6 option A, recommended, zero compiler change) vs widen
  `condDataUseDisposition` to recognize a `SelectClassify`-claimable select (option B, saves one flag
  rail per peeled phi, Rule-13-core).
* **OQ-2** — H-3: accept the `fp mux + state-prep arm` over-decline and fixture it, or teach F2 to
  skip a claimable select.
* **OQ-3** — P6: an identity phi beside a real one leaves `soleMergePhi` still refusing. Peel it
  anyway (a wasteful but harmless select), erase it (it is a pure live-range extender —
  `isBenignLiveRangePhi`'s domain), or keep declining? Not probed.
* **OQ-4** — P7 admits a `CmpInst` or a rail leaf. An `and`/`or`/`xor` **condition tree**
  (`CondTreeEmit::collectCondTree`) is a legitimate region condition that the peel cannot clone
  cheaply. Decline it (recommended for this increment) or clone the tree?
* **OQ-5** — should the peel also fire when the merge holds **one** phi that is *not* the region's
  (a data mux beside a **void** arm, i.e. `p60`)? Today that shape declines `control flow` and the
  peel fixes it (`h60`/`h61`). It is strictly a widening of the *same* predicate with `>1 phi`
  relaxed to `≥1 non-region phi` — worth doing, but it is a second accept class and should be its
  own increment row.
* **OQ-6** — `p86_two_armdefined` shows `-O1` IPSCCP const-folding an arm chain on the equality edge
  (`s = r+7` became the constant `9`), which makes a phi peelable that the *source* did not write as
  a mux. Sound (the constant is what the program computes on that edge) but worth stating, because
  it means the peel's population is partly manufactured by `-O1`'s own equality propagation — the
  same mechanism drbq Inc 4's F1/F2 exist to fence.
