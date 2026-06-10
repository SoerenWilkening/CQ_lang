# Phase 4.2 IMPLEMENTATION — RSSA swap-routed value-arm control flow (method-B)

Module layout, signatures, and the **test-driven** work-item sequence for the
4.2 increment defined by [`PRD.md`](PRD.md) **Part II (§§7–10)**. Companion to
the PRD (which fixes *scope* and *binding decisions*, incl. the §7.6
`cqrt_copy_<W>` resolution — PRD §8.1); this file fixes *how the code is
built*. Sibling of the closed 4.1 plan ([`IMPLEMENTATION.md`](IMPLEMENTATION.md))
and follows its structure §-for-§. Every cited symbol was verified against the
live tree (branch `swap-route-control`, 2026-06-10).

**Authoritative contracts** this plan is built against (FileCheck specs):
`docs/design/rssa-swap-control/swap_route_if_diamond_uncompute.ll` (B-keep —
graduates from "sketched" to CHECK-pinned in WI-4), plus the new lit contracts
`control_swap_value_diamond.ll` (§5d) and `control_swap_value_ifelse.ll`
(§5e). **Symbol order IS the contract** (CHECK-pinned), plus the hard
postconditions `CHECK-NOT: _controlled`, `CHECK-NOT: phi i32`, and
**`CHECK-COUNT-2: @cqrt_free`** for the diamond (rail-final + flag) /
**`CHECK-COUNT-3`** for the dual-rail if/else (§5e) — `out` and the restored
source are never freed.

Fixture authoring rule (bd `swap-route-detect-known-limits`): `opt`'s
`DS_Error` handler exits on the FIRST diagnostic — author every swap-route
fixture with **one tainted region per file**.

---

## 0. Accept criterion (the one definition everything keys on)

> **4.2 additionally lowers a tainted-condition region iff ALL hold; otherwise
> it declines loudly and lowers nothing (Prime Directive):**
>
> 1. **(shape)** the same §0-4.1 clean diamond / if-else (one 2-incoming merge
>    `PHINode`, all 4.1 shape guards — sequential-region, compare/branch gap,
>    condition-used-outside-branch, compound-condition — unchanged);
> 2. **(value arm)** each content arm's contribution to the merge phi is a
>    **pure linear value chain** — its arm-block-bounded def-use lineage from
>    the merge back to a base contains **only supported tainted integer
>    `BinaryOperator`s** (the `OpcodeSupport` stems), each link consuming the
>    threaded value as its **sole tainted operand** (other operand classical →
>    the `_hl`/`_lh` template shapes), no `cq_phi`/`cq_theta`/compare/cast
>    link, no fan-out, no stray op in the arm block (the
>    `armBlockIsPureSpine` analog over the value chain — Rule 8 linearity);
> 3. **(routed base)** the chain bottoms at **exactly the routed slot**:
>    the diamond's straight-through (Pred-edge) incoming / the if/else arms'
>    **shared** base — a tainted quantum handle (derived pre-region `cq_phi`
>    base permitted iff identical, the 9hh discipline); merge type is
>    **integer** (an FP merge is an angle — PRD §8.1/§8.3);
> 4. **(no clobber, §3c — ACTIVE)** `Routed ∉ condProvenance(cond)`. The
>    routed register and the condition's transitive taint provenance are
>    disjoint — which is also what keeps the `icmp_inv(q)` flag-strip valid
>    with zero reliance on the reverse-play (PRD §8.2).
>
> Phase arms (4.1 criterion) continue to accept unchanged; a region is
> phase-armed or value-armed **per arm chain**, and any mixture inside one
> chain (or across the two if/else arms) declines (PRD §10).

Decline dispositions added/changed by 4.2 (shared `diagnoseUnderControl`,
`ControlPlan.h:242`; `…: <What> under quantum control`):

