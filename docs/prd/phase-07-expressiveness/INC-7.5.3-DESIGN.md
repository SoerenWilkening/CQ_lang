# Phase 7.5 Increment 3 — Provenance Hardening + Full Decline Matrix (design + clearance scaffold)

> Written at the start of Inc 3 (2026-06-23), bd `test_C_libtooling-7z9k.3`.
> Builds on Inc 1 (`7-5-inc1-qrom-read-design`) + Inc 2 (`7-5-inc2-shadow-store-shapes`).
> CORE change to the escape/uncompute spine + the frozen-ABI-adjacent QRAM
> classifier — Rule-13 gated. Over-declining is safe; over-**accepting** is the
> only unforgivable bug (Prime Directive). This doc states the accept boundary,
> the decline matrix, and the two over-decline hardening fixes precisely so the
> independent reviewer can audit the over-accept surface against the lowered IR.

## 0. The `-O1` reality that scopes Inc 3 (Rule 11, extracted real IR)

`arr[q]` **directly on a local array** lowers to an **array-decay** gep
(`getelementptr [N x iW], ptr %base, i64 0, i64 %idx`) — Inc 1/2 already handle
this. **Any pointer indirection** (`int *b = …; b[q]`) decays to a **flat**
element gep (`getelementptr iW, ptr %base, i64 %idx`) — Inc 1/2 do NOT handle
this, and it is exactly the shape a pointer phi/select produces. So the
provenance walk MUST handle flat geps to accept any single-origin phi/select.

clang `-O1` **folds** a degenerate single-origin pointer phi (`if(c) b=arr; else
b=arr`) away entirely, and turns a genuine two-offset select into an **integer
offset select** + a byte gep (a dynamic base offset). So real `-O1` rarely emits
a clean single-origin pointer phi/select; the single-origin ACCEPT is exercised
by hand-written `.ll` fixtures (same vehicle as the dead-LIFO fixtures, which
clang would DCE).

## 1. The single structural ACCEPT — `matchQramAccess`

ONE matcher is the shared truth for the carve AND both emitters (carve/emit can
never diverge — the Inc 1 discipline). A `load`/`store` is accepted iff:

1. `isSimple()` (no atomic/volatile).
2. its pointer is a **single-use** gep, in EITHER
   - **array-decay** form: source element type `[N x E]`, exactly 2 indices
     (constant-zero, then the trailing index), OR
   - **flat** form: scalar source element type `E`, exactly 1 index;
   with the **trailing index TAINTED** (a classical-index access stays classical
   — not ours, no spurious taint).
3. the gep base **resolves to a single origin** via `walkPtrOrigin` — a clean
   `alloca` or constant `global` of array type `[N x E]` — AND the base is a
   **direct** origin pointer (`isDirectOriginPtr`: the base, stripping bitcasts,
   IS the origin object, or a phi/select ALL of whose arms are direct to the
   SAME origin). This guarantees a **zero net offset** — the index is cleanly the
   trailing gep operand. A gep-with-offset base, a same-origin-different-offset
   phi/select, or a multi-origin phi/select is NOT direct → not accepted.
4. `E` is a scalar cell (`isIntegerTy() || isFloatingPointTy()`); the gep's
   accessed type matches the origin element type.
5. NOT under tainted control (`instUnderTaintedControl` — straight-line, §2.11)
   and NOT inside a natural loop (`LoopInfo` — the 7.3 boundary).
6. an `alloca` origin is `!isArrayAllocation()` (static N); a `global` origin is
   `isConstant() && hasInitializer()`.

`matchQramAccess` accepts the structural shape EVEN for fp/i128 cells (E has a
width but no reversible copy); the EMITTER width-gates those to `kMsgQramCell`
(the Inc 1/2 carve/emit discipline — a carve is never a silent accept). Origin
`global` → the Inc 1 QROM read path (`lowerQramReads`, untainted array handle);
origin `alloca` → the Inc 2 Shadow path (`lowerShadowMemory`, tainted in-place
register). The two wrappers `classifyQromRead`/`classifyShadowAccess` are
`matchQramAccess` filtered by origin kind.

## 2. `walkPtrOrigin` — the single-origin proof + decline naming

Resolves a pointer to its unique base object, OR a named decline reason. Strips
`bitcast`; follows `getelementptr` base (gep chains) and pointer `phi`/`select`
(all arms must resolve to the SAME origin object). Bottoms out:

