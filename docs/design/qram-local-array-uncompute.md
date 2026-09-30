# QRAM local-array uncompute on a returned/measured load (bug `sxuk`)

> **Design note pinning the fix integration point.** Core escape/uncompute-spine
> change (independent adversarial review required: `CLAUDE.md` R11). Companion to
> the corrected `7-5-qram-design-decisions` bd memory (decisions 4/6). The same
> reasoning is carried in the source comments at `kMsgQramCohEscape` and
> `emitCopyOutIfDirectMeasure` (`ir-pass/src/QramLowering.cpp`) and at `isCopyOutSink`
> (`ir-pass/src/ChainWalk.cpp`); symbols and fixture names below were checked against
> the tree on 2026-09-30. Plan of record: `NORTHSTAR.md`. The QRAM lowering and
> the `cqrt_qram_*` ABI this note builds on are in [`../backend.md`](../backend.md)
> §6.1 and §11.4.

## The bug

A non-`main` function that builds a **local** alloca array by tainted-index
stores, loads a value, and **returns or measures** that value — with the array
*pointer* never escaping — leaves the array's stores **un-reversed**:

```
%arr = call i32 @cqrt_qram_alloc_i32(i32 8)
call void @cqrt_qram_store_i32(%arr, %h, %qval)
%v = call i32 @cqrt_qram_load_i32(%arr, %h2)
ret i32 %v            ; ← no store_unc, no load_unc, no free; opt exit 0
```

The returned value stays **entangled with the leaked local scratch array**; for
superposed cells (the case the tainted-store Shadow path exists for) tracing out
the dead array **dephases** the result — a verify-clean silent miscompile.

## Root cause (traced in source)

The load result `%v` is the only tainted data terminal (the array handle is
non-terminal because the load consumes it — `ChainWalk::isInPlaceGateOn`
recognizes `cqrt_qram_store_` but not `cqrt_qram_load_`). For a returned `%v`,
`FreePoint::computeFreePoint` classifies it **Escaped** (`isRecognizedEscapeUser`
→ `ret`), so it is dropped from `InsertTerms` and `Uncomputation::uncompute`
bails at the **`InsertTerms.empty()`** guard *before* `recoverDataDag` ever runs.
The stores, reachable only through `%v`, are abandoned. (For a *measured* `%v`,
`FreePoint` returns **Measured** — same outcome.) This keys reverse-vs-leak on
the **loaded value's** escape, not the **array handle's** ownership — but the
caller cannot own a local array it cannot reach.

## The fix — method-B copy-out (mirrors the 7.6 I/O tape-write)

This is structurally identical to how the I/O output-tape write keeps a taped value's
lineage alive: a `cqrt_tape_write` is a **source-preserving sink** (`isOutputSink`) that
reads-and-preserves its source, so the source stays a non-escaped terminal and
its lineage "uncomputes normally (Bennett copy-out)" while the kept output rail
carries the answer out. We do the same with a `cqrt_copy`:

> **CORRECTION 2026-06-24 (bug `l6xk`; VERIFIED physics, supersedes the framing
> below for the *coherent return* case).** The copy-out + whole-DAG reversal is
> correct **only for a MEASURED** loaded value. For a **coherent `ret`/`cq_invert`**
> escape it is a *silent dephasing miscompile*: `arr[p]` at a superposed address is
> entangled with the **local index** `p` (and the store index `q`); the reversal
> uncomputes and **frees those index rails**, a dirty free (a reset of a rail that is
> not `|0⟩`; `CLAUDE.md` R5) that dephases the
> returned carrier to a classical mixture (off-diagonal coherence **exactly 0**;
> `ρ = diag(2c²s², c⁴+s⁴)`). No-cloning forbids returning a clean coherent `arr[p]`
> once its local address is erased — and *leaving the index allocated does not help*
> (the carrier is already mixed the instant the copy fires; it only defers the
> collapse). So a coherent qRAM-load escape now **loud-declines** (`kMsgQramCohEscape`),
> across **both** the Shadow store/load path **and** the Inc-1 QROM read path
> (`return tbl[q]` was the same latent bug). The copy-out below fires **only for the
> direct `cq_measure` sink** (`emitCopyOutIfDirectMeasure`), where measurement
> immunity makes the diagonal the correct distribution.
> See `bd memory 7-5-qram-coherent-return-nocloning`. The original "disentangled
> escaped return" claim (step 1 / the end of this section) is TRUE for the measure
> sink and FALSE for a coherent return.
>
> **Status against NORTHSTAR goal 1 (2026-09-30): this decline is current behavior,
> not a ruled physics wall.** What the argument above establishes is that the
> returned carrier can never be *pure* (it is entangled with the local index
> whether that rail is freed or left allocated). It does not establish that the
> program cannot be compiled: nothing is cloned by a plain `ret`, and a
> faithful lowering (copy nothing, reverse nothing, leave the local index and array
> rails allocated, return the load result, so the caller receives the mixed
> carrier the source literally asks for) is not built. "No-cloning forbids it"
> above describes why the *copy-out plus whole-DAG reversal* strategy is wrong for
> a coherent return, not why the construct is unlowerable. Read the decline as
> **not yet lowered**: it needs a bd issue and an owner ruling (goal 1's closed
> list is extended only by the owner), and until then it stays loud.
>
> **AMENDMENT 2026-08-11 (bd `5pio`, owner ruling).** The index rails described above
> as *freed* are **no longer freed**, on either path. `ChainWalk::isCopyOutSink` now
> seeds the bd 261j record freeze — a `cqrt_copy_<W>` **destination** is a kept
> carrier exactly as an output tape is — so the correlation propagates **backward**
> from the copy source and any ancestor whose gate is `cqrt_ry_` (these `cq_theta`
> index roots) fails `preservesBasisUnderRecord`, is fully reverse-played, and is then
> **left allocated** (the rule for a rail not provably `|0⟩`, `CLAUDE.md` R5). The measurement-immunity argument above is
> still *valid on its own terms*; it is simply no longer what the compiler relies on,
> and the ruling deliberately preferred one uniform source-side invariant over two
> independent justifications — measurement immunity is a different claim from "the
> rail is |0⟩", and only the latter is what freeing a rail requires (`CLAUDE.md` R5). Measured cost: 9 lit
> fixtures and 6 e2e goldens moved, 30 `cqrt_free`s removed, every changed line a
> removed free. **The coherent-escape decline is NOT made redundant by this** — a
> coherent `ret` mints no copy (`emitCopyOutIfDirectMeasure` returns early unless the
> sole direct user is a measure), so nothing seeds the freeze on that path and the
> reversal would still free the index rail. See bd memory
> [`bennett-copyout-destination-2026-08-11`].

1. **`QramLowering` (the integration point).** In `processShadowAlloca`'s **load
   branch**, right after `A.MemOp->replaceAllUsesWith(Out)`, if `Out` (the
   `cqrt_qram_load` result) is the **sole, direct** operand of a `cq_measure_*` in a
   **non-`main`** function (the coherent-`ret` case is loud-declined upstream), emit
   the copy-out and redirect the measurement:
   ```
   %qret = call i32 @cqrt_alloc_<W>(0)        ; fresh |0> carrier
   call void @cqrt_copy_<W>(%v, %qret)        ; CNOT-class copy, PRESERVES %v
   ret i32 %qret                              ; escape now carries the copy
   ```
   `%qret` is a kept rail (returned/measured → never reversed). `%v`'s only user
   is now the copy.

2. **Spine vocabulary (`ChainWalk` + `DagTraversal`).** Teach the spine that an
   uncontrolled `cqrt_copy_<W>(src, dst)` reading a handle as **arg-0 (src)** is a
   source-preserving sink — new shared predicate **`isCopyOutSink(G, H)`**:
   - `ChainWalk::isTerminalHandle` treats it as a benign user, so `%v` stays a
     terminal candidate;
   - `DagTraversal::recoverDataDag`'s closure scan treats it as benign (like
     `isOutputSink`), so `%v`'s DAG is **closed**, not `NotClosed`.

   No `FreePoint` change is needed: the copy is an ordinary `cqrt_` user, so it
   already lands in the post-dom user set and the reversal anchors **after** it.

With those two pieces, `Out` becomes a non-escaped terminal and the **existing
whole-DAG dead-array reversal** does the rest: `cqrt_qram_load_<W>_unc` then the
`cqrt_qram_store_<W>_unc` chain (strict LIFO), then `Out` freed. The array handle is
left allocated but now **clean `|0>`** (stores restored it), so it is a
accepted leak (never freed dirty, `CLAUDE.md` R5) — disentangled from the returned `%qret`.

