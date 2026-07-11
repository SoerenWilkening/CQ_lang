# PRD — Compound (`and i1`/`or i1`) conditions on the tainted-data `select`

**bd:** `test_C_libtooling-3c6m.12` (libm L4 lever) · **branch:** `3c6m.12-compound-cond-select`
**Status:** design-of-record, written at increment start (Rule 16).
**Parent design:** Phase 4.4 select merge (PRD Part IV §16; `IMPLEMENTATION-4.4.md`),
the kjd1 fp-data un-staging (`fp-data-select-PRD.md`, `FP_SELECT_CLEARANCE.md`).

---

## 0. Empirical scoping (Rule 11 — measured, not guessed)

The lever ticket names two capabilities: *fp-select chains* and *compound
`(or i1)` conditions*, with openlibm `fdim` as the first target. Measured
against the census-exact pipeline (`clang -O1 -fno-builtin` corpus →
`llvm-link` → `internalize,always-inline,globaldce,default<O2>,scalarizer,
instcombine,dce` → `cq-lowering`) on 2026-07-11:

* **Chains already lower.** The openlibm `fdim` qc and cq masks flatten to TWO
  chained tainted-condition selects (`%5 = select(ogt…)`, `%6 = select(uno…, %1,
  %5)`) and BOTH lower today: each select is an independent `SelectRegion`; the
  inner merge's out-rail feeds the outer's controlled copy as a tainted source
  (the exact derived-base mechanics the atan2-qq clearance verified, bd memory
  `libm-census-multiarg-taint-masks-3c6m48`). **No pass change is needed for
  chains; this increment pins the shape with a lit fixture.**
* **The qq mask of `fdim` is NOT a select shape.** clang keeps a two-level
  `br` CFG with a 3-incoming merge phi (`mixed phase/value arm` decline) — that
  is L6 (general nested control, `3c6m.14`) territory, not L4.
* **Compound conditions are the live gap.** `(q<0.25 || q>0.75) ? a : b`
  survives to a `select i1 (or i1 %c1, %c2)` and declines at gate 2
  (`dyn_cast<CmpInst>` fails → generic `control flow`), pinned today by
  `control_swap_reject_select_badcond.ll`. `&&` folds to `and i1`; a 3-way
  `||` folds to a two-node `or` TREE (`or %c3, (or %c1, %c2)`). Integer
  `(n==3||n==7)` is InstCombine-fused to `(n&-5)==3` and already lowers.

**Scope of this increment:** accept a tainted-data `select` whose condition is
a tree of `and i1`/`or i1` nodes over HL-lowerable tainted `CmpInst` leaves.
Everything else keeps declining loudly (Prime Directive), including: `xor i1`
nodes and `xor …, true` (NOT) nodes, `freeze` nodes, `select`-of-i1
combinators (`select c1, true, c2` — InstCombine canonicalizes the pure-compare
form to `or`/`and`, so this shape is off the -O1/O2 canonical path), `phi`/
`trunc`/argument/call leaves, classical (untainted) leaves, Q+Q leaves, and
every non-select consumer of a compound condition (a compound `br` condition
still declines in `ArmClassify` — untouched).

## 1. Why this is safe (the analytic argument, Rule 2)

The single-select §16.3 proof rests on: (a) the flag is a **basis-valued
predicate** of the data registers, (b) the two `cqrt_copy_*_controlled` calls
write only the fresh `|0⟩` out-rail (true-copy on `f`, X-bracketed false-copy
on `¬f`), (c) the strip returns the flag to `|0⟩` exactly because the merge
never wrote the condition's lineage. The compound extension changes ONLY (a):
the control is now the root of a **classical reversible boolean network** over
per-leaf flags —

* leaf flags: `cq_template_(i|f)cmp_<pred>_<W>_hl(handle, literal)` — basis
  predicates, exactly as today;
* `AND` node on a fresh `|0⟩` ancilla `g`: `cqrt_toffoli(l, r, g)` ⇒
  `g = l∧r`;
* `OR` node on a fresh `|0⟩` ancilla `g`: `cqrt_cnot(l, g); cqrt_cnot(r, g);
  cqrt_toffoli(l, r, g)` ⇒ `g = l⊕r⊕(l∧r) = l∨r`.

