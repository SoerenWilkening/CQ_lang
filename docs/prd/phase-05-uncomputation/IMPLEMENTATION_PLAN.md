# Phase 5 — Implementation Plan (modular, test-driven)

**Status (2026-06-17).** Companion to [`PRD.md`](PRD.md). The PRD is *what & why*;
this is *how, in what order, with which tests, in which modules*. Grounded in a
10-agent investigation of the live spine, ABI generator, runtime, Phase-4 callers,
fixtures, and dead-code claims (every PRD claim about current code re-verified
against source per Rule 11 — corrections recorded in §2). **Baseline at authoring:
18/18 ctest green** (`ir-pass-lit` 136 fixtures, 6 e2e slices… now 12, runtime,
frontend). Do not start a WI until the prior WI's gate is green.

**How to use.** Work the WIs in dependency order (§5). Each WI is red-green-refactor:
write the failing fixture first (Rule 12), implement minimally, keep the suite green,
clear the core change (Rule 13) before commit. Module-size budget is enforced per
§3 — **no hand-written module exceeds ~300 LOC** (generated artifacts are exempt;
see §3).

---

## 1. Design decisions (resolve the forks the investigation surfaced)

These are decided here so the WIs don't re-litigate them. Each is an internal
engineering choice (no user-facing behavior fork), so they are recorded, not asked.

- **DD-1 — `emitInverseChain` returns `bool` (success), not a threaded handle; the
  caller owns the free and the decline message.** Today `emitInverseChain` returns
  `Value*` (a threaded/fresh handle) and callers free *that* (`A.RailFinal`,
  `CS.RailFinal`, the Phase-5 `Final`). Under the void `_unc` ABI nothing new is
  minted, so there is no handle to thread. New contract: `bool emitInverseChain(…,
  Terminal)` returns `true` iff every link inverted; the caller frees the **original
  terminal handle it already holds** (`ChainFinal` / the recovered root) and, on
  `false`, emits **its own** loud decline (Phase-5 data-uncompute message vs Phase-4
  value-arm message — §2.5 "message owner"). `emitInverseCall` keeps `CurHandle`
  (still needed to thread in-place rotation/involution results across links) but
  loses `Flag`/`csyms`.

- **DD-2 — Keep generating the `_inv` family; switch all *emitters* to `_unc`.** The
  `_unc` family is added; `_inv` generation stays (Phase-7 region inversion may
  repurpose it — PRD §2.3). After Phase 5 **nothing emits `_inv`** (both Phase-5
  data-uncompute and Phase-4 value-arm reverse-play emit `_unc`). Leaving `_inv`
  generated-but-unused is the low-churn choice and preserves Phase-7 optionality;
  the symbol-count cost is accepted (qubits/symbols not scarce). Revisit deletion at
  Phase 7 if unused.

- **DD-3 — `_unc` operand-slot convention: `out` is always arg 0; the remaining args
  are the forward operands in their original order.** Forward
  `out = cq_template_<op>_<W>_qq(lhs, rhs)` → `cq_template_<op>_<W>_qq_unc(out, lhs,
  rhs)`; `_hl(h, lit)` → `_hl_unc(out, h, lit)`; `_lh(lit, h)` → `_lh_unc(out, lit,
  h)`. `out` is zeroed; all sources are read-and-preserved. This single rule
  (prepend `out`, keep forward order) minimizes the QQ-slot-swap miscompile surface
  and is the **pinned mapping** the Rule-13 review checks (PRD §6 hazard).

- **DD-4 — `ControlOwnedRails` *replaces* the dead `FlagImage`, it does not extend
  it.** `FlagImage` is built from `taint.ControlFlag`, which has **zero writers**
  (verified) — so today it is an empty set and subtracts nothing; Phase-4 out-rails
  are excluded only *incidentally* (their `cqrt_copy` user makes `isTerminalHandle`
  false). The dead `FlagImage`/`ControlFlag` plumbing is deleted in WI-1; a real
  `ControlOwnedRails` set (Phase-4-emitted `cqrt_alloc` out-rails / work rails) is
  introduced in WI-4 **before** the loud flip (WI-5), so a legitimately Phase-4-owned
  dead rail is never spuriously declined.