| pointer chain hits | result |
|---|---|
| `alloca [N x E]` (static N) | **Origin(alloca)** |
| constant `global [N x E]` | **Origin(global)** |
| `alloca` with dynamic size / non-array type | `kMsgQramDynN` |
| `phi`/`select` arms with ≥2 distinct origins | `kMsgQramMultiOrigin` |
| `inttoptr` / `ptrtoint`-forged address | `kMsgQramProvenance` |
| `addrspacecast` | `kMsgQramAddrSpace` |
| `call` to an allocator (`malloc`/`calloc`/`realloc`/`aligned_alloc`/`_Znwm`…) | `kMsgQramHeap` |
| other `call` / `Argument` / unknown | `kMsgQramProvenance` |
| a cyclic (loop-carried) phi | `kMsgQramMultiOrigin` (visited-set bail) |

## 3. The carve — `classifyQramCarve` → {Accept, Decline(msg), NotQram}

Consulted by `declineTaintEscapes`. A `load`/`store`/`gep` whose pointer/result
is tainted is in QRAM's domain; the verdict:

- **GEP** (a tainted address-gen, not under tainted control, every user a
  load/store/gep using it as a pointer) → **Accept** (carve — suppress the
  generic decline; the memop owns the single verdict). Under control / escaping
  use → NotQram (generic).
- **LOAD/STORE** with a tainted pointer:
  - under tainted control → **NotQram** (ControlDetect/generic domain — preserves
    the jumptable `kMsgOther`, `control_swap_reject_switch_jumptable.ll`).
  - inside a loop → **Decline(`kMsgQramLoop`)**.
  - `matchQramAccess` → **Accept**.
  - else name the decline via the pointer chain: a multi-use (shared) address gep
    → **Decline(`kMsgQramAlias`)**; else `walkPtrOrigin(base/ptr)` Bad →
    **Decline(its msg)**; a clean single origin that simply failed the
    offset/shape cleanliness (e.g. a dynamic byte offset) → **NotQram** (generic
    `kMsgOther` — a safe loud decline, not a silenced accept).
- value-tainted / classical-pointer store → pointer untainted → **NotQram**
  (generic `kMsgStore`; the value-at-classical-index store is out of QRAM scope).

**Totality / no silent gap:** every tainted-pointer load/store is Accept, a named
Decline, or NotQram (which falls to the generic loud `kMsgOther`/`kMsgStore`).
A double decline (two memops sharing an aliasing gep both naming `kMsgQramAlias`)
is harmless (over-declining is safe; `opt` still exits non-zero). The ONLY hazard
guarded is over-accept: Accept ⟺ `matchQramAccess`, which is conservative.

## 4. Decline matrix (Rule 12 — each a mirrored negative fixture)

| pattern | message | fixture |
|---|---|---|
| pointer-phi/select multi-origin | `kMsgQramMultiOrigin` | `lowering_reject_qram_multi_origin.ll` (NEW) |
| inttoptr / ptrtoint forged address | `kMsgQramProvenance` | `lowering_reject_qram_inttoptr.ll` (UPGRADE), `_ptrtoint.ll` (NEW) |
| addrspacecast | `kMsgQramAddrSpace` | `lowering_reject_qram_addrspacecast.ll` (NEW) |
| dynamic-N / VLA alloca | `kMsgQramDynN` | `lowering_reject_qram_dynamic_n.ll` (UPGRADE) |
| heap allocation | `kMsgQramHeap` | `lowering_reject_qram_heap.ll` (NEW) |
| aliasing fan-out (shared address gep) | `kMsgQramAlias` | `lowering_reject_qram_aliasing.ll` (NEW) |
| QRAM access inside a loop | `kMsgQramLoop` | `lowering_reject_qram_in_loop.ll` (UPGRADE) |
| fp cell | `kMsgQramCell` (emitter) | `lowering_reject_qram_fp_cell.ll` (unchanged) |
| i128 cell | `kMsgQramCell` (emitter) | `lowering_reject_qram_i128_cell.ll` (unchanged) |
| mixed tainted+classical access | `kMsgQramMixed` (emitter) | `lowering_reject_qram_mixed_access.ll` (unchanged) |
| pointer/heap escape of the alloca | `kMsgQramEscape` (emitter) | `lowering_reject_qram_alloca_escape.ll` (unchanged) |
| mid-sequence observation | `kMsgQramMidSeq` (emitter) | `lowering_reject_qram_mid_seq.ll` (unchanged) + `_tape_obs.ll` (NEW) |

