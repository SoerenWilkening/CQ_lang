# Rule-13 REVIEW, ROUND 2 — bd `test_C_libtooling-b6ap`: the MULTI-PHI MERGE PEEL, reviewing the round-1 FIX

Independent adversarial review of the round-1 fix on branch `merge-phi-peel`
(worktree `/Users/sorenwilkening/Desktop/CQ_b6ap`), 2026-09-11.
SUBJECT `CQ_b6ap/build/ir-pass/{cq-opt,libCQPass.so}`; ORACLE
`CQ_lang/build/ir-pass/{cq-opt,libCQPass.so}` (`main` `0c7380c`, read-only —
never rebuilt, never written to). Nothing under `ir-pass/`, `include/`,
`tests/`, `tools/` was edited in either checkout; nothing was committed; the
build was not touched. Probes + runners: `review_b6ap_r2_probes/`
(`./ab.sh <n>` runs one on BOTH binaries; `./twin.sh <n>` compares the
SUBJECT's lowering of the FUSED module against the ORACLE's lowering of the
HAND-PEELED twin; `handpeel.py` builds that twin mechanically;
`sweep.sh <dir>` re-runs a whole probe corpus on both).

## VERDICT: **CLEAR-WITH-ITEMS**

**F-B6-1 is CLOSED.** I attacked the taint delta, its four-call adjudication and
its completeness from twelve consumer directions and could not re-open it. Every
consumer class I could reach is either a LOUD decline or an ACCEPT whose emitted
stream is **byte-identical to the ORACLE's lowering of the hand-peeled twin of
the same module** — which is the increment's own contract, now measured on **27
programs** instead of one.

**F-B6-2 / P10 holds**, and its deliberately-wider spelling costs nothing
measurable.

One NEW finding, an **OVER-DECLINE** (hand-IR only): there is a **fifth**
taint-consuming stage before the peel — `foldIdentityBitcasts` (`:159`) — that is
not in `adjudicateTaintDelta`'s four calls, and it has a measured customer whose
disposition differs from the hand peel's. It declines loudly; it cannot produce a
wrong unitary. Two ITEMS and three DOC items besides.

| # | finding | grade |
|---|---|---|
| **F-B6R2-1** | `foldIdentityBitcasts` (`:159` / `:787`) is a FIFTH taint-consuming pre-peel stage and is not re-asked: a same-width int↔int `bitcast` made tainted only by the peel is left STANDING and dies at `no template for opcode 'bitcast i32' in tainted context`, while the hand-peeled twin of the same module lowers at exit 0 **on both binaries** | **OVER-DECLINE** (hand-IR only) |
| **F-B6R2-2** | the peel is a new **customer-generator for bd `3d8q`** (the sibling-`cq_theta` stale-name hole): two sibling chained thetas on ONE peeled mux out-rail, both measured, emit one register — exit 0, 2b clean. PRE-EXISTING and shared (reproduces on the ORACLE with no peel at all) and byte-identical to the hand-peeled twin | **ARGUED** (population-widening item) |
| **M-D** | `declineStaleRecordOps` over the peel delta **HAS a measured customer** (`S02`) — the fix's open question 1 is answered in the affirmative: the call is not dead and must stay | resolved |
| **D-1** | the `delta` is consumed by only TWO of the four calls, and only as a DIRECT-ARGUMENT membership test; the header's framing implies a stronger obligation than the code needs | **DOC** |
| **D-2** | `propagateFromSeeds(…, skipRuntimeCalls=true)` is passed at the ROUND-1 sites with no recorded argument; it is vacuous there today and would stop being so the day a stage emitting `cqrt_*` is added above the peel | **DOC** |
| **D-3** | P10 is pinned by exactly ONE fixture, whose redness requires deleting P10 (not `main`); and `guardedShadowStoreShape` taking a `StoreInst *` is the reason its narrow spelling is sufficient — worth a retirement trigger | **DOC** |

---

## 1. The stage table (brief item 2) — the NOTES §2 method, run from `propagate()` to `:441`

Every stage in `CQLoweringPass::run` between the first `propagate` and the peel,
asked: *does it read `taint.Tainted` to make a decision ABOUT A CONSUMER, and is
that decision falsified when the peel grows taint 250 lines later?* Line numbers
are this tree's; the second entry point mirrors them at `:787`–`:904` / `:921`.