- **DD-5 — Module-split trigger is 300 LOC of *hand-written* code.** Generated
  artifacts (`runtime/cq_templates.{h,c}`) are exempt — modularity for them lives in
  the *generator*. Pre-existing over-budget modules (`SwapRouteEmit.cpp`, 375 LOC)
  are **not** refactored opportunistically by a WI that only touches them
  mechanically; they are flagged as separate follow-ups (§3).

---

## 2. Verified current-state map (file:line; PRD-claim corrections in **bold**)

The spine (all currently under 300 LOC):

| Module | LOC | Role today |
|---|---|---|
| `EmitInverse.{h,cpp}` | 74 / 133 | `emitInverseCall` mints a **fresh `_inv` handle** (`cpp:92-104`) and returns it; `cqrt_ry/rz` re-emit negated angle (`:55-63`), `cqrt_x`/`cswap` as-is (`:76-84`); controlled path is a bare `return nullptr` placeholder (`:106-108`); `Flag`/`csyms` are `(void)`-unused (`:40-43`). `emitInverseChain` threads `Cur` and returns it (`:111-130`). |
| `ChainWalk.{h,cpp}` | 87 / 191 | `dataInputHandle` returns the **first tainted operand only** (`:27-38`); `recoverForwardChain` is a **linear** backward walk (`:110-189`); `HasFanOut` bails fan-out; `MeasuredUpstream` already **scans all lineage handles** (`:151-158`). |
| `FreePoint.{h,cpp}` | 49 / 256 | PDT last-use placement; `Measured`/`Escaped`/`Insert` classification; owns `kMsgPostMeasure`, `kMsgLoopBackedge`, `kMsgUnrecognized`; dead-φ live-range extension (`isBenignLiveRangePhi`). **Unchanged by Phase 5** (confirm placement under the DAG driver). |
| `Uncomputation.{h,cpp}` | 34 / 197 | Per-terminal loop; `isStep2Emittable` guards (empty/fanout/cross-block/controlled/QQ); `FlagImage` from `taint.ControlFlag` (`:126-128`, **dead — empty**); the `emitInverseChain==nullptr → continue` and the cross-block `return false → continue` are the **two remaining silent skips**. |
| `CQLoweringPass.cpp` | 179 | `uncompute()` is the unconditional last step in **both** entry points (`:115` `run`, `:174` `runOnFunction`); `lowerControlRegions` runs before `lowerRotations` (verified). |

ABI / runtime:

| Artifact | LOC | Note |
|---|---|---|
| `tools/opcode_table.yaml` | 257 | 18 binary ops; variants incl. `inv_qq/inv_hl/inv_lh`. |
| `tools/gen_templates.py` | 278 | `VARIANT_INFO` map, `signature()`, `stub_body()`, `--check` SHA gate. **Adding `_unc` pushes it >300 → split (§3).** |
| `runtime/cq_templates.{h,c}` | 1191 / 8210 | **Generated** (exempt from 300-LOC rule). `_inv` bodies mint a fresh handle. |
| `runtime/cq_runtime.{h,c}` | 295 / 500 | `cqrt_toffoli` **live** (`h:188`); `cqrt_toffoli_inv` referenced **only** by the dead minter string (`ControlledSymbols.cpp:96`). |

**PRD claim corrections (Rule 11):**
- **§2.5 "measured-upstream scan follows only the first parent" — imprecise.** The
  scan already iterates *all* lineage handles (`ChainWalk.cpp:151-158`). It becomes
  correct-for-QQ automatically once `dataInputHandle` yields *both* parents into the
  lineage. The deliverable is the DAG lineage, not the scan loop.