| Shape | Disposition | Diagnostic `What` |
|---|---|---|
| value chain on a condition-provenance register (`if(q>5){q=q+3}`, transitive `if(q+1>5){q=q+3}`) | **permanent §3c reject** (now non-vacuous) | `arm rewrites a condition operand` *(PRD-pinned, unchanged)* |
| linear HL/LH chain on the routed base (`if(q>5){p=p+3}`) | **ACCEPT** *(was: defer `value-arm swap-route`)* | — |
| QQ chain link (`if(q>5){p=p+r}`) | defer (oracle-unmodeled) | `value-arm swap-route` *(string retained for the deferred subset)* |
| mixed `cq_phi`+value chain; heterogeneous phase/value if/else | decline (§6a territory) | `mixed phase/value arm` *(new)* |
| impure value arm (fan-out / stray op) | decline (Rule 8) | `impure value arm` *(new, mirrors `impure phase arm`)* |
| `ChainBase != Routed` — Defect-2 derived straight-through, fresh-value mux (`if(q>5){p=q+1}`) | decline (4.4 mux family — **the Defect-2 string fix**, PRD §8.3) | `control flow` *(existing generic)* |
| FP-typed merge phi | decline (angle, never data) | `control flow` |
| nested / `select` / `switch` | unchanged 4.1 dispositions | `nested control flow` / `select` / `switch` |

---

## 1. Module map

No new translation units — 4.2 **extends** the four 4.1 modules (Rule 14;
house rule one-concern-per-TU still respected; watch the ≤300-LOC budget on
`SwapRouteEmit.cpp`, currently 359 — split a `ValueArmEmit` helper TU only if
it bursts).

### Edits to existing files

| File | Change |
|---|---|
| `runtime/cq_runtime.h` + `.c` | **WI-1.** Declare + define `cqrt_copy_i{1,8,16,32,64}` (`void (int32_t src, int32_t dst)`), trace `cqrt_copy_<W>(h<src>, h<dst>)` — the `cqrt_cswap` no-arrow convention. Hand-written core ABI (PRD §8.1); the YAML is NOT touched. |
| `ir-pass/src/WidthDispatch.cpp` + `.h` | **WI-1.** `copyFn(StringRef Abi)` — lazy `FunctionCallee` mint of `cqrt_copy_<W>` (mirrors `allocFn`, `WidthDispatch.h:69`); integer ABI widths only (assert/empty on `f32`/`f64`). |
| `ir-pass/src/ArmClassify.cpp` + `.h` | **WI-3.** Value-chain walk (`walkValueChain` + `valueArmIsPureChain`, the value twins of `walkPhaseSpine`/`armBlockIsPureSpine`); per-arm `ArmClass {Phase, Value}` surfaced to the emitter; §3c active predicate `Routed ∈ Prov` on routable chains; retire the if/else `readsProvenance` fallback (`ArmClassify.cpp:182-201` — replaced by base-identity, PRD §8.3); new decline strings per §0. |
| `ir-pass/include/ControlPlan.h` | **WI-3.** One `enum class ArmClass` + per-arm class fields on `ControlRegion` (prefer reusing `Shadow`/`ShadowFalse` for the ordered chain ops — they are the retained vocabulary; add nothing the emitter re-derives). |
| `ir-pass/src/SwapRouteEmit.cpp` | **WI-4/WI-5.** The value-arm emission path in `emitRegion` (§4): chain move+retarget, `rewriteBinary` reuse, copy-out, reverse-play via `emitInverseChain` + `emitRoute` brackets, frees, RAUW phi→`out`; scrub extended to `taint.StaleDeclined`. |
| `ir-pass/src/EmitInverse.cpp` | **WI-4.** Guard comment at the involution arg-0 threading seam (`EmitInverse.cpp:67-75`): `cqrt_cswap` must never be fed through a threaded chain (arg 0 is the FLAG) — the swap-route emitter brackets routes itself (PRD §8.5). No behavior change. |
| `tests/e2e/CMakeLists.txt` + new slice | **WI-6.** `slice_control_value_diamond.{c,expected.log}` + explicit `add_test` (e2e is not auto-globbed). |
| `docs/design/rssa-swap-control/swap_route_if_diamond_uncompute.ll` | **WI-4.** Pin (B-keep) with the §5d stream (deliberate spec regeneration, Rule 12). |
| `docs/design/rssa-swap-control/prototype_semantics.py` | **WI-2.** `demo_D` — the method-B path-B demo (§8.1 below). Oracle only; not in the build. |
| `docs/backend.md` | **WI-1.** Core-ABI section: the `cqrt_copy_<W>` family + freeze-reopen note. |

