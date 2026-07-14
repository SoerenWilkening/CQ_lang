# PRD — 3c6m.14 (L6): General acyclic tainted control via block-predicate MUX flattening ("PredMux")

**bd:** `test_C_libtooling-3c6m.14` (P1, gate OPENED by owner go-decision 2026-07-13)
**Branch:** `3c6m.14-control-l6` (off main @ `b6345ec`, census + 3c6m.13 signpost included)
**Written:** 2026-07-13, at phase start (Rule 16)
**Evidence base:** census 3c6m.50 (`tools/library_coverage/FULL_DEPTH_CENSUS.md`,
4-lens adversarially verified) · this PRD's own recon (8-agent workflow over the
8 inlined target bodies + the emitter architecture, 2026-07-13) · 11 live
substrate probes (§2.3).

---

## 0. Standing directives (owner, 2026-07-13 — stamped onto every libm lever ticket)

1. **Rule 17 — this is a BUILD ticket.** The census target shapes below are
   exactly what we set out to support; a safe-decline is **not** the escape
   hatch for them. If a sub-part proves harder than scoped, bring it to the
   owner or file a scoped follow-up — never ship a decline-only stub for the
   target shape. (A genuinely off-pattern input outside the target still
   declines loudly — unchanged.)
2. **Ground truth = Bennett.jl** (tobiasosborne/Bennett.jl;
   `docs/design/bennett-parity/PARITY_MAP.md`). This capability is
   **B-recognition**: Bennett demonstrably compiles general acyclic control
   (`_compute_block_pred!` OR-reduced block predicates, PARITY_MAP.md:147 = bd
   `iw81.14`), and the 3c6m.50 census confirmed **0 C-physics walls** anywhere
   in libm (independent 241-body scan). Never a physics impossibility.
3. **Exact per-cell targets** from `peel_census_merged.json` (§1). Projections
   are upper bounds; only the 8 first-milestone cells are IR-verified.
   **Re-census after landing** to expose layers hidden behind control.
4. Follow-ups are explicitly permitted for harder-than-scoped sub-parts.

**Correctness doctrine (SCOPING.md §0, restated because it binds everything
below):** RSSA/Bennett prove *classical* reversibility only. No correctness
claim here is "it's Bennett, therefore correct" — the quantum-coherence
argument is made freshly in §6, and reduces to already-Rule-13-cleared CQ
substrate plus a *classical* IR-equivalence proof obligation.

---

## 1. Goal and target set

**Goal:** lower real openlibm libm bodies whose only blockers are
tainted-control-family shapes — arbitrary-depth **acyclic** nests of tainted
`br`/`switch`, multi-phi and N-incoming merges, DAG (non-tree) reconvergence,
sequential sibling regions, and (for exp/erf/atan) const-global table reads
under that control.

**First milestone — the 8 IR-verified CONTROL-alone cells** (Lens A: 0 allocas,
0 stores, 0 loops post-O2, blockers exclusively control-family):

| order | cell | body | blocks | shape highlights (recon 2026-07-13) |
|---|---|---|---|---|
| 1 | `scalbn.f64` | s_scalbn.c | 9 | tainted 3-way `switch` + nested brs in 2 arms; **cross-arm DAG join** (`.thread4.i`, 3 phis); 5-way return merge |
| 2 | `lround.f64` | s_round.c (+floor ×2) | 32 | depth ~5–6 nest; two mirrored floor sub-DAGs; 6-pred merges with **2 phis sharing edge predicates**; fcmp conds; `fneg`, `fptosi` |
| 3 | `log.f64` | e_log.c | 22 | depth ~5; 11-incoming return phi; interior 3-phi merge whose outputs drive later conditions; 1 fcmp among 10 int conds |
| 4 | `tanh.f64` | s_tanh.c (+expm1 ×2) | ~90 | deepest nest (~7–8); **two nested tainted 3-way switches**; k-mux re-tested as scrutinee; **undef phi incomings**; compound AND conds |
| 5 | `cbrt.f64` | s_cbrt.c | 7 | staircase early-exits; 2-phi interior merge; `udiv` by const 3 (opcode-table-covered) |
| 6 | `atan.f64` | s_atan.c | 19 | sequential top-level regions; reused cond across regions; **QROM reads** (@atanhi/@atanlo, muxed index); **volatile load**; compound conds |
| 7 | `exp.f64` | e_exp.c | ~30 | **QROM reads** (@ln2HI/@ln2LO/@halF, tainted sign-bit index, in-bounds [2 x double]); **volatile @twom1000 loads** (never-stored internal global); 9-way return merge |
| 8 | `erf.f64` | s_erf.c (+exp ×2) | 62 | **two full exp bodies in sequence** (strongest sequential-sibling case); 6 QROM reads + 6 volatile loads; 9-way return merge |

