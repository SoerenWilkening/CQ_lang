# Bennett.jl ↔ CQ_lang Capability-Parity Map

> **Analysis of record.** Goal set by owner 2026-06-24: *"whatever Bennett.jl can
> do, we want to be able to do as well."* This document classifies **every**
> Bennett.jl capability by what CQ_lang needs to match it end-to-end, so the
> expansion work has a single authoritative work-list.
>
> Produced by a 25-agent parity workflow that mapped both codebases **from source**
> (Bennett.jl clone + CQ `ir-pass/src`), classified each capability, then
> **adversarially re-verified** every bucket against source (the verifier's whole
> job was catching a recognition-gap mislabeled "backend-only," or a buildable
> mislabeled "physics-floor"). Bennett.jl pinned at the 2026-06-23 `main`.
> Regenerate: see [§Methodology](#methodology).

---

## The two compilers are at different layers — this is the whole story

**Bennett.jl** is a gate-emitting circuit compiler: any pure Julia function →
fixed reversible circuit (NOT/CNOT/Toffoli), with measured Toffoli counts, auto-
dispatching memory and arithmetic *strategies*. It fuses recognition **and** gate
synthesis in one tool.

**CQ_lang** is a taint-driven recognizer + a **trace-only** ABI. The opt pass
lowers tainted stock LLVM opcodes to reversible runtime-template calls
(`cqrt_*` / `cq_template_*`); the runtime *prints a trace line* per call — there is
**no gate decomposition anywhere in CQ yet**, by owner decision. Gate synthesis
behind every ABI symbol is deferred to a post-freeze backend (Phase 9).

That single architectural fork is why most of Bennett's apparent breadth is **not**
a CQ deficiency — see bucket **A** below.

## The four buckets

| Bucket | Meaning | What "reach parity" costs |
|---|---|---|
| **DONE** | CQ's opt-pass already **recognizes and lowers** this to its reversible ABI. (Gate synthesis is trace-only for *all* ops, so DONE = recognition complete.) | nothing — recognizer parity already held |
| **A-backend** | Pure gate-synthesis behind an ABI CQ **already emits**. Recognizer is *not* the blocker. | build a backend module (Phase 9); **zero opt-pass change**. Cost/expense irrelevant. |
| **B-recognition** | CQ currently **declines** the shape; needs opt-pass recognizer work (accept-predicate + red-green decline fixture), decline-safe. | write the matcher + fixtures |
| **C-physics** | Not expressible as a *fixed reversible circuit* in CQ's model (no-cloning / linearity / unbounded-RAM). Must stay declined. | a different execution model (RAM-VM) — i.e. BennettVM, or never |

## Tally (107 capabilities)

| Bucket | Count | Read as |
|---|---:|---|
| **DONE** | 36 | recognizer parity already achieved |
| **A-backend** | 34 | one Phase-9 gate backend behind the frozen ABI |
| **B-recognition** | 31 | the real expansion work-list (opt-pass) |
| **C-physics** | 6 | the deliberate floor — all facets of one missing VM |

---

## Five cross-cutting truths (from the completeness critic)

1. **The execution-model split is the largest axis.** Bennett ships **two**
   targets — a fixed circuit (`target=:reversible`, what this map measured) and a
   reversible **VM** (`target=:reversible_vm` / `mem=:vm`, i.e. **BennettVM.jl**).
   *Every* C-physics row (unbounded heap, dynamic-n growth, general aliasing,
   reversible `Dict`, unbounded loops, coherent `when()`) is one facet of the same
   missing VM. Bennett itself moved unbounded memory there. This is **mutual
   decline at the circuit layer, not a CQ gap.**

2. **FP-as-DATA vs FP-as-ANGLE is the deepest tension.** Bennett treats `f64`
   uniformly as a 64-bit data wire (soft-float over bit patterns); CQ presumes
   `f64` is a **rotation angle** unless it reaches arithmetic as a data result.
   *Every* fp B-recognition item (extra fcmp predicates, fma, min/max, round,
   sqrt, transcendentals, fp memory cells, i128↔fp casts) shares **one
   precondition**: a principled fp-data carve that preserves the `ArmClassify`
   angle fence so an angle never reaches a soft-float template. **Build that
   disambiguation once → a whole family unlocks; ship it wrong → the f64 silent-
   miscompile family reopens across all of them.**

3. **Bounded-loop unroll (Phase 7.3) is a hidden force-multiplier.** It gates
   QRAM-in-loop, `break` (7.4), and loop-carried provenance. And a model
   asymmetry sharpens the hazard: Bennett surfaces "K too small" at *simulate*
   time via a runtime `LoopGuard`; **CQ has no simulator**, so it must prove the
   static trip-count bound at **compile time** or decline.

4. **Recognizer-agnostic-by-architecture is why bucket A is huge.** CQ's only
   dispatch axes are ABI *width* + HL/LH/QQ operand shape — **zero** gate-strategy
   or cost-target axis. So *all* of Bennett's strategy richness (3 adders, 3
   multipliers, 5 memory strategies, 5 uncompute schedules, wire recycling)
   collapses behind CQ's single per-symbol ABI as Phase-9 backend work. This is
   the deferral, **not** 34 separate parity gaps.