Every gate is a computational-basis permutation; **inputs are never mutated**
(no transient X-bracket on shared flag rails — controls are read-only), so a
leaf or node shared by two tree positions is safe by construction. No rotation
is emitted anywhere in the network, so no phase is created (Rule 7 untouched;
gate 5 still owns operand coherence). The copies fire on the root exactly as
the single-flag proof — `out = root ? a : b`, no double-write on either basis
branch.

**Uncompute is exact LIFO** (the Phase-5 discipline): reverse node order —
inverse network (`AND`: `toffoli`; `OR`: `toffoli; cnot(r,g); cnot(l,g)`) —
then `cqrt_free(g)`; then reverse leaf order — `_inv` compare strip then
`cqrt_free(flag)`. A parent's inverse fires while its children's rails are
still allocated (reverse post-order), and the merge never writes any leaf's
condition lineage (the copies write `out` only), so every ancilla and flag is
returned to `|0⟩` **exactly** — every `cqrt_free` is a proven-`|0⟩` free
(Rule 6). Sources and `out` stay allocated (Rules 6/8, unchanged).

**Dedup is load-bearing on BOTH legs** (design-review MAJOR): the mint, the
strip, AND the step-6 erase all consume the DEDUPED lists — the memoized
minted-leaf/node records and `Tree.Leaves`/`Tree.Nodes` (unique per Value) —
never the tree-position sequence. A position-sequence strip would `_inv` +
`cqrt_free` a shared flag rail twice: the second `_inv` re-computes the
predicate onto a freed rail and the second free frees it dirty — a hidden
measurement collapsing q (Rule 6) plus a double-free/UAF. Pinned by the
shared-leaf and shared-interior-node fixtures (exactly one `_inv` + one free
per unique rail). The memo is **per-region-emission** (`FlagOf` is local to
`emitSelectRegion`): a second select sharing the same condition tree re-mints
fresh rails — two independent realizations, each with its own balanced strip
(sharing rails across regions would entangle their strips); pinned by
`control_swap_select_shared_root_two_selects.ll`.

**Self-operand nodes decline** (design-review MAJOR): `or/and i1 %c, %c`
would resolve BOTH controls of one `cqrt_toffoli` to a single rail (per-Value
memo) — value-correct in trace semantics yet an ill-formed physical 3-qubit
gate (duplicated control wire) frozen into the golden at exit 0. Non-canonical
(InstCombine folds `x∨x`/`x∧x`), so `collectCondTree` rejects any node with
`op0 == op1` rather than acquiring an unprobed peephole
(`control_swap_reject_select_or_selfdup.ll`).

