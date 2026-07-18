# PRD — bd 20xt.4: spec-callee const-global QROM read (atan2l inner-atanl blocker b)

**Status:** Increment 1 DONE (blocker b). Increment 2 (blocker c) open.
**Branch:** `3c6m.14-control-l6`. **Epic:** `20xt` (ld80 transcendentals).
**Depends on:** 20xt.3 (clone fp-select const-arm widening, blocker a).

## Context

`atan2l.f80` calls `atanl` (a large, un-inlined `internal fastcc` function at
`-O1`) with a tainted argument inside a tainted-condition diamond. `atanl`'s body
holds the `atanhi[id]`/`atanlo[id]` tainted-index reads of the const-global
coefficient tables (`ld80/invtrig.c`). For atan2l to lower end-to-end, `atanl`
must be **specialized** into a Bennett-wrapped reversible clone whose body lowers
those QROM reads. After 20xt.3 cleared blocker (a) (the const-arm fp-select),
atan2l declines at `s_atanl.c:82:10` — `scanBody` rejects the QROM-read
`getelementptr [0 x x86_fp80] @_ItL_atanhi, i64 %id` as an "unsupported
instruction" (a GEP is not on the whitelist). This is **blocker (b)**.

The full atan2l compose is three composed blockers (all reuse the shared
`matchQramAccess` structural core — Rule 14):
- **(a)** clone fp-select const-arm widening — DONE (20xt.3).
- **(b)** `scanBody` admit + clone emit + Bennett-wrap capture of the QROM read
  — **this PRD, Increment 1.**
- **(c)** `isSpeculatableDataflow`/`isSpeculatablePureCalleeBody` (the E4'
  pending-spec-call proof) must admit the QROM read so atan2l's tainted diamond
  flattens (hoisting the atanl call) — **Increment 2 (open).**

## Increment 1 — the spec-clone-path QROM read (blocker b)

**Scope:** a **straight-line** const-global tainted-index QROM read inside a
Phase-6 specialized callee (no control, no index-select — those ride Increment 2 /
the atanl full clone). This is the spec-callee edition of the top-level Phase-7.5
QROM read.

### Mechanism

The module-level `lowerQramReads` (CQLoweringPass) runs **before** `specialize`,
so a clone (created inside `specialize`) still holds raw `gep`+`load`s. The clone
lowers + reverses its own QROM reads:

1. **`scanBody` admit** (`SpecializeReject.cpp`, taint-blind pre-clone shape
   scan): the QROM-read `LoadInst` and its address `GEP` are admitted via the new
   **`qromReadShapeInScope`** (`QramLowering.cpp`) — a taint-blind STRUCTURAL
   check reusing the SAME helpers `matchQramAccess` uses
   (`matchAddressGep`/`walkPtrOrigin`/`isDirectOriginPtr`) plus the identical
   array/const/pun/width gates, so the admit can never STRUCTURALLY diverge from
   the emitter (Rule 14). Taint/control/loop/bounds proofs are DEFERRED to the
   emitter (the clone body's index is not in the module taint).

2. **clone emit** (`Specialization.cpp buildClone`): after `lowerCloneControl` +
   `lowerCloneSelect`, before `lowerOps`, call
   `lowerQramReads(M, wd, cloneTaint, /*inBennettClone=*/true)`. Scoped by
   `cloneTaint` (only the clone's tainted-index reads match). `inBennettClone`
   SKIPS the top-level coherent-return no-cloning fence (`kMsgQramCohEscape`) —
   see soundness below. Emits `cqrt_qram_alloc_<W>` (array-handle birth, at the
   clone entry) + `cqrt_qram_load_<W>` (Toffoli copy-out); the load result joins
   `cloneTaint` as a reversible producer.

3. **Bennett-wrap capture** (`Specialization.cpp` capture loop): the
   `cqrt_qram_load_<W>` call is captured (via `isForwardQramLoad`) into
   `ForwardStream` + `ScratchRails` — reversed by `emitInverseChain` via the
   existing `cqrt_qram_load_<W>_unc` (out-first: un-copies the dead value rail
   using the preserved cell), then the value rail is `cqrt_free`d **after the
   complete reverse**. The `cqrt_qram_alloc_<W>` array handle is EXCLUDED (not
   `isForwardTemplate`/`isForwardQramLoad`/a select op) — a CLASSICAL resource
   token, never reversed or freed (matches the top-level `isQramArrayHandle`).

### The coherent-return fence SKIP (the load-bearing soundness claim)

The top-level `return tbl[q]` declines with `kMsgQramCohEscape` because the raw
entangled load value escapes with **no** copy-out and the whole-DAG uncompute
later dirty-frees the local index `q` (dephasing the carrier — a verify-clean
silent miscompile; memory `7-5-qram-coherent-return-nocloning`). In a **clone**
the escape is handled by the Bennett wrap: the return `RV` is COPIED OUT to a
fresh `|0⟩` rail **before** the reverse, then the reverse uncomputes the ENTIRE
forward stream — the qram load `_unc` un-copies the load rail using the preserved
cell, the index `_unc` zeroes the index — leaving the final state
`Σᵢ αᵢ |inputᵢ⟩|f(inputᵢ)⟩` with all scratch `|0⟩`: a clean basis function of the
borrowed inputs (Bennett's theorem). The fence is therefore **vacuous** in a
wrapped clone; `inBennettClone=true` skips it. The top-level entry points keep
the default `false` (the fence still fires — regression-pinned by
`lowering_reject_qram_read_coherent_return.ll`).

### No new frozen symbol (Rule 14/15)

The frozen 7.5 QRAM ABI `cqrt_qram_{alloc,load}_f80` (+ `_unc`) already exists;
the runtime YAML is untouched. `EmitInverse` already reverses `cqrt_qram_load_`.

### Emitted clone (verified, deterministic e2e trace)

For `static const double kTable[4]; double lookup(double x){int id=((int)x)&3; return kTable[id]+x;}`:

```
cqrt_qram_alloc_f64(4) -> a1                 ; array handle (never freed)
... fptosi/and -> h3 (index) ...
cqrt_qram_load_f64(a1, h3) -> h4             ; Toffoli copy-out
cq_template_fadd_f64(h4, h0) -> h5
cqrt_alloc_f64(0.0) -> h6 ; cqrt_copy_f64(h5, h6)   ; Bennett copy-out
cq_template_fadd_f64_unc(h5, h4, h0)
cqrt_qram_load_f64_unc(h4, a1, h3)           ; reverse the load (cell preserved)
... and_unc/fptosi_unc ...
cqrt_free(h2/h3/h4/h5)                        ; scratch freed AFTER full reverse
ret h6
```

Exactly 1 `cqrt_ry` + 1 `cqrt_measure` (Rule 5); `a1` never a `cqrt_free` operand;
`h4` reversed before free; `h3` (index) live through the `load_unc`; no double-free.

## Tests (Rule 12 red-green)

- `spec_accept_qram_read.ll` — positive: the clone lowers + reverses (CHECK the
  alloc/load/load_unc + array handle never freed + `load double` gone).
- `spec_reject_qram_read_nonconst.ll` — a non-const global is not a QROM table.
- `spec_reject_qram_read_alloca.ll` — an alloca origin is the Shadow ABI, not
  admitted (fences the two QRAM ABIs apart in the spec-clone path).
- `spec_reject_qram_read_pun.ll` — the 38t2 pun class (access type != cell type).
- e2e `slice_spec_qram_read.c` / `.expected.log` — the full pipeline smoke.

## Increment 2 (open — blocker c + atanl full clone)

- `isSpeculatableDataflow` (used by `isSpeculatablePureCalleeBodyImpl`) admits the
  claimable const-global QROM read (structural, pure) so `isSpeculatablePure
  CalleeBody(atanl)` passes → atan2l's `%204` tainted diamond flattens (E4
  pending-spec-call hoist) → the hoisted straight-line atanl call is specialized
  by Increment 1's machinery.
- The atanl full clone additionally exercises: `lowerCloneControl` flattening the
  argument-reduction cascade, the **i64 index-select** in `lowerCloneSelect`, and
  the NeedsMask index masking (`and id, N-1`) inside the clone. Only when atanl
  reaches `opt` exit 0 and LINKS+RUNS does atan2l become COMPILES (then a separate
  follow-up promotes it COMPILES→VERIFIED via the 3c6m.53 real-openlibm recipe).