All 8 reproduce their census declines on this branch (verified 2026-07-13):
scalbn = flat `control flow under quantum control` at the switch
(SwitchClassify G11 nested-br); lround/log/atan/cbrt/tanh = `nested control
flow under quantum control`; exp/erf = the 3c6m.13 signpost `const-global table
read under tainted control` (fires at `declineTaintEscapes`, **before**
detection).

**Projected ceiling** (do not quote as verified): ≤48 CONTROL-alone cells; 119/123
cells have CONTROL on their critical path. The ~40 uninspected cells need
per-cell IR inspection before claiming (census blind spots: post-control opcode
gaps, accepted-Shadow stores, masked loops).

**Named substrate sub-issues this work subsumes or advances:** `1dky`
(sequential same-source siblings — subsumed for pure-dataflow regions),
`iw81.14` (path-predicated phi / `_compute_block_pred!` — this IS that engine,
realized at the classical IR level), `3lro` (in-loop control — explicitly OUT,
§7).

---

## 2. Design decision: flatten to the shipped select substrate, not a new gate emitter

### 2.1 The decision

**PredMux is a classical IR-to-IR CFG normalization, not a gate emitter.** A
new pass module (`PredMuxFlatten.cpp`) recovers a maximal eligible acyclic
tainted-control region and rewrites it — *entirely at the LLVM IR level,
before any gate is emitted* — into straight-line code:

- every arm instruction moves to the entry block in topological order
  (unconditional evaluation of all arms — precisely the compute-everything
  discipline method-B and the 4.4 select merge already practice at gate level);
- every tainted `br`/`switch` edge becomes an **edge predicate** — an `i1`
  expression over (possibly predicate-inverted) `icmp`/`fcmp` leaves composed
  with `and`/`or` (§4.3);
- every merge phi becomes a **chained `select` network** keyed on edge
  predicates (§4.4);
- the region's blocks are erased; the function shrinks by one region.

After the flatten + re-`propagate`, the module is exactly the kind of
straight-line tainted-select program the pass already lowers end-to-end: the
selects land in `SelectClassify`/`SelectMergeEmit` (4.4, incl. the kjd1 fp-DATA
family), compound `i1` trees land in the 3c6m.12 Toffoli conjunction network,
compares in `CompareLowering`, casts/arith in `lowerOps`, (later increments)
now-straight-line table reads in the 7.5 QROM path, and the Phase-5 whole-DAG
LIFO spine + the emitters' own flag-strip/free discipline clean the garbage.

### 2.2 Why (Rule 14 — reuse over reinvention)

A new *gate* emitter for general control would have to own: flag mint +
per-seed stale-condition wire walks, conjunction-ancilla LIFO, controlled-copy
bracket polarity, out-rail bookkeeping (`Tainted`/`BirthOrder`/`HandleWidth`/
`UntaintedMergeRails`/`ControlOwnedRails`), round-2 repropagation, uncompute
bucket classification, and block-lifetime teardown — each a documented
silent-miscompile site in the project history. PredMux owns **none** of them:
it never mints a gate, never touches a rail, never writes taint bookkeeping
(it re-runs `propagate` instead). Every quantum-side obligation is discharged
by shipped, Rule-13-cleared machinery *through its existing entry points*.

The docs endorse exactly this framing: iw81.14 names the missing engine as
"generalize to OR-reduced block predicates (Bennett `_compute_block_pred!`
algebra)"; the conjunction algebra "already exists in miniature" and is
Rule-13-cleared for select conditions (compound-cond-select PRD §45–109); the
QCM/Bennett reconvergence theorem gives the structural precondition
(synchronization + injectivity). PredMux lifts the shipped condition-tree
algebra from select conditions to block-reachability predicates — at the IR
level, where the composition is *checkable by classical reasoning alone*.

### 2.3 Substrate envelope — verified live (2026-07-13, this branch)

Eleven hand-written probes compiled through the real pipeline
(`clang -O1` → `cq-lowering`), each verified to exercise real select lowering
(controlled-copy calls present; p3 minted 3 Toffolis):

| probe | shape | result |
|---|---|---|
| p1 | cascaded selects `c1 ? a : (c2 ? b : c)` (int) | exit 0 |
| p2 | **one condition shared by two selects** (the multi-phi-merge shape) | exit 0 |
| p3 | depth-3 `&&`/`!` compound condition | exit 0, Toffoli network |
| p4 | fcmp condition + f64 data | exit 0 |
| p5 | **condition derived through another select's result** | exit 0 |
| p6 | f64 select + `fptosi` + `fneg` + i64 measure | exit 0 |
| p7/p8 | literal arm (int / f64) | exit 0 |
| p9b | depth-3 **f64** select cascade | exit 0, 7 controlled copies |
| p10 | `fdiv` inside an arm | exit 0 |