**No new frozen symbol.** `cqrt_cnot` / `cqrt_toffoli` / `cqrt_alloc_i1` /
`cqrt_free` are existing hand-written core-ABI symbols (`runtime/cq_runtime.h`
§11.4 — reserved "for internal use"; `ControlledSymbols.h` header doctrine:
"multi-condition control is built from single-control ops plus Toffoli flag
conjunction"). No YAML change, freeze-orthogonal. This does NOT rebuild the
excised `FlagConjunction` controlled-op path: the control mechanism remains
the 4.4 controlled-XOR copy merge (no `_controlled` gate substitution, no CFG
linearization); only the flag the merge already consumes becomes a computed
conjunction rail.

## 2. Detection (SelectClassify) — the widened gate ladder

Gate 1 (tainted condition) unchanged. Gate 2 generalizes:

* `collectCondTree(root)` — ONE shared shape walk (exported from
  SelectClassify, consumed verbatim by SelectMergeEmit so classifier and
  emitter cannot drift — the g387 "phase-invariant carve/enqueue" discipline):
  post-order over `and i1`/`or i1` `BinaryOperator`s; leaves must be
  `CmpInst`s; any other node fails the walk → decline `control flow`.
  A single-`CmpInst` root is the degenerate tree (today's path, byte-identical
  emission).
* Per leaf: `comparePredLowerable` (gate 2), tainted-leaf membership (an
  untainted/classical leaf declines — a mixed classical∧quantum condition is
  out of scope v1), NOT Q+Q (gate 2b — both compare operands tainted declines),
  **`compareFlagMintable`** (design-review MAJOR — the detection-side dry-run
  of the HL mint: recoverable non-i128 ABI width from the classical operand +
  in-scope post-flip predicate; with one flag per leaf the emitter's mint is
  no longer atomic, so an unmintable leaf MUST decline before any sibling flag
  is emitted — the ziov.4 detect-before-mutate discipline; this also sharpens
  the pre-L4 single-leaf emit-time `no template` bail into the control dialect,
  re-pinning `control_swap_reject_select_fp128_cond.ll` exactly as that
  fixture's own comment anticipated), and the **i1-operand leaf fence**
  (design-review MINOR — `icmp eq i1 %c, false` is a boolean NOT smuggled past
  the tree grammar whose mint passes a raw i1 into the i32 handle slot;
  non-canonical, declined).
* Gate 2c (stale condition) runs over the LEAF UNION: `condProvenance` per
  leaf accumulated into one seed set → single position-free
  `findNonDiagonalWireGate(seeds, CrossValueRouting=true)` walk + the
  provenance `FreezeInst` fence; the positional prong (c) same-block scan runs
  per leaf (`[leaf, Sel)` for a tainted-arg0 `cq_theta`). The union-seeding is
  sound ONLY because `findNonDiagonalWireGate` computes its on-ancestry exempt
  set PER SEED (WireWalk.cpp — an in-source comment forbids a shared/unioned
  exempt set); a union-refactor there would reopen the two-leaf shared-wire
  chained-theta stale miscompile (design-review NIT — do not "simplify" it).

Gates 3–6 are UNTOUCHED (they read the select's value side): angle reach,
data-width copy predicates (int + kjd1 fp), operand coherence
(`operandCarriesPhase` / `hasCoherentDownstreamUse` / lineage freeze), operand
aliasing. The three-legged angle fence is not moved: the compound work touches
only the condition side, and every leaf flag is minted by the SAME
`lowerCompareToFlag` the single-select uses.

`ControlPlan` is untouched — `R.Condition` carries the root `Value*` (the
legacy `Conj/CondA/CondB` fields stay unpopulated); the emitter re-derives the
tree via the shared walk and loud-bails on any malformed plan (Rule 1).

## 3. Emission (SelectMergeEmit) — the generalized six steps

1. **MINT** — post-order walk: leaf flags via `lowerCompareToFlag` (memoized
   per leaf — a shared leaf mints once); per node, `cqrt_alloc_i1(false)`
   ancilla + the 1-gate (`AND`) / 3-gate (`OR`) network above. Ancillas and
   flags are NOT added to `taint.Tainted` (their only users are `cqrt_*`
   calls — invisible to uncompute, exactly like today's flag).
2. **ALLOC** the `|0⟩` out-rail — unchanged (incl. `ControlOwnedRails`,
   `BirthOrder`, `HandleWidth`).
3. **COPY true** on the root flag — unchanged.
4. **COPY false**, X-bracketed on the root flag — unchanged (§16.3 bracket
   order still the load-bearing hazard, now pinned for the compound stream).
5. **STRIP** — reverse node order: inverse network + `cqrt_free(ancilla)`;
   then reverse leaf order: `_inv` compare strip + `cqrt_free(flag)`.
6. **REWIRE** — RAUW `%sel → %out`, erase the select, then cascade-erase the
   condition tree ROOT-FIRST (reverse post-order nodes, then leaves), each
   node only `if use_empty()` (+ `scrubTaint`) — a SHARED node/leaf (also read
   as data, or feeding a second select) survives for `lowerOps`, the existing
   shared-compare discipline verbatim.

## 4. Interactions audited at design time

* **Stale-record guard (`declineStaleRecordOps`)**: leaf compares feeding an
  `or`/`and` are data-position (`isDataPositionCompare` excludes only direct
  `br`/`select` condition users), so the pass-wide guard visits them — but its
  position-aware walk correctly ACCEPTS a theta scheduled after the compare
  (data ops emit at their own position). The mint-at-SELECT hazard is
  therefore guarded ONLY by gate 2c here — per-leaf, as specified above.
  The guard can also fire on the `and`/`or` node itself when a chained theta
  consumes a leaf's i1 result wire — an over-decline, the safe direction
  (design-review NIT). IN-LOOP shapes (Rule-13 clearance correction): a
  theta-free in-loop compound select — loop-invariant condition wire computed
  in the preheader, select in the body — ACCEPTS and is faithful (the full
  conjunction network is minted and balanced per iteration; the 9ymx
  discipline extends unchanged). Only a backedge-STALED condition wire
  declines, and there whichever pre-detection guard's proof fails first fires
  with its own brand (opcode-dialect) before gate 2c's control string — guard
  ownership differs by shape; every declining path stays loud (measured
  2026-07-11).
* **`lowerOps` double-lowering**: canonical single-use tree → erased at step 6
  before `lowerOps` (L84 < L111). Shared leaf → survives, data-lowered at its
  own position for the independent use (existing discipline). A surviving
  shared NODE (`or i1` with a data user) rides the generated bitwise-i1
  family (`and`/`or`/`xor` carry `i1` widths in `opcode_table.yaml`); if a
  shape lands outside it, `diagnoseNoTemplate` fires — loud either way. The
  data realization's intermediate tainted handles (the data-path compare
  flags, `cq_template_or_i1` result, casts) are LEFT ALLOCATED, never
  uncomputed — a standard qubit leak in the Rule-6 accepted regime, asymmetric
  with the fully-uncomputed control network (Rule-13 clearance NIT; boolean
  value stays consistent between the two realizations — verified).
* **`select`-of-i1 combinator conditions** (design-review MINOR corrected the
  original mechanism claim): detection of ALL selects completes BEFORE any
  emission (`detectControlRegions` precedes `lowerControlRegions`), so the
  outer select declines at gate 2 while its condition is still the live inner
  `SelectInst` — the decline is a pure-detection outcome and `opt` exits
  non-zero with no output written. Pinned by
  `control_swap_reject_select_i1sel_combinator.ll`.
* **Cross-region shared leaf (br diamond + compound select)**: the br region's
  own classification declines its shape loudly, rejecting the module —
  measured and pinned by
  `control_swap_reject_select_tree_br_crossregion.ll`.
* **Specialization-pending calls between a leaf compare and the select**: gate
  2c's wire walk flags only `cq_theta_`-prefixed calls, so a tainted-arg call
  that Phase-6 later specializes is transparent to it — soundness of the
  select-time flag mint then rests on the Bennett wrap's EXACT wire
  restoration (real at HEAD; pre-existing single-select exposure, not widened
  by this increment). Named here so a future wrap change re-audits this
  dependency (design-review MINOR).
* **IOSink guarded prints / ArmClassify br-conditions / SwitchClassify /
  ClassicalCallArm**: none consume the select tree walk; compound conditions
  at those consumers keep their existing loud declines. `copyControlledFn`'s
  integer null-fence and `copyControlledFpFn`'s select-local minting are
  untouched (the minter-null-is-a-classifier audit stands).
* **Cross-region lifetime**: tree nodes are pure i1 instructions dominating
  the select, live until step 6 — the same lifetime class as today's single
  compare; no new erasure window.

## 5. Verification plan (Rules 12/13)

* **Red-green**: `control_swap_reject_select_badcond.ll` FLIPS to the accept
  `control_swap_select_and2.ll` (deliberate Rule-12 re-pin, the fpdata
  precedent); new positives: `or2` (int), `or2 fp` (f64 — the fdim family),
  `or3` tree (`or(c3, or(c1,c2))`), shared-leaf; chain pin
  `control_swap_select_chain_fdim.ll` (two chained selects — no pass change).
  Ordered CHECKs pin the full stream incl. network order, bracket order, LIFO
  strip order.
* **New declines** (each mirroring its diagnostic character-for-character):
  `xor i1` node; `freeze` node; classical leaf; Q+Q leaf; per-leaf stale
  chained theta (same-block positional + cross-block provenance); i1-select
  combinator (pins the loud outcome).
* **e2e golden**: `slice_control_select_compound.c` — links (the only layer
  that proves `cqrt_cnot`/`cqrt_toffoli` resolve) and byte-diffs the trace.
* **Rule 13**: independent adversarial multi-lens clearance (over-accept
  probes, coherence/dephasing, staleness, aliasing/no-cloning, network/bracket
  order, taint-bookkeeping/UAF) before commit.
