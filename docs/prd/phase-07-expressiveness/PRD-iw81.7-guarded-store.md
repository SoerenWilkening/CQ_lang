# PRD — iw81.7: guarded Shadow store (tainted-index memop UNDER tainted control)

> **Status:** DRAFT, opened 2026-07-06. Owner-blessed new ABI (2026-07-06).
> Bennett.jl is the **ground truth** for the store mechanics (owner directive
> 2026-07-06). This composes the two deepest hazard domains — **memory × control**
> — so every off-shape declines loudly (Prime Directive) and the core change gets a
> Rule-13 adversarial clearance before commit.
>
> **v1 accept shape (owner-locked 2026-07-06):** a **tainted-index guarded MUX
> store** into a **bounded fixed-shape alloca array**, under a **depth-1 tainted
> `br`-diamond**, reusing the region's existing compare-flag as the path predicate.
> Everything else declines (see §6).

---

## 0. The corrected design (why the first-pass "swap-route it" framing was wrong)

The swap-route control mechanism (`SwapRouteEmit`) routes a single **local SSA
register** through a `|0⟩` work rail and runs the arm body **uncontrolled** on the
rail (`Rz|0⟩ = |0⟩` makes the inactive branch a clean no-op). Its load-bearing
precondition (`armBlockIsPureSpine` / `valueArmIsPureChain`): the arm body is **a
pure, reversible transform of one local register that writes only that register**.

A **store violates every conjunct**: it writes a memory *location* (not a routable
rail), it cannot be confined to a private `|0⟩` copy, and it is a shared
side effect. Concretely, swap-routing `if (q<k) arr[i]=v` and running the store
uncontrolled writes **`arr[0]=0` on the inactive branch** (index/value rails stay
`|0⟩`) — the "store on the wrong branch" verify-clean-invisible miscompile. **A
store must be *genuinely controlled*, not swap-routed.** This is fine — the owner's
"it's OK that a QRAM store requires actual control" is correct.

### 0.1 Bennett.jl ground truth — the store is a pure reversible function on a memory VALUE

Bennett.jl (`src/shadow_memory.jl`, `src/softmem.jl`) does **not** treat memory as a
shared global side effect. Memory is an **SSA value** (a packed memword threaded
through mem-SSA); a store is a **pure reversible function** `(arr, idx, val[, pred])
→ arr'` lowered by the ordinary Bennett compute→copy→uncompute spine. Two forms:

- **Unguarded shadow store** (`emit_shadow_store!`, the "universal reversible store
  primitive") = **checkpoint-then-write**, `3·W` CNOTs:
  1. `CNOT old → tape` — evacuate the old cell value onto a fresh tape slot (kept, not
     cloned, not destroyed);
  2. `CNOT tape → cell` — cell is now `old ^ old = 0`;
  3. `CNOT val → cell` — write `val` into the **zeroed** cell ⇒ exactly `val`.
  Bennett reverse unwinds to `cell = old`, `tape = 0`. **No `old ^ new`** — the old
  value is *moved* to the tape, restored on the reverse pass.

- **Guarded shadow / MUX store** (`emit_shadow_store_guarded!` /
  `soft_mux_store_guarded_NxW`) = the same store with **each CNOT lifted to a
  `Toffoli(pred, …)`** (known cell) or **`pred & (idx==k)` folded into each slot's
  branchless `ifelse`** (tainted index, bounded `N·W ≤ 64`). `pred=1` ⇒ identical to
  unguarded; `pred=0` ⇒ every Toffoli is a no-op ⇒ **identity on cell and tape**.

Because the guarded store is a **fixed reversible circuit that is a no-op when
`pred=0`**, it stays **coherent even under a superposed `pred`** — a Toffoli with a
superposed control is a valid unitary; it entangles `pred` (hence `q`) with the
memory result, which is exactly the intended physics.

### 0.2 The "old ^ new" concern was a wrong-realization artifact — it is a BACKEND concern

The first-pass objection ("a memory cell already holds `old`, so a controlled-copy
writes `old ^ new`") only arises if you realize the store as an **IR-level XOR into a
live cell** — which is what "reuse 4.4 controlled-copy" literally suggested. That is
**not** the store. Per **PRD-7.5 §2.4 (owner decision 1)** the CQ QRAM store ABI is
**strategy-agnostic** `(array, index, val)`: the IR pass "owns **ordering only**",
and the **per-store tape + the gate-level mechanics (Shadow / MUX-EXCH / QROM,
checkpoint-then-write) are BACKEND-owned, never in the IR/ABI**. There is no
live-cell XOR anywhere the IR pass can get wrong. Bennett.jl **is** the reference
implementation of those deferred backend gates.

### 0.3 What Bennett.jl does NOT hand us (the "ours" layer)

Bennett.jl is a reversible-**classical** compiler: its `pred` is a **definite** bit,
and it **never reasons about a superposed `pred`** (SCOPING §0 provenance table;
PARITY_MAP separates B-recognition from C-physics). The **mechanism** transfers
wholesale and is coherent; the **proof** of coherence under superposed control —
clean flag uncompute, never freeing a dirty tape/cell (§3b), the §3c "don't clobber a
cell the condition reads" rejection — is CQ's own **Rule-13 obligation**, inherited
from nothing.

---

## 1. The real IR shape (Rule 9 — measured, not guessed)

`clang -O1` on the v1 source (`docs`/scratch `guarded_store.c`) **preserves the
branch diamond** (no predication, no hoist) and the store arm has **no merge phi**
(a store produces no SSA value):

```llvm
entry:
  %arr = alloca [8 x i32]                 ; bounded fixed-shape array
  memset 0                                ; zero-init (kMsgQramInit carve)
  %q = call cq_theta_si32(...)            ; condition source (also the later load index)
  %i = call cq_theta_si32(...)            ; tainted store index
  %f = icmp slt i32 %q, 3                 ; TAINTED compare = the path predicate
  br i1 %f, label %arm, label %merge      ; TRUE successor = the store arm

arm:                                      ; side-effect-only arm, NO phi
  %gi = sext i32 %i to i64
  %g  = getelementptr [8 x i32], ptr %arr, i64 0, i64 %gi
  store i32 7, ptr %g                     ; arr[i] = 7  (tainted index, classical value)
  br label %merge

merge:
  %gq = getelementptr [8 x i32], ptr %arr, i64 0, i64 (sext %q)
  %v  = load i32, ptr %gq                 ; observe the array (7.5 tainted-index load)
  ret ... cq_measure(%v)
```

Salient facts driving the recognizer:
- **Condition is a tainted `icmp`** (the existing `lowerCompareToFlag` mint applies).
- **The arm is side-effect-only** (a gep chain + a Shadow store into a bounded alloca
  array; a tainted index; **no merge phi**). This is a **new region shape** — the
  existing detectors decline it (no `soleMergePhi` to route). Nearest precedents:
  **`AbortPark`** (side-effect-only arm, no phi, flag kept on a tape) and
  **`ClassicalCallArm`** (hoist + controlled merge, no clone).
- **`q` (the condition) is PRESERVED** by the arm (a store to `arr` memory never
  writes the scalar SSA `q`), and `q` is read again at the merge → the **flag-strip
  `icmp_inv(q)` is valid** (like a phase arm). No §3c clobber for the disjoint case.

### 1.1 Current behavior (the decline to replace)

`declineTaintEscapes` (runs at `CQLoweringPass.cpp:116`, **before**
`detectControlRegions` at :163) fires **first**: the store-arm gep is under tainted
control, `qramCarveVerdict` returns **`NotQram`**, and it falls through to the generic
`kMsgOther` (`"cq taint escape: tainted value reaches an unsupported instruction"`).
So the accept path must (a) **carve** the guarded-store gep/store out of the pre-detect
escape decline, and (b) route the region to a new control recognizer.

---

## 2. Pass-order architecture (follows the existing flatten-then-reanalyze grain)

```
declineTaintEscapes        (116)  ← ADD carve: a guarded-store-under-diamond gep/store
                                     is deferred (not declined) so control detect sees it
detectControlRegions       (163)  ← ADD: recognize the GuardedStoreArm diamond (pure analysis)
lowerControlRegions        (164)  ← ADD emit: mint pred, mark the store guarded+record pred,
                                     FLATTEN the diamond; DO NOT strip the flag (defer, §3)
repropagateControlMerges   (180)  ← re-propagate taint on the now-FLATTENED straight-line CFG
                                     ([[0vvq-byref-unfreeze]] precedent)
lowerShadowMemory          (211)  ← emit the GUARDED store cqrt_qram_store_<W>_controlled(pred,…)
                                     for a store recorded by the control emitter; plain otherwise
lowerRotations/Ops/Measures(246+) ← q, i, val lower to i32 handles as usual
uncompute                  (257)  ← whole-DAG LIFO reverses the guarded store via its
                                     _controlled_unc; THEN strips + frees each recorded pred (§3)
```

**Why this grain:** `lowerControlRegions` flattens the diamond *before*
`repropagateControlMerges` and `lowerShadowMemory`, so the previously-under-control
store becomes **straight-line** and lowers through the **existing 7.5 Shadow store
path** — only the *symbol* changes (plain → `_controlled`, with the recorded `pred`
operand). This is the same mechanism `[[0vvq-byref-unfreeze]]` used to lower a
control-merge-fed by-ref libm call: flatten, then re-run the straight-line lowering.

### 2.1 The coordination side-channel

Mirror `TaintSet::GraveyardRails` / `ControlOwnedRails` / `OutputRails`: add a new
`TaintSet` side-channel recording, per accepted guarded store:
`{ StoreInst* store, Value* predFlag, /* enough to re-mint icmp_inv: */ CmpInst-kind
predicate, Value* condHandle (q), int literal, StringRef width }`.
- Populated by the control emitter (`GuardedStoreArmEmit`).
- Consumed by `lowerShadowMemory` (emit the `_controlled` symbol with `predFlag`).
- Consumed by `uncompute` (emit `_controlled_unc`, then the deferred pred strip+free).

---

## 3. The core hazard — pred lifetime through the LIFO store-uncompute

The store's uncompute (`cqrt_qram_store_<W>_controlled_unc(pred, arr, idx, val)`)
must run **while `pred` is still live** and gated by the **same** `pred` value — an
ungated / already-stripped `_unc` over-pops the inactive branch (a dephasing silent
miscompile: hazard #1). But the control emitter's *normal* flag-strip (`icmp_inv`)
runs eagerly at the region merge. **These conflict.** Resolution:

1. The control emitter mints `pred`, records it, and **does NOT strip it** (defer).
   `pred` is a `ControlOwnedRail` kept live across the whole DAG.
2. `EmitInverse` reverses the guarded store as its `_controlled_unc` with the **same
   `pred` operand** — mechanical (the pred is just a call operand). LIFO places the
   `_unc` late in the reversal (the store is early in forward order).
3. **After** the whole-DAG LIFO completes, the uncompute stage emits, per recorded
   pred: the **flag-strip `icmp_inv(q)`** (valid — `q` is preserved by §1) + a
   `cqrt_free(pred)`. Ordering holds because the store's `_unc` (one of the earliest
   forward ops) is one of the *last* LIFO reversals, so a strip emitted after the LIFO
   is necessarily after the `_unc`.

**Coherent-first (Rule 5) mandates the proper strip, not a leak.** `pred = icmp(q)`
is entangled with `q`; `q` is used coherently downstream (the merge load index + its
measure). Leaking `pred` (AbortPark-style) would leave a which-path copy of `cond(q)`
entangled with `q` → a partial measurement that dephases `q` under interference.
Because `q` is preserved, `pred` is cleanly strippable — so we strip it. (AbortPark
may leak only because `abort` terminates; we do not.)

---

## 4. New ABI (owner-blessed 2026-07-06) — strategy-agnostic, hand-written core

Add to the hand-written `cqrt_*` core ABI (`runtime/cq_runtime.{h,c}`; the
`cqrt_copy_<W>_controlled` precedent — NOT the generated YAML surface), per the 5
integer widths `i1/i8/i16/i32/i64`:

```c
void cqrt_qram_store_<W>_controlled    (int32_t pred, int32_t arr, int32_t idx, int32_t val);
void cqrt_qram_store_<W>_controlled_unc(int32_t pred, int32_t arr, int32_t idx, int32_t val);
```

- Trace-only bodies (`printf`), like every `cqrt_*`. `pred` is arg 0 (the guard).
- **Strategy-agnostic** (PRD-7.5 §2.4): the backend realizes the guarded Toffoli-lifted
  shadow / per-slot MUX (`emit_shadow_store_guarded!` / `soft_mux_store_guarded`); the
  ABI stays `(pred, arr, idx, val)` and owns the tape.
- `_controlled_unc` is a **distinct symbol** (the store is not self-inverse — forward
  keeps history, reverse plays it back), gated by the **same `pred`**.
- Minted lazily via `WidthDispatch` (the `cqrt_qram_store_<W>` precedent). Named by
  `TemplateName` grammar (`_controlled` / `_controlled_unc` suffixes).

FP / `i128` cells stay declined (no reversible copy width — the 7.5 rule).

---

## 5. Recognizer (accept predicate) — pure analysis, before mutation (Rule 9)

Accept iff **all** hold (else decline loudly; a decline fixture + adversarial probe per
clause, Rule 12):

1. Tainted-condition **`br` diamond**, depth-1 (`Pred -[f]-> {arm, merge}`), `f` a
   tainted `CmpInst` (reuse `ControlDetect` shape recovery).
2. The gate arm is a **single side-effect-only block**: a gep-chain + **one Shadow
   store** into a **bounded fixed-shape alloca array** (reuse `classifyShadowAccess`
   origin walk), tainted index, **no merge phi**, sibling empty (straight to merge).
3. The store's array **`qramCarveVerdict == Accept`** *ignoring* the under-control
   test (bounded shape, integer width, single-origin provenance, no aliasing/mixed/
   mid-seq/escape) — i.e. everything the straight-line 7.5 store requires.
4. **§3c**: the store's array is **not read by the branch condition** (the condition
   `q` is an SSA scalar disjoint from `arr`; if `cond` transitively loads from `arr`,
   reject — the guard would reference a clobbered cell).
5. `q` (condition provenance) is **not value-written** by the arm (trivially true for a
   store-only arm; the flag-strip validity guard).

---

## 6. Decline matrix (Prime Directive — over-decline is safe)

Each ships a `RUN: not … | FileCheck` negative mirroring the diagnostic
character-for-character.

| Off-shape | Verdict |
|---|---|
| **Unbounded / dynamic-N** array, heap alloc | decline (physics floor — needs BennettVM RAM-VM; PARITY_MAP:191) |
| **General aliasing / fan-out** on the array | decline (linear-lineage, Rule 8) |
| **Deeper than depth-1** nest (guard is a block reachability predicate, not the single flag) | decline (needs `_compute_block_pred!` OR-reduction = **iw81.14**, unbuilt) |
| **Coherent/superposed cell** or FP / `i128` element width | decline (no reversible copy width; no-cloning) |
| **§3c**: arm stores into a cell the condition reads | decline (clobber) |
| Store **in a loop** | decline (iw81.13) |
| Mixed arm (store **+** a value/phase op), two content arms | decline (homogeneity) |
| Store arm on a classical (untainted) condition | ignored (classical control, compiled as-is) |

---

## 7. Increments

- **Inc 1 — ABI:** add `cqrt_qram_store_<W>_controlled(_unc)` (runtime h/c) + `WidthDispatch`
  minting + `TemplateName` grammar. Red-green at the symbol level (a lit fixture that
  hand-writes the guarded call and checks it survives verify + links). No recognizer yet.
- **Inc 2 — Recognize + accept (depth-1, const value):** the `GuardedStoreArm` region
  Kind + `classifyGuardedStoreArm` + `GuardedStoreArmEmit` (mint pred, record, flatten,
  defer strip) + `declineTaintEscapes` carve + `lowerShadowMemory` guarded emission +
  `EmitInverse` guarded adjoint + deferred pred strip in `uncompute`. Positive lit
  fixture on §1's IR. Every §6 row as a decline fixture.
- **Inc 3 — e2e golden:** one vertical slice (`slice_qram_guarded_store.c`) linking the
  new symbols, byte-diffed against a golden trace.
- **Rule-13 clearance:** independent adversarial review (analytic/trace) of the pred
  lifetime, the inactive-branch `_unc` gating, the §3c carve, and the flatten/reanalyze
  interaction, before commit.

## 8. Done-criteria

Both lit layers green (positive + full §6 decline matrix), the e2e golden byte-diff
clean, `gen_templates.py --check` clean (YAML untouched — hand-written core), full
`ctest` green, and a Rule-13 adversarial clearance recorded (this doc §Clearance).

## 9. Clearance (Rule-13 adversarial review — 2026-07-07)

Independent 6-lens adversarial review + skeptic adjudication (pred-lifetime,
control-dependence refinement, carve/detect divergence, flatten-CFG safety, coherence
under superposed control, over-accept matrix). Outcome:

- **CONFIRMED sound:** pred-lifetime ordering (store-reverse-before-strip is airtight
  via reverse-program-order; the `railOf(store)==flag` / `Earliest` free-after-strip
  is masked because the mint precedes the store — a load-bearing ordering now
  commented); the control-dependence `instUnderTaintedControl` refinement (full
  idom-chain walk, post-dominates-ALL-dominating-brs AND-semantics, no 7.5
  regression); carve↔detect anti-divergence (every `DeferControl` funnels to accept
  or loud decline via the shared `guardedShadowStoreShape` + non-nested gate); the
  flatten (merge-φ + user-escape double fence); coherence (flag strip valid — `q`
  unchanged by a store; `§3c` `conditionReadsMemory` sufficient); the over-accept
  fences (fp/i128 cell `kMsgQramCell`, escape, non-zero init, mid-seq, swapped-arm,
  Q+Q, nested).

- **[C1] CONFIRMED silent miscompile — FIXED (2026-07-07).** `soleSideEffectStore`
  rejected only `Load`/`Call`/`Invoke`; an `atomicrmw`/`cmpxchg`/`fence` (reads no
  tainted value → `declineTaintEscapes` skips it) in the store arm was accepted and
  hoisted UNCONDITIONALLY by the flatten (a classical side effect on the wrong
  branch, trace-invisible). Fixed by adding the atomic/fence isa checks + a
  `mayHaveSideEffects()` catch-all; paired negative fixture
  `lowering_reject_qram_guarded_store_side_effect.ll`.

- **[P1] pre-existing owner-doctrine (NON-blocking, filed as follow-on).** In `main`,
  `computeFreePoint` returns `Escaped` for every terminal, so the whole-DAG reversal
  is skipped and the guarded flag is left LIVE (never stripped). The adjudicator
  confirmed this is **subsumed by the pre-existing 7.5 Shadow-scratch main-leak**: a
  plain `arr[q]=v` in `main` already leaves the cell entangled with `q` un-reversed
  (same `main` early-out), so iw81.7 does NOT introduce a new class — it inherits
  7.5's `main` behavior. A 7.5/main-doctrine question for the owner
  (coherent-reuse-then-measure-in-main Shadow programs), not an iw81.7 barrier. The
  shipped e2e golden deliberately uses a `noinline` helper (not `main`) so the
  reversal is exercised.

**Verdict:** CLEARED after the [C1] fix — 0 remaining confirmed silent miscompiles.

## 10. Post-core v1 declines (additive follow-ons, not correctness debt)

Discovered during implementation/review; each declines LOUDLY (Prime Directive):
swapped-branch (FALSE-successor store arm — needs ¬flag brackets through the guarded
`_unc`); nested diamond (`instUnderTaintedControl(BI)` gate — the inner-only-guard
hazard); two guarded stores sharing a block (cross-region block-lifetime pre-flight);
`§3c` condition-reads-memory; fp/i128 cell; dynamic-N / heap / aliased (inherited 7.5).