(p9 also demonstrated that clang itself refuses deep if-conversion — 0 selects
at O1 for a 3-deep nested ternary — which is precisely the gap PredMux fills.)
Integer division (`udiv`/`sdiv`/`urem`/`srem`) and `fdiv`/`frem` are in
`opcode_table.yaml` at all widths, so cbrt's `udiv` is covered.

**Depth validated (2026-07-13, this branch):** the synthetic depth-20
data-cascade (p12: 20 selects → 41 controlled copies) and depth-10
select-feeds-condition cascade (p13: 21 controlled copies) both lower clean —
the fixpoint depth lround/log/tanh need is proven live. Inc 1 carries both as
committed fixtures.

---

## 3. Non-goals (v1) — these stay with their owners or stay declined

- **Phase arms / any region containing `cq_*` calls** (rotations, measures,
  I/O): stay with the swap-route emitters (4.1/4.3) or their loud declines.
  PredMux eligibility excludes them structurally (§4.2 E4) — no behavioral
  change for every shipped accept shape.
- **In-loop tainted control** (`3lro`): region entry on a CFG cycle is never
  claimed; the d8jl decline stands.
- **Stores / Shadow memory under control**, dynamic-shape arrays: not claimed
  (E5). (QROM *reads* are Increment 3, under proof.)
- **Non-curated calls inside regions** (incl. classical-call arms — 6.5 owns
  those; they contain calls, so E4 leaves them).
- **Multi-exit regions** (a `ret`/`abort` inside an arm that does not rejoin):
  not claimed; 7.2's abort-park/controlled-return and the existing declines
  own them. (All 8 targets are early-return-*unified* by O2 — single exit.)
- **Irreducible CFGs**, `i128`/vector/`fp128` data at merges, atomics,
  `va_arg`: not claimed (E2/E7); existing declines stand.
- **fp-angle consumers**: unchanged — the three-legged angle fence and the
  select-emitters' own gates adjudicate post-flatten exactly as they do for
  hand-written selects today.

---

## 4. Algorithm specification

New module `ir-pass/src/PredMuxFlatten.cpp` (`cq` namespace), entry
`bool flattenPredMuxRegions(Module&, WidthDispatch&, TaintSet&)` returning
"changed", driven to fixpoint by the orchestrator (§5).

### 4.1 Region recovery

For each function, in block order: find a **tainted terminator** `T` (a
conditional `br` whose condition ∈ `taint.Tainted`, or a `switch` whose
scrutinee is tainted) not yet claimed. Let `E = T->getParent()`.

- `M` = the immediate post-dominator of `E` (PostDominatorTree, computed fresh
  per candidate — never cached across mutations, Rule 9).
- Region `R` = all blocks on paths `E → M`, excluding `M` but including `E`
  (forward DFS from `T`'s successors, stopping at `M`).

### 4.2 Eligibility ladder (ALL must hold, else **leave untouched** — PredMux is
accept-only; every non-claimed shape falls through to today's loud declines,
exactly the `lowerByRefInline`/`lowerControlledIOSinks` accept-only precedent)

- **E1 — claim witnesses (anti-overlap with shipped emitters).** At least one:
  (W1) some block in `R` other than `E` has a tainted conditional terminator
  (nested/sequential-hosting shapes — flat accepts require straight-line arms);
  (W2) `T` is a `switch` with a non-straight-line arm; (W3) `M`'s phi set is
  not the sole-2-incoming single phi (`≥2` phis, or a single phi with `>2`
  incomings) **and** the shape is not a shipped switch-accept (which requires
  straight-line arms, so W2 covers it). These witness that today's detection
  *declines* the region (its accepts are pinned by its own fixtures:
  `soleMergePhi` 2-incoming, straight-line arms, depth-2 homogeneous-phase
  nests — the latter contain `cq_phi` calls and are excluded by E4 anyway).
  Wrong-direction risk is fail-safe both ways: a wrongly-claimed
  would-have-been-accepted region still lowers correctly (different, equally
  cleared mechanism); a wrongly-unclaimed region declines loudly as today.
