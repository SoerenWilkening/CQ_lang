# Audit — every `cqrt_free` emitter against the bd 261j record invariant

**bd `test_C_libtooling-urlv`.** Written 2026-08-10. This is an **audit with a
written verdict per emitter**, not a code sweep. It deliberately does **not** copy
the bd 261j(a) record freeze into N emitters — the conclusion is that copying it
would be the wrong fix, and the reason is structural.

## The question

bd 261j(a) ruled: **freeing a rail that has been RECORDED onto a carrier the
reversal never touches is a hidden measurement unless that rail's own forward chain
is a basis permutation of conditions still holding their producer-time values**
(bd memory [`record-freeze-invariant-2026-08-10`]). The freeze that enforces it
lives in exactly one place — `DagTraversal` step 3b decides, and
`Uncomputation::emitDagReversal` executes.

The 261j round asked only *"can the SPINE reach the emitters' rails?"* The converse
was never asked:

> **Per emitter: can a kept-carrier RECORD reach a rail that this emitter frees?**
> Where it cannot, *why* — written at the emitter, so the next widening does not
> silently open it. Where it can, does the rail's forward chain satisfy the
> invariant?

## The census — and why a grep is not one

`grep -rn 'CreateCall(.*freeFn'` reports **15 sites across 9 modules**. That number
is wrong, and how it is wrong is worth recording:

* `BreakReversePlay` emits **9** frees through `mintCall`, not `CreateCall` — a
  `CreateCall` grep finds **zero** of them.
* `BennettWrap` binds `FunctionCallee Free = wd.freeFn();` and calls `Free` in a
  loop — invisible to any `freeFn`-adjacent call-name grep.
* Counting *mentions* instead gives 12 files / 37 mentions, which over-counts:
  `WidthDispatch` **defines** `freeFn`, and most of `Uncomputation`'s hits are prose.

Censused spelling-agnostically (every `freeFn()` occurrence resolved to its
enclosing emission call, plus every variable bound to `freeFn()`), and bounded by
the fact that the string literal `"cqrt_free"` occurs **exactly once** in the tree
(`WidthDispatch.cpp:523`), so no module can mint a free by another route:

| module | free sites | what it frees |
|---|---|---|
| `Uncomputation.cpp` (**the spine**) | 1 | whole-DAG data rails — **has the 261j freeze** |
| `BreakReversePlay.cpp` | 9 | 7.4 break capture rails + per-iteration scratch |
| `SwapRouteEmit.cpp` | 4 | per-arm work rails + the path-predicate flag |
| `SelectMergeEmit.cpp` | 2 | leaf flags + tree node rails |
| `SwitchRouteEmit.cpp` | 2 | per-case work rail + eq flag |
| `SwitchValueEmit.cpp` | 2 | per-case work rail + eq flag |
| `BennettWrap.cpp` | 1 (a loop) | clone-body `ScratchRails` |
| `ClassicalCallArmEmit.cpp` | 1 | the path-predicate flag |
| `IOSinkLowering.cpp` | 1 | the controlled-I/O path-predicate flag |
| `NestedRouteEmit.cpp` | 1 | per-level work rails + flags |
| `SwitchDataMuxEmit.cpp` | 1 | the N eq flags |

**25 sites across 11 modules** — 24 outside the spine. This corrects the ticket,
which listed 16 modules and named `Compare`, `GuardedStoreArm`, `Loop`, `PredMux`,
`RegionTree` and `Specialize` as free emitters. **They emit none.**

Cross-referenced against the minters of kept carriers: only **`IOSinkLowering`** and
**`AbortParkEmit`** emit a `cqrt_tape_write_*`, and `AbortParkEmit` emits no free.

## The structural finding

Across all 24 non-spine sites, an emitter frees exactly **two** rail classes:

1. **Its own path-predicate FLAG**, minted by `lowerCompareToFlag` / `emitEqFlag`
   and returned to `|0⟩` by that call's `_inv` twin immediately before the free.