`CQLoweringPass.cpp` is **untouched**: the pipeline position
(`detectControlRegions` → `lowerControlRegions` before `lowerRotations` /
`lowerOps`, both entry points) already serves value arms — the RAUW
flow-through argument is identical (emitted calls reference `@cq_theta`
results; later RAUW updates them).

---

## 2. Shared diagnostic helper

Unchanged — `diagnoseUnderControl` (`ControlPlan.h:242`, defined in
`ControlDetect.cpp`). The two new strings (`mixed phase/value arm`,
`impure value arm`) ride the same `"cq controlled lowering: " + What + " under
quantum control"` surface, mirrored character-for-character by their decline
fixtures (Rule 12).

---

## 3. Detection & classification (pure analysis, before any mutation — Rule 9)

`classifyArms` (ArmClassify) grows the value-arm leg. Per arm, after the
existing pre-checks (compound-cond, condition-data-use, stale-condition
`nonDiagonalGateBeforeBranch`, tainted-angle — all unchanged and **arm-class
independent**, so they cover value regions for free):

```
Base = walkPhaseSpine(ArmIncoming, ArmBB)            // existing: consumes cq_phi links
if Base == ArmIncoming or spine consumed no link:    // not a phase arm — try value
    Chain = walkValueChain(ArmIncoming, ArmBB)       // NEW: linear BinaryOperator chain
    if Chain.valid:                                  // supported stems, sole-tainted-operand links
        ChainBase = Chain.base
        if merge type is FP            → decline "control flow"         (angle)
        if ChainBase != Routed         → decline "control flow"         (mux family; Defect-2 fix)
        if Routed ∈ Prov               → decline "arm rewrites a condition operand"  (§3c ACTIVE)
        if !Tainted(Routed)            → decline "control flow"
        if !valueArmIsPureChain(...)   → decline "impure value arm"     (fan-out / stray)
        if any link has tainted 2nd op → decline "value-arm swap-route" (QQ defer)
        else ACCEPT as ValueArm — record ordered Chain into Shadow/ShadowFalse
    else if chain hit a cq_phi link    → decline "mixed phase/value arm"
    else                               → existing dispositions (unchanged)
```

Notes:
- **`walkValueChain` is arm-block-bounded** for the same load-bearing reason
  as `walkPhaseSpine` (`ArmClassify.cpp:63-73`, bd
  `swap-route-ifelse-derived-base-boundary`): a value op defined OUTSIDE the
  arm is the routed base's lineage, never an arm gate — and an unbounded walk
  would double-collect a shared pre-region op (the WI-3 double-erase family).
- **Both if/else arms must be `ValueArm` over the SAME routed base** (or both
  phase — the 4.1 path). One phase + one value arm → `mixed phase/value arm`.