5. **CQ already *exceeds* Bennett at the recognizer in several rows** (a parity
   *inversion*): CQ accepts native `fadd`/`frem` and `f32`/`f16` arithmetic that
   Bennett *loudly declines* (Bennett needs the `SoftFloat` wrapper / asserts
   `w==64`); CQ ships `f16↔*` conversions Bennett reaches only bit-inexactly. A
   naive "match Bennett" framing **understates** CQ's current opcode surface.

---

## B-recognition — the real expansion work-list (31)

These are the only items that need **opt-pass** work. Each is decline-safe today
(CQ loudly declines), so each ships red-green (negative fixture mirrors the
current diagnostic → flip to accept). Grouped by phase owner.

### Phase 7.1 — opcode-surface completion
| Capability | Effort/Value | Change |
|---|---|---|
| `bitcast` int↔int same-width | **S/med** | zero-gate reversible identity: add same-width-int stem to `castInScope` + fold path. **fp↔int reinterpret stays declined** (angle invariant). ⭐ lowest-effort open B item |
| `fcmp` — 7 missing predicates (`one/ord/uno/ueq/ult/ule/...`) | M/low | add predicate templates to `opcode_table.yaml` + extend `compareInScope` fcmp set. fp-data only — keep the `ArmClassify` angle fence |
| Aggregates `extractvalue`/`insertvalue` | L/low | decompose tainted aggregate → per-field scalar handles (no new ABI) |
| Vector `extractelement`/`insertelement`/`shufflevector` | L/low | SLP-scalarize `<N×iN>` → N scalar handles; static lane / int lane only |
| fp `fma` / `min·max` / `round` / `fsqrt` family | M/low ea. | fp-intrinsic recognizers + YAML rows. **int min/max already DONE**; fp rides `kMsgUnknownCallee` today |
| fp transcendentals (`exp/log/sin/cos/pow/...`) | L/low | fp-intrinsic recognizers (mind the `exp/exp2/expm1` prefix-collision ordering). Largest surface, lowest priority |
| `i128↔fp` cross-domain casts | M/low | add i128↔fp pairs to `castInScope`; crosses both the i128 freeze boundary and the fp hazard |