- **`emitInverseCall`'s `CurHandle` must be kept** (threads in-place results); only
  `Flag`/`csyms` are removed. (Earlier "remove the unused params" must not over-reach
  to `CurHandle`.)
- **Phase-4 goldens carry `_inv` and will change.** `add/mul/xor_i32_hl_inv` (8
  occurrences) are **value-arm reverse-play via the shared `emitInverseChain`** and
  flip to `_unc`. `icmp_{eq,sgt,slt}_i32_hl_inv` (15 occurrences) are flag-strip /
  teardown emitted on a **different path** — WI-3 must audit whether they flow through
  `emitInverseChain` (→ migrate) or are direct (→ stay `_inv`). All 9 `_inv`-bearing
  goldens are in the regen + Rule-13 re-clearance set.
- **Dead-code claims confirmed:** `ControlFlag` zero writers; `FlagTeardown` zero
  functional refs; `cqrt_toffoli_inv` reachable only via the dead `toffoliFn`;
  `controlledRyInvFn` / `controlledDataTemplateFn` zero callers.

---

## 3. Module architecture & size budget

New/changed **hand-written** modules and their post-Phase-5 budget:

| Module | Now | After | Action |
|---|---|---|---|
| `tools/gen_templates.py` | 278 | ~150 | **Split.** Extract C-code emission to `tools/abi_codegen.py` (~140: `signature()`, `stub_body()`, void-`_unc` bodies); keep YAML-read + CLI + `--check` in `gen_templates.py`. (Optional `tools/variant_grammar.py` ~70 for the variant map if `abi_codegen.py` itself nears 300.) |
| `ir-pass/.../ChainWalk.cpp` | 191 | ~150 | **Split.** Extract the reverse-topological worklist + visited-set into `DagTraversal.{h,cpp}` (~100, reusable by Phase-7). `ForwardChain` API stays in `ChainWalk.h`. |
| `ir-pass/.../Uncomputation.cpp` | 197 | ~180 | **Conditional split.** If the LIFO emission loop + `ControlOwnedRails` + loud-decline branches push it past 300, extract the DAG-LIFO driver to `UncomputeDriver.{h,cpp}`; keep terminal collection + dispatch + diagnostics in `Uncomputation.cpp`. |
| `ir-pass/.../EmitInverse.cpp` | 133 | ~170 | In place (void `_unc` emission + bool return). Stays < 300. |
| `runtime/cq_templates.{h,c}` | 8210 | ~16k | **Exempt (generated).** Modularity is in the generator (DD-5). If hand-debugging ever needs it, split by opcode family — *not now*. |

**Pre-existing over-budget (flagged, not fixed by Phase 5):** `SwapRouteEmit.cpp`
(375). WI-3 touches it with a ~2-line mechanical edit only; a refactor is a separate
follow-up issue.

---

## 4. Work items (dependency-ordered; each is red→green→clear)

### WI-1 — Excise dead controlled-op scaffolding (subtractive; de-risks the surface)
**Depends on:** none. **Modules:** `ControlledSymbols.{h,cpp}`, `TaintPropagation.h`,
`Uncomputation.cpp`. **PRD:** §2.13, §2.7.
- **Tests-first:** none new — this is behavior-preserving. The gate is *the existing
  suite stays 100% green* and `opt -verify` clean after each deletion.
- **Steps (delete in this order, rebuild green between each):**
  1. `ControlledSymbols`: delete `toffoliFn` (decl `h:76`, def `cpp:90-98`) +
     `cqrt_toffoli_inv` runtime decl/body — **keep `cqrt_toffoli`** (live, Rule 14).
  2. Delete `controlledRyInvFn` (`h:71` / `cpp:74-88`) and `controlledDataTemplateFn`
     (`h:52-55` / `cpp:20-55`) — zero callers (verified).
  3. `TaintPropagation.h`: delete `ControlFlag` (`:87`) and `FlagTeardown` (`:112-117`).
  4. `Uncomputation.cpp`: delete the `FlagImage` construction (`:126-128`) + its
     `.count(H)` filter (`:145`). (DD-4: it was an empty no-op; real exclusion is
     `isTerminalHandle` until WI-4 adds `ControlOwnedRails`.)
  5. Remove now-unused `(void)csyms` / `(void)Flag` only **after** WI-3 drops the
     params (sequencing note — leave the casts until then to keep WI-1 self-contained).