| line | stage | taint-dependent consumer decision? | in the four? | disposition |
|---|---|---|---|---|
| 145 | `lowerByRefInline` fixpoint (+ full re-propagate) | yes — the by-ref out-param producer | no | **ARGUED**: a producer left un-inlined keeps its `store`, which the **re-asked** escape net owns (`kMsgStore`). Decline-only |
| **159** | **`foldIdentityBitcasts`** | **YES — folds ONLY `taint.Tainted.count(BC)` same-width int↔int bitcasts** | **NO** | **HOLE — F-B6R2-1, MEASURED (`BC1`)**. Over-decline |
| 170 | `foldVolatileConstGlobalLoads` | no taint parameter | n/a | — |
| 179 / 194 / 209 / 227 | `foldVolatileConstAllocaLoads`, `eraseDeadVolatileScalarStores`, `promoteVolatileScalarLocals`, `promoteFp80Union` | the GATES are alloca/union SHAPE; taint is carried for scrubbing | no | **ARGUED**: an unpromoted value stays in memory ⇒ the re-asked escape net owns it. Decline-only |
| 251 / 275 / 304 | `flattenPredMuxRegions` fixpoint | yes (E-gates) | no | **ARGUED**: ACCEPT-ONLY. A region it does not claim falls to `detectControlRegions` (the Rule-13-cleared 4.4/Phase-4 substrate) or to a loud decline. No measured customer |
| 273 | `unrollConstTripLoops` | yes (U-gates) | no | **ARGUED + MEASURED** (`L01`, `L06`): ACCEPT-ONLY; an unclaimed loop reaches `lowerLoops` and then `detectControlRegions`, which declines |
| 302 | `recognizeCtlzIdiomLoops` | YES — Z8 needs a TAINTED entry value, and it COMPETES with Q1 | no | **MEASURED `L06`**: the idiom over a peel-tainted entry is not recognised, `lowerLoops` Q1 has already run, and the residual is `nested control flow under quantum control` — loud on the SUBJECT, loud on the ORACLE |
| **321** | `detectSpecializations` | yes | **YES — call 2** | pinned by the fix's mutant M-B (`r20`); 7 measured members here (`r20`,`k01`,`R01`,`R05`,`W13`,`W22`,`Z02`), all twin-identical |
| **330** | `declineTaintEscapes` | yes | **YES — call 3** | pinned by M-C; 9 measured members here (`K01`,`K02`,`K03`,`K05`,`K07`,`L04`,`L05`,`W20`,`W21`) |
| **337** | `declineStaleRecordOps` | yes | **YES — call 4** | **M-D now has a customer: `S02`** (§3) |
| 349 | `lowerControlledIOSinks` | yes | no | **CLOSED BY ITS OWN LOUD DECLINE**, measured (`I01`): its merge gate is `hasNPredecessors(2) && (NumPhis == 0 \|\| ValuePhi)` and `ValuePhi` is only set when `NumPhis == 1`, so EVERY ≥2-φ merge with an I/O-sink arm fires `kMsgIOControl` at `:349` — identical string on both binaries. A classical non-constant value arg fires `kMsgIOArg`. The peel never sees such a site un-adjudicated |
| 365 | `lowerLoops` | YES (Q1 trip count, X1 cross-iteration, `InPlaceRailOps`) | no | **ARGUED + 4 MEASUREMENTS** (`L01`,`L04`,`L05`,`L06`), all loud. The in-place-immediate half — the bd `eqpx` class reached through the peel instead of through round-2 taint — is closed one stage later by `lowerOps`' own G2 re-verification under FINAL taint. `lowerLoops` emits only three CONSTANT-argument `cqrt_alloc_*` calls (`LoopLowering.cpp:1746/1748/1750`), so it cannot leave an emitted runtime call holding a peeled select |

Stages AFTER the peel need no re-ask and were measured to handle a peel-tainted
value correctly: `lowerIOSinks` (`:571`, `K08`), `lowerQramReads` (`:581`, `K09`),
`lowerShadowMemory` (`:593`, `K10`), `declineClassicalMuxes` (`:605`, `K07`),
`specialize` (`:624`, `r20`/`k01`/`R01`/`R05`), `lowerRotations` (`:628`, `K11` —
the peel flips a `cq_theta` from SOURCE to CHAINED and it lowers correctly),
`lowerOps` (`:629`), `uncompute` (`:660`), `EmitInverse` via `cq_invert_*`
(`C02`).

