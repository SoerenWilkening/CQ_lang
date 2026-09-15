# Track M — FILE SURFACE (report to the orchestrator, ahead of everything else)

Session 2026-09-15. Scoping only; no pass source edited, nothing built, no suite run.
ORACLE verified at start: `build/ir-pass/cq-opt` `0e280fc6…9c6d`,
`build/ir-pass/libCQPass.so` `94602c78…507b` — both match `PROTOCOL.md`.

---

## THE THREE ANSWERS, FIRST

### 1. File surface — **BOTH E2 AND E3 COLLIDE WITH THE HEADLINE (Group 1)**

| | E2 (bd `fve8`) | E3 (bd `yiid`) |
|---|---|---|
| `ir-pass/src/MeasureLowering.cpp` | **EDIT** (the clause, ~8 lines) | — (but see the note) |
| `ir-pass/include/MeasureLowering.h` | **EDIT** (comment at `:67-68` names the decline) | — |
| `ir-pass/src/TaintPropagation.cpp` | — | **EDIT** (`propagate`, the new normalizer) |
| `ir-pass/include/TaintPropagation.h` | — | **EDIT** (the record for the L1 re-ask) |
| `ir-pass/src/CQLoweringPass.cpp` | — | **EDIT** ×2 (the post-fixpoint re-ask, BOTH entry points) |
| `ir-pass/test/*.ll` | 1 inverted + 2 new | **≥21 edited** + 7 new (see §2) |
| `tests/e2e/*` | 0 | 1–2 new slices + goldens (tail anchor conflict) |
| `tools/`, `runtime/`, `include/CQ.h` | none | **none** — no ABI change, no new symbol (re-measured, §3) |

**Group 1 (the rail bank) is stated by the orchestrator to touch
`TaintPropagation.{cpp,h}`, `MeasureLowering.cpp`, `QramLowering.{cpp,h}`,
`RailBankPromote.{cpp,h}`, `CQLoweringPass.cpp`, `MergePhiPeel.cpp`.**

* **E2 ∩ Group 1 = `MeasureLowering.cpp`** — certain collision. E2's edit is inside
  `lowerMeasures`' branch (1), the same function any measure-side rail-bank work touches.
* **E3 ∩ Group 1 = `TaintPropagation.{cpp,h}` + `CQLoweringPass.cpp`** — certain collision,
  and not a mechanical one: E3 changes **what `propagate` returns**, which is the input to
  every stage the rail bank adds.

**⇒ By `PROTOCOL.md` S1, E2 and E3 are in GROUP 1. They cannot have their own gate.**
That is a topology fact, not a preference: S1's rule is "same file under `ir-pass/` ⇒ same
group", and both hit two of Group 1's six files.

### 2. Does E3 fit this session? — **NO. It is its own increment, and two owner questions come first.**

The *mechanism* is small and I will not pad it: **~40–70 production lines**, no ABI, no new
symbol, and its target stream is **already a shipped capability** (§3 below — every
explicit-re-seed twin ACCEPTS on the ORACLE, and one of them is byte-identical to the
relabelled module). Rule 17 cuts both ways and I am not inflating this.

The *cost* is not the mechanism. It is what the mechanism moves, and I measured it rather
than inheriting `IMPL_D.md` §14.6's figure:

| measured | number | instrument |
|---|---|---|
| fixtures holding a **DEFINITE** post-measure use (same block ⇒ dominance certain) | **22** | `probes/post_measure_ir_scan.py`, self-tested 7/7 |
| of those, fixtures whose verdict or stream **MOVES** under E3 | **21** | `probes/relabel.py` + ORACLE, 22 runs |
| — shipped **DECLINE → ACCEPT** | **15** | ″ |
| — shipped **ACCEPT → DECLINE** (a *regression*) | **1** | `control_angle_select_ry_alias_pre_gate` |
| — decline **string moves** to a different fence (fixture `CHECK` must be rewritten) | **2** | ″ |
| — **ACCEPT → ACCEPT with a MOVED STREAM** | **3** | lowered-IR body diff |
| modules with a cross-block post-measure use my instrument **cannot adjudicate** | **≤608** | upper bound, same scan |
| committed goldens whose stream moves | **0 of 383** | `probes/post_measure_trace_scan.py`, self-tested 6/6 |

Three of those rows are the reason for the verdict, and none of them is schedule padding:

* **One shipped ACCEPT becomes a DECLINE** (`control_angle_select_ry_alias_pre_gate`). E3
  turns a CHAINED theta into a SOURCE theta, and the folded **angle-select** classifier
  requires a quantum base — so `rotation angle under quantum control` fires on a program
  that lowers today. An "ACCEPT-only widening" that regresses a shipped accept is not one.
  `IMPL_D.md` §14 does not mention this shape.
