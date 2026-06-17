# Phase 5 PRD — IR pass: per-op uncomputation (swap-route generation)

**Status (2026-06-17).** Written at the start of Phase 5 per Rule 16. The
uncompute *spine* (`EmitInverse` / `ChainWalk` / `FreePoint` / `Uncomputation`)
already landed incrementally alongside Phase 4 — it is live in the main pipeline
as the unconditional last step (`CQLoweringPass.cpp:115`, `:174`), with 13 green
`lowering_uncompute_*` lit fixtures — but it shipped *conservative* (uncontrolled,
single-register, single-block chains only) and **no new-generation PRD was ever
authored**. This document is that PRD. It **supersedes** the archived old-gen
Phase 5 PRD
([`docs/archive/old-design/phases/phase05-uncomputation/PRD.md`](../../archive/old-design/phases/phase05-uncomputation/PRD.md)),
whose control-coupled mechanics (§2.7 in-shadow controlled adjoint) died with the
controlled-op path in `7cde677`.

**Section-anchor compatibility.** The spine code cites `PRD §2.1 / §2.2 / §2.3 /
§2.4 / §2.5 / §2.6 / §2.8 / §2.9 / §2.10`. The anchors are **kept** so existing
comments still resolve; their *content* is updated where the void-`_unc` ABI and
the silent→loud flip require it: §2.1 extended, **§2.2 revised** (explicit
control-owned-rail boundary), **§2.3 revised** (void in-place `_unc` uncompute ABI
— supersedes the fresh-minting `_inv` and the "no new ABI" claim), **§2.4 revised**
(divergent-arm shape is now a loud decline), §2.5 clarified (message owner),
**§2.7 CANCELLED**, and §§2.11–2.13 new/updated.

**Design of record:** [`docs/backend.md`](../../backend.md) §9–10;
[`ROADMAP.md`](../../../ROADMAP.md) Phase 5. **Authoritative status:** ROADMAP.

---

## 0. Invariant recap (not new — the ground Phase 5 stands on)

- **Taint is the only Q/C boundary** (Rule 3). Phase 5 acts only on
  source-derived tainted **data** handles.
- **Coherent-first; never insert a measurement** (Rule 5). Uncomputation emits
  no measurement and **never frees a rail that is not provably `|0⟩`** (Rule 6) —
  a dirty/entangled rail is left allocated (a leak, accepted in the
  qubits-not-scarce regime), never freed.
- **Verify-clean is necessary, never sufficient** (Rule 2). Correctness is
  established by golden e2e trace diff + independent adversarial review (Rule 13);
  the uncompute core is exactly where verify-clean silent miscompiles live.
- **Phase 4 already reuses this spine.** `emit_inverse` is the engine for the
  swap-route value-arm **reverse-play** (method-B), and `FreePoint` computes the
  §3b "free only a `|0⟩` rail" point. Phase 5 productionizes the *implicit
  last-use data uncompute* over the **same** spine — it does not fork it (Rule 14).

---

## 1. Scope

Phase 5 productionizes the per-op uncomputation of source-derived tainted data
handles past the conservative single-register/single-block slice, to the full
acyclic shape that the project's reversibility model admits.