- **Gate:** full suite green; `opt -verify` clean; `git grep` shows zero references
  to each deleted symbol. **Rule-13:** light (subtractive, `TaintPropagation` struct
  touched) — one reviewer confirms no writer/reader appeared under the new driver.

### WI-2 — `_unc` runtime ABI family (generator + YAML + regenerate + rebaseline)
**Depends on:** none (parallel with WI-1). **Modules:** `tools/opcode_table.yaml`,
`tools/gen_templates.py` → **split** to `tools/abi_codegen.py`; regenerates
`runtime/cq_templates.{h,c}`. **PRD:** §2.3, §3; Rule 15.
- **Tests-first:** extend `tools/gen_templates_test.py` with assertions for the new
  variants (red): a `void cq_template_<op>_<W>_qq_unc(int32_t,int32_t,int32_t)` exists,
  signature is `void` (no `int32_t` return, no `cqrt_alloc_handle` in the body), trace
  format is `cq_template_..._unc(h%d, h%d, h%d)` with **no `-> h` suffix** and **no
  handle-counter advance**, `_hl_unc`/`_lh_unc` carry the classical literal in the
  forward slot (DD-3), signedness stripped to width (`_si32`→`_i32`).
- **Steps:**
  1. Split `gen_templates.py`: move `signature()`/`stub_body()` into `abi_codegen.py`;
     `gen_templates.py` keeps load-YAML / enumerate / write / `--check` / CLI.
  2. YAML: add `unc_qq`/`unc_hl`/`unc_lh` variant tokens per binary op (+ unary/cast
     `unc` for arity-1: `_unc(out, src)`).
  3. `abi_codegen.py`: emit `void` `_unc` bodies — trace sources + `out`, **no alloc,
     no return** (DD-3 slot order). Add a banner comment: "`_unc` bodies are
     trace-only stubs; real zeroing is Phase 8+ bodies."
  4. Regenerate `cq_templates.{h,c}`; update the `--check` SHA baseline
     **deliberately** (`runtime/cq_templates.h:1`); regenerate `test_trace.*` only if
     touched.
- **Gate:** `gen_templates_test.py` green; `gen_templates.py --check` clean (single
  commit unit: code + regenerated artifacts together — partial commit fails `--check`);
  header compiles (`runtime` ctest). **Rule-13:** n/a (no IR-pass core touched);
  Rule-15 (width-only) reviewer check on the new bodies.

### WI-3 — `EmitInverse` void `_unc` shape + `emitInverseChain→bool` + Phase-4 migration
**Depends on:** WI-2 (the `_unc` symbols must be mintable). **Modules:**
`EmitInverse.{h,cpp}`, `SwapRouteEmit.cpp`, `SwitchValueEmit.cpp`, `Uncomputation.cpp`;
regenerate affected fixtures + Phase-4 goldens. **PRD:** §2.3, §6; DD-1, DD-3.
- **Audit-first (load-bearing):** trace every `_inv` in the 9 goldens to its emitter.
  `add/mul/xor_i32_hl_inv` → `emitInverseChain` (migrate to `_unc`).
  `icmp_*_inv` → determine if via `emitInverseChain` or a direct flag-strip path;
  record the verdict in the WI before regenerating. Only migrate what flows through
  the shared spine.
- **Tests-first:** regenerate the *existing linear* fixtures
  `lowering_uncompute_chain_reassign.ll` and `lowering_uncompute_dead_sibling_no_measure.ll`
  to assert `cq_template_*_unc(out, src…)` (in-place, no `_inv`, no fresh handle) — these
  fail until the emitter switches (red).