---

## 2. F-B6-1: twelve directions, none re-opened

### 2a. Delta completeness (brief item 1)

`propagateFromSeeds` fills `Delta = Seeds ∪ (Tainted_after − Tainted_before)`, and
the walk it runs IS `propagateWorklist` — the shipped rule, a plain forward
user-graph fixpoint that writes **nothing but `out.Tainted`**
(`TaintPropagation.cpp:374-411`). So the delta is, by construction, a **superset
of every value the peel makes tainted**, whatever the consumer kind.

The *decisive* structural fact — and it is worth writing down, because it makes
the completeness question much smaller than the brief assumes — is that **only
TWO of the four calls consume the delta at all**, and both do so as a
DIRECT-ARGUMENT membership test:

* `replanReseedSpecialization` — `for (Use &Op : Site->args()) if (reseed.count(Op.get()))`
* `detectSpecializations(&reseed)` — the same test (filter (c))

`declineTaintEscapes(M, taint, plan6)` and `declineStaleRecordOps(M, taint)` take
**no delta**: they re-scan the whole module against the (now grown) `taint`. A
consumer therefore cannot be missed by being "far away" from a seed — only by not
being tainted at all, and the walk is the same one `propagate` runs.

Measured anyway, one consumer class per probe, each against its mechanically
hand-peeled twin:

| probe | consumer of the peeled mux | SUBJECT | twin on ORACLE |
|---|---|---|---|
| `K01` | a **classical-condition `phi` in a later block**, then an unknown callee | `unknown callee` | **same string** |
| `K02` | a **`switch`** on the mux | `unknown callee` | **same string** |
| `K03` | a **curated reversible intrinsic** (`llvm.bswap.i32`) | `unknown callee` | **same string** |
| `K04`/`K05` | a **`store` through a GEP whose index is the mux** | `stored to memory` | **same string** |
| `K07` | an i32 **`ret`** (an allowed escape) | `muxed by a classical-condition select` | **same string** |
| `K08` | a **7.6 output tape** value | `continued lineage` | **same string** |
| `K09` | a **QROM read index** (`lowerQramReads`) | **ACCEPT, 34 lines** | **BYTE-IDENTICAL** |
| `K10` | a **Shadow alloca index** (`lowerShadowMemory`) | **ACCEPT, 34 lines** | **BYTE-IDENTICAL** |
| `K11` | **arg-0 of a `cq_theta`** — the peel flips it SOURCE → CHAINED | **ACCEPT, 33 lines** | **BYTE-IDENTICAL** |
| `K04`(2-hop)/`R05` | a Phase-6 candidate reached **two hops** / **transitively** | ACCEPT | **BYTE-IDENTICAL** |
| `C01` | the region's condition is an **`fcmp`** (the clone is an `FCmpInst`) | **ACCEPT, 32 lines** | **BYTE-IDENTICAL** |
| `C02` | a `cq_invert_begin/_end` bracket over a mux-derived chain | ACCEPT | emitted-symbol stream **IDENTICAL** |
| `CF1` | a `freeze` of a mux-derived value (the re-asked escape net's identity-freeze FOLD, a MUTATION, now runs a second time) | **ACCEPT, 32 lines** | **BYTE-IDENTICAL** |

On the round-1 reviewer's own `Instruction::clone`-metadata question (their §7
item 6, carried forward as fix OQ4): at LLVM 19 an `ICmpInst` carries **no**
poison-generating flags, and an `FCmpInst`'s fast-math flags and `!dbg` are copied
identically to the original's — so the clone mints the same flag the original
would. `C01` is the measurement.

### 2b. The four-call set (brief item 2) — see §1. One hole, F-B6R2-1.

### 2c. `r20`'s byte-identity claim (brief item 4)

Re-measured at the **IR** level, not only the trace:

```
diff  r20.s.ll (SUBJECT, fused)   r23.o.ll (ORACLE, hand-peeled twin)
1c1
< ; ModuleID = 'r20_clone_measured.s1.ll'
> ; ModuleID = 'r23_clone_handpeel.s1.ll'
```
— i.e. **byte-identical apart from the input filename**. Varied as the brief asks:

| variation | SUBJECT | vs its own hand-peeled twin on the ORACLE |
|---|---|---|
| `R01` helper with **two tainted args** (mux + region φ) | ACCEPT, emits the bare Q+Q `cq_template_add_i32(h1,h4)` | **BYTE-IDENTICAL** (25 lines) |
| `R02` helper returns **void** (and stores) | LOUD `cq specialization: callee contains a non-reversibilizable construct … (memory access)` | — |
| `R03` helper **inlinable** (no `noinline`) | ACCEPT, the arms fold to `alloc(8)`/`alloc(6)` | **BYTE-IDENTICAL** (21 lines) |
| `R04` measure on the **mux itself** as well as on the result | ACCEPT, 27 lines | **BYTE-IDENTICAL** |
| `R05` **transitive** (6.3) inner clone | ACCEPT, 36 lines | **BYTE-IDENTICAL** |

### 2d. Round-2 sites (brief item 6)

`adjudicateTaintDelta` is called **once per `repropagateControlMerges` call**, after
the whole `detectAndLowerOnwardControl` fixpoint, over
`reseed = UntaintedMergeRails ∪ (Tainted − beforeTaint)` with `beforeTaint`
snapshotted at function ENTRY — so **every iteration's** peel growth is inside it.
The `if (delta.empty()) return;` the fix adds can never fire there (the function
early-returns on `UntaintedMergeRails.empty()`, so `reseed ⊇ UntaintedMergeRails ≠ ∅`),
which is what makes the refactor behaviour-preserving. Measured on the round-2
pin's own hand-IR shape (`control_peel_round2_out_cond.ll`'s module):

| probe | round-2 peel's mux consumer | SUBJECT | ORACLE |
|---|---|---|---|
| `W20` | `store` to a global | **`tainted value stored to memory`** | `control flow` |
| `W21` | unknown callee | **`tainted value consumed by an unknown callee`** | `control flow` |
| `W22` | a Phase-6 candidate (the `r20` shape one round later) | ACCEPT, 39 lines — `cq_template_add_i32_hl(h8, 1)` **on the rail**, not on a handle tag | twin **BYTE-IDENTICAL** |
| `W23` | a **ROUND-3** region's condition | ACCEPT, 41 lines — flag mint on `h8`, controlled Ry, strip, free | twin **BYTE-IDENTICAL** |

### 2e. `detectSpecializations` at its THIRD program point (fix OQ3, bd 9paa)

The implementer argued, without a probe, that the peel's delta cannot contain a
region's own not-yet-lowered merge φ. **It can** — `Z02` is the customer: a second
region's merge φ over the peeled mux becomes tainted through the delta, the call
reading it enters `Pending` at `:444` while the region is UNLOWERED, and
`lowerControlRegions` RAUWs the φ to the 4.4 `%out` afterwards. The result is
correct and **BYTE-IDENTICAL to the hand-peeled twin** (48 lines): the clone reads
`cq_template_add_i32_hl(h13, 1)` on the merge out-rail. `CL1` confirms the other
half — a candidate whose body contains control still declines LOUDLY at the third
program point (`cq specialization: callee contains tainted control flow under
quantum lift`), i.e. the mask-independent `scanBody` is unaffected by the new slot.

### 2f. The angle boundary, re-attacked through the fix (brief item 8)

A peeled ANGLE select cannot reach a Phase-6 clone: `classifyCandidate` step (A)
requires every tainted argument to be an i32 handle, and the tainted `double`
never gets that far — `A01` declines `rotation angle under quantum control`
**identically on both binaries**, as does `A02`. The peel cannot run INSIDE a
clone body either (`specialize` is `:624`, the peel `:443`; a callee's values carry
no taint at `:443`), so the P7/F-L3-1 "orphaned angle in the clone" shape is
structurally unreachable — an over-decline, worth recording rather than probing
further. The round-1 angle family re-ran unchanged (`f01`,`f03`,`f04`,`f05`,`f06`,`f07`,
`d01`,`d02`), and `f01`/`f04`/`d02` are now additionally **twin byte-identical**.

---

## 3. M-D: `declineStaleRecordOps` over the delta HAS a customer (brief item 3)

The fix could not construct one and recorded a structural argument. **The argument
is wrong, and the clause is load-bearing.** The missing case is not an op that
reads a stale record *and* the mux — it is an op whose staleness is CREATED by the
peel, because the peel flips a `cq_theta` from a SOURCE mint to a CHAINED rotation
on the mux rail:

```c
int m = 5, n = 1;
if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
int r = cq_theta(m, 0.2);   // SOURCE prep at :337 (m is a classical φ);
                            // CHAINED at lowerRotations (m is the mux rail)
int s = m + 1;              // reads the PRE-Ry record of that same rail
```

`S02`, plain C at `-O1`. At `:337` `m` is a classical `phi`, so `s = m + 1` is a
classical `add` and is not even in `inLowerOpsScope` — the once-only sweep
structurally cannot see it. The SUBJECT declines
**`cq opcode lowering: operand predates a non-diagonal gate`**, and the ORACLE gives
its hand-peeled twin the **same string** at its own `:337`. `checkStaleOp` has
exactly one caller (`OpcodeLowering.cpp:201`, inside `declineStaleRecordOps`), and
`declineLiftedStaleRecordOps` (`:615`) is gated on a non-empty `LiftedConsumers`
which this module cannot populate — so the decline comes from call 4 of
`adjudicateTaintDelta` and from nowhere else.

**Answer: the call must stay; mutant M-D now has a pinnable customer.** It deserves
a decline fixture (`S02` transcribes directly) — the current set pins three of four
calls.

---

## 4. F-B6R2-1 — `foldIdentityBitcasts` is the FIFTH stage (OVER-DECLINE, hand-IR only)

`foldIdentityBitcasts` (`:159`, mirrored at `:787`) folds a same-width int↔int
`bitcast` to its operand **only when the bitcast is already in `taint.Tainted`**
(`TaintPropagation.cpp`: `if (taint.Tainted.count(BC) && …)`). It is the ONLY
handler for that opcode — its own header says the fold-eligibility test mirrors
`castInScope`'s accept — so a tainted bitcast it does not fold has no template.

The peel taints such a bitcast ~280 lines later. Four-way matrix, `BC1` (hand IR:
a 3-φ merge, two peelable, `%bc = bitcast i32 %mux to i32`):

| module | ORACLE | SUBJECT |
|---|---|---|
| FUSED (φ) | `control flow under quantum control` | **`no template for opcode 'bitcast i32' in tainted context`** |
| HAND-PEELED twin | **exit 0** | **exit 0** |

So the SUBJECT lowers the hand peel of this very module and declines the module the
peel is supposed to make identical to it. That **falsifies the increment's stated
contract** ("produce the module the hand peel already is") — in the SAFE direction.

* Not reachable from `clang -O1` C: an `i32→i32` bitcast is folded by InstCombine
  long before the pass sees it, so the population is hand IR (and union punning of
  same-width integers).
* The residual is a LOUD decline, never a wrong unitary: `castInScope` has no
  accept for an unfolded tainted bitcast.
* Two cheap dispositions: add `foldIdentityBitcasts(M, taint)` as a fifth call in
  `adjudicateTaintDelta` (it is idempotent and monotone — it only ever removes
  no-ops), or record the residual at the peel's slot comment beside the other four.
  The first is a Rule-14-clean reuse; the second is honest. **What must not happen
  is the stage table claiming four when it is five.**

---

## 5. F-B6R2-2 — the peel widens bd `3d8q`'s population (ARGUED)

`S03` — the same program as `S02` with the `add` replaced by a SECOND chained theta:

```c
int r1 = cq_theta(m, 0.2);
int r2 = cq_theta(m, 0.6);   // SIBLING on the same mux rail
```

accepts at `opt` exit 0, STRICT 2b clean, and emits
`ry(h8,0.2); ry(h8,0.6); measure(h8); measure(h8)` — `r1` measured as
`Ry(0.6)Ry(0.2)|m⟩` where the source names `Ry(0.2)|m⟩`. Two warnings fire
(`non-diagonal gate over a live derived record`) and nothing declines.

**It is NOT the peel's**, and that is measured, not argued: `S04` is the same defect
with **no peel anywhere** (`int m = q + 1; r1 = cq_theta(m,.2); r2 = cq_theta(m,.6);`)
and it reproduces on the **ORACLE**, exit 0, 8 lines, one register. This is
CLAUDE.md's open P1 bd `test_C_libtooling-3d8q` — *"the pass-wide stale-record guard
sweeps PURE ops only, so a `cq_theta` or `cq_measure` READER of a stale name is
never asked"*. `S03` is byte-identical to its hand-peeled twin.