| | In scope |
|---|---|
| **Total adjoint dispatch** | The uncompute primitive is **void and in-place**: `void cq_template_<op>_<W>…_unc(out, src…)` **zeroes the `out` rail, reading (and preserving) the live source handle(s)**. This *replaces* the fresh-minting `_inv` *operation* (returns a new handle, never zeroes a rail — wrong for uncompute; threading it frees a dirty rail = hidden measurement). `cqrt_ry/rz` re-emit with negated angle; `cqrt_x` is self-adjoint; a QQ node's `_unc` reads **both** live parents. Any primitive with no correct uncompute → **loud decline** (not a silent `nullptr`-skip). |
| **QQ operand shape** | Reverse two-quantum-operand ops — a DAG node with two tainted parents — incl. the **both-parent** measured-upstream scan. |
| **Whole-DAG LIFO reversal** | Replace per-terminal independent reversal with **one reverse-topological pass over the tainted data DAG**, adjointing each gate **exactly once**, freeing each rail after its last reverse-use. **Fan-out included. No `cqrt_cswap`.** |
| **Loud-decline the irreversible** | A **measured intermediate** (reversing would collapse a measured register) and a **loop-backedge** live range decline loudly. |
| **Cleanup** | Verify-then-delete the dead old-controlled-op scaffolding (Rule 11): the `toffoliFn` flag-conjunction minter + its `cqrt_toffoli_inv` twin (**keep `cqrt_toffoli`** — a live documented core-ABI primitive, Rule 14); the unused `Flag`/`csyms` params on `emitInverseCall` (**there is no `_controlled_inv` branch** — only a `nullptr` placeholder, folded into §2.12's loud decline); any other confirmed-dead controlled-op minters (`controlledRyInvFn`, `controlledDataTemplateFn`); and the `ControlFlag` (read-but-never-written) / `FlagTeardown` (unreferenced) fields. |
| **Rule 16** | One e2e golden that **links** a real main-pipeline data-handle `_unc` + `cqrt_free`. |

| | Explicitly OUT |
|---|---|
| Whole-function / region inversion (invert a function's net unitary) | Phase 7 (`cq_invert`) — same `emit_inverse` engine, different trigger + region-scaffolding inversion. |
| `cqrt_cswap`-based source-freeing / ownership transfer | Phase 4 (control routing); **never needed for Phase 5's uncompute-to-`|0⟩`** (see §2.11). |
| Real loop uncomputation (loop-carried registers, per-iteration reversal) | Post-freeze quantum-`while`; **extends** Phase 5's spine, not a rewrite (§2.9). |
| Measure-then-reuse (gate after a measure on the same handle) | OUT; the stale `backend.md §11.2` is corrected to match the loud reject (§2.5). |
| Real reversible template bodies | Phase 8+. `emit_inverse` walks at **template-call granularity** while bodies are stubs (§2.3). |

---

## 2. Design decisions

### 2.1 Reverse the whole register *DAG* at last use — not per-SSA-value, not per-terminal

A tainted data register is built by a chain of gates (`cqrt_alloc` mint, in-place
`cqrt_ry/rz`, reassigning `cq_template_*` producers that RAUW a fresh result).
The adjoint is emitted **once** at the last-use point over the recovered chain,
not per SSA value (`ChainWalk::recoverForwardChain` / `isTerminalHandle`).

**Generalization (the core of Phase 5):** the recovered structure is in general a
**DAG**, not a linear chain — a handle may have two tainted parents (QQ) and may
feed two consumers (fan-out). The conservative slice collapsed a *linear*
reassignment chain and **bailed** on fan-out (`ChainWalk::HasFanOut`) because it
reversed **per terminal independently**, which adjoints a shared prefix twice
(use-after-free + double-free; pinned no-emit by
`lowering_uncompute_chain_fanout.ll`). Phase 5 replaces per-terminal reversal with
a single whole-DAG pass (§2.11), so each gate is adjointed exactly once. The
per-node adjoint is a **void in-place `_unc`** that reads the node's original
forward operands and zeroes its output rail (§2.3) — it produces no new handle, so
the per-terminal "two divergent restored-prefix handles, no merge operator"
hazard cannot arise.

### 2.2 The Phase 4 / Phase 5 partition: source-derived data vs control scratch

Phase 5 owns **source-derived data** handles only. Pass-invented control scratch
(swap-route flags, work rails, merge `cqrt_copy[_controlled]` out-rails) is
uncomputed/owned **by the Phase-4 emitter** — phase arms strip the flag via
`icmp_inv` and free `|0⟩` rails; value arms reverse-play (method-B) and free.
The uncompute driver subtracts a **control-owned image** so it never selects a
pass-invented rail. Today that image covers only flag *values* (not the in-shadow
keys — the direction trap; `Uncomputation.cpp` `FlagImage`), and that is **not
sufficient**: a merge **out-rail** is a `cqrt_alloc` result that Phase 4 inserts
into `taint.Tainted` and **leaves allocated** (Rule 6/8), excluded from the
Phase-5 walk *today only* by the incidental fact that its `cqrt_copy` user makes
`isTerminalHandle` return false — **not** by any §2.3 decline (§2.3 classifies
`cqrt_copy` as *invertible*, so a surfaced copy never trips the un-invertible
path; and `recoverForwardChain(out)` bottoms out at the alloc with an empty chain,
which under §2.12's flip would become a *spurious loud decline* of a legitimately
Phase-4-owned rail). **Deliverable:** make the image explicit — subtract
Phase-4-emitted `cqrt_alloc` out-rails / work rails (a `ControlOwnedRails` set),
not just flag values, *before* terminal selection — and keep `cqrt_copy` **out**
of the Phase-5 invertible surface (it is Phase-4-owned, or Phase-7 for user
`cq_invert` — §2.3). A positive fixture pins that a dead-but-unmeasured value-merge
out-rail stays allocated and does **not** trip the flip.

### 2.3 `emit_inverse` is TOTAL over the emitted primitive surface — via void in-place `_unc`

`emit_inverse` is the one shared adjoint helper, walked at **template-call
granularity** (once bodies are real, the same helper walks at gate granularity —
Rule 14). The uncompute of a forward op `out = f(src…)` is **not** its inverse
*operation* (a fresh-minting `_inv` that returns a new handle); it is the inverse
*step* — a **void, in-place** primitive that **zeroes `out`'s rail while reading
(and preserving) the live sources**:

> `void cq_template_<op>_<W>…_unc(out, src₁ … src_k)`

This is Bennett uncompute: the target rail is cleared by recomputing `f` from the
still-live inputs, so **non-injective ops (`mul`/`and`/`or`) uncompute fine** (you
never invert the lossy function), and the **sources are preserved** — a shared
source must survive to uncompute its other consumers and then be uncomputed by its
own ancestor (§2.11). It must be **total over every primitive the pass emits**:

- `cqrt_ry` / `cqrt_rz` → re-emit **in place** with **negated angle**. *(done)*
- `cqrt_x` → self-adjoint involution, emitted **as-is**. *(done)*
- `cq_template_<op>_<W>[_hl|_lh|_qq]` → its **`_unc`** form: `void`, args
  `(out_handle, src_handle…[, classical_literal])`, zeroing `out`. A QQ node passes
  **both** live parent handles as sources (§2.11); the source→arg slot mapping is
  fixed by the generator and pinned by the Rule-13 review.
- **Any other primitive → NO correct uncompute → return the "un-invertible" signal
  so the driver declines LOUDLY** (§2.12). Replaces today's silent `nullptr` → skip.
  (`cqrt_copy` / `cqrt_cswap` are **not** in this surface — they are Phase-4-owned
  route/copy-out scratch, reverse-played by Phase 4, or Phase-7 for user
  `cq_invert`; Phase 5 never inverts a copy — §2.2.)

**This requires a runtime-ABI change** (superseding the earlier "no new ABI / no
YAML edit" framing). The shipped `_inv` twins are the fresh-minting inverse
*operation* and are **wrong for uncomputation** — threading one frees a
dirty/entangled rail (a hidden measurement, Rule 6/8). Edit `tools/opcode_table.yaml`
+ `tools/gen_templates.py` to emit the `void … _unc(out, src…)` family (Rule 15:
width-only, signedness stripped, handles always `i32`); the `gen_templates.py
--check` SHA baseline **changes deliberately**, and the existing
`lowering_uncompute_*` fixtures + golden are **regenerated** (Rule 12). The
fresh-minting `_inv` twins are retired here (they may be repurposed for Phase-7
region inversion).

### 2.4 Last-use via `PostDominatorTree`

The free/adjoint point is the SSA last-use: collect the terminal's instruction
users, post-dominate to their nearest common block, anchor just after the latest
in-block user (else the block's first insertion point, after φ-nodes)
(`FreePoint::computeFreePoint`). A divergent-per-arm aspect that is a **non-mutating
use** with a dead (`use_empty`) merge result merely extends the live range; the
merge post-dominator placement is sound (pinned by
`lowering_uncompute_branch_botharms.ll`). A chain whose **mutating gates** span
arms (the divergent per-arm rotation shape — the reverted `543bd85` miscompile,
where a single merge-point adjoint would fire `R†` on **both** exclusive paths) is
**loudly declined**, not silently skipped: the cross-block `isStep2Emittable` bail
flips from `continue` to a source-located `DiagnosticInfoUnsupported` (its own
message + Rule-12 negative fixture; §2.12). Region-local per-arm reverse-play is
**Phase 4's** job (the swap-route emitter), not Phase-5 data uncompute — Phase 5
declines and defers to it, settling the open policy the
`divergent-arm-uncompute-soundness-guard` memory left undecided.

### 2.5 Measurement is the quantum→classical sink — terminal skips, intermediate declines

"Invert quantum functionality, not classical." A **measurement collapses
superposition** and is irreversible; we never reverse *across* one.

- **Measured terminal** (`q = θ; … ; m = measure(q)`, the common case) → benign
  **skip**: nothing to uncompute, the user owns the result, no free
  (`FreePoint` → `Measured`). **Not a decline.**
- **Measured intermediate** — uncomputing a dead register would require reversing
  *through* a register measured elsewhere → **loud decline** (a hidden projective
  collapse; flagged by `ChainWalk`'s `MeasuredUpstream` field, emitted as
  `kMsgLineageMeasured` by `Uncomputation.cpp`). Under QQ this scan must follow
  **all** tainted parents, not just the first (§2.11).
- **Measure-then-reuse** (a gate after a measure on the same handle) is OUT and a
  loud reject (`FreePoint` `kMsgPostMeasure`); the stale `backend.md §11.2`
  ("measure does not consume the handle; subsequent `ry` re-rotates") is corrected
  to match.

### 2.6 Escape detection + catch-all loud diagnostic

A handle consumed by a `ReturnInst`, resident in `main`, or inside a
`cq_invert_*` region **escapes** → no free, no diagnostic (the caller / Phase 7
owns it). An **unrecognized** user is a **loud** `DiagnosticInfoUnsupported`
(source-located via `!dbg`) — never a silent skip. *(done; preserved.)*

### 2.7 [CANCELLED] In-shadow data handle → controlled adjoint, flag kept alive

The archived §2.7 had Phase 5 emit a `_controlled_inv` adjoint for in-shadow data
handles, keeping the control flag alive. **Cancelled.** Under swap-route there are
no controlled arithmetic ops in the lowered IR (arm bodies run verbatim); in-region
reversal is owned by Phase 4 (method-B reverse-play, §2.2). There is **no
implemented `_controlled_inv` branch** to delete — only a `return nullptr`
placeholder (folded into §2.12's loud un-invertible decline) plus the
now-permanently-unused `Flag`/`csyms` parameters and the `toffoli` conjunction
minter; all are **dead** and removed (§2.13).

### 2.8 Pass ordering: Phase 5 runs last

`uncompute(M, wd, taint)` runs **after** every other mutation has settled `taint`
into its final post-lowering state (`CQLoweringPass.cpp:115`, `:174`) — and in
**both** entry points (the twin-pipeline trap). Terminals are collected by a full
walk **first**, then emitted, so freshly-inserted `_unc`/`free` calls are never
re-scanned.

### 2.9 Acyclic-CFG assumption; loops loud-declined, mechanism extended later

Phase 5 reverses on acyclic CFGs. A tainted handle whose live range crosses a
**loop backedge** is **loudly declined** (`lowering_uncompute_loop_backedge.ll`) —
never miscompiled. Real loop uncomputation (loop-carried registers, per-iteration
compute/uncompute) is post-freeze and **extends** this spine; it does not replace
it. A classical (untainted) loop is passthrough — Phase 5 does not consider it.

### 2.10 `cqrt_free` after the adjoint sequence, only on a proven-`|0⟩` rail

`cqrt_free(handle)` is emitted by the **driver** at the same last-use point, after
the adjoint sequence has returned the rail to `|0⟩` (§3b soundness obligation). It
is **not** an `emit_inverse` case: `alloc`/`free` reverse into each other only for
whole-*region* inversion (Phase 7), not per-op uncompute. The free is emitted only
when the whole reversed sub-DAG is provably `|0⟩`; an un-invertible link (§2.12)
emits **no** dangling free.

### 2.11 Whole-DAG LIFO reversal — fan-out and QQ are DAG shapes, reversed once

The productionization. The tainted data DAG (rooted at `cqrt_alloc`/`cq_theta`
mints; leaves = dead, non-escaping, non-measured terminals) is reversed by a
**single reverse-topological (LIFO) pass**:

- adjoint each gate **exactly once** (a `Seen` set dedups shared prefixes), in
  reverse program order — which, because SSA dominance puts every def before all
  its uses, **is** a valid reverse-topological order of the def-use DAG (a shared
  source's adjoint therefore always follows all of its consumers');
- emit each node's **void `_unc`** referencing its **original forward operands**
  (still live in the IR): zero the node's output rail, read its source handle(s),
  following **all** tainted parents of a QQ node (both as the `_unc` source
  operands and for the measured-upstream scan of §2.5). There is **no threaded,
  recovered handle** — the void uncompute produces nothing, so reconvergent fan-out
  has no "two divergent restored-prefix handles" to merge;
- a leaf is uncomputed **before** its source, so a shared prefix is zeroed only
  after all its consumers are gone, with the source still intact — standard Bennett
  uncompute over a DAG;
- free each rail after its **last reverse-use** (a fanned-out source is *read* by
  each consumer's `_unc`, so it is freed only after the last of them).

```
forward:   h=ry();  h1=add(h,1);  h2=add(h1,1);  h3=mul(h1,2)    // h, h1 fan out
LIFO undo: mul_unc(h3,h1);  free h3     // reads live h1, zeroes h3
           add_unc(h2,h1);  free h2     // reads live h1, zeroes h2
           add_unc(h1,h);   free h1     // h1's last reverse-use done → free
           ry(-θ) on h;     free h
```

**`cqrt_cswap` is not used and not needed.** It is required only to free a source
*while a derivative carrying its superposition survives past it* (ownership
transfer / conditional routing — the Phase-4 use). Phase 5 returns the **whole**
sub-DAG to `|0⟩` in LIFO order, so it never keeps a derivative alive while freeing
its source; and a derivative that *does* escape/measure excludes its whole ancestor
sub-DAG from freeing (§2.5/§2.6). The Rule-8 `cswap` scenario is therefore
structurally absent from Phase 5.

### 2.12 Silent-skip is abolished — every unprovable shape declines loudly

Aligning the spine with the Prime Directive: a tainted data handle the pass cannot
**prove** reversible declines **loudly** (source-located `DiagnosticInfoUnsupported`,
`opt` exits non-zero), rather than silently leaving the rail allocated. This flips
**every** silent `continue` to a loud decline — the `emit_inverse` un-invertible
signal (formerly `nullptr` → skip) **and every `isStep2Emittable` bail, including
the cross-block / divergent-arm bail of §2.4** (today a silent `return false` →
`continue`, the lone remaining silent skip). Only then is "no silent skip remains"
(§4) literally true. Each new loud predicate ships with a negative
`RUN: not … | FileCheck` fixture mirroring the diagnostic character-for-character
(Rule 12). **Note:** this is a deliberate, safe behavioral change — a program that
previously compiled-with-leak now errors; over-declining is safe, the leak was the
inconsistency.

### 2.13 Dead old-controlled-op scaffolding deleted

Verify-then-delete (Rule 11) the scaffolding the swap-route generation made
unreachable: the `ControlledSymbols::toffoliFn` flag-conjunction minter and its
`cqrt_toffoli_inv` twin (**confirmed zero callers**) — but **keep `cqrt_toffoli`**,
a live documented core-ABI primitive reserved for value/permutation arms (Rule 14),
so the deletion is scoped to the minter + `_inv` twin, *not* `cqrt_toffoli[_inv]`
wholesale; the unused `Flag`/`csyms` params on `emitInverseCall` (**no
`_controlled_inv` branch exists** — only the `nullptr` placeholder §2.12 folds into
the loud decline); any other confirmed-dead controlled-op minters
(`controlledRyInvFn`, `controlledDataTemplateFn`); and the `TaintSet::ControlFlag` /
`FlagTeardown` fields — precisely, `ControlFlag` is **read but never written**
(`FlagImage` subtracts a permanently-empty map; `Uncomputation.cpp:127`) and
`FlagTeardown` is unreferenced, so both are dead-by-non-population, not "unread".
Re-confirm no writer appears under the new driver before removal.

---

## 3. Deliverables

- **Runtime ABI (`tools/opcode_table.yaml` + `tools/gen_templates.py`)** — emit the
  **void `cq_template_<op>_<W>…_unc(out, src…)`** uncompute family (replacing the
  fresh-minting `_inv` for uncompute use, §2.3); regenerate `cq_templates.{h,c}`;
  the `gen_templates.py --check` baseline is updated **deliberately** (Rule 15).
- **`ChainWalk`** — **rewrite** the single-parent linear `Lineage` (today
  `dataInputHandle` hops only the first tainted operand) into a real multi-parent /
  multi-consumer **DAG** traversal (visited-set worklist); reverse-topological order
  = reverse program order; measured-upstream scan over **all** parents.
- **`EmitInverse`** — emit the **void `_unc`** form `(out, src…)` referencing the
  node's original forward operands, with a pinned QQ source→arg slot mapping; the
  un-invertible signal that drives the loud decline; remove the unused
  `Flag`/`csyms` params (no `_controlled_inv` branch exists — §2.13). It no longer
  threads or returns a recovered handle.
- **`Uncomputation`** — replace the per-terminal loop with the whole-DAG LIFO
  driver; flip **every** silent skip to a loud decline (§2.12, incl. the cross-block
  / divergent-arm bail §2.4); free each rail after last reverse-use; subtract an
  explicit **`ControlOwnedRails`** image (Phase-4 alloc out-rails / work rails, not
  just flag values) before terminal selection (§2.2); delete the dead
  `FlagImage`/`ControlFlag`/`FlagTeardown` plumbing (§2.13).
- **`FreePoint`** — unchanged classification; confirm placement under the DAG
  driver.
- **`ControlledSymbols`** — delete the `toffoliFn` minter + the `cqrt_toffoli_inv`
  twin; **keep `cqrt_toffoli`** (live core primitive, Rule 14) (§2.13).
- **Lit fixtures** — positive: QQ `_unc` reversal, fan-out/DAG reversal (replacing
  the `chain_fanout` no-emit lock with a real reversed-DAG check), and a
  dead-but-unmeasured **value-merge out-rail** left allocated without tripping the
  §2.12 flip (§2.2); negative (loud, Rule 12, each mirroring its message
  character-for-character): the **un-invertible primitive** (message text
  specified), measured-intermediate under QQ (both-parent), the **cross-block /
  divergent-arm** shape (§2.4), and the other flipped formerly-silent shapes.
- **E2E golden** — one slice that links a real data-handle `_unc` + `cqrt_free`
  (a dead-but-unmeasured-and-unreturned tainted handle) diffed against its golden.
- **Docs** — correct `backend.md §11.2` (measure-then-reuse OUT); update the Phase 5
  prose in `backend.md §9–10` to the void-`_unc` whole-DAG model (§9.2 still
  describes the superseded per-terminal model).

---

## 4. Done criteria

- Programs producing dead tainted handles with mid-function non-`main` last-use
  points emit the reversed adjoint + `cqrt_free` at the post-dominator block —
  for linear chains, **QQ**, and **fan-out/DAG** shapes (each gate adjointed
  once).
- `emit_inverse` is total over the emitted primitive set; every un-invertible /
  unprovable shape **declines loudly** with a negative fixture mirroring the
  string (Rule 12). No silent skip remains in the uncompute path.
- The full suite is green (`ir-pass-lit`, e2e goldens, runtime). The
  `gen_templates.py --check` baseline is regenerated **deliberately** for the new
  void `_unc` ABI family (§2.3) — it is *not* unchanged.
- **≥1 e2e golden** diffs clean against output captured from real linked code
  exercising a data-handle `_unc` + `cqrt_free` (Rule 2/16 — the only layer that
  proves every emitted symbol resolves + signature-matches).
- Dead controlled-op scaffolding removed; `opt -verify` clean.
- **Rule 13 clearance:** the whole-DAG reversal is a core lowering change — cleared
  by an independent adversarial review using analytic/trace reasoning (no
  statevector sims) before commit. A green suite alone does not clear it.

---

## 5. Out of scope

- Whole-function / region inversion (Phase 7 `cq_invert`; oracle uncompute).
- `cqrt_cswap`-based source-freeing / ownership transfer (Phase 4; not needed —
  §2.11).
- Real loop uncomputation (post-freeze quantum-`while`; extends this spine).
- Measure-then-reuse / mid-circuit measurement feedback (post-backend; doc
  corrected).
- Real reversible template bodies (Phase 8+); `emit_inverse` stays at template-call
  granularity.
- ~~Any new runtime ABI symbol / `opcode_table.yaml` edit~~ — **superseded** (§2.3):
  the void `_unc` uncompute family *does* require a YAML + `gen_templates.py` edit.
  What stays out is any *new hand-written `cqrt_*` core symbol* beyond the generated
  `_unc` family.

---

## 6. Risks

- **Whole-DAG reversal is the silent-miscompile zone (Rule 10/13).** Wrong
  topological order, a gate adjointed twice (the very bug the per-terminal bail
  avoided), or a free of a not-`|0⟩` rail are all verify-clean. The reverse-topo
  ordering, once-per-gate guarantee, and free-after-last-reverse-use must be proven
  analytically, not just tested.
- **QQ `_unc` operand slots + the void-ABI regeneration.** Mapping `(out, src₁,
  src₂)` to the wrong `_unc` args, omitting the `out` (target) operand, or following
  only one parent in the measured-upstream scan is a verify-clean wrong unitary (the
  `uncompute-lineage-measure-guard` bd issue reopens on the un-scanned branch).
  Target zeroed, both sources read-and-preserved, both slots. The fresh-minting
  `_inv` family **must not** be reused for uncompute — it frees a dirty rail (Rule 6/8).
- **The void-ABI switch changes shipped behavior, not just new shapes** (§2.3). The
  existing *linear* `lowering_uncompute_*` fixtures + golden move from fresh-minting
  `_inv` to void `_unc`; regenerate them deliberately (Rule 12) and re-verify the
  **Phase-4 callers** of the shared spine (`SwapRouteEmit` value-arm reverse-play,
  `SwitchValueEmit`) do not regress.
- **The silent→loud flip is a behavioral regression** (§2.12) — intended and safe
  (over-decline), but it changes which programs compile; document it and regenerate
  baselines deliberately (Rule 12), never by reflex.
- **Dead-code deletion must verify unreachability first** (Rule 11) — `toffoliFn`
  is confirmed dead (but `cqrt_toffoli` is live — keep it); `ControlFlag` is **read
  but never written** and `FlagTeardown` is unreferenced (dead-by-non-population,
  not "unread") — re-confirm no writer appears under the new driver before removal.
- **Acyclic assumption is load-bearing** (§2.9). A loop-carried tainted live range
  must hit the loud decline, never the DAG driver — confirm the backedge guard
  fires *before* DAG recovery.