- **Steps:**
  1. `EmitInverse.cpp:92-104` template branch: emit the `_unc` symbol (DD-3 slots),
     **void**, reading forward operands, zeroing `out`; no fresh mint, no return value.
  2. `emitInverseCall` → return `bool` (invertible) keeping `CurHandle` for
     rotation/involution threading; **drop `Flag`/`csyms`**; remove the `(void)` casts.
  3. `emitInverseChain` → `bool` (DD-1): loop, AND the per-link results; return
     success. No threaded handle.
  4. Migrate callers: `Uncomputation.cpp:186` (free the recovered root, not `Final`);
     `SwapRouteEmit.cpp:375` + `SwitchValueEmit.cpp:250` (drop the assignment; free
     `ChainFinal`; on `false` emit the value-arm loud decline).
  5. Regenerate exactly the audited Phase-4 goldens (`_inv`→`_unc` where the spine
     drives it).
- **Gate:** `ir-pass-lit` + all e2e green with regenerated baselines; no `_inv` emitted
  by any spine path. **Rule-13 (core):** independent adversarial review of the void
  in-place semantics and the Phase-4 value-arm reverse-play equivalence (does `_unc`
  return the routed rail to `|0⟩` exactly as the old `_inv` was *intended* to?), plus
  the DD-3 slot mapping. **Rule-12:** the regenerated fixtures are the positive lock.

### WI-4 — Whole-DAG LIFO reversal (ChainWalk DAG recovery + driver + `ControlOwnedRails`)
**Depends on:** WI-3 (void `_unc` emitter), WI-1 (dead `FlagImage` gone). **Modules:**
`ChainWalk.{h,cpp}` → **split** `DagTraversal.{h,cpp}`; `Uncomputation.cpp`
(→ conditional `UncomputeDriver.{h,cpp}`). **PRD:** §2.1, §2.2, §2.11; §6. **This is the
core silent-miscompile zone.**
- **Tests-first (positives, red):**
  - `lowering_uncompute_qq_both_parents.ll` — `prod = mul_qq(q1,q2)` dead: assert
    `mul_qq_unc(prod, q1, q2)` reads **both** parents, then `q2` reversed+freed, then
    `q1` (DD-3 slots).
  - `lowering_uncompute_fanout_dag.ll` — **replaces** `chain_fanout.ll`'s NO-EMIT lock:
    `h1` fans to `h2,h3`; assert each gate's `_unc` appears **exactly once**, LIFO
    order, and `h1` is freed **only after** its last consumer's `_unc` (the
    once-per-gate + free-after-last-reverse-use invariants).
  - `lowering_uncompute_dead_merge_outrail.ll` — a dead-but-unmeasured Phase-4 merge
    out-rail: assert Phase-5 **neither uncomputes nor declines** it (left allocated;
    `ControlOwnedRails` subtracts it). Pins DD-4.
- **Steps:**
  1. `dataInputHandle` → return **all** tainted operands (QQ = two parents).
  2. `recoverForwardChain` → worklist + visited-set **DAG** recovery;
     reverse-topological order = reverse program order (SSA dominance guarantees
     def-before-use). Extract the worklist into `DagTraversal`.
  3. Driver: collect terminals first (unchanged ordering safety, §2.8); single
     reverse-topo pass; `Seen` set adjoints each gate **once**; free each rail after
     its **last reverse-use**.
  4. Add `ControlOwnedRails` (Phase-4 `cqrt_alloc` out-rails / work rails) and subtract
     it **before** terminal selection (DD-4).
  5. Lift the `HasFanOut` and single-register (`Tainted!=1`) guards — now handled.
