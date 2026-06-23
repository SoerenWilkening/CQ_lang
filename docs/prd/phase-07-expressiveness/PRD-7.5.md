# Phase 7.5 PRD — QRAM, full Shadow model (DRAFT)

> **Status:** DRAFT, written at the start of Phase 7.5 (2026-06-23) to
> memorialize the design decisions resolved in PRD-discovery discussion + the
> verified Bennett.jl ground-truth investigation. Does not duplicate
> [`ROADMAP.md`](../../../ROADMAP.md) §"Phase 7 — 7.5", the
> `bd memories pointer-boundary-linearity-bennett` /
> `7-5-qram-design-decisions` directives, or
> [`bennett-jl-comparison.md`](../../bennett-jl-comparison.md); captures the
> 7.5-specific decisions, deliverables, and done criteria. One PRD covers the
> whole tainted-index memory increment family.
>
> **STUB-ONLY (owner direction 2026-06-23):** This phase delivers **the IR pass
> only** — the translation of `load`/`store`/`getelementptr`/`alloca` opcodes
> over a tainted index to `cqrt_qram_*` **trace-only** stub calls, exactly as
> every other op lowers to `cqrt_*` / `cq_template_*`. **No gate implementation.**
> The Shadow/MUX-EXCH/QROM gate-level mechanics live in the (deferred) backend;
> Bennett.jl is the ground-truth reference for *what the stubs represent*, not a
> thing we re-emit as gates here.
>
> **Owner decisions folded in 2026-06-23 (PRD-discovery dialogue):**
> (1) **backend owns the per-store tape**, the IR pass owns **ordering only**
> (keeps the LLVM IR debuggable; the tape never appears in the IR);
> (2) v1 ingests **both** const-global reads (QROM-shaped) **and** alloca-backed
> mutable arrays (Shadow-shaped);
> (3) **full Phase-5 last-use uncompute integration** (a dead array's stores are
> reversed in strict LIFO; an escaped/measured array is not reversed);
> (4) the **fuller provenance walk** (single-origin proof through gep chains /
> pointer phi-select where provable), not the trivial single-gep-only accept;
> (5) an **escaped array's residual tapes LEAK** (Rule-6 "left allocated, never
> freed", option A) — **not** the Bennett copy-out-and-reverse wrap;
> (6) acceptance is **conditioned on the reversal-ensured contract** (§2.8) — any
> unprovable invariant is a **loud decline**, never a silent accept.

---

## 0. Invariant recap (not new — the ground 7.5 stands on)

- **Over-declining is safe; over-accepting is a silent miscompile** (Prime
  Directive). C emits `inttoptr`/aliasing/pointer-phi readily (unlike Bennett's
  memory-safe Julia), so 7.5 trips the loud memory-reject **far more often** —
  every new accept-predicate ships a decline fixture + adversarial probe
  (Rule 12), and every reject names the offending pattern (Bennett's signpost
  model).
- **Reversibility ⟺ linearity ⟺ no-cloning** ([[pointer-boundary-linearity-bennett]]).
  What stays rejected after 7.5 (arbitrary aliasing, no-provenance
  `inttoptr`/`ptrtoint`/`addrspacecast`, heap escape, runtime-unshaped
  containers) is forbidden by **physics**, not as a CQ shortcut — triangulated
  by Bennett's pebble game, the Axelsen–Glück linear reversible heap, and
  Bennett.jl's own reject set. The load-bearing precondition, shared with
  Bennett, is **every allocation has a known shape (width × count) at compile
  time**; dynamic-index access into managed, known-shape memory is reversible.
- **The compiler never inserts a measurement the user did not write** (Rule 5).
  A QRAM `load`/`store` adds **zero** measurement gates. Coherent-first.
- **Free only a proven-`|0⟩` rail; an Escaped/kept rail is never freed dirty**
  (Rules 6/8). **A freed entangled write rail is a hidden measurement** that
  collapses the register — the central physics hazard of memory. The uncompute
  spine must **own the write rails' reversal ordering** (§2.4/§2.8); a rail not
  provably `|0⟩` is **left allocated** (a qubit leak, accepted in the
  qubits-not-scarce regime), never freed.