- **E2 — acyclicity + not-in-loop.** No block of `R` on any CFG cycle; `E` not
  in a loop (reuse/mirror `regionEntryInLoop`'s reducibility-independent walk).
- **E3 — single exit.** Every terminator inside `R` targets blocks in
  `R ∪ {M}`; no `ret`/`unreachable`/`indirectbr`/`invoke`/`callbr` inside `R`.
- **E4 — pure speculatable dataflow.** Every instruction in `R` is one of:
  binary int/fp arithmetic, bit ops, `icmp`/`fcmp`, casts, `select`, `phi`,
  `fneg`, `freeze`, or a **call to a curated pure keep-set intrinsic**
  (`llvm.fmuladd`/`fma`/`fabs`/`copysign`/`sqrt`/min/max/rounding — exactly the
  `isCuratedReversibleIntrinsic` + hardware keep-set surface; `memory(none)`
  required). Any other call (incl. any `@cq_*`), any store, any atomic → leave.
  Loads: **Increment 1–2: leave**; Increment 3 admits the two proven forms in
  §4.5(c)/(d).
- **E5 — no memory writes** (subsumed by E4; stated for the decline matrix).
- **E6 — tainted-only internal control.** Every conditional terminator inside
  `R` is tainted. (A *classical* branch inside a tainted region is a mixed
  shape — leave; today's paths own it. Classical-condition selects over
  tainted data inside `R` are also left — `declineClassicalMuxes` domain.)
- **E7 — mux-lowerability type gates** (detect-before-mutate: mirror the
  substrate envelope so a claimed region cannot half-lower): every phi being
  converted has integer width ≤ 64 **or** scalar fp `f16/f32/f64/f80`
  (`abiWidthFromType` non-empty + the copy families' envelopes); every
  condition leaf is an `icmp`/`fcmp` on template-supported scalar types.
- **E8 — value-only merges.** `M`'s phis (and internal phis) are data merges;
  any phi that is `Rz`-lineage-phase-answer-shaped is unreachable here since E4
  excludes rotations inside `R`; the post-flatten angle fence still backstops.
- **E9 — no `R`-defined value used outside `R ∪ M-phis`** (SSA guarantees this
  for a single-exit region; asserted, not assumed).

### 4.3 Predicate algebra (the `_compute_block_pred!` realization)

Process `R` in topological order (exists by E2):

- `BP(E) = ⊤` (represented as "no predicate"; never materialized).
- For edge `e = (S → D)` with terminator polarity: literal `lit(e)` =
  - `br i1 c` true-edge → `c`; false-edge → **predicate-inverted compare**:
    when `c` is a single-use `icmp/fcmp`, emit a fresh compare with
    `getInversePredicate` (NaN-correct for fcmp: ordered ↔ unordered); when
    `c` is compound or multi-use, emit `xor i1 c, true` is **forbidden** —
    instead push the negation to leaves by De Morgan during construction (the
    network is built by PredMux, so ¬ never lands on an interior node; leaves
    are always direct compares, possibly inverted). This keeps every emitted
    tree inside the 3c6m.12-cleared and/or-over-compare-leaves shape (its
    Toffoli/CNOT algebra has AND and OR nodes only).
  - `switch` case-`k` edge → `icmp eq scrut, k`; default edge →
    `and` of `icmp ne scrut, k_i` over all cases.
- `EP(e) = BP(S) ∧ lit(e)` (skip the ∧ when `BP(S) = ⊤`).
- `BP(D) = EP(e₁) ∨ … ∨ EP(e_m)` over `D`'s in-edges (m ≥ 2 only at
  reconvergence points; OR is required exactly there — scalbn's
  `.thread4.i`, exp's `%27`).
- All predicate instructions are inserted in the linearized stream *after*
  the values they read, cached per block/edge (each `BP`/`EP` materialized
  once — no per-phi duplication; sharing is safe: p2 probe + the 3c6m.12
  "controls are read-only, shared nodes safe by construction" clearance).

**No-NOT invariant:** by construction the network contains only and/or over
(possibly inverted) compare leaves. Any shape that would force an interior
negation that cannot be pushed to leaves does not exist under E6 (every
literal is a compare or a case-equality).

### 4.4 Phi → select chains

For each phi (internal merges first, in topo order; then `M`'s phis) with
incomings `(v_i, e_i)`, `i = 1..m`:

```
mux = select(EP(e₁), v₁, select(EP(e₂), v₂, … select(EP(e_{m-1}), v_{m-1}, v_m)…))
```

- The last incoming is the fallback (its `EP` is implied by "merge reached ∧
  no earlier edge taken"; per basis state the taken path makes exactly one
  `EP(e_i)` true — §6.1).
- **Unreached-merge garbage is inert:** when an *internal* merge is not on the
  taken path, all its `EP`s are false and the chain yields the fallback's
  (garbage) value; every downstream consumer of that value is itself selected
  only under edge predicates that conjoin the (false) `BP` of the consuming
  block — the ∧-with-block-predicate excludes garbage *everywhere*, including
  muxed-scrutinee re-tests (tanh's k-switch) whose garbage eq-flags are ANDed
  with a false `BP`.
- `undef` incomings (tanh `%87`/`%230`) are **frozen to the type's zero
  constant** before conversion (the incoming is dead on every basis state that
  selects it — clang emits `undef` precisely because the source never reads it
  on that path; freezing pins a deterministic bit-pattern so no poison enters
  the predicate network).
- phis whose incomings all come from `R`-edges convert fully; `M`-phis with an
  incoming from outside `R` cannot occur (E3: `M`'s only `R`-external preds
  would make `M` reachable around `E`… possible in general — e.g. a pre-region
  bypass. **v1 rule:** if `M` has any predecessor outside `R ∪ {E}` the phi
  keeps that incoming and gains exactly one new incoming from the flattened
  `E` (the chain value); if that leaves a live 2-incoming phi over tainted
  data with a *classical* reaching edge, it is the `declineClassicalMuxes`
  domain and the region is **left unclaimed** instead (checked at E3-time:
  `M`'s preds ⊆ R). The 8 targets all satisfy preds(M) ⊆ R.)

### 4.4a Inc 2 — i1 phis convert to boolean algebra (the tanh mechanism)

An i1 phi converted to a select chain produces a `select i1` VALUE; when that
value feeds a downstream select **condition**, the condition falls off the
3c6m.12 and/or-over-compare-leaves flag-mint grammar (`collectCondTree`,
SelectClassify.cpp) and the consuming select declines `control flow under
quantum control` — the census tanh.f64 blocker (`s_expm1.c:168`,
`k = invln2*x + ((xsb==0)?0.5:-0.5)`, where `xsb==0` reaches the ternary
through an i1 phi at an internal merge).

Inc 2 therefore converts an i1 phi with >1 unique incoming, **when every
incoming already sits inside the substrate condition-tree grammar**
(`isBooleanCondTree`: supported compare leaves — never over i1 operands —
distinct-operand `and i1`/`or i1` nodes, i1 constants; NO xor/trunc/freeze/
select/phi; depth ≤ 16), to the Bennett `_compute_block_pred!` boolean
algebra instead:

```
mux = ∨ᵢ (EP(eᵢ) ∧ vᵢ)          -- ∧true folds to EP, ∧false drops the term,
                                 -- x∧x = x and x∨x = x fold by identity,
                                 -- all-dropped ⇒ constant false
```

- **Equivalence:** exactly one `EP(eᵢ)` is true when the merge is on the taken
  path (§6.1), so the ∨ picks that edge's value; off-path all terms are false
  and the result is `false` — garbage excluded downstream by the same
  ∧-with-block-predicate argument as the chain's fallback garbage (§4.4). The
  folds only strengthen this (they never change the on-path value).
- **Grammar closure:** EP trees are and/or-over-compare-leaves by
  construction (§4.3); ∧/∨-composing them with grammar-conforming incomings
  stays inside the grammar, so a muxed condition remains flag-mintable and
  the emitted nodes keep the substrate's self-operand fence unreachable (the
  EP==v and Acc==Term identity folds).
- **Fallback:** any off-grammar incoming keeps the Inc-1 select chain —
  byte-identical posture (the consuming select declines loudly exactly as
  before; `control_predmux_i1phi_offgrammar_fallback.ll` pins it).
- **Poison note (Inc-2 Rule-13 clearance, Lens-1 NIT, accepted):**
  `and i1 false, poison` is poison where the chain's `select` blocked the
  unselected arm — a real SSA-refinement asymmetry. Non-observable today
  because every minted ∧/∨ carries the (unconditionally tainted) EP operand
  and lowers to a total-function template before any consumer, concretizing
  poison; moved region ops already drop poison flags. **This masking depends
  on EP being unconditionally tainted-and-lowered** — a future change that
  lets an EP fold to a classical constant, or that defers lowering so clang
  sees a residual classical `and i1 …, poison`, must re-examine this note.

Fixtures: `control_predmux_accept_i1phi_cond.ll` (integer),
`control_predmux_accept_i1phi_cond_fp.ll` (the fp mini-tanh),
`control_predmux_accept_i1phi_const_folds.ll` (const-true→EP / const-false→
drop), `control_predmux_accept_i1phi_data.ll` (result as zext'd DATA —
`cq_template_{and,or}_i1` path), `control_predmux_accept_i1phi_final_merge.ll`
(i1 phi at `R.Merge`, entry-bypass literal + pre-region-value incoming),
`control_predmux_i1phi_offgrammar_fallback.ll` (decline pin). E2E:
`slice_libm_real_{log,cbrt,tanh}` (real openlibm bodies; tanh doubly inlines
expm1 and is the mechanism cell).

### 4.5 Normalizations (each proof-gated, each part of the claimed region only)

- **(a) Poison-flag strip.** Every instruction moved out of its guarding
  branch drops `nsw/nuw/exact/nneg/disjoint` (`dropPoisonGeneratingFlags`) —
  the standard speculation discipline. Bit-semantics and template selection
  are unaffected (signedness lives in the opcode/predicate, not these flags —
  Rule 15; verified against `TemplateName`/`OpcodeSupport` at implementation).
- **(b) `undef` freeze** — §4.4.
- **(c) [Inc 3] Volatile-const fold (curation).** A `volatile load` of a
  scalar `GlobalVariable` with internal/private linkage, a constant
  initializer, and **zero stores module-wide** folds to its initializer
  (openlibm's `@twom1000` fp-underflow-signal idiom). This deliberately drops
  the fp-environment side effect — consistent with the trace-only/no-fp-env
  runtime semantics and the documented lgamma/errno curation precedent. Scoped
  to loads inside a claimed region; any other volatile access → region left
  unclaimed.
- **(d) [Inc 3] Const-global QROM reads under control.** A load inside `R`
  is admissible iff the 7.5 single-origin provenance walk proves a
  const-global with compile-time shape AND the index's range (known-bits /
  `ConstantRange`) provably fits the array bound (exp/erf: `zext(lshr(x,31))`
  ∈ {0,1} into `[2 x double]`). The load moves to the straight line like any
  other op; post-flatten it is a *straight-line* tainted-index read that
  `lowerQramReads` (7.5 Inc 1) accepts and the spine reverses. This is the
  "reversal-integrated form" 3c6m.13 planned: the read's control is subsumed
  by the mux predicates, not by a standalone under-control QROM accept.
  Requires flipping the 3c6m.13 signpost carve to `DeferControl`
  (QramLowering.cpp:657–662; guarded-store :597–603 precedent) so
  `declineTaintEscapes` (step 116) defers instead of exiting before detection;
  the backstop stays loud: a read still under tainted control after the
  PredMux fixpoint (region not claimed) declines exactly as today via the
  under-control check on the `lowerQramReads` path (`instUnderTaintedControl`)
  — verified red-green in Inc 3 (the four existing
  `lowering_reject_qram_read_under_control*` fixtures must stay green with
  their strings unchanged, minus the ones whose shapes become accepts —
  re-scoped deliberately, never by reflex).

### 4.6 Flatten mechanics (block-lifetime discipline)

1. Capture all `BasicBlock*` identities up front (Rule 9 / SIGSEGV family).
2. Build the linearized instruction stream in `E` *before* `T`, in topo order:
   moved arm instructions (flags stripped), predicate network, select chains
   (internal merges in topo order, then `M`'s).
3. RAUW each phi to its chain value; erase phis.
4. Replace `T` with `br M`; erase `R \ {E}` blocks (now empty of live code)
   in a single coordinated teardown —
   `replaceSuccessorsPhiUsesWith`-discipline; **one region per fixpoint
   round**, so no cross-region stale-pointer hazard exists by construction
   (each round re-runs recovery from scratch — nothing cached across
   erasures; this is also how sequential siblings compose: erf's two exp
   regions claim in successive rounds).
5. Return `changed = true`; the orchestrator re-runs `propagate` (§5) so every
   new select/predicate/compare joins `Tainted` through the front door.

Interior tainted terminators of a claimed region need no `Claimed`-set
coordination with `detectControlRegions` — they are *erased* before detection
ever runs (contrast with the in-detection Claimed set at ControlDetect.cpp:455).

### 4.7 Post-flatten guard re-runs (the 2qyz lesson)

After the fixpoint settles (no more claims), the orchestrator re-runs the two
pure pre-mutation guards on the post-flatten IR — `declineTaintEscapes` and
`declineStaleRecordOps` (both idempotent; `StaleDeclined`-skip already in
place) — a *full* re-sweep, never a scoped re-check. (Expected no-ops for the
8 targets — no rotations in-body, no new escapes — but the schedule argument
in §6.2 is thereby enforced, not assumed.)

---

## 5. Pipeline placement

```
 84   while (lowerByRefInline) taint = propagate
 98   foldIdentityBitcasts
 NEW  while (flattenPredMuxRegions(M, wd, taint)) taint = propagate(M, wd);
 NEW  declineTaintEscapes-re-run gate ── folded into the existing call at 116
107   detectSpecializations
116   declineTaintEscapes
123   declineStaleRecordOps
135   lowerControlledIOSinks
151   lowerLoops
163   detectControlRegions / 164 lowerControlRegions
180   repropagateControlMerges … (unchanged)
```

**Placement rationale:** running the PredMux fixpoint immediately after
`foldIdentityBitcasts` (and before *all* analysis guards) means every guard,
the specialization pre-pass, loop lowering, detection, select classification,
QROM lowering, classical-mux guard, and uncompute all see the post-flatten IR
through their normal, shipped entry points — no re-run bookkeeping, no
scoped-re-check trap, no ordering carve except the Inc-3 `DeferControl` flip
(whose loud backstop sits *after* the flatten in `lowerQramReads`). The
eligibility walk needs only `taint.Tainted` membership for conditions —
available from step 1's `propagate`. In-loop regions are excluded by E2's own
cycle walk (PredMux cannot rely on `lowerLoops` having run — it runs before
it; E2 is self-contained).

The §4.7 re-runs come for free with this placement: `declineTaintEscapes`
(116) and `declineStaleRecordOps` (123) *already* run after the fixpoint. No
second invocation needed — placement satisfies 2qyz by construction.

**Twin-pipeline parity (WI-1.12):** the same fixpoint is added to
`runOnFunction` at the mirrored position, with the same comment block.

---

## 6. Correctness argument (three layers, smallest-possible quantum surface)

### 6.1 Classical layer — per-basis-state IR equivalence (the only NEW proof)

Claim: for every input basis state (every concrete value of the tainted
source), the flattened straight-line program computes bit-identical values for
(i) every `M`-phi replacement and (ii) every value live out of the region.

Sketch (structural induction over topo order): fix a basis input `x`. The
original execution takes exactly one path `π(x)` through `R` (all conditions
are pure total functions of already-computed values — E4/E6). By induction:
`BP(B)(x) = [B ∈ π(x)]` and `EP(e)(x) = [e ∈ π(x)]` (base: `BP(E) = ⊤` and `E ∈
π(x)` always; step: exactly the taken out-edge of the last on-path block has a
true literal ∧ true source-BP; every off-path edge fails one conjunct — note
inverted-compare leaves are *total*, so off-path literals are well-defined
garbage, and the ∧-with-`BP` makes their value irrelevant). Hence at every
merge exactly the `EP` of the on-path in-edge is true (mutual exclusivity is
inherited, never assumed), so each select chain returns the on-path incoming —
which by induction equals the original phi's value. Moved instructions compute
the same pure functions of the same SSA operands (poison flags stripped ⇒
total two's-complement/IEEE semantics — the semantics the templates implement
anyway); off-path instructions compute garbage that no selected value depends
on. No LLVM optimization runs between the flatten and template lowering (one
pass invocation), so IR-level poison pedantry has no consumer. ∎

Speculation legality in the LLVM sense is enforced syntactically by E4
(side-effect-free, non-trapping ops; fp is non-trapping under the module's
`"no-trapping-math"`; integer div appears only with constant nonzero divisors
in the corpus — nonetheless E4 admits `udiv/sdiv/urem/srem` only when the
divisor is a nonzero constant, else leave).

### 6.2 Schedule layer — no wire-window is crossed

The flatten moves pure ops from arm blocks into `E`. Every moved op stays
after all pre-region instructions and before all post-region instructions in
program order; rotations/measures cannot exist inside `R` (E4). Therefore the
relative order of every tainted pure op w.r.t. every opaque `cq_*`/wire gate
is preserved — the stale-record analysis and MINT_AT_COMPARE wire-window
reasoning see an unchanged wire schedule. Enforced, not assumed: the full
`declineStaleRecordOps` sweep runs after the fixpoint (§5), and the per-select
gate-2c stale-condition walk runs at classification exactly as for
hand-written selects.

**§3c / QCM injectivity:** the select-form lowering performs no in-place write
to any register a condition reads — every mux lands on a fresh `|0⟩` out-rail
(SelectMergeEmit mechanics), and all sources stay allocated (merge sources are
never freed). Synchronization holds by E3 (single reconvergence). The §3c
clobber class is structurally unrepresentable in the emitted stream.

### 6.3 Quantum layer — everything reduces to Rule-13-cleared substrate

Post-flatten the module contains only shapes with existing clearances: 4.4
select merges (int + kjd1 fp; X-bracket polarity, flag strip, out-rail
bookkeeping, round-2 repropagation), 3c6m.12 conjunction networks (read-only
controls, exact-LIFO ancilla uncompute), CompareLowering flags, straight-line
opcode/cast lowering + the Phase-5 whole-DAG LIFO spine for which-path
garbage (SCOPING §3: all-classical value arms; every non-|0⟩ rail is
spine-owned, emitter-owned, or a documented safe leak — never freed dirty).
PredMux adds **zero** new gate sequences, zero new runtime symbols (nothing
frozen — freeze-orthogonal), zero new taint-bookkeeping writers.

**Residual quantum-side obligations discharged by increment gates:** (i) deep
cascade fixpoint depth (§2.3 probe pair); (ii) e2e goldens per cell (the only
layer that links — Rule 2); (iii) independent adversarial review per increment
(Rule 13) focused on §6.1's equivalence, the eligibility ladder's
completeness (over-accept hunting: an op class E4 wrongly admits, a hidden
side channel, an unreached-garbage path that escapes the ∧-with-BP argument),
and the Inc-3 curations.

---

## 7. Decline / leave matrix (Rule 12 — each row gets a fixture)

PredMux itself **never diagnoses** — it leaves, and today's owner declines
loudly. The matrix pins that the leave→decline composition stays intact:

| shape | disposition | pinned by |
|---|---|---|
| region containing `cq_phi`/`cq_theta`/`cq_measure` (phase/value-rotation arms, incl. depth-2 phase nests) | leave → existing accept or decline | existing 4.1/4.3 fixtures stay green byte-identical |
| region entry on a CFG cycle / in-loop nest | leave → d8jl `control flow inside a loop body` | `control_swap_reject_nested_loop*.ll` stay green |
| store / atomic / non-curated call inside region | leave → escape-guard or control decline | new negative fixtures |
| classical branch inside tainted region (E6) | leave → existing decline | new negative fixture |
| `ret` inside region (multi-exit) | leave → existing decline (`non-reconverging value exit` / 7.2 paths) | existing fixtures |
| merge phi `i128`/vector/`fp128` (E7) | leave → existing decline | existing G4-family fixtures |
| volatile access other than the (c)-proven form | leave | new negative fixture (Inc 3) |
| load without the (d) proof (non-const global, unprovable bounds, escaped) | leave → QROM/escape declines | existing `lowering_reject_qram_*` + new |
| divisor not provably nonzero constant | leave | new negative fixture |
| `M` has a predecessor outside `R` | leave | new negative fixture |
| **flipped fixtures**: pure-dataflow shapes previously pinned as `nested control flow` declines (`control_swap_reject_nested_multireg{,_derived}.ll`, `control_swap_reject_seq_ifelse.ll`, `control_swap_reject_nested_depth3.ll` if value-class, …) | now claim + accept | inventoried and re-scoped **deliberately** in Inc 1: each flipped input becomes an accept fixture; a modified twin (e.g. + a store) re-pins the decline |

---

## 8. Increment plan (each: red-green fixtures first → implement → full ctest →
independent adversarial Rule-13 clearance → commit; opus reviewers per the
workflow-model-tiering directive)

- **Inc 1 — PredMux core + scalbn.f64 + lround.f64.**
  `br` + `switch` regions, multi-phi + N-incoming merges, DAG reconvergence,
  predicate algebra + select chains, poison strip, undef freeze, fixpoint +
  re-propagate, twin-pipeline parity. Gates: the depth-10/20 cascade probe
  pair; lit fixtures (accept: minimal nested-value diamond, switch-with-nested-
  arm, cross-arm DAG join, 6-incoming merge, shared-cond two-phi merge;
  decline matrix rows above); flipped-fixture re-scope; e2e goldens
  `slice_libm_scalbn` + `slice_libm_lround` (real openlibm bodies, injected,
  golden trace). Rule 13.
- **Inc 2 — log.f64 + tanh.f64 + cbrt.f64** (scale + nested switches +
  undef freeze in anger + udiv). Expected zero new mechanism; any gap becomes
  a scoped fix within Inc 2 or an owner-visible follow-up. e2e goldens ×3.
  Rule-13 delta review.
- **Inc 3 — atan.f64 + exp.f64 + erf.f64** (QROM DeferControl flip + in-bounds
  index proof + volatile-const fold + sequential-sibling composition at
  scale). e2e goldens ×3. Full Rule 13 (two curations + a carve flip = core
  changes).
- **Inc 4 — re-census + scoreboard.** Re-run `peel_census.py`
  (normal/first-blocker mode; the census-mode plugin remains throwaway) over
  the full 123-cell surface; publish delta (expected: the 8 flip to COMPILE;
  some projected CONTROL-alone cells surface hidden non-control layers —
  that's the census working, file per-lever follow-ups); update
  `FULL_DEPTH_CENSUS.md` §5 + the two-number scoreboard (INJECTION-covered
  only — verified cells need goldens, Rule 2 + the scoreboard-honesty rule);
  update 3c6m.14 / file follow-ups (f32 siblings `scalbnf/lroundf/...` are
  expected near-free wins — separate ticket with its own verification).

---

## 9. Open questions / risks (tracked, none blocking Inc 1)

1. **Cascade depth**: RESOLVED — probed live to depth 20 (data) / depth 10
   (condition-chained), both clean (§2.3).
2. **Gate/rail scale** (erf: ~10² predicates + selects): trace-runtime and
   qubits-not-scarce make this a non-blocker; noted for the Phase-9/10
   resource story.
3. **The ~40 projected cells**: not claimed by this PRD; Inc 4's re-census +
   per-cell inspection decides the next tickets (census limitation 2a/2b/2c).
4. **f32/f80 width siblings**: mechanically identical flatten; f80 cells also
   need SHADOW (3c6m.51) — out of scope here.
5. **Interaction with future 8h7d loop widenings**: PredMux is
   loop-orthogonal by E2; if 7.3+ later unrolls a bounded loop into an acyclic
   region, PredMux composes for free — noted, not designed here.