- **Gate:** new positives + all prior fixtures/goldens green; `chain_fanout.ll`
  retired/replaced. **Rule-13 (core, deepest):** adversarial proof of (a) reverse-topo
  correctness, (b) once-per-gate dedup soundness across shared prefixes, (c)
  free-after-last-reverse-use, (d) `ControlOwnedRails` neither under- nor over-inclusive,
  (e) backedge guard fires **before** DAG recovery (§2.9). Analytic/trace only, no sims.

### WI-5 — Abolish silent skips: every unprovable shape declines loudly
**Depends on:** WI-4 (`ControlOwnedRails` must protect Phase-4 rails *before* the flip).
**Modules:** `EmitInverse.cpp`, `Uncomputation.cpp`. **PRD:** §2.4, §2.12; §6.
- **Tests-first (negatives, red — each `RUN: not … | FileCheck`, message mirrored
  character-for-character, Rule 12):**
  - `lowering_uncompute_uninvertible.ll` — a primitive with no `_unc` → loud
    un-invertible decline (new message, owned per DD-1).
  - `lowering_uncompute_divergent_arm.ll` — mutating gates spanning exclusive arms
    (the reverted `543bd85` shape) → loud cross-block/divergent-arm decline (flips the
    `isStep2Emittable` `return false`).
  - `lowering_uncompute_measured_intermediate_qq.ll` — QQ node whose **second** parent
    is measured upstream → loud `kMsgLineageMeasured`, naming the measured parent.
- **Steps:** flip the `emitInverseChain==false → continue` (DD-1 caller-owned message)
  and the cross-block `return false → continue` (§2.4) to source-located
  `DiagnosticInfoUnsupported` (`!dbg`, non-zero exit). Confirm **no silent `continue`
  remains** in the uncompute path (§4 "no silent skip remains" becomes literally true).
- **Gate:** all negatives loud + message-exact; positives still green. **Rule-13:**
  confirm the flip didn't convert a *legitimate* Phase-4-owned rail into a spurious
  decline (the DD-4 positive `dead_merge_outrail` fixture must stay green).
- **Note:** this is a deliberate, safe behavioral regression (programs that compiled-
  with-leak now error) — document it; regenerate baselines deliberately, never by reflex.

### WI-6 — E2E golden: real data-handle `_unc` + `cqrt_free`
**Depends on:** WI-4 (driver), WI-3 (`_unc` emit). **Modules:** `tests/e2e/`. **PRD:**
§3, §4 (Rule 2/16). 
- **Steps:** add a slice with a **dead, unmeasured, unreturned** source-derived tainted
  handle (e.g. compute then drop a value, no measure) — exercises the whole forward
  link → LIFO `_unc` → `cqrt_free` path. Capture the golden from the **real linked
  binary** (the only layer that proves every emitted `_unc`/`free` symbol resolves and
  signature-matches), wire `tests/e2e/CMakeLists.txt`.
- **Gate:** `e2e-slice-*` green, byte-exact diff. This is the link-layer proof the
  `_unc` ABI (WI-2) and the emitter (WI-3) agree on signatures.

### WI-7 — Docs + final Rule-13 clearance + closeout
**Depends on:** WI-1…WI-6. **Modules:** `docs/backend.md`, `ROADMAP.md`, `bd`.
- **Steps:** correct `backend.md §11.2` (measure-then-reuse OUT, matches the loud
  reject); rewrite `backend.md §9–10`/§9.2 from the per-terminal `_inv` model to the
  void-`_unc` whole-DAG model; flip ROADMAP Phase 5 status; `bd remember` the new
  hard-won gotchas (the `_inv`→`_unc` Phase-4 regression surface; DD-3 slot mapping;
  `ControlOwnedRails`-before-flip ordering); close the bd epic.
- **Gate:** full suite green; consolidated Rule-13 sign-off that the whole-DAG reversal
  + void-ABI is cleared (a green suite alone does **not** clear it — §4).

---

## 5. Dependency graph & ordering