2. **Its own WORK RAIL** — an emitter-minted `|0⟩` ancilla (`A.Rail`, `CS.Rail`,
   `NR.G`, `ScratchRails`, `cq.brk.R`), returned to `|0⟩` by a route-back†, a `_unc`
   chain, or a reverse-play before the free.

No emitter frees a **data** rail; that is the spine's job, and the spine is where the
freeze lives. That is why the answer is not "copy the freeze 24 times": in every case
the rail's forward chain is built from **basis permutations** (compares, controlled
copies, cswaps, toffolis), never from an `Ry` — and an `Ry` chain is precisely what
the 261j freeze exists to catch. `preservesBasisUnderRecord` would clear every one of
these rails if it were asked.

## Verdicts

### A record CAN reach a freed rail, and the free is sound — `IOSinkLowering.cpp:681`

Not a "cannot happen". This emitter passes its flag as the **ctrl** of
`cqrt_tape_write_<W>_controlled(ctrl, tape, src)` (line 625) and then strips and
frees that same flag. A controlled write records its ctrl's label in the entry's
**existence pattern** exactly as it records `src`'s label in its content — which is
why `recordsIntoKeptCarrier` is slot-blind. So a kept-carrier record demonstrably
reaches a rail this emitter frees.

The free is nevertheless **sound**, by the invariant rather than by luck. With `R` =
the flag and `W` = its mint `cq_template_icmp_*(q, k)`:

* (a) `R` starts at `|0⟩` — a fresh alloc.
* (b) `W` is a basis permutation of `cond(W) = {q}` (`flag ^= (q ⋈ k)`), **not** an
  `Ry`. This is exactly the case `preservesBasisUnderRecord` whitelists via
  `isTemplateProducer`, so the spine's freeze would reach the same verdict.
* (c) the reversal is exactly `W†` — the same `lowerCompareToFlag` with
  `inverse=true`.
* (d) `q` holds its producer-time value at strip time, because **every copy
  destination is a fresh out-rail and never a `Cond` operand**. This is the clause
  that cost a re-implementation when it was assumed instead of established (261j),
  and here it is a structural property of the emitter.

Contrast with the 261j defect, which is what makes the distinction legible: there the
recorded rail's chain was `cqrt_ry` — `cond(W) = ∅` and `W` not trivial on `|0⟩`, so
no amount of reverse-play returns it to `|0⟩`.

**Comment debt found here.** `IOSinkLowering.cpp:610-613` still carried the exact
sentence bd 261j(a) ruled false — *"`src` is PRESERVED (CNOT-class) so q stays
coherent and `src`'s own lineage uncomputes normally (Bennett)"*. 261j corrected four
copies; this was a **fifth**, on the emitter that mints the recording gate. Corrected.

### A record reaches a rail that is deliberately NEVER freed — `AbortParkEmit`

The positive precedent, and it predates the ruling. `AbortParkEmit` writes its flag
onto the tape (`cqrt_tape_write_i1(Tape, Flag)`) and then frees **nothing**: *"There
is NO flag strip (the park changed q, so `icmp_inv(q)` would not zero the flag) and
NO graveyard/flag free (Rule 6)."* It additionally inserts the flag into
`taint.GraveyardRails`, so the **spine** cannot free it either. That is the 261j
invariant, correctly applied and written down, before there was a name for it — and
it is why this module appears in the tape column and not in the free column.

### A record reaches a freed rail, and the free is sound — `BreakReversePlay.cpp:417-418`

This is urlv's flagged candidate, and the ticket's framing of it is **wrong on the
facts**. It reads: *"Sound today ONLY because all its frees precede the record —
emitter-incidental ordering, asserted nowhere."* Measured on a break-plus-`printf`
probe (`opt` rc=0), the emitted order is the opposite:

```
  copy_controlled(eqz, h, R)      ; consolidate
  cqrt_copy_i32(R, out)           ; THE RECORD                      (line 56)
  copy_controlled(eqz, h, R)      ; un-consolidate (self-inverse)
  <backward loop × n: the per-iteration adjoint C†>
  cqrt_free(R) ; cqrt_free(idx)                                     (lines 98-99)
  cqrt_tape_write_i32(tape, out)                                    (line 100)
```

The frees come **after** the record, not before, and the soundness does not rest on
ordering at all. `R` is a **Bennett scratch**: allocated at `|0⟩`, written only by
`cqrt_copy_i32_controlled` (a basis permutation conditioned on `h`/`idx`/`fire`),
copied out, then returned to `|0⟩` by an exact adjoint replay before the free. That
satisfies (a)–(d) for the same reason the IOSink flag does — `W` contains no
rotation. The user cannot introduce one: `R` is emitter-minted and unnameable from
source, and its only writers are the capture copies.

**What is still owed, stated honestly.** Stage 2b cannot *prove* it — it reports
`UNPROVEN U1-cross-stream` because the write history crosses a back edge — which is
why the five loop-break slices carry the documented `--allow-unproven` waiver. The
verdict above is an analytic argument, not a mechanical one. **The condition that
would break it is a rotation reaching `R`**, so any widening that lets one into the
capture path re-opens this entry. The CLAUDE.md calibration applies: the loop/break
surface produced over-accepts in three successive adversarial rounds, one of them
*after* the epic was closed as "Rule-13 cleared".

### A record CANNOT reach a freed rail

For the flag/work-rail emitters — `SwapRouteEmit`, `SwitchRouteEmit`,
`SwitchValueEmit`, `SwitchDataMuxEmit`, `SelectMergeEmit`, `NestedRouteEmit`,
`ClassicalCallArmEmit` — the reason is uniform, and is now written at each site:

> the rail is minted by this emitter, is `|0⟩` at mint, is returned to `|0⟩` by this
> emitter's own adjoint immediately before the free, and is **never an operand of a
> kept-carrier gate**: these emitters' copies write to a fresh `%out` and read from
> data rails they do not free, and **none of them mints a tape write** (only
> `IOSinkLowering` and `AbortParkEmit` do).

`BennettWrap` is excluded one step earlier: its `ScratchRails` live inside a Phase-6
**clone body**, which the spine never sees, and each is inserted into
`ControlOwnedRails` at the free site.

## What this audit does NOT establish

* It is an analytic audit, not a mechanical gate. Nothing here is enforced by a
  check; the protection is the written justification plus the per-site comments.
* It is a statement about **today's** emitters. The entry that most deserves
  re-running on any widening is `BreakReversePlay`, and the trigger to watch for is a
  rotation on a capture rail.
* It says nothing about the `cqrt_copy_<W>` **freeze** question — whether the
  copy-out surface needs 261j's treatment at all is bd 8gi5's open owner scope
  question, deliberately not decided here.

## Postscript — what the audit's own Rule-13 round added

The adversarial round on the free-PLACEMENT changes (bd uow0 repair + bd 8gi5/e4zs
anchors) turned up one thing this audit should carry, because it bears directly on
how much any verdict here is worth:

**`free_pairing_check.py` does not see a CROSS-BLOCK use-after-free.** Measured: on
a module where HEAD emits `cqrt_free(%h_op)` in `entry` and reads `%h_op` from a
`cqrt_tape_write_` in a successor block, stage 2b reports
`2 cqrt_free site(s): 2 verified, 0 violation(s)` and exits 0. Its F2 check reasons
over a straight-line stream, so a free and its later use in different blocks are
simply not compared. Where the fixed pass does return rc=1 on such modules it is via
`UNPROVEN U3-extern-rail` — an accident of block-local streaming, not detection.

That is worth writing down twice over. It is the second gate (after the golden
byte-diff and `opt -verify`) that cannot witness this defect class, so for anything
placement-related the lit `CHECK` ORDER lines are the only protection — and it is
the sharpest available argument for bd 261j(b), which owns exactly this checker.