> **AMENDED 2026-08-11 (bd `5pio`).** This step list used to read "…the index/value
> rails **freed**, `Out` freed". The index/value rails are now fully reverse-played
> and then **LEFT ALLOCATED**: `isCopyOutSink` seeds the bd 261j record freeze, the
> correlation propagates backward from the copy source, and an ancestor whose gate is
> `cqrt_ry_` fails `preservesBasisUnderRecord`. `Out` itself — a `cqrt_qram_load_<W>`
> result, a basis permutation of `arr`/`idx` — stays freeable and is still freed, so
> the LIFO store reversal this section exists to describe is unchanged. See the
> amendment in the `l6xk` correction block above.

## Why each scope boundary

- **Taped loads already work** — `cqrt_tape_write` is `isOutputSink`, so `%v`'s
  lineage already uncomputes; no copy-out is inserted (the sole-user is the tape
  write, not a `ret`/`cq_measure`).
- **`main` skipped** — `FreePoint` makes everything in `main` Escaped (process
  exit reclaims); the reversal would not fire, so the copy is pointless. Avoids
  touching the `slice_qram_store` e2e golden.
- **Genuine array-pointer escape** (pointer returned/stored-out) still leaks —
  the caller owns it; unchanged.
- **const-global QROM** (`lowerQramReads`) unchanged — no stores to reverse.

## Scope of increment 1 / follow-ups

Inc 1 handled the **direct** sole-user escape. The arith-then-escape / fan-out
follow-up (bug `l6xk`) is resolved **NOT** by extending the copy-out (that was the
wrong instinct — see the correction above) but by **splitting on the sink type**:

- **arith-then-MEASURE** (`cq_measure(a[p]+1)`) — **accepts**, immune. The escaped
  terminal is the arith result whose forward sink is a measure; the load's direct
  user is the `add`, so the direct-measure copy-out does not fire — the array/index
  rails are **left allocated (an accepted leak, never freed dirty)**, which is correct under
  measurement immunity (the measured distribution is right; resource cleanup is the
  only thing skipped). Fixture `lowering_qram_store_arith_measure.ll`.
- **arith-then-RETURN / fan-out-then-RETURN** (`return a[p]+a[r]`) — **loud
  declines** (`kMsgQramCohEscape`). The forward walk `coherentlyEscapesToReturn`
  follows the load result through tainted arithmetic to a `ret`/`cq_invert` (stopping
  at any measure/tape collapse sink) and rejects: no-cloning forbids the coherent
  return once the local index is uncomputed. Fixtures
  `lowering_reject_qram_coherent_return{,_arith}.ll` (Shadow, direct + arith) and
  `lowering_reject_qram_read_coherent_return.ll` (QROM).

The mid-sequence-observation guard (`kMsgQramMidSeq`) is unchanged. `main`'s `ret`
is the process-exit observation (immune; not declined).

## Red-green

- **Flip** the two measure-form fixtures that *assert the leak*
  (`lowering_qram_store_alloca_i32.ll`, `lowering_qram_store_flat_gep.ll`:
  `CHECK-NOT: cqrt_qram_store_i32_unc` → assert `cqrt_copy` + `..._store_..._unc`
  + `..._load_..._unc`).
- `lowering_qram_store_dead_lifo.ll` (dead load) and `lowering_qram_store_load_copy.ll`
  (load-into-store) are unaffected (load result not observed).

> **`l6xk` update:** the sxuk return-form ACCEPT fixture was renamed and **flipped to
> a DECLINE** (`lowering_reject_qram_coherent_return.ll`) — a coherent return is the
> no-cloning miscompile, not a copy-out target. The Inc-1 QROM accept fixture
> `lowering_qram_read_const_global_i32.ll` was switched to the **measure form** (the
> direct `return tbl[q]` it used to assert is now declined:
> `lowering_reject_qram_read_coherent_return.ll`).

## Clearance

Independent adversarial review (`CLAUDE.md` R11) of the spine edits (`ChainWalk`,
`DagTraversal`, `QramLowering`) before commit — a green suite does not clear it.