- **§3c diamond test changes form**: from the 4.1 proxy
  `Prov.count(StraightThrough)` *at the first value op* to
  `Routed ∈ Prov` *on a fully-classified routable chain*. The if/else
  `readsProvenance` fallback is retired (PRD §8.3) — the memory's warning
  (don't reject the `p=q+1` read) is honored structurally: a read shows up as
  `ChainBase != Routed`, which is `control flow`, never the §3c string.
- **`condProvenance` is reused verbatim** (`ArmClassify.cpp:147-177`,
  incl. the arg-1 angle exclusion).

---

## 4. Emission — the value path of `emitRegion` (SwapRouteEmit)

Per accepted value region, emitted into the pred block before the conditional
`br` (IRBuilder at `BI`), in this exact order (the §5d contract). Steps 1–3
and the bracket/X polarity machinery are byte-identical reuse of the 4.1
helpers (`lowerCompareToFlag`, `wd.allocFn`, `emitRoute`):

1. **Flag mint** — `lowerCompareToFlag(cond, wd, taint, {}, false, BI)`
   (`CompareLowering.h:110`). Unchanged.
2. **Rail alloc** — `wd.allocFn(abi)`; `abi = abiWidthFromType(chain op type)`
   (`OpcodeSupport.h:69`) — the chain ops still carry `iN` types pre-RAUW
   (PRD §8.1 width-source; do NOT read the `cq_theta` suffix here).
3. **Route-in** — `emitRoute(B, csyms, flag, p, rail, Negated, DL)`
   (`SwapRouteEmit.cpp:110`).
4. **Arm chain verbatim on the rail** — for each chain op in forward order:
   `op->moveBefore(BI)`; replace its threaded-base operand (the link that
   pointed at the previous chain value / the routed base) with the rail
   handle (first link only — later links already point at their predecessor);
   then **`rewriteBinary(op, wd, taint)`** (`ArithLowering.h:51`) — the
   straight-line per-op emitter reused verbatim: it emits the
   `cq_template_<op>_<W>_hl/_lh/_qq` call at the op's (now pred-block)
   position, RAUWs, and bookkeeps taint. Collect the minted forward
   `CallInst`s (the chain for step 6). A `false` return (no template) already
   diagnosed → abort the region loudly (never a silent skip — the 4.1
   `emitRegion` bail discipline, `SwapRouteEmit.cpp:163-180`).
5. **Route-back** — `emitRoute(...)` with the chain-final value (post-RAUW it
   is the final template handle). `p` now holds the muxed answer.
6. **Copy-out** — `out = B.CreateCall(wd.allocFn(abi), {0}, "out")`;
   `B.CreateCall(wd.copyFn(abi), {p, out})`. **Never free `out`; never free
   `p`** (PRD §8.5).
7. **Reverse-play `R†`** — `emitRoute(...)` (route-back†), then
   `railFinal2 = emitInverseChain(B, ForwardChain, wd, csyms,
   /*Flag=*/nullptr, /*Terminal=*/chainFinalHandle)` (`EmitInverse.h:67` —
   the first real invocation; body chain ONLY, the cswaps are bracketed by
   `emitRoute` because of the arg-0 seam, PRD §8.5), then `emitRoute(...)`
   (route-in†) **with the rail operand = `railFinal2`** (the threaded handle).
8. **Rail free** — `wd.freeFn()(railFinal2)`: provably `|0⟩` on both branches
   only AFTER step 7 (§3b — the free follows the reverse-play; emitting it
   earlier is the dirty-free hidden measurement).
9. **Flag-strip + flag free** — `lowerCompareToFlag(..., inverse=true)` then
   `freeFn()(flag)`. Valid outright: the condition register is disjoint from
   the routed register in every accepted region (§0 criterion 4).
10. **Rewire + erase + scrub + flatten** — RAUW merge phi → `out`; erase phi,
    erase the (already-rewritten, use-empty) original chain ops in reverse
    order; **scrub each erased instruction from `taint.Tainted`,
    `taint.BirthOrder`, `taint.PhiCalls` AND `taint.StaleDeclined`** (§6.1);
    `flattenRegion(R, taint)` (`RegionFlatten`) unchanged.

**If/else (WI-5):** two rails, both arms routed (else under ¬flag via the
X-bracket), both chains replayed on their own rails, route-backs for both,
ONE copy-out (after both route-backs `p` holds the two-sided answer), then R†
for both arms in reverse emission order, two rail frees, strip, flag free.
The join remains the literal adjoint of the split.

---

## 5. Target symbol sequences (the FileCheck contract)

### 5d. Value diamond — `if (q > 5) { p = p*5; p = p+15; }` (linear HL chain)

```
%flag  = call i32  @cq_template_icmp_sgt_i32_hl(i32 %q, i32 5)      ; 1 mint
%rail  = call i32  @cqrt_alloc_i32(i32 0)                           ; 2 |0> rail
         call void @cqrt_cswap(i32 %flag, i32 %p, i32 %rail)        ; 3 route in
%v1    = call i32  @cq_template_mul_i32_hl(i32 %rail, i32 5)        ; 4 chain (verbatim)
%v2    = call i32  @cq_template_add_i32_hl(i32 %v1, i32 15)         ; 4 chain
         call void @cqrt_cswap(i32 %flag, i32 %p, i32 %v2)          ; 5 route back
%out   = call i32  @cqrt_alloc_i32(i32 0)                           ; 6 copy target
         call void @cqrt_copy_i32(i32 %p, i32 %out)                 ; 6 B-keep copy
         call void @cqrt_cswap(i32 %flag, i32 %p, i32 %v2)          ; 7 route-back†
%u1    = call i32  @cq_template_add_i32_hl_inv(i32 %v2, i32 15)     ; 7 chain adjoint
%u2    = call i32  @cq_template_mul_i32_hl_inv(i32 %u1, i32 5)      ; 7 chain adjoint
         call void @cqrt_cswap(i32 %flag, i32 %p, i32 %u2)          ; 7 route-in†
         call void @cqrt_free(i32 %u2)                              ; 8 clean rail free
%f0    = call i32  @cq_template_icmp_sgt_i32_hl_inv(i32 %q, i32 5)  ; 9 strip
         call void @cqrt_free(i32 %flag)                            ; 9 flag free
%m     = call i32  @cq_measure_si32(i32 %out)                       ; (phi RAUW'd → out)
```

Hard postconditions: `CHECK-NOT: _controlled`, `CHECK-NOT: phi i32`,
`CHECK-COUNT-2: @cqrt_free` (and a guard `CHECK-NOT: @cqrt_free` after — no
free of `%out`, no free of `%p`, no `uncompute` third free). All four cswaps
capture-match the same `%[[F]]/%[[P]]` pair; the adjoint order is the exact
reverse with `_inv` twins.

### 5e. Value if/else — `if (q>5) { p = p+3...; } else { p = p*7...; }`

Split routes both rails (then unbracketed, else X-bracketed); both chains;
join = adjoint split for both; ONE `cqrt_copy` of the settled `%p`; R† for
both arms; two rail frees + flag free (**`CHECK-COUNT-3: @cqrt_free`**);
strip; phi RAUW'd → `out`.

### 5f. §3c active reject — `if (q > 5) { q = q + 3; }`

Unchanged string, now non-vacuous:
```
error: …: cq controlled lowering: arm rewrites a condition operand under quantum control
```
Contrast set pinned alongside (each its own fixture, one region per file):
`p=p+3` ACCEPTS (5d); `p=q+1` and the Defect-2 derived-straight-through shape
decline `control flow` (NOT the §3c string, NOT accepted); QQ `p=p+r` declines
`value-arm swap-route`; `rz(p,a);p=p+3` declines `mixed phase/value arm`.

---

## 6. Interlock hazards (Rule 10 / Rule 13 — the silent-miscompile surface)

1. **Dangling work-list pointers, now incl. `StaleDeclined`.** The emitter
   erases arm `BinaryOperator`s that `propagate`/`declineStaleRecordOps` may
   have recorded. `scrubTaint` (`SwapRouteEmit.cpp:50`) must grow
   `taint.StaleDeclined.erase(I)` (and stays idempotent) or a later walk
   dereferences freed memory. (`rewriteBinary` also promotes its template
   result into `Tainted`/`BirthOrder` — those template calls are NOT erased
   and need no scrub.)
2. **`uncompute` must add nothing.** The routed register's users now include
   `cqrt_copy` — extend the §6.2-4.1 argument: `isTerminalHandle`
   (`ChainWalk.cpp:84`) returns false for `cqrt_*` users, so `p`, the rail
   handles, and `out` (measured/escaped) all stay out of the uncompute net.
   **Net frees per value diamond: exactly two** (probe §8.3).
3. **The `emitInverseCall` cswap arg-0 seam.** `EmitInverse.cpp:67-75` threads
   `CurHandle` into `Args[0]` for involutions; for `cqrt_cswap` arg 0 is the
   FLAG — feeding route cswaps through `emitInverseChain` would thread a rail
   handle into the flag slot (verify-clean wrong unitary). The emitter
   brackets routes via `emitRoute` only; WI-4 lands the guard comment.
4. **Copy placement.** `cqrt_copy` must sit AFTER the route-back (the answer
   is on `p` only then) and BEFORE the route-back† (R† destroys it on `p`).
   Off-by-one placement is trace-plausible and verify-clean — pinned by the
   §5d symbol order.
5. **Free ordering.** The rail free consumes the FINAL threaded handle
   (`railFinal2` from `emitInverseChain`), not the forward `%rail`/`%v2` —
   freeing a stale handle version is trace-plausible (the trace prints
   *some* `h<N>`) but wrong. Pinned by capture-matching `%[[U2]]` in 5d.
6. **`-O1` reassociation.** clang reassociates chain constants
   (`p+3; p*5` → `p*5; +15` — measured, PRD §8.4); fixtures must pin the
   POST-reassociation chain for C-sourced shapes; hand-written `.ll` pins the
   canonical short forms.
7. **Twin-pipeline drift** — no orchestrator change in 4.2, so the hazard is
   dormant; if a deferred-emission alternative is ever taken instead of the
   §4 `rewriteBinary`-at-emit design, it revives (both entry points).
8. **Phase-arm regression.** The value path must be unreachable for phase
   regions: every 4.1 phase fixture keeps `CHECK-NOT: cqrt_copy` (dephasing
   guard — bd `rz-diag-flag-strip-invariant`).

---

## 7. Test-driven work-item sequence

Red-green per Rule 12 (fixture first, watch it fail, implement minimally;
accepts land `; XFAIL: *` until their WI). One commit per WI. WI-4/WI-5 are
core-lowering changes — they do **not** ship on a green suite alone (Rule 13);
they clear only after §8 (and WI-2 is their oracle precondition).

| WI | Goal (observable) | Lands | Red→Green fixtures |
|---|---|---|---|
| **WI-1** | **`cqrt_copy_<W>` core ABI** (PRD §8.1). 5 integer widths, signature/trace pinned; `WidthDispatch::copyFn`; docs/backend.md ABI note. | `runtime/cq_runtime.{h,c}`, `WidthDispatch`, backend.md. | **green:** runtime trace-golden extension covering `cqrt_copy_*`; header-compile test; `gen_templates.py --check` clean (YAML untouched). |
| **WI-2** | **Method-B oracle demo** (`demo_D`) — the §8-owed path-B run (Rule 13 gate for WI-4): B-keep on a value arm with the output register MEASURED ≡ controlled-op reference; rail+flag exactly `|0⟩`; the **two-channel interference probe** per the §8.1(c) bar (channels A+B asserted vs the analytic closed forms, PRD §8.2; incl. the answer-register probe: downstream Ry on `out`, superposed `p₀`, basis AND superposed control); negative control: B on a phase arm dephases (reproduce P0 0.585→0.500). Verdict recorded in SCOPING §8. | `prototype_semantics.py` (`demo_D`), SCOPING §8 update. | oracle run passes; no build-system coupling (oracle is not in the build). |
| **WI-3** | **Detection: value-arm classification + §3c ACTIVE + Defect-2 fix** (no emission — accepted value regions keep declining `value-arm swap-route` until WI-4 flips them; no new transitional string). | `ArmClassify` (+`ControlPlan.h` ArmClass), per §3. | **green:** `control_swap_value_reject_clobber_active.ll` (§3c on a would-be-routable chain), `control_swap_reject_value_mux_derived.ll` (Defect-2 → `control flow`), `control_swap_reject_value_readcond.ll` (`p=q+1` → `control flow`, NOT §3c), `control_swap_defer_value_qq.ll`, `control_swap_reject_value_mixed.ll`, `control_swap_reject_value_fanout.ll`, `control_swap_reject_value_fp_merge.ll`; existing `control_swap_reject_clobber.ll` + `control_swap_defer_valuearm.ll` stay green unchanged. **XFAIL:** the 5d/5e accepts. |
| **WI-4** | **Emit value diamond** (core). §4 path; first real `emitInverseChain` invocation (§7.5 discharged); `EmitInverse` seam guard; scrub incl. `StaleDeclined`; pin (B-keep) in the design fixture; **delete/graduate** `control_swap_defer_valuearm.ll` → the accept (deliberate baseline regeneration, Rule 12). | `SwapRouteEmit`, `EmitInverse` comment, design fixture. | **green (un-XFAIL):** `control_swap_value_diamond.ll` (5d) + `control_swap_value_diamond_polarity.ll` (FALSE-successor arm, Rule 9) + `control_swap_value_diamond_derived.ll` (pre-region `cq_phi` base). |
| **WI-5** | **Emit value if/else** (dual rails + ¬flag bracket + single copy-out + dual reverse-play). | `SwapRouteEmit` (two-arm value), `ArmClassify` (both-arms-same-base). | **green (un-XFAIL):** `control_swap_value_ifelse.ll` (5e); decline stays: heterogeneous phase/value if/else (`control_swap_reject_value_mixed_ifelse.ll`). |
| **WI-6** | **e2e golden** (Rule 16/2 — the ONLY layer that links; the only proof `cqrt_copy_i32` resolves + signature-matches). C source = the measured `-O1`-surviving 6-op linear chain (PRD §8.4). | `tests/e2e/slice_control_value_diamond.{c,expected.log}` + explicit `add_test`. | **green:** `ctest -R e2e-slice-control-value-diamond`. |
| **WI-7** | **§8 adversarial clearance + docs + closeout** (Rule 13). Probe matrix (§8 below); SCOPING §7.5/§7.6 marked resolved + §8 gap closed + §9 refresh; ROADMAP 4.2 flip; `bd remember` (copy-ABI invariant; Defect-2 supersession; select-folding shape reality); update bd memory `swap-route-detect-known-limits`. | docs, memories, residual XFAIL removal. | full `ctest` green; `gen_templates.py --check` clean. |

Dependencies: WI-4 ← {WI-1, WI-2, WI-3}; WI-5 ← WI-4; WI-6 ← WI-4;
WI-7 ← {WI-4, WI-5, WI-6}.

---

## 8. Adversarial verification plan (Rule 13 — clears the core change)

A green suite does not clear the value path of `SwapRouteEmit`. Scope note
(bd `rule13-no-backend-clearance-scope`): clearance is **design-level oracle
modeling + lowered-IR reading + structural probes** — no execution backend
exists; never claim "statevector-verified output".

1. **Oracle witness (WI-2, precondition).** `demo_D`: (a) B-keep value arm,
   output register **measured** — distribution ≡ controlled-op reference
   (assert < 1e-12); (b) rail + flag populations exactly 0 after R† + strip;
   (c) **two-channel interference probe** (PRD §8.2; adjudicated bar —
   independent review oracle, 2026-06-10 — shared verbatim with PRD §8.2 and
   bd paj.2: **the documented deviation is asserted against the analytic
   closed form on BOTH channels, plus exact-zero deltas on all observables in
   the basis-`p₀` regime**). **Channel A** — control visibility (Hadamard
   test on `q`): assert vs reference `Σ_p b_p b*_{f(p)}` / B-keep
   `Σ_p |b_p|² · [f(p)=p]`. **Channel B** — answer-register coherence: a
   downstream Ry on `out` (`cq_theta(out, t)` model) + measure, with
   **superposed `p₀`**, under **BOTH** a basis-state and a superposed control
   — even with a basis condition (channel A delta exactly zero) `out` loses
   `p`-coherence (review-oracle witness, 2-bit registers, `f = +1 mod 4`:
   reference `[.5, 0, 0, .5]` vs B-keep flat `[.25, .25, .25, .25]`).
   Garbage-dephasing must be exact-ZERO (rails/flag exactly `|0⟩`). If any
   number contradicts the §8.2 closed forms, WI-4 does not ship; (d) negative
   control: path B on a phase arm reproduces the P0 0.585→0.500 dephasing
   (why Rule 7 forbids B for phase arms).
2. **Read the actual lowered IR** (Rule 11) for 5d/5e and diff against the
   oracle-modeled construction — the emitter-fidelity gap is invisible to
   every automated layer.
3. **No-spurious-free probe.** `CHECK-COUNT-2: @cqrt_free` (diamond) /
   `CHECK-COUNT-3` (if/else) + trailing `CHECK-NOT: @cqrt_free` — proves
   `uncompute` added nothing and **neither `out` nor the source register is
   freed** (a free of either is a hidden measurement of the answer / of `q`).
4. **Polarity probe.** FALSE-successor value arm lowers to the identical
   routed stream with the X-bracket (arms by merge-phi incoming identity).
5. **§3c active matrix** (5f contrast set): `q=q+3` rejects (exact string,
   source-located); transitive `q+1>5` variant rejects; `p=p+3` accepts;
   `p=q+1` + Defect-2 decline `control flow` (never the §3c string, never
   accepted); QQ defers; mixed declines `mixed phase/value arm`; fan-out/stray
   declines `impure value arm`.
6. **Dephasing guards.** Every phase fixture keeps `CHECK-NOT: cqrt_copy`;
   every value fixture has `CHECK-NOT: _controlled`; the mixed-arm decline is
   the structural guarantee no chain ever carries both.
7. **Guard-composition probes** (PRD §8.7): value accept fixture passes
   `declineTaintEscapes`/`declineClassicalMuxes` by construction (it would
   exit non-zero otherwise); a chained-theta value variant of the
   stale-condition family declines (`condition predates a non-diagonal gate`);
   a post-compare tainted `cq_theta` + value arm declines.
8. **Free-target probe.** The rail free's operand capture-matches the FINAL
   `_inv` handle (`%[[U2]]`), not the forward rail/chain handles (hazard
   §6.5).
9. **e2e trace diff** (WI-6) — the linking proof for the new ABI symbol.

---

## 9. Done criteria (maps PRD §9) — open at 4.2 start

- [ ] 5d + 5e lower to the pinned streams; postconditions green; `opt -verify`
      clean (second-RUN lines).
- [ ] `cqrt_copy_i{1,8,16,32,64}` in the hand-written core ABI; runtime trace
      test covers them; `gen_templates.py --check` clean (YAML untouched).
- [ ] `demo_D` passes the two-channel bar (§8.1(c) — both channels asserted
      vs the analytic closed forms; exact-zero deltas in the basis-`p₀`
      regime); verdict in SCOPING §8; recorded BEFORE/WITH WI-4 (Rule 13).
- [ ] §3c active matrix fully fixtured (5f); Defect-2 declines `control flow`;
      bd memory updated.
- [ ] First real `emitInverseChain` invocation (§7.5 discharged); seam guard
      landed.
- [ ] `slice_control_value_diamond` e2e links + diffs clean.
- [ ] 4.1 phase fixtures all green, `CHECK-NOT: cqrt_copy` intact.
- [ ] §8 adversarial review clears the emitter change — not just green tests.
- [ ] Full `ctest` green.

---

## 10. Reuse map (Rule 14 — every need resolves to an existing symbol)

| Need | Existing symbol (file:line) |
|---|---|
| Flag mint / `_hl_inv` strip | `lowerCompareToFlag` (`CompareLowering.h:110`) — unchanged |
| Route in/out (+¬flag bracket) | `emitRoute` (`SwapRouteEmit.cpp:110`) over `ControlledSymbols::cswapFn`/`xFn` |
| `|0⟩` rail + copy target | `WidthDispatch::allocFn` (`WidthDispatch.h:69`) |
| Clean rail/flag free | `WidthDispatch::freeFn` (`WidthDispatch.h:116`) |
| **Arm chain body emission** | `rewriteBinary` (`ArithLowering.h:51`) — the straight-line per-op emitter, reused verbatim at the moved position |
| **Chain adjoint (reverse-play)** | `emitInverseChain` (`EmitInverse.h:67`) — first real invocation; body chain only (the cswap arg-0 seam, PRD §8.5) |
| ABI width from the chain type | `abiWidthFromType` (`OpcodeSupport.h:69`) — reliable pre-RAUW for integer chains |
| Condition provenance (+angle exclusion) | `condProvenance` (`ArmClassify.cpp:147`) |
| Arm-block-bounded walks | `walkPhaseSpine`/`armBlockIsPureSpine` pattern (`ArmClassify.cpp:63/94`) — value twins follow it |
| CFG flatten + scrub | `flattenRegion` (`RegionFlatten`) + `scrubTaint` (`SwapRouteEmit.cpp:50`, grown by one set) |
| Loud decline | `diagnoseUnderControl` (`ControlPlan.h:242`) |
| Free-point discipline (4.3 generalization) | `computeFreePoint` (`FreePoint.h:44`) — still not invoked by the region path (single-block argument, PRD §8.5) |
| **NEW (the only ABI addition)** | `cqrt_copy_<W>` (5 integer widths, hand-written core; `WidthDispatch::copyFn` mint) |

Deliberately **not** used: `_controlled` family (§6a reserve);
`recoverForwardChain`/`ChainWalk` (the reverse-play target is the verbatim
forward chain the emitter just built — no lineage recovery needed);
`cqrt_copy` for ANY phase-arm purpose (Rule 7).

---

## 11. Out of scope (declines wired in WI-3, implemented in later increments)

QQ chain links (oracle-unmodeled — own demo before any accept); mixed
phase/value arms + heterogeneous if/else (§6a territory); fresh-value mux /
Defect-2 family (`control flow`, the 4.4 `select` machinery); FP merges
(angles); nested (4.3 — `computeFreePoint` + block-lifetime activate there);
`select` (4.4 — NB: most short C value arms reach the pass select-folded,
PRD §8.4); `switch` (4.5); controlled `return`/`break`; real template bodies
(trace-only through the freeze). Each declines loudly — a feature, not a gap
(Prime Directive).
