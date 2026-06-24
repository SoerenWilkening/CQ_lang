# QRAM local-array uncompute on a returned/measured load (bug `sxuk`)

> **Design note pinning the fix integration point.** Core escape/uncompute-spine
> change (Rule 13). Companion to the corrected `7-5-qram-design-decisions` memory
> (decisions 4/6) and `docs/design/bennett-parity/PARITY_MAP.md`.

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

This is structurally identical to how Phase 7.6 keeps a taped value's lineage
alive: a `cqrt_tape_write` is a **source-preserving sink** (`isOutputSink`) that
reads-and-preserves its source, so the source stays a non-escaped terminal and
its lineage "uncomputes normally (Bennett copy-out)" while the kept output rail
carries the answer out. We do the same with a `cqrt_copy`:

1. **`QramLowering` (the integration point).** In `processShadowAlloca`'s **load
   branch**, right after `A.MemOp->replaceAllUsesWith(Out)`, if `Out` (the
   `cqrt_qram_load` result) is the **sole, direct** operand of a `ret` or a
   `cq_measure_*` in a **non-`main`** function, emit the copy-out and redirect the
   escape:
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
`cqrt_qram_store_<W>_unc` chain (strict LIFO), the index/value rails freed, `Out`
freed. The array handle is left allocated but now **clean `|0>`** (stores
restored it), so it is a Rule-6-compliant safe leak — disentangled from the
returned `%qret`.

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

Inc 1 handles the **direct** sole-user `ret`/`cq_measure` escape (the reported
bug). A load result consumed by arithmetic *then* returned (`return a[i]+a[j]`)
is the escaped terminal one level up; it still leaks (status quo, not a
regression) and is a follow-up — the copy-out would move to the actual escaped
terminal. A fan-out load result is left as-is. The mid-sequence-observation guard
(`kMsgQramMidSeq`) is unchanged: a store *after* an observed load still declines.

## Red-green

- **Flip** the two measure-form fixtures that *assert the leak*
  (`lowering_qram_store_alloca_i32.ll`, `lowering_qram_store_flat_gep.ll`:
  `CHECK-NOT: cqrt_qram_store_i32_unc` → assert `cqrt_copy` + `..._store_..._unc`
  + `..._load_..._unc`).
- **Add** a return-form fixture (`lowering_qram_store_return_load.ll`) — the
  reported bug, now copy-out + reversal.
- `lowering_qram_store_dead_lifo.ll` (dead load) and `..._load_copy.ll`
  (load-into-store) are unaffected (load result not observed).

## Clearance

Rule-13 independent adversarial review of the spine edits (`ChainWalk`,
`DagTraversal`, `QramLowering`) before commit — a green suite does not clear it.