Positive: `lowering_qram_read_flat_gep.ll` (NEW — flat gep off an alloca via a
single-origin phi accepts) and `lowering_qram_store_load_copy.ll` (NEW —
`arr[p]=arr[q]` dead-load-then-store accepts; the §6.2 hardening).

## 5. The two over-decline hardening fixes (bd NOTES — safe over-declines)

1. **Tape-write observation → clean `kMsgQramMidSeq`.** `isObservedValue` (the
   §2.8(iii) mid-seq guard) now recognizes a `cqrt_tape_write_<W>` I/O-output sink
   (already lowered by `lowerIOSinks`, which runs before `lowerShadowMemory`) as
   an observation, alongside `ret` and `cq_measure_*`. WITHOUT this, an
   output-observed load before a later store lowered + then tripped the CONFUSING
   spine `kMsgDivergentArm`; now it loud-declines cleanly at the mid-seq guard.
   Correctness was sound either way (declined); diagnostic clarity only.

2. **Dead-load-then-store (`arr[p]=arr[q]`) accepts — a latent Inc 2 crash fix.**
   `processShadowAlloca` captured the store's value operand at classify time
   (`A.StoreVal`); when an earlier load access RAUW'd that original load to the
   new `cqrt_qram_load` and queued it for erase, the new store re-used the STALE
   original-load pointer → a dangling operand (crash / verify-fail, masked as
   `kMsgDivergentArm`). FIX: re-read the value operand FRESH from the original
   store at emit time (`cast<StoreInst>(A.MemOp)->getValueOperand()`), so it picks
   up the load's RAUW and the new store consumes the new load. The array is then
   a normal in-place register; if it is dead/loaded it is left allocated (a Rule-6
   safe leak — a loaded array is not a terminal), never miscompiled.

## 6. Rule-13 over-accept audit checklist (for the independent reviewer)

- `matchQramAccess` is the ONLY accept; confirm it cannot accept a multi-origin /
  forged / heap / dynamic-N / addrspacecast / offset-unclean pointer (read the
  lowered IR of each decline fixture — it must `opt`-fail, not lower).
- `isDirectOriginPtr` guarantees zero net offset (the index is the trailing gep
  operand). Confirm sel_single (dynamic byte offset) declines.
- the frozen `cqrt_qram_*` signatures are UNCHANGED by Inc 3 (no ABI edit).
- the two over-decline fixes are SAFE over-declines / a crash fix — confirm they
  add no new accept beyond the proven single-origin shape.

## 7. Rule-13 clearance outcome (independent adversarial review, 2026-06-24)

An independent reviewer ran ~40 adversarial probes across all 7 over-accept
targets, reading the actual lowered IR. The provenance / offset-cleanliness /
aliasing / width / mid-sequence / carve-emit-totality machinery held (every
off-pattern declined loudly; the spine reversal was analytically correct with no
double-free / dirty-rail free). **Two over-accepts were found and FIXED before
commit:**

- **Finding 1 (silent miscompile — the real one): non-zero `memset` dropped.**
  `processShadowAlloca` whitelisted `llvm.memset` UNCONDITIONALLY. The runtime
  models a fresh array as |0⟩ (`cqrt_qram_alloc_<W>` is count-only), so
  `memset(arr, 0xAA, …)` then `load arr[q]` of an un-overwritten cell read 0 in
  the trace while the true value is `0xAAAAAAAA` — verify-clean WRONG DATA (exactly
  PRD §6 risk #5). **Fix:** accept ONLY a constant ZERO-fill memset; a non-zero /
  non-constant fill loud-declines `kMsgQramInit`
  (`lowering_reject_qram_nonzero_init.ll`). The realistic `={3,1,…}` initializer
  comes as `llvm.memcpy` and already declined (`kMsgQramEscape`); the QROM read
  path carries real const contents through the const-global origin.
- **Finding 2 (degenerate / UB-input, minor): `[0 x iW]` array accepted.** A
  zero-length array indexed by a tainted value lowered to
  `cqrt_qram_alloc_<W>(0)` (any index OOB). **Fix:** `matchQramAccess` declines
  `OT->getNumElements() == 0` (rides the generic loud decline). UB input, lowest
  severity, but no reason to admit it.

Both fixes are pure decline-tightenings (over-declining is safe), add no new
accept, and keep the full suite + all QRAM fixtures green.