> ⚠️ The whole fp-intrinsic cluster shares **one** precondition (cross-cutting #2).
> Build the fp-data carve first; the rest are then near-mechanical YAML+fixture.

### Phase 7.3 — bounded loops  *(force-multiplier — unlocks ~4 rows)*
| Capability | Effort/Value | Change |
|---|---|---|
| Bounded loops (static-K unroll) | **XL/high** | static-trip-count unroll + MUX-freeze of loop-carried merge-phis + Phase-5 uncompute extension + unbounded/K-too-small decline fixtures. **Must prove K at compile time** (no runtime guard) |
| QRAM/tainted-index access **inside a loop** | L/med | gated on 7.3; per-iteration store reversal + LIFO tape pairing across iterations |

### Phase 7.4 — break *(after 7.3)*
| Capability | Effort/Value | Change |
|---|---|---|
| loop `break` / early-exit | L/med | per-site exit registers + MUX-freeze of exit state + §3a reverse-play |

### Phase 7.5 follow-on / post-freeze — QRAM provenance & memory shapes
| Capability | Effort/Value | Change |
|---|---|---|
| **Pointer arguments** (fn takes a `Ptr`/array param) | **L/med** | accept a known-shape pointer parameter (caller-inlined array or `dereferenceable` annotation). ⭐ biggest practical Bennett-parity win — leans on Phase-6 specialization to carry shape from the call site |
| Pointer `phi` / `select` multi-origin merge | L/med ×2 | guarded per-origin store **and** load fan-out (mirror `_lower_load_multi_origin!`), fan-out cap. No-cloning concern is on the **data**, not the address merge → legal (B, not C) |
| Guarded Shadow store (QRAM-under-tainted-control) | L/med | path-flag-controlled `cqrt_qram_store` reusing 4.4 controlled-copy mechanics. ⚠️ a store on the wrong branch is the verify-clean-invisible miscompile — flag must route coherently |
| fp-as-bitpattern / `i128` memory cells | L/med | treat the cell as W-bit bitpattern data (distinct from an arg-1 angle); fp needs a `cq_template_copy_f<W>` ABI. Copying a bit pattern is a permutation, **not** no-cloning |
| `inttoptr`/`ptrtoint`/`addrspacecast` provenance through casts | M/low | recover static provenance when the underlying origin is statically known *(closed-world subset of the C-physics `ptrtoint` row)* |
| NTuple aggregate args / returns (incl. `sret`) | L/low | flatten aggregate arg / sret return into per-field scalar handles |
| Dynamic-size (runtime-n) alloca — **bounded** | XL/low | persistent-DS-style fixed-state ABI for the bounded-max_n case. *Unbounded n is C-physics* |
| Persistent-DS reversible maps (linear-scan/Okasaki/HAMT/CF) — **bounded** | XL/low | recognize pattern + persistent-tree fixed-state ABI (B), then tree gate body (A). Bounded only |
| Feistel bijective-hash primitive | L/low | a `CQ.h` intrinsic + new `cqrt_feistel`-style ABI (legal permutation; no ABI backs it today) |
| Tabulate (pure-fn → QROM table) | L/low | recognize a small-input pure tainted fn and *choose* tabulation over per-op lowering. Optimization, not a correctness gap |

### Phase 8 — manual inversion
| Capability | Effort/Value | Change |
|---|---|---|
| `cq_invert_begin/_end` adjoint bracket | **L/high** | thin `ManualInversion` consumer over the **existing** `EmitInverse` spine (the `_inv` forward-threaded vs `_unc` void-zeroing seam is already reserved). Recognizer-glue, not new physics. Markers + XFAIL fixture already exist |

### Unscheduled / general
| Capability | Effort/Value | Change |
|---|---|---|
| General-CFG path-predicated `phi` (beyond diamond/one-register) | L/med | generalize to OR-reduced block predicates (Bennett's `_compute_block_pred!` algebra). *post-7.3* |
| `compose(c1,c2)` pipeline combinator | M/low | only if surfaced as an explicit API; straight-line C expressing the same already lowers |

---

## A-backend — one Phase-9 gate backend behind the frozen ABI (34)

**None of these need an opt-pass change.** CQ already emits the ABI symbol; the
work is synthesizing the gate body behind it. This is the architectural deferral
(cross-cutting #4), not 34 gaps. Listed so the Phase-9 backend has its full menu.

- **Arithmetic gate bodies:** ripple / Cuccaro / QCLA adders; two's-complement
  subtractor; shift-add / QCLA-tree (Sun-Borissov) multipliers; partial-products
  + parallel-adder-tree helpers; restoring division/rem; bitwise `and/or/xor`;
  constant + barrel shifters; integer comparator; identity peephole; strategy
  auto-dispatch + `target=` selector. *(Karatsuba was removed upstream from
  Bennett — non-actionable.)*
- **Soft-float gate bodies** (recognizer COMPLETE for all): `fadd`/`fsub`/`fmul`/
  `fdiv`/`frem`/`fneg`; the 6 ordered `fcmp` predicates; `fptosi/fptoui/sitofp/
  uitofp`; `fpext`/`fptrunc` (incl. f16); **f32/f16 scalar arithmetic (CQ exceeds
  Bennett here)**. `fneg` = one `cqrt_x` on the sign wire (trivial first target).
- **Memory strategy gate bodies:** MUX-EXCH (packed N·W≤64); Shadow-checkpoint
  (large dynamic idx); the `_pick_alloca_strategy` dispatcher; optional MemorySSA
  alias oracle. *(Dynamic-index store/load is already accepted+lowered — verified
  no N·W ceiling in `matchQramAccess`; only the gate realization is deferred.)*
- **Uncompute schedules** (behind the existing `_unc`/free ABI): Eager /
  ValueEager (Kahn reverse-topo) / Checkpoint / Pebbled (Knill) / PebbledGroup +
  WireAllocator rail recycling. Branch-free/loop-free DAG precondition.
- **Broadcast:** `fast_copy` n-way log-depth fan-out (single copy is DONE).

---

## C-physics — the deliberate floor (6)

All six are facets of the **same missing execution model** (cross-cutting #1).
They must stay loudly declined; over-accepting any is the project's one
unforgivable bug.

| Capability | Why it's the floor | Alt mechanism |
|---|---|---|
| `ptrtoint`/`inttoptr` (general, forged) | pointer-as-integer over a real address space is inexpressible as a fixed circuit. *Bennett accepts it only in its RAM-VM (`ptr_cells=true`)* | RAM-VM only. **Closed-world tag round-trip is a B-recognition subset** |
| Atomics `atomicrmw`/`cmpxchg` (+ atomic/volatile) | concurrency/observer semantics, no fixed-circuit story | sequential RAM-VM |
| Exceptions `invoke`/`landingpad`/`resume` | non-local control flow has no reversible-circuit form | none |
| `indirectbr` / computed goto | runtime-computed jump target can't be routed in a fixed circuit | PC-based RAM-VM |
| Heap / general aliasing (multiple live overlapping pointers) | unbounded + alias = needs RAM. **Bounded fixed-shape heap is a B subset** | RAM-VM (BennettVM); bounded subset → B |
| `when(qubit)` coherent superposed control (Bennett *vision*, unbuilt) | needs an external quantum host (Sturm.jl). **CQ already covers the source-expressible coherent subset** via tainted-`br` swap-route + `cqrt_cswap` | the swap-route path *is* the alt mechanism for the reachable subset |

> **The single most important framing:** the entire C-physics column is "build a
> RAM-VM" — which is *literally what BennettVM.jl is for*. If unbounded
> memory/loops are a real goal, that is a **separate execution model / project**,
> not a QRAM strategy. Bennett came to the same conclusion (hence the split repo).

---

## Where CQ already exceeds Bennett (parity inversions)

Track these so "match Bennett" doesn't accidentally *narrow* CQ:

- CQ recognizes **native `fadd`/`frem`** directly; Bennett requires the `SoftFloat`
  wrapper and has no `frem` primitive.
- CQ accepts **`f32`/`f16` arithmetic**; Bennett asserts `w==64` and declines.
- CQ ships **`f16↔*` conversions**; Bennett reaches f32 paths only bit-inexactly
  (widen-to-f64 / double-round).
- CQ's **pointer-`phi`/`select` provenance is *lowered*** (single-origin walk);
  Bennett's MemorySSA is opt-in *analysis* that only "informs future lowering."

The bit-exactness burden for the above shifts onto CQ's **future backend**, not its
recognizer — i.e. these are A-backend obligations CQ has *already opted into* at the
recognizer.

---

## DONE — recognizer parity already held (36, summary)

No work owed (gate synthesis is the universal Phase-9 deferral). By domain:

- **Opcodes:** int `add/sub/mul/and/or/xor/shl/lshr/ashr`, `udiv/sdiv/urem/srem`,
  all 10 `icmp` predicates, fp arith *recognizer* (`fadd/fsub/fmul/fdiv/frem/
  fneg`), `sext/zext/trunc`, `freeze`, `frem`, `fpext/fptrunc`, `addrspacecast`,
  terminators `ret/br/switch/unreachable`, `phi` (diamond + one-register lift),
  `select`, `call` (registered-callee inlining).
- **Memory:** `alloca`/`load`/`store`/`getelementptr`, static + **dynamic-index**
  Shadow store/load, QROM const-table lookup (runtime idx), GEP provenance walk.
- **Control:** `select` MUX, `switch` (4 accept shapes), `br` + path-predicate
  diamond, depth-2 homogeneous nest, `freeze`, `unreachable`, **realized
  `controlled()`** (swap-route + `cqrt_cswap`) over the recognized shapes.
- **Construction:** canonical Bennett (forward+copy+uncompute), self-reversing
  fast-path + contract validation, single `fast_copy`, call inlining +
  specialization + cache (Phase 6), ancilla classification.

> Caveat on `controlled()`: CQ recognizes 4 source-level tainted-control shapes;
> Bennett's `controlled()` is unconditional over *any* compiled circuit. The
> overlap is DONE; "deeper/non-homogeneous control" is the B-recognition residue
> (general-CFG phi row).

---

## Ranked priorities (critic's order)

1. **`bitcast` int↔int identity** — B, **S/med**. Lowest effort open item; the
   fp↔int carve-out doubles as a decline-fixture for the f64 hazard.
2. **Bounded loops (7.3)** — B, XL/high. Highest leverage; unlocks QRAM-in-loop,
   `break`, loop-carried provenance. Prove K at compile time.
3. **Manual inversion `cq_invert` (Phase 8)** — B, L/high. Adjoint backend already
   exists; this is recognizer-glue over `EmitInverse`. User-facing primitive.
4. **Adder/sub/bitwise gate bodies (Phase 9)** — A, M/high. Foundational backend
   tranche; every other arithmetic strategy composes on the adder.
5. **Guarded Shadow store / QRAM-under-control** — B, L/med. Composes the two
   deepest hazard domains (memory × control); flag must route coherently.
6. **Multi-origin pointer phi/select** — B, L/med ×2. Same recognizer closes both;
   no-cloning is on data not address → legal.
7. **Integer comparator + divider gate bodies (Phase 9)** — A, M/high. Comparator
   gates the whole swap-route control path.
8. **fp extra-predicate + fp-intrinsic cluster** — B, M/low. Largest surface,
   lowest priority; sequence *after* the fp-data disambiguation lands.

Plus **Pointer arguments** (B, L/med) — not in the critic's top-8 but the single
biggest practical "compile `f(ptr,i)`" unlock; leans on Phase-6.

---

## Methodology

- **Workflow:** `bennett-parity-map` (25 agents). Per domain: map both codebases
  from source (parallel) → classify each Bennett capability → **adversarial
  re-verify** each bucket against source → completeness critic. Verifier mandate:
  refute any A-backend that CQ actually *declines* (→ B), any C-physics that is
  merely unbuilt (→ B), any DONE not actually lowered.
- **Sources:** Bennett.jl + BennettVM.jl clones (`/tmp/bennett-parity`, 2026-06-23
  `main`); CQ `ir-pass/src`, `runtime/`, `tools/opcode_table.yaml`, `ROADMAP.md`,
  `docs/prd/phase-07-expressiveness/`.
- **Corrections the verifier made** (sample): `bitcast` C→B (unbuilt matcher, not
  physics); `when(qubit)` split into realized `controlled()` = DONE + coherent
  vision = C; dynamic-index MUX-EXCH/checkpoint accept re-confirmed (no N·W ceiling
  in `matchQramAccess`); pointer-phi evidence fixture corrected to
  `lowering_reject_qram_multi_origin.ll`.
- **Regenerate:** re-run the workflow (script under the session `workflows/scripts/`)
  after re-cloning Bennett.jl. Re-pin the Bennett SHA in this header.