- **No-cloning** (Rule 8): freeing a source carrying superposition needs
  controlled-SWAP, not copy+uncompute; whole-chain reversal requires **linear
  lineage** — fan-out / aliasing bails. Aliasing **is** the copy/diagonal map
  linear logic lacks.
- **Verify-clean ≠ correct** (Rule 2). 7.5's hazards — a non-LIFO store
  reversal, a mid-sequence observation reversed away, an aliasing pair that
  breaks the tape pairing, a wrong `_<W>` element-width symbol, a mis-modeled
  initializer — are **all verify-clean with no downstream backstop**. Cleared by
  analytic/trace reasoning + golden e2e diff + independent Rule-13 review, never
  by `opt -verify`.
- **Taint is the only Q/C boundary** (Rule 3). 7.5 adds **no taint source and no
  sink**; `@cq_theta` stays the sole source, `@cq_measure` the sole sink. It only
  changes *what a tainted value reaching a memory op does* — coherent QRAM
  lowering instead of loud decline.
- **Handles are always `i32`; width lives in the symbol suffix** (Rule 15). The
  `<W>` in `cqrt_qram_*_<W>` is the **element** width (read by SSA identity
  **before** rotation lowering RAUWs operands to `i32`); the **index** handle is
  always `i32` regardless of its logical width (the `-O1` `zext …to i64` is
  irrelevant to the symbol).

---

## 1. Scope