The ITEM is the population, not the defect: **a 4.4 merge OUT-RAIL is now a shared
parent**, so `3d8q`'s customer set grows with this increment. It belongs in the
`3d8q` row, not as a blocker here — but it should be written down before `3d8q` is
scoped, because its fix will have to cover a rail nobody wrote in the source.

---

## 6. P10 / F-B6-2 (brief item 5) — holds; the narrow spelling is sufficient

`armWritesMemory` sees `StoreInst`/`AtomicRMWInst`/`AtomicCmpXchgInst` and **NOT**
`@llvm.memset`/`@llvm.memcpy` (they are `CallInst`s) nor a call to a function that
stores. I built all three and each declines anyway, at the ARM classifier:

| probe | arm content | ORACLE | SUBJECT |
|---|---|---|---|
| `M03` | `@llvm.memset` on a global | `control flow` | `control flow` |
| `M04` | `@llvm.memcpy` | `control flow` | `control flow` |
| `M02` | a call to a visible function that stores | `control flow` | `control flow` |
| `M05` | a plain `StoreInst` (the P10 control) | `control flow` | `control flow` |
| `g01` | the 7.5 guarded Shadow store | `guarded store with a merge value` | **same string** |
| `g02` | its one-φ control | ACCEPT | ACCEPT, unchanged |

The reason the narrow spelling is enough is structural and should be in the comment:
**the only owner in the tree that ACCEPTS an arm which writes is the 7.5 guarded
store, and its recogniser is `bool guardedShadowStoreShape(llvm::StoreInst *SI, …)`
(`QramLowering.h:83`) — it takes a `StoreInst *`.** Every other write-arm shape has
no classifier at all and dies at `control flow`. That is a **retirement trigger**: the
day any classifier accepts a `MemIntrinsic` arm, P10 must widen with it. I found no
over-decline: no accept fixture and no shipped slice has a write in a peeled arm.

---

## 7. Decline-string moves (brief item 7)

Both probe corpora re-run end-to-end on both binaries
(`review_b6ap_r2_probes/sweep_r1probes.txt`, `sweep_implprobes.txt` — 39 + 48
entries). **Every SUBJECT verdict is either an ACCEPT of a shape the ORACLE
declines, or a LOUD decline. Nothing went decline → silent; nothing went
accept → decline.** The moves, all within the decline class:

| probe | ORACLE | SUBJECT | owner |
|---|---|---|---|
| `f02` | `control flow` | `tainted value stored to memory` | the re-asked escape net now owns it (the fix's own noted move) |
| `x03` | `control flow` | `tainted value stored to memory` | same — the r1 `freeze` probe was built on an escaping module |
| `r02`/`r04`/`r07`/`r11` | `control flow` | the four escape strings | the F-B6-1 fix |
| `r09`/`r10` | `control flow` | `returned at non-i32 width` / `not a lowerable integer scalar` | deeper fences |
| `s01` | `control flow` | `stale rail record read past a controlled Ry` | gate 2c |
| `p85`/`p86`/`p87` | `control flow` | `condition predates a non-diagonal gate` / `state prep seed is proven equal…` | the increment's own |
| `p00`/`p01`/`p20`/`p21`/`p40` | `control flow` | `bare i1 register condition` | bd `l4x4` |

On whether an EARLIER owner ever gives a *worse* message (the fix's own round-2
question 2): in every move above the new string is strictly MORE specific than
`control flow under quantum control`, and every one of the 48 hand-peeled `h*`
probes gives the **same verdict on both binaries**, so the escape net taking
ownership does not relocate a message away from its true cause.

**Independent corpus diff** over the pre-existing fixtures (the 35
`control_peel_*.ll` excluded), exit code + stderr + lowered text, stride-3 sample:

```
=== 592 fixtures compared (stride 3): 0 RCDIFF, 0 DIAGDIFF, 0 OUTDIFF ===
```

---

## 8. Rail-root (`isCondRailLeaf`) peels — the r9e5 discipline is inherited, measured

The `bool` e2e slice exercises the rail-root path with TWO muxes, and the golden is
right: **two independent `cqrt_cnot(h0, hN)` copies of the user register, each
`cqrt_x`-bracketed on its own ANCILLA, each un-copied and freed at `|0⟩`; the
register carries only the diagonal `cqrt_rz_i1(h0, 0.7)` and read-only controls.**
That is `CopyRailRoot` verbatim — the peel inherits it by handing the select to
`SelectMergeEmit` rather than re-spelling it (Rule 14). The two r9e5 rail fences
still fire through the peel, identically on both binaries:

| probe | SUBJECT | ORACLE |
|---|---|---|
| `RL1` rail measured before the read point | `condition measured before the control route` | **same string** |
| `RL2` sibling `cq_theta` between the rail's def and the selects | `condition predates a non-diagonal gate` | **same string** |

Note for the record: **N peeled muxes on a rail root mint N CNOT copies of the user
register** (2 in the shipped slice). Each is a read-only control and sound; it is the
rail-root form of OQ-1's cost, and it will grow when bd `l4x4` lands and the
`stateprep_rail` fixture flips to an accept.

---

## 9. Gates I ran

| gate | result |
|---|---|
| `ctest -R ir-pass-lit` (SUBJECT) | **Passed, 40.29 s, 1/1** |
| `ctest -R 'fused.regions\|guarded'` | **6/6 Passed, 5.77 s** |
| independent corpus diff, ORACLE vs SUBJECT, stride-3 over the 1776 pre-existing fixtures | **592 compared — 0 RCDIFF, 0 DIAGDIFF, 0 OUTDIFF** |
| red-green of the 10 NEW fixtures on `main` 0c7380c | 8 decline `control flow` (RED); the 2 guarded-store ones behave as their headers state (`..._reject_guarded_store` keeps its string, `..._ctrl_unchanged` is exit 0) |
| both probe corpora re-run on both binaries (`sweep.sh`) | 39 + 48 entries, **0 decline→silent, 0 accept→decline** |
| 27 mechanical hand-peel twins (`handpeel.py` + `twin.sh`) | **27 BYTE-IDENTICAL, 9 same-diagnostic, 1 divergence (`BC1` = F-B6R2-1)** |
| full `ctest` | NOT run (the brief forbids it); the fix records 389/389 |
| `e2e-loop-twin-matrix` | NOT re-run (1027 s). §6 of round 1 ruled the five cells and the fix kept the ruling; I re-derived nothing and take no new position |

---

## 10. Items for the next round / for the record

1. **F-B6R2-1** — decide: a fifth call, or a recorded residual. Either way the slot
   comment and `FIX_b6ap_R1.md`'s stage table must stop saying the set is four
   consumer-adjudicating stages when `foldIdentityBitcasts` is a fifth.
2. **A decline fixture for `S02`** — M-D is the only one of the four calls with no
   fixture, and it now has a reachable plain-C customer.
3. **F-B6R2-2** — add the peel's merge out-rail to bd `3d8q`'s population note.
4. **DOC, the delta's contract** — say in `TaintPropagation.h` that only the two
   SPEC calls consume `delta`, and as a DIRECT-ARGUMENT test; the other two re-scan
   the module. It is what makes completeness cheap, and it is what a fifth,
   delta-driven call would invalidate.
5. **DOC, `skipRuntimeCalls=true` at the round-1 sites** — vacuous today (only
   `lowerControlledIOSinks` emits before the peel and it loud-declines every ≥2-φ
   merge; `lowerLoops`' three `CreateCall`s are constant-argument allocs). It stops
   being vacuous the day a stage that emits `cqrt_*` is added above the peel.
6. **DOC, P10's retirement trigger** — `guardedShadowStoreShape` takes a
   `StoreInst *`; that, not breadth, is why the narrow spelling suffices.
7. **Assume a fifth thing.** This round's productive question was the fix's own, one
   level up: *"the fix re-asks the stages that adjudicate consumers — is the set of
   such stages the set the fix enumerated?"* It was not (F-B6R2-1). The successor
   for round 3 is the other half: **the peel does not only GROW TAINT, it DELETES a
   `phi` and INSERTS two instructions.** I checked the consumers of the deletion
   (`soleMergePhi`, `liftOneRegisterMergePhi`, `LiteralIntegrity` guard 1,
   `BirthOrder`) and of the insertion (`condDataUseDisposition`,
   `f2SeedPinnedByLiveRegister`, `reverifyRailCondReads`) and found nothing — but I
   checked them by reading, not by a probe family, and that is exactly the shape of
   argument this project's history says to distrust.