```
WI-1 (dead-code)  ─┐
                   ├─→ WI-3 (EmitInverse void + Phase-4 migrate) ─→ WI-4 (whole-DAG + ControlOwnedRails)
WI-2 (_unc ABI)  ──┘                                                      │
                                                                          ├─→ WI-5 (silent→loud flip)
                                                                          └─→ WI-6 (e2e golden)
                                                                                      │
                                                          WI-7 (docs + clearance) ←───┘
```

- **WI-1 ∥ WI-2** (independent; do first, both green).
- **WI-3 needs WI-2** (symbols) and is cleanest after WI-1 (params already half-dead).
- **WI-4 needs WI-3** (void emitter) — the core.
- **WI-5 needs WI-4** (`ControlOwnedRails` must precede the flip — DD-4).
- **WI-6 needs WI-3+WI-4**; **WI-7 last.**
- **Commit discipline:** WI-3's signature change breaks Phase-4 callers — its emitter
  switch + caller migration + golden regen land as **one green commit**.

---

## 6. Risk register (PRD §6 + the regression the investigation surfaced)

| Risk | WI | Mitigation / gate |
|---|---|---|
| Wrong reverse-topo order / gate adjointed twice / free of non-`|0⟩` rail (all verify-clean) | WI-4 | Analytic proof of the three invariants; Rule-13 (no sims). |
| QQ `_unc` slot swap / omitted `out` / one-parent measured scan (verify-clean wrong unitary) | WI-3, WI-4 | DD-3 pinned mapping; both parents in lineage → scan covers both; Rule-13 + e2e diff. |
| **`_inv`→`_unc` flips Phase-4 value-arm goldens** (shared `emitInverseChain`) | WI-3 | Audit emitter paths first; regenerate only spine-driven goldens; Rule-13 re-clear Phase-4. |
| Reusing fresh-minting `_inv` for uncompute (frees a dirty rail = hidden measurement) | WI-3 | DD-2: no emitter calls `_inv`; grep-gate "no `_inv` from spine". |
| Silent→loud flip changes which programs compile | WI-5 | Intended/safe (over-decline); deliberate baseline regen; each loud path has a char-exact negative fixture. |
| Spurious decline of a Phase-4-owned dead rail after the flip | WI-4→WI-5 | DD-4: `ControlOwnedRails` lands **before** the flip; `dead_merge_outrail` positive fixture. |
| Loop backedge processed by the DAG driver | WI-4 | Backedge guard fires **before** `recoverForwardChain`; `loop_backedge.ll` stays loud. |
| Dead-code deletion breaks a live path | WI-1 | Verified zero refs; rebuild green between each deletion; keep `cqrt_toffoli`. |
| `gen_templates.py --check` churn / partial commit | WI-2 | Code + regenerated artifacts in one commit; `--check` is the gate. |
| Twin entry points (`:115`/`:174`) diverge | all | Both call sites verified; any driver change applies to both; DT/PDT/LoopInfo must not assume module scope in `runOnFunction`. |

---

## 7. Done criteria (rolls up PRD §4)

- [ ] Dead tainted handles with mid-function non-`main` last-use emit reversed adjoint +
      `cqrt_free` for **linear, QQ, and fan-out/DAG** shapes — each gate adjointed once.
- [ ] `emit_inverse` total over the emitted primitive set; **every** un-invertible /
      unprovable shape declines loudly with a char-exact negative fixture; **no silent
      skip remains**.
- [ ] Full suite green; `gen_templates.py --check` baseline regenerated **deliberately**
      for the void `_unc` family.
- [ ] ≥1 e2e golden diffs clean against a **real linked** data-handle `_unc` + `cqrt_free`.
- [ ] Dead controlled-op scaffolding removed; `opt -verify` clean.
- [ ] **Rule-13 clearance** of the whole-DAG reversal + void-ABI by independent
      adversarial analytic/trace review — a green suite alone does not clear it.
- [ ] All hand-written modules ≤ ~300 LOC (splits per §3); generated artifacts exempt.
```