7.5 widens the **accepted-C subset** so a **tainted-index memory access** —
plain C `a[i]` with a quantum `i`, and the stores/loads/geps `clang -O1` emits
for it — lowers **coherently** to `cqrt_qram_*` trace stubs instead of
loud-declining at `declineTaintEscapes`. Today a tainted-index `getelementptr`
declines with `kMsgOther` ("cq taint escape: tainted value reaches an
unsupported instruction") and a tainted-value `store` with `kMsgStore` ("cq
taint escape: tainted value stored to memory") (`TaintPropagation.cpp:332-334`).

**The `-O1` reality that scopes the entire phase (Rule 11, verified by
extracting real IR).** `clang -O1` **SROA-scalarizes any array whose every
access is a static (compile-time-constant) index** — `arr[3]=q; return
arr[3]+arr[1]` lowers to `ret %theta` with **no array at all**. Therefore:

- **Static-index memory never reaches the pass** — Bennett's pure static
  `:shadow` is auto-handled by clang; **it is not 7.5's problem.**
- **Only dynamic/tainted-index accesses survive** (the one thing `-O1` cannot
  scalarize). `return constarr[q]` survives as `getelementptr [N x iW], ptr
  @__const…, …, %taintedidx` + `load` (a **QROM-shaped** read); `arr[q]=v` keeps
  the `alloca` + `gep` + `store` (a **Shadow-shaped** mutate). Once an array has
  **any** dynamic access, the **whole `alloca` survives** and even its
  static-index loads (`arr[0]`) become real `load`s.

So 7.5 is, precisely, **the dynamic-index memory the optimizer hands us**.

**Bennett ground truth** (`src/lowering/memory.jl`, `src/shadow_memory.jl`;
[[7-5-qram-design-decisions]]): Bennett dispatches per access — `idx isa
ConstOperand → :shadow` (static); dynamic `N·W ≤ 64 → :mux_exch_NxW` (packed
`soft_mux`); dynamic `N·W > 64 → :shadow_checkpoint`, the **universal fallback**
(per-slot index-equality-guarded shadow stores / per-slot Toffoli-copy loads).
**CQ's v1 "Shadow model" = `shadow_checkpoint` generalized** — the one strategy
that works for any known shape and any index. MUX-EXCH (packed, `N·W ≤ 64`),
QROM (const tables), Feistel (bijective), and Persistent-DS (dynamic-N) are
**post-freeze optimizations** over the frozen v1 ABI, CQ's concrete post-7.5
memory roadmap.

**Frozen-ABI fault line (the one axis that matters):**

| Item | New frozen ABI? | Freeze-gating? |
|------|-----------------|----------------|
| Array resource | **Yes** — `cqrt_qram_alloc_<W>` | **Yes** |
| Tainted-index load | **Yes** — `cqrt_qram_load_<W>` (+ `_unc`) | **Yes** |
| Tainted-index store | **Yes** — `cqrt_qram_store_<W>` (+ `_unc`) | **Yes** |
| Per-store **tape** (old-value rail) | **No** — backend-owned, never in the IR/ABI (§2.4) | n/a |
| Shadow vs MUX-EXCH vs QROM choice | **No** — backend implementation detail (§2.1) | n/a |

7.5 adds a **new frozen `cqrt_*` core-ABI family** (§2.3) so the backend can own
the physical memory. The symbols are **hand-written core ABI**
(`runtime/cq_runtime.{h,c}`), **not** YAML-generated templates (Rule 15 governs
`cq_template_*`, not `cqrt_*`). 7.5 is the **freeze-gating** increment of
Phase 7; it **must land pre-freeze** and is cleared by independent Rule-13
review (§4) — both for the frozen signatures and because it edits the
escape/uncompute spine (where every silent miscompile has lived).

---

## 2. Design decisions

### 2.1 Stub-only, strategy-agnostic ABI — Shadow/MUX/QROM is a **backend** choice
Per owner direction, 7.5 emits **trace-only `cqrt_qram_*` stubs**; it does **not**
implement the per-slot equality-guarded fan-out, the tape CNOTs, or the
MUX/QROM packing. At the stub level all five Bennett strategies collapse to one
`(array, index)` ABI — the backend (deferred) picks Shadow / MUX-EXCH / QROM per
allocation. The **only** place a strategy could leak into the frozen ABI is the
per-store tape; owner decision 1 (§2.4) keeps it backend-owned, so the ABI stays
strategy-agnostic. The "Shadow model" name records the **v1 backend target**
(`shadow_checkpoint`), not an IR-pass obligation.

### 2.2 Scope follows the optimizer — dynamic-index only, both array sources (owner decision 2)
Per §1's `-O1` finding, 7.5 lowers exactly the memory ops that survive SROA:
- **Const-global tainted-index read** (QROM-shaped): `getelementptr` off a
  `@__const` global + `load`, tainted index. Read-only — no store, no tape, no
  reversal of the array. **Simplest; Increment 1.**
- **Alloca-backed mutable array** (Shadow-shaped): `alloca [N x iW]` (const N) +
  `gep` + `store`/`load`, tainted index. Needs `cqrt_qram_alloc`, the store path,
  and the reversal machinery. **Increment 2.**

Both are v1. A **classical-index** access on a *surviving* array (e.g. `arr[0]`
after a dynamic store forces the alloca to survive) stays **classical** — the
pass touches it only if its index **or** value is tainted; an untainted load/store
on the surviving array is left alone (no spurious taint).

### 2.3 The explicit QRAM ABI (NEW frozen `cqrt_*` core symbols)
Hand-written core ABI added to `runtime/cq_runtime.{h,c}` (trace-only bodies),
frozen at Phase 11. `<W>` is the **element** width, `W ∈ {i1,i8,i16,i32,i64}`
(the integer widths with a reversible copy — `widthHasReversibleCopy`,
`OpcodeSupport.cpp:180-187`; **no fp** — an fp cell is the angle hazard, §2.10;
**no i128** — deferred with the 7.1 i128 follow-up). All handles are `i32`
(Rule 15):

- `int32_t cqrt_qram_alloc_<W>(int32_t count);` — register a **known-shape**
  array of `count` width-`W` cells; the backend allocates the physical register
  block and returns the **array handle** (an `i32` resource token). Initial cell
  contents are **classical metadata** (§2.6): `|0⟩` for a memset-0 `alloca`, the
  constant table for a `@__const` global — replayed at inspection, not a runtime
  feature (mirrors 7.6's classical format string).
- `int32_t cqrt_qram_load_<W>(int32_t arr, int32_t idx);` — read the cell at
  (quantum) index `idx` into a **fresh** `i32` value handle (Toffoli-copy-out;
  the cell is **preserved**). An ordinary data producer.
- `void cqrt_qram_store_<W>(int32_t arr, int32_t idx, int32_t val);` — write
  `val` into the cell at index `idx`. **Void, in-place on the arg-0 array
  handle** (the backend stashes the displaced old value on its own tape; §2.4).
- `void cqrt_qram_load_<W>_unc(int32_t out, int32_t arr, int32_t idx);` — adjoint
  of a load: un-copy the dead loaded value `out` back to `|0⟩` using the cell
  (`_unc(out, src…)` convention, like `cq_template_*_unc`).
- `void cqrt_qram_store_<W>_unc(int32_t arr, int32_t idx, int32_t val);` —
  adjoint of a store: the backend **pops** its tape, restoring the cell's old
  value (same args as the forward store; `_unc` selects pop over push).

**Trace format** (the golden contract): `cqrt_qram_alloc_i32(8) -> a0`,
`cqrt_qram_load_i32(a0, h3) -> h4`, `cqrt_qram_store_i32(a0, h3, h2)` (void), and
the `_unc` twins. Array handles print with a distinct prefix (`a<N>`) for
readability but are `i32` like every handle. The exact format is **frozen** —
Rule-13 (§4).

### 2.4 Backend owns the per-store tape; the IR pass owns **ordering only** (owner decision 1)
A reversible store displaces the cell's old value into a fresh `|0⟩` ancilla —
Bennett's **tape**. For a **quantum** index this is not one rail but **`n` per-slot
tapes + `n` equality wires** per single `arr[q]=v` (`shadow_checkpoint`); the count
and structure are a **gate-level decomposition** 7.5 explicitly does not emit.
**Decision: the backend owns the tape; it never appears in the IR or the ABI.**
The IR pass emits the forward `cqrt_qram_store_<W>` and — for a non-Escaped array
— a `cqrt_qram_store_<W>_unc` at the Phase-5 reversal point; the backend's `_unc`
body pops *its own* tape. The IR pass owns **when/in-what-order** stores reverse
(ordering); the backend owns the **physical** tape (reversibility). This keeps the
lowered IR readable — a developer sees `cqrt_qram_store(a0, h3, h2)`, not `n`
threaded rails — at the cost of trusting the contract in §2.8.

### 2.5 A store is a **void in-place mutator on the array handle** — like `cqrt_rz`
`cqrt_qram_store_<W>(arr, idx, val)` is void with the array handle as **arg-0** —
structurally the same shape `ChainWalk.cpp:isInPlaceGateOn` already recognizes for
`cqrt_ry_`/`cqrt_rz_` (a void mutation that mints no new value and keeps the
handle live). **Decision:** extend that in-place-mutator vocabulary to
`cqrt_qram_store_`, and add a **new adjoint rule** `store → cqrt_qram_store_<W>_unc`
to the `EmitInverse` dispatch table (the closed per-call adjoint table the live
Phase-5 driver consults — Rule 14, extend don't fork). A **load** is an ordinary
tainted data producer (a copy-out): the spine already reverses such producers, so
`load → cqrt_qram_load_<W>_unc` is the same pattern as `cq_template_*` → `…_unc`.
The loaded value's width is recorded into the `HandleWidth` side-table (the 7.1
discipline, `RotationLowering.cpp:164`) so downstream consumers pick the right
`_<W>`.

### 2.6 Array-handle birth + initializer modeling
- **Const-global** (`@__const.f.arr`): the pass materializes one
  `cqrt_qram_alloc_<W>(count)` for the global (shape read from the array type) at
  first tainted-index use; the constant **contents stay classical** (inspection
  metadata, §2.3) — no per-cell init calls, no taint (the data is classical; only
  the index is quantum). This is the QROM read.
- **Alloca** (`alloca [N x iW]`, **const N**): one `cqrt_qram_alloc_<W>(N)`; the
  `llvm.memset` / store-of-constants initializer `-O1` emits (`int arr[N]={…}`)
  seeds the **classical** initial contents recorded against the handle. A
  **dynamic-N** `alloca` → **decline** (needs Persistent-DS, post-freeze).
- The **index** operand is the tainted value feeding the gep; the **gep** is
  resolved to `(array handle, index handle)` and **erased** (it does not get its
  own stub — it is absorbed into the load/store, like Bennett's `PtrOrigin`).

### 2.7 Full Phase-5 last-use uncompute integration (owner decision 3)
The array participates in the whole-DAG spine like any handle:
- **Dead (scratch) array** at scope exit → its stores reverse in **strict LIFO**
  (`cqrt_qram_store_<W>_unc` per forward store, reverse program order;
  `Uncomputation.cpp:136` iterates `D.Calls` reversed), every loaded-value copy
  uncomputes (`cqrt_qram_load_<W>_unc`), tapes return to `|0⟩`, cells restore.
- **Escaped / measured array** (its final mutated state **is** the answer —
  returned or measured after the last store) → **reversed nothing** (the current
  `Uncomputation.cpp:227` Escaped/NotClosed skip; FreePoint's escape
  classification, `FreePoint.cpp:68-77`, is the hook). Its residual tapes leak
  (§2.9).

### 2.8 The reversal-ensured contract (owner condition — decline LOUDLY if unprovable)
Acceptance is conditioned on **proving** reversal; Bennett gets this free from its
whole-DAG pebble reversal, CQ earns it surgically. All four must hold, else the
access **loud-declines**:
- **(i) Paired emission.** Every forward `cqrt_qram_store` on a non-Escaped array
  gets exactly one `_unc` twin from the spine (the standard `_unc` discipline).
- **(ii) Strict LIFO to the same array.** `_unc` twins fire in exact reverse
  program order of the forward stores to that array, so the backend's tape stack
  pops in push order. In-place void mutations on one handle are **totally
  ordered**, and a quantum-index store touches every cell (fan-out), so the stores
  **never commute** — reordering is never legal and the chain is linear by
  construction.
- **(iii) No mid-sequence observation.** The array may Escape (be returned /
  measured / read coherently) **only after its last store**, or not at all. A
  measure/return between two stores observes an intermediate state a later
  reversal would corrupt → **decline** (new QRAM guard on FreePoint's escape
  classification).
- **(iv) Linear lineage, single origin, known shape** (Rule 8 + Bennett's
  precondition). Each load/store pointer resolves to a **single `PtrOrigin`**
  (the fuller provenance walk — gep chains, and pointer phi/select where a single
  origin is provable), the array has a **compile-time shape (W × N)**, and there
  is no aliasing fan-out. Pointer-phi **multi-origin**, `inttoptr`/`ptrtoint`/
  `addrspacecast`, heap escape, dynamic-N `alloca`, and runtime-unshaped
  containers → **decline**, each with a pattern-naming diagnostic.

### 2.9 An escaped array's residual tapes **leak** (owner decision 5 — option A)
When the array Escapes, the spine reverses nothing, so the backend's per-store
tapes are never popped — they hold old values. **Decision: accept the leak**
(Rule-6 posture: dirty rails are *left allocated, never freed* → never a hidden
measurement, never a collapse). Since the array Escaped, the §2.8(iii) guard
guarantees no remaining in-function coherent interference reads it, so the leaked
tapes cannot dephase a live computation. The **Bennett copy-out-and-reverse wrap**
(copy the answer, reverse all stores, leave a clean array) is **rejected for v1** —
it inserts a copy+reverse the user did not write and fights coherent-first
"keep the answer in place" (Rule 5); revisit post-freeze only if a concrete
interference hazard surfaces.

### 2.10 Integer cells only; the fp/angle wire stays uncrossed
Cell width is gated on **`widthHasReversibleCopy`** (integer `i1..i64`), never on
`abiWidthFromType`-non-empty (f64 has a valid width yet is an **angle** — the f64
silent-miscompile family). A **floating-point** array element → **decline**
(`isFPOrFPVectorTy()`, not scalar-only `isFloatingPointTy`). A QRAM load/store of
an integer cell is **basis-encoded data** (Toffoli-copy correct, Rule 7), never an
in-place phase answer — the integer-only scope is the structural guard, stated
explicitly in the Rule-13 clearance.

### 2.11 Straight-line only; taint boundary unchanged
7.5 lowers **straight-line** tainted-index memory. A QRAM access inside a loop
needs the loop **unrolled** (7.3, not yet done) — until then it hits the existing
loud loop-backedge reject (Rule 6 `FreePoint`); 7.5 does **not** lift that.
7.5 adds **no taint source and no sink**; it only changes what a tainted value
reaching a memory op does.

### 2.12 Trace-only posture unchanged
The runtime stays trace-only (owner decision 2026-06-10). The "memory" in v1
**is** the ordered sequence of `cqrt_qram_*` trace lines on an array handle; cell
contents (const tables, initializers) are **classical** inspection metadata, not a
simulated runtime feature. No simulation, no measurement.

---

## 3. Deliverables

1. **Frozen ABI** (`runtime/cq_runtime.{h,c}`, hand-written, trace-only bodies):
   `cqrt_qram_alloc_<W>`, `cqrt_qram_load_<W>` (+ `_unc`), `cqrt_qram_store_<W>`
   (+ `_unc`) for `W ∈ {i1,i8,i16,i32,i64}`, trace format per §2.3. Callees minted
   lazily in the pass via a `WidthDispatch`-style helper (mirror `copyFn`).
2. **Carve-out** of tainted-index `gep`/`load`/`store` from `declineTaintEscapes`
   (`TaintPropagation.cpp`) — for the **proven** single-origin known-shape shape
   only — mirrored into the `runOnFunction` shim. Lands **together** with the
   emitter (Rule 12/13 — a carve-out without an emitter leaves a memory op reading
   the `i32` handle post-RAUW, the opaque silent miscompile).
3. **Provenance + emitter module** (new in `ir-pass/src/`, `cq` namespace): the
   single-`PtrOrigin` walk (gep chains, pointer phi/select where provable; §2.6,
   §2.8(iv)); array-handle birth + initializer modeling (§2.6); per accepted
   load/store, emit `cqrt_qram_load_<W>` / `cqrt_qram_store_<W>` and erase the gep;
   record the loaded-value width in `HandleWidth`. Wired into `CQLoweringPass::run`
   **before `lowerRotations`** (pre-RAUW SSA identity, the control/IO precedent).
4. **Uncompute-spine integration**: extend `ChainWalk.cpp:isInPlaceGateOn` to
   `cqrt_qram_store_`; add `store → cqrt_qram_store_<W>_unc` and
   `load → cqrt_qram_load_<W>_unc` rules to `EmitInverse`; the §2.8(iii)
   mid-sequence-observation guard on FreePoint's escape classification; the
   §2.9 escaped-array leak (no `cqrt_free`). A probe asserting LIFO store reversal
   and that an escaped array's stores are **not** reversed.
5. **Decline fixtures** (Rule 12, mirrored char-for-char): pointer-phi
   multi-origin, `inttoptr`/`ptrtoint`/`addrspacecast`, dynamic-N `alloca`, heap
   escape, fp cell, `i128` cell, a mid-sequence measure/return between two stores,
   a fan-out (aliasing) pointer, and a QRAM access inside a loop (7.3 boundary).
6. **Positive lit fixtures** (two RUN lines incl. `-passes=verify`, CHECK +
   CHECK-NOT): const-global read (`return constarr[q]` → `cqrt_qram_alloc` +
   `cqrt_qram_load`, `CHECK-NOT: getelementptr` surviving); alloca store+load
   (`arr[q]=v; …` → `cqrt_qram_alloc` + `cqrt_qram_store` + `cqrt_qram_load`); a
   **dead-array** fixture proving LIFO `_unc` reversal; an **escaped-array**
   fixture proving no store reversal.
7. **≥1 e2e golden smoke** (Rule 16; `tests/e2e/run_slice.sh` + a new
   `add_test(NAME e2e-slice-qram …)` block in `tests/e2e/CMakeLists.txt` — **cmake
   re-configure required**, e2e does not auto-discover): a program doing tainted-
   index array access lowers to `cqrt_qram_*` lines, **no measurement**,
   `opt -verify` clean, golden trace diff clean.

---

## 4. Done criteria

- Programs using tainted-index array access (const-global QROM reads and
  alloca-backed Shadow mutates) lower to `cqrt_qram_alloc_<W>` +
  `cqrt_qram_load_<W>` / `cqrt_qram_store_<W>` sequences — **zero measurement
  gates**, `opt -verify` clean, golden e2e trace diffs clean; a dead array's
  stores reverse in **strict LIFO**, an escaped array's stores are **not**
  reversed.
- Every off-pattern shape declines **loudly** with a source-located diagnostic
  naming the pattern: pointer-phi multi-origin, `inttoptr`/`ptrtoint`/
  `addrspacecast`, dynamic-N `alloca`, heap escape, fp/`i128` cell, mid-sequence
  observation, aliasing fan-out, and a QRAM access inside an un-unrolled loop.
- `gen_templates.py --check` SHA-256 drift clean (the new symbols are hand-written
  `cqrt_*`, **not** YAML — confirm the drift check stays green and the new core
  symbols are declared in `cq_runtime.h` with matching `.c` bodies).
- Each lit accept-predicate has a mirrored negative `RUN: not … | FileCheck`
  (Rule 12), diagnostic matched character-for-character.
- **The QRAM lowering is cleared by independent adversarial Rule-13 review** — a
  green suite alone does not clear it — covering **both** the new **frozen
  `cqrt_qram_*` signatures** (a wrong frozen ABI is permanent) **and** the
  escape/uncompute-spine edits (the verify-clean reversal hazards of §6).

---

## 5. Out of scope (declines, or other phases)

- **Static-index memory** — auto-scalarized by `-O1` (§1); never reaches the pass.
- **MUX-EXCH / QROM / Feistel / Persistent-DS as distinct backends** — post-freeze
  optimizations over the frozen v1 ABI; v1 emits one strategy-agnostic stub family.
- **Aliasing / no-provenance pointers** (`inttoptr`/`ptrtoint`/`addrspacecast`,
  multi-origin pointer-phi, heap escape) — permanent decline (no-cloning /
  linearity, [[pointer-boundary-linearity-bennett]]).
- **Dynamic-N `alloca` / runtime-unshaped containers (`Dict`, runtime-sized
  arrays)** — needs Persistent-DS (managed/shaped/opt-in), post-freeze.
- **fp / `i128` cells** — angle family / deferred-width; loud decline.
- **QRAM inside a loop** — needs 7.3 bounded-loop unroll; declines at the
  loop-backedge reject until then.
- **String output (`%s` / pointer args)** — declines at the `kMsgStore` store
  guard; coherent string output **is** this phase's `store` path, but the
  `printf("%s")` *call* surface is 7.6's concern (it declines upstream).
- **Tape inspection / physical qubit numbering / the Shadow gate sequence /
  multiple aliasing views** — backend concerns; v1 emits `cqrt_qram_*` trace lines
  only, no simulation.
- **`cq_invert` over a QRAM region** — Phase 8 (composes over the `EmitInverse`
  rule 7.5 registers).

---

## 6. Risks (the verify-clean ones first)

1. **Non-LIFO store reversal** — `_unc` twins fired out of order pop the backend's
   tape stack wrong → silent wrong cell restore. The central Rule-13 hazard.
   Mitigation: §2.8(ii) strict reverse-program-order over a totally-ordered,
   never-commuting store chain + a LIFO-reversal probe.
2. **Mid-sequence observation reversed away** — measuring/returning the array
   between two stores, then reversing a later store, corrupts the observed value.
   Mitigation: the §2.8(iii) guard + a decline fixture (measure between stores).
3. **Aliasing / multi-origin provenance** — two array handles aliasing the same
   memory break the LIFO tape pairing (use-after-free / double-free of cells).
   Mitigation: §2.8(iv) single-`PtrOrigin`, known shape, the full decline matrix.
4. **Wrong `_<W>` element-width symbol** — a stale/wrong operand width emits the
   wrong `cqrt_qram_*_<W>` (verify-clean). Mitigation: mirror the proven 7.1
   `HandleWidth` capture-by-SSA-identity-pre-RAUW discipline exactly.
5. **Initializer mis-modeling** — a mis-read `llvm.memset` / const-table seeds
   wrong initial cell contents (verify-clean wrong data). Mitigation: model the
   initializer as classical metadata against the handle (§2.6) + a fixture asserting
   the recorded shape/contents.
6. **Surviving-array static access mishandled** — once an alloca survives, `arr[0]`
   is a real `load`; an untainted classical-index load must stay classical (no
   spurious taint), and a tainted-value-at-static-index store must still be handled.
   Mitigation: gate the carve-out on index-or-value taint (§2.2) + a mixed-access
   fixture.
7. **Escaped-array dirty-tape leak** — accepted (Rule-6, §2.9), but only sound if
   the §2.8(iii) guard truly makes escape terminal (no later coherent read).
   Mitigation: the (iii) guard is load-bearing for (5) too; the Rule-13 clearance
   states the no-later-interference argument explicitly.
8. **Permanent frozen-surface error** — `cqrt_qram_alloc/load/store_<W>` (+ `_unc`)
   freeze at Phase 11. A wrong signature (arg order, void-vs-handle store, width
   set, array-handle type, `_unc` arg convention) is a permanent v1 ABI defect.
   Mitigation: the §4 Rule-13 gate; mirror `cqrt_alloc_<W>` / `cqrt_copy_<W>` /
   `cq_template_*_unc` conventions exactly.
9. **Carve-out without emitter** — suppressing the decline but not lowering the
   memory op leaves it reading the `i32` runtime handle after `lowerRotations`.
   Mitigation: carve-out + emitter in the **same** increment (Rule 12).
10. **Phase-vs-basis (Rule 7)** — confirm analytically a QRAM cell is always
    basis-encoded data (Toffoli-copy correct), never an in-place phase answer. The
    integer-only scope (§2.10) is the structural guard; the Rule-13 clearance
    states it explicitly.

---

## 7. Increments (each red → green → clear, Rule 12/13)

1. **Const-global tainted-index READ (QROM-shaped)** — read-only, no store/tape/
   reversal. Frozen `cqrt_qram_alloc_<W>` + `cqrt_qram_load_<W>` (+ `_unc`); the
   carve-out (§2.2) + provenance walk (§2.6/§2.8(iv), single gep off a global) +
   emitter; `HandleWidth` threading (§2.5); the loaded-value uncompute; decline
   fixtures (§3.5, the provenance subset) + positive fixture + e2e smoke. **Frozen-
   ABI + escape-spine change → independent adversarial Rule-13 clearance before
   commit.** De-risks the load path, provenance, and array-handle birth without the
   store/tape/reversal complexity.
2. **Alloca-backed mutable store/load (Shadow-shaped)** — `cqrt_qram_alloc_<W>` for
   an `alloca` + initializer modeling (§2.6) + `cqrt_qram_store_<W>` (+ `_unc`) +
   the §2.5 in-place-mutator / `EmitInverse` rule + the §2.7 LIFO reversal + the
   §2.8(iii) mid-sequence-observation guard + the §2.9 escaped-array leak. The core
   reversibility increment + its positive/decline/dead-array/escaped-array
   fixtures + e2e smoke. **Rule-13 clearance** (the §6.1–6.3, 6.7 reversal hazards).
3. **Provenance hardening + full decline matrix** — the §2.8(iv) walk extended to
   pointer phi/select single-origin proof + the complete Rule-12 adversarial probe
   family (every §5/§6 reject: multi-origin, `inttoptr`/`ptrtoint`/`addrspacecast`,
   dynamic-N, heap escape, fp/`i128`, aliasing fan-out, loop boundary), each a loud
   pattern-naming diagnostic + negative fixture. **Rule-13 clearance** for the
   over-accept surface.

> All three increments must land **before the Phase-11 freeze** (frozen ABI) and
> each must clear independent adversarial review before commit.