* **E3 DELETES A USER-WRITTEN `cq_measure`, and it reaches the 7.6 OUTPUT TAPE.** Measured
  on two shipped fixtures: `lowering_stale_reader_chain_accept` loses `%m3 =
  cqrt_measure_i32(%h)` outright, and `lowering_io_tape_measure_then_tape` loses
  `cqrt_tape_alloc` + `cqrt_tape_write_i32` and emits a plain `printf` instead. §14.7's
  closing line anticipated it (*"decide that with 7.6, not here"*) — it now has a measured
  customer in the tree, and the 7.6 output-tape ABI is one of the five items the freeze is
  gated on. **This is an owner decision, not an agent one.**
* **The L1 round-2 obligation is real and undischarged.** `repropagateControlMerges` does
  **not** call `propagate` or `collectAndSeed` (verified: `TaintPropagation.cpp:1833-1887`
  rebuilds the FnSets by hand and calls `propagateWorklist` directly), so bd `z9t1`'s
  structural discharge — *"every propagate round re-asks it"* — **is false for the round-2
  fixpoint**. E3 owes an explicit re-ask in both entry points. That is the L1 PREDICATE
  species that has already produced one silent miscompile here (bd `9pum`).

**Recommendation:** E3 is **one increment of its own**, after the headline, opened by the
two owner questions (`SCOPE_M.md` §7). It is not a "bolt it onto Track M" item, and the
`GROUP 1` collision means it cannot even be gated in parallel.

### 3. Does E3 compose with E2, subsume it, or make it harder? — **COMPOSES; DOES NOT SUBSUME; MAKES E2 *STRONGER*.**

Measured, not argued:

* **No subsumption.** E3's relabel target is always a `@cq_measure_<sfx>` *result*, never an
  `undef`. It cannot create, remove or route around an `undef` at a sink. The direct
  spelling `_Bool b; return cq_measure(b);` declines on the ORACLE (`probes/src/e2a`) and
  would still decline with E3 alone.
* **E3 enlarges exactly the branch E2 edits.** Every post-measure `cq_measure(q)` becomes
  `cq_measure(m)`, whose operand is a measure result and therefore **never tainted**
  (`isMeasureSink`, `TaintPropagation.cpp:217-227`) — so it lands in `lowerMeasures`'
  CLASSICAL branch (1), the eight lines E2 rewrites. Measured on `m14b`: relabelled, it
  accepts at 6 trace lines with the second measurement lowered classically.
* **E2 makes E3 more consistent, not less.** E2's correct RAUW target is
  `Constant::getNullValue(Measure->getType())`, not the operand (`SCOPE_M.md` §1.3(c)). With
  that, a program that measures an `undef` and then re-reads the name gets **one** value at
  both sites. With the operand-RAUW spelling it would get `0` at the measurement and
  `undef` at the re-read.
* **Order:** land **E2 first** (8 lines, one file, one fixture inverted), then E3. The
  reverse order forces E2's refinement measurement to be retaken over E3's enlarged
  population.

---

## Attribution strings (for a group gate's per-track mover attribution)

* **E2 removes:** `cq_measure_<sfx> operand is an undef/poison literal; a classical
  measurement needs a defined value` — **for the whole-value `isa<UndefValue>` spelling
  only.** It **keeps** that string for the `ConstantExpr` / global-initializer residual
  (`SCOPE_M.md` §1.3(b)), so the string does **not** lose its last customer. Any mover on this
  string is E2's.
* **E3 removes (measured, 15 fixtures):** `cq controlled lowering: condition measured
  before the control route under quantum control`, `cq opcode lowering: rotation/measure
  operand predates a non-diagonal gate`, `cq rotation lowering: unsupported
  quantum-derived rotation angle`, `cq taint escape: tainted value stored to memory`.
* **E3 adds (measured, 3 fixtures):** `cq taint escape: tainted value muxed by a
  classical-condition {select,phi}`, `cq controlled lowering: rotation angle under quantum
  control`. ⚠ The last of those is the **A→D regression** — an unattributable-looking
  mover that is in fact E3's and must be declared up front or it reads as a group-gate
  finding.

---

## ⚠ Erratum, self-caught before hand-off

The first draft of this file and of `SCOPE_M.md` carried **"18 movers, 14 D→A"**. Both were
HAND counts off a 22-row table and both were wrong. Recomputed mechanically (the loop is in
`GATES.md`): **15 D→A, 1 A→D, 2 string-move, 3 stream-move, 1 unchanged = 21 movers of 22**,
and **18 of the 22 are negative fixtures**, not 17. Every number in these documents that a
reader might act on is now machine-counted; a table read by eye is not a measurement.
