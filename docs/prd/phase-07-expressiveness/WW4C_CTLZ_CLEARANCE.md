# WW4C_CTLZ_CLEARANCE — Rule-13 adversarial round on the shift-count → `llvm.ctlz` idiom recognizer

**bd:** `ww4c.4` (Increment 3) · **Branch:** `ww4c-ctlz-idiom` · **Date:** 2026-08-22
**Subject:** `ir-pass/src/CtlzIdiomPrepass.cpp` + `ir-pass/include/CtlzIdiomPrepass.h`, the
Z1–Z9 fence and the §4.6 mutation, as landed by Inc 1 (`7385c4d`) and exercised by Inc 2
(`dc8f6c6`).
**Method:** 9 independent adversarial lenses, each prompted to **refute** a named claim, then
**27 independent skeptics** — one per substantive finding, each prompted to refute *that*, with
`REFUTED` as the default on non-reproduction. Analytic and trace-level reasoning plus
arithmetic sweeps; **no quantum simulation** (owner decision 2026-06-10). Style follows
[`WI7_SWITCH_CLEARANCE.md`](../../design/rssa-swap-control/WI7_SWITCH_CLEARANCE.md).

---

## 0. Verdict

**CLEARED, after fixing one real over-accept.**

| | count |
|---|---|
| adversarial lenses | 9 |
| findings raised | 71 |
| independently refuted (dropped) | **1** |
| **silent miscompiles found** | **0** |
| **over-accepts found** | **1 — fixed in this round (Z1(c))** |
| Rule-12 assertion-quality defects | 13 → all closed |
| doc-drift corrections | 17 → all applied |
| claims attacked and **survived** | 40 |

The round did what the ticket budgeted it for. `bd ww4c.4` opened with *"the loop campaign is
3-for-3 at finding over-accepts in adversarial rounds… assume this shape hides them too."*
**It did.** That record is now **4-for-4**, and — as with the `rwou` round on `y05j` — the hit
came **after** the increment had shipped green with 24 fixtures and a 5-lens Inc-2 round.

### The one that mattered

> **Z1's "TOP-LEVEL" test was a `LoopInfo` property, and `LoopInfo` models only NATURAL
> loops.** An **irreducible** cycle has no back edge, so `LoopInfo` reports no loop for it at
> all: `getParentLoop()` returns `nullptr` and `isInnermost()` returns `true` even when the
> idiom's header sits inside a cycle. Such a loop was **claimed**, placing the four emitted
> gates inside a cycle that re-executes them and re-allocates a rail on every traversal.

Fixed by **Z1(c)** — `isPotentiallyReachable(exit, header)` must be false — stated as CFG
reachability rather than a `LoopInfo` query *precisely because `LoopInfo`'s blindness is the
defect*, and deliberately **not** given `LI`, which would reintroduce it. Full account in §2.

---

## 1. Lens-by-lens verdicts

### L1 — whole-domain equality of the closed form (ticket claim #1) · **CLEARED**

The claim the ticket says the design dies on. It survived the hardest attack in the round.

* `f(v) = 1 + (ctlz_N(v << 1) & (N−1))` re-derived independently of PRD §4.1, then checked
  against a simulator of the loop **the fence actually admits** (not the C source):
  **~7.7 × 10¹⁰ compared pairs, 0 mismatches.**
* A second oracle **executed the literal emitted LLVM IR against the literal admitted loop IR**
  at `-O0` so nothing folded — the strongest form available, since it tests the construct
  rather than a model of it. 0 mismatches.
* The `(C0−1)` APInt wrap was probed at `C0 = INT_MIN`, the mask `N−1` at all four admitted
  widths, and the `sub` operand direction — all correct.
* **Both committed goldens were reproduced from an independent hand-rewrite** of the real
  openlibm stage-1 IR: byte-identical traces.

Independently re-measured by the main agent (`sweep.c`): **0 mismatches** at i8 and i16
exhaustively × 6 seeds; **exhaustive 2³² at i32 × 8 seeds** including `INT_MIN`/`INT_MAX`
(the spread that pins the `(C0−1)` wrap — Inc 1 swept one seed); i64 259 boundary + 20 M
random. `max f = N−1` at every exhaustive width.

> **The i64 row remains proof-plus-probe and MUST NOT be quoted as exhaustive** (PRD §4.2/§13).

### L2 — Z5 sufficiency, termination, and the mask-shift exclusion (claim #2) · **CLEARED**

* An **80-cell grid** (10 predicates × 2 successor orders × shl-in-op0/op1 × const 0/1) and a
  **1200-cell structural fuzz** each yield **exactly two** claimed cells:
  `icmp sgt <shl>, 0` on the true edge and `icmp sle <shl>, 0` on the false edge. Both denote
  the same program.
* Main agent's independent 20-cell grid reproduced this exactly: **2 of 20**, and every
  operand variation declines — `sgt 0, %sh` (swapped, semantically identical → an over-decline,
  correct), `slt 0, %sh`, `sgt %sh, 1`, `sge %sh, 1`, `sgt %sh, %sh`, `sgt %x, 0`, `sgt %dec, 0`.
* `getInversePredicate` confirmed **by measurement** to be the logical negation (`sgt`→`sle`),
  not the swapped predicate (`slt`) — via a discriminating cell that declines.
* Z3 + Z5 bound `f` by `N−1` at every admitted width, including `v < 0`, `v == 0`,
  `v == INT_MIN`, `v == 1`.
* **No spelling was found in which a divergent loop passes the fence.**
* Z5's `isZero()` clause is load-bearing on **real openlibm source**: `e_fmodf.c` ships an
  identical-looking loop four lines away that genuinely diverges.

### L3 — §4.6 leaves no orphan (claim #4) · **CLEARED**

The implementation deliberately does *not* use the PRD's collect-then-mutate `WeakTrackingVH`
worklist — it erases five values by pointer in dependency order with no traversal, on the
grounds that Z6 and Z7 pin the dead set exactly. **That stronger claim holds.**

* Every possible user of all five erased values enumerated under Z2–Z7; each has provably zero
  users at its `eraseFromParent()`.
* Corroborated by **128 generated CFG variants** (64 claims, 0 verifier failures), **13
  hand-built pathological CFGs**, and four exhaustive 2³² arithmetic sweeps of the guarded /
  inverted-polarity / chained shapes.
* Operand-bundle, `callbr`, `invoke`, unreachable-block and debug-record uses of the escaping
  counter are all rewritten correctly. `blockaddress`, `indirectbr`, duplicate header edges,
  `Exit == Preheader`, multi-block loops and two-out-of-loop-predecessor shapes all decline.
* **The dominance argument survives the `getLoopPredecessor` relaxation and is airtight**:
  LLVM requires a phi incoming to dominate its *predecessor's terminator*, and PH being the
  **unique** out-of-loop predecessor means every path into the header crosses that terminator.
  The multiple-successors relaxation is irrelevant to dominance. (Main agent reached the same
  conclusion independently.)
* Main agent measured that two of the ticket's named pathological CFGs are **structurally
  impossible on well-formed input**: a predecessor reaching the header via two edges is
  rejected by LLVM's own verifier (`PHINode should have one entry for each predecessor`), and
  a header that is the function entry block likewise (`Entry block must not have predecessors`).

### L4 — the over-accept hunt · **ONE FOUND** (see §2), otherwise **CLEARED**

~35 hand-built probes plus two automated differential grids — **2544 loop spellings** — with a
simulator of the original loop as oracle. Of 2544 mutated spellings **only the 5 legal ones
were claimed**; every claim matched the simulated loop on every probe value; no claimed loop
was non-terminating; no probe produced a crash, invalid IR, or a free-pairing violation.
Fan-out through a shared prefix, chained/adjacent/shared-entry multi-claims, dead escapees,
i8/i16/i64 link, guarded QROM, tainted diamonds, `blockaddress`, `invoke`, and
duplicate/unreachable predecessors all behaved.

### L5 — pipeline interaction · **CLEARED**

The one place the `LoopUnrollPrepass` analogy breaks: this fence and `tryCaseA`'s Q1 compete
for the same loops.

* **Ordering:** the ctlz fence and the unroll fence are disjoint on **three independent
  clauses** (U3, U5, U6 — each independently implied by Z8); measured as **zero unroll claims**
  across all 24 fixtures and both real slices.
* **Taint staleness:** `propagate` **rebuilds** the `TaintSet` from scratch, so the documented
  staleness cannot become a heap-address-reuse false positive. No dangling read, no iteration
  while stale.
* **Fixpoint:** terminates. Note the sharpened statement — a claim **can** create a new
  fence-passing loop, so the bound is **loop-count monotonicity**, not claim independence.
* **Twin-pipeline parity** is real and stronger than "same call in the same slot": the two
  entry points are behaviourally identical for this pass (and `runOnFunction` is a documented
  dead shim).
* **Q1 competition:** every near-miss lands on Q1's exact message; a claimed loop never
  reaches Q1; every decline-owner shift is loud → loud.
* **Downstream:** the "4 forward gates / 0 `_unc` / 0 `cqrt_free`" shape is the pre-existing
  **measured-lineage** disposition, **not** an orphaned-gate defect. Main agent confirmed:
  `free_pairing_check.py` is **PASS, strict, 0 unproven** on all six positive fixtures, and the
  three e2e slices pass with **no `--allow-unproven`** (PRD §7 item 4 discharged).
* A claim **can** create a stale-record hazard that did not exist before it — and
  `declineStaleRecordOps` catches it **loudly**.

### L6 — the `i1 false` immarg and PredMux flattening (claim #5) · **CLEARED, justification corrected**

* **The emission survives:** `CQ_SPEC_DBG=1` shows `call i32 @llvm.ctlz.i32(…, i1 false)` at
  **every** site, including both claims of `both_loops` and the real `ilogb.f64` slice.
* **The W7 clause-(e) characterisation survives verbatim**, isolated by control experiment
  (swap the `@llvm.ctlz` for an `lshr` and the same 2-incoming guarded module flattens, exit 0).
* Both real cells flatten through the `>2`-incoming disjunct; the quoted merge arities (6 and 4)
  are exact.
* **What broke — the RULE's stated MECHANISM.** Two lenses independently rebuilt both target
  cells with `i1 true` and measured them lowering **identically** (same exit code, same template
  count, IR differing only in `ModuleID`). So *"copying `i1 true` verbatim DECLINES the very
  cell this pass exists to unblock"* is **false**: the cells were never blocked on it, because
  their merges ride the `>2` disjunct and the poison-gated clause is never consulted (bd `ut09`).
  **`i1 false` is kept** — it is conservative, it is the honest spelling, and it keeps the chain
  admissible on any claim path that *does* route through that clause. Only the reason changed.

### L7 — Z8 byte-stability (claim #6) and the §1.1 honesty obligation · **CLEARED, attribution corrected**

* **Byte-stability holds by measurement, not assertion:** zero claims across **1357
  pre-existing modules** (1093 ir-pass fixtures + 245 CQ.h e2e sources + 19 classical lib TUs).
* **§1.1 honesty obligation genuinely discharged, both directions.** ACCEPT: a 400-cell sweep
  over width × seed × polarity × add-order × poison-flags × entry-provenance × enclosing-shape
  × function-name claimed **318/318** non-i128 cells and declined **82/82** i128 cells, with
  **zero sensitivity** to name, seed, enclosing shape or provenance. DECLINE: 10 constructed
  `ilogb`-resembling near-misses (including the divergent `sge 0` spelling) produced **zero**
  claims.
* Nothing in the tree is "one taint change away" from a silent claim — nothing in the tree has
  the shape at all.
* **What broke — the attribution.** Z8 declines **exactly one** loop in the entire tree, and it
  is `…_skip_classical.ll`, a fixture *this branch added*. Byte-stability is delivered **100 %
  by the structural fence Z1–Z7/Z9 and 0 % by Z8**. Four places said otherwise. This matters
  for one specific reader: whoever widens Z3/Z6/Z9 per §5.2 is the first person for whom Z8
  carries load, and the old sentence would have told them it was already settled.

### L8 — Rule-12 fixture audit · **13 defects, all closed**

Mechanically determined, by repair-until-claimed plus leave-one-out, how many independently
fatal clauses each of the 24 fixtures declines on.

**Survived:** 11 negative fixtures isolate exactly one clause; **all 16 negative CHECK lines
mirror the real diagnostic character-for-character**; fixture economy is clean (1 `cq-opt`
spawn each, 0 standalone `-passes=verify` lines); no probed clause over-accepts.

**Broke** — see §3.2 for what shipped in response.

### L9 — documentation drift · **17 corrections**

Every factual assertion in the header (171 lines), the `.cpp` (413), both `CQLoweringPass.cpp`
comment blocks, the PRD and all 24 fixtures was re-measured rather than trusted.

**Survived:** the closed form, the §4.2 table and the §4.3 worked example all reproduce; every
live source citation is accurate; the `nm -g` zero-new-frozen-symbols claim holds (extended to
all four Z9 widths); both `clang` idiom measurements reproduce; both transcriptions of "real IR"
are instruction-for-instruction accurate.

### L10 — adversarial verification of the findings themselves

**27 skeptics, one per substantive finding, each prompted to refute.** 26 CONFIRMED, **1
REFUTED** — and the refutation was load-bearing: a lens claimed PRD §4.3's *"no controlled copy,
no flag mint, no `cqrt_free`"* was contradicted by the goldens (10, 9 and 23 occurrences). The
skeptic reproduced every number, then showed the **inference** fails: §4.3 describes what the
**recognizer** emits, and all 10 controlled copies in `slice_libm_real_ilogb.expected.log` are
the *source's* 6- and 4-incoming return-phi merges decomposed. The recognizer emits zero merges.
**§4.3 was not edited.** This is the round's own evidence that the verify stage is not ceremony.

---

## 2. The over-accept, in full

### What was wrong

`CtlzIdiomPrepass.cpp` Z1 excluded nested loops with
`if (L->getParentLoop() || !L->isInnermost() || L->getNumBlocks() != 1) return false;`
and the comment above it states the stakes exactly:

> *"a nested one buys no target coverage and opens an unreviewed interaction class… turning a
> shape that declines loudly today (Q1, on the inner tainted exit) into an outer loop carrying
> tainted values across iterations, adjudicated by owners nobody looked at for this."*

`getParentLoop()` is a **`LoopInfo`** property. `LoopInfo` recognises only **natural** loops —
a back edge `u → v` where `v` **dominates** `u`. An **irreducible** cycle has no such edge, so
`LoopInfo` does not model it at all.

### The witness (shipped as `lowering_ctlz_idiom_reject_irreducible_cycle.ll`)

`entry` branches to **both** `%A` and `%B`, so neither dominates the other and the cycle
`A → pre → scan → out → B → A` is irreducible. LLVM agrees:

```
$ opt -passes='print<loops>' -disable-output witness.ll
Loop info for function 'irr2':
    Loop at depth 1 containing: %scan<header><latch><exiting>
```

Exactly one loop, reported at **depth 1** — top-level. Before the fix:

```
$ CQ_CTLZ_DBG=1 cq-opt -passes=cq-lowering -S witness.ll
CQ_CTLZ_DBG: claiming shift-count loop in @irr2 (i32, C0=i32 0)     EXIT=0
```

and the four-op chain landed **inside the cycle** — `shl`/`ctlz`/`and`/`sub` re-executed and
re-allocating a rail on every traversal, with the escaping counter available to an outer
accumulator.

### Why it is an over-accept and not a curiosity

**The A/B twin.** Changing `shl nuw i32 %w, 1` → `shl nuw i32 %w, 2` — **one token**, taking
the loop off-fence via Z3 — makes the **same module** decline loudly at Q1. So the recognizer
was converting a loud decline into a silent accept, which is the Prime Directive's one
unforgivable direction.

### The honest limits, recorded so this is never over-quoted

* **No wrong value was demonstrated.** Per visit to the header the substituted chain computes
  the same counter the loop would.
* **The hazard class is pre-existing.** Tainted arithmetic inside an irreducible cycle already
  compiles today, independently of this pass — measured. The recognizer did not invent it.
* **Two downstream guards catch the dangerous sub-case:** a tainted accumulator crossing the
  back edge declines at `cq taint escape: tainted value muxed by a classical-condition phi`.

The defect is that **the fence admitted a shape its own contract excludes and nobody reviewed.**
Under Rule 17 the intent was "TOP-LEVEL" and the implementation did not deliver it, so fixing it
is *building the intent*, not substituting a decline for work.

### The fix

```cpp
if (isPotentiallyReachable(Ex, H, /*ExclusionSet=*/nullptr, &DT))
  return false;
```

`H`'s only predecessors are `PH` and `H` itself (Z1/Z2), so **`H` is inside some larger cycle
iff control can get from the exit back to the header** — reachability is the exact test, not a
proxy. It is answered on the CFG, so it is blind to nothing, and `LI` is **deliberately not
passed**: `LoopInfo`'s natural-loop blindness is the entire defect. A genuine parent loop is
caught here too, redundantly with `getParentLoop()`.

**Red → green, measured:** witness claimed + exit 0 before; **no claim** + loud Q1 decline
after. **Non-regression:** all 32 ctlz fixtures green, and all four e2e slices — including both
real cells — still pass. The fix is a pure narrowing.

---

## 3. What changed in this round

### 3.1 Code (1 change)

| file | change |
|---|---|
| `CtlzIdiomPrepass.cpp` | **Z1(c)** — the irreducible-cycle clause; `#include "llvm/Analysis/CFG.h"`; `fencePasses` now takes `DominatorTree &` |

### 3.2 Fixtures (7 new, 8 rewired)

**New decline fixtures** — each isolated by a **verified delta pair** (a minimal edit that
flips the file from declined to claimed):

| fixture | clause it isolates |
|---|---|
| `…_reject_irreducible_cycle.ll` | **Z1(c)** — the over-accept above |
| `…_reject_counter_width_mismatch.ll` | Z9 same-width. **The sharpest of the five:** without it the emitter would build a cross-width `sub` and do a cross-type RAUW, both guarded in LLVM by `assert` **only** — and this toolchain builds with assertions **OFF** (`llvm-config --assertion-mode` → `OFF`), so the failure would be *silent malformed IR* |
| `…_reject_blockaddress_header.ll` | `hasAddressTaken` — no ctlz fixture contained the string `blockaddress` at all |
| `…_reject_dead_counter.ll` | Z7's **require**-the-escape direction |
| `…_reject_two_preds.ll` | Z1's unique-out-of-loop-predecessor clause — the one place the fence is deliberately **wider** than PRD §5 |
| `…_reject_escaping_counter_phi.ll` | Z7 on the counter **phi** (closed form `C0−(f−1)`, a *different* one) |

**New positive fixture:** `…_chained.ll` — two idiom loops in sequence where the second's entry
value is the first's escapee. It is the **only** assertion that the driver's re-propagate is
load-bearing: at the first call the escapee is classical, so Z8 fails for loop 2; only after
`propagate` re-runs does it become claimable. `…_both_loops.ll` could not witness this, because
its two loops are independent.

**Rewired positives (all 6 + 2 new).** Every positive asserted its chain with `%{{…}}` wildcards
— pinning symbols and literals but **not dataflow**. Measured: **three genuine miscompiles of
`c_exit` passed**, including the mask-drop, which breaks the design at exactly `v == 0` — the
one input the whole design rests on. `both_loops` was blind a second way: swapping which loop
each constant terminates also passed, because `CHECK-DAG` order-insensitivity is exactly what
hides that mutant. All positives now use FileCheck **captures**, and the assertions are
**mutant-validated**: 10 mutants constructed, every `sed` verified non-no-op, **10/10 caught**.

**The `i1 false` immarg is now pinned directly.** Nothing asserted PRD §4.5(1) — a rule the
header calls NOT OPTIONAL — because the lowered form the positives check has already had the
immarg dropped by Rule 15's width-only ABI. `env CQ_SPEC_DBG=1 … 2> %t.spec.ll` captures the
pre-`detectSpecializations` module on **stderr**, where `@llvm.ctlz` is intact; stdout is
**byte-identical** with the env var set, so this costs **no extra `opt` spawn**. The `IMMARG`
prefix pins all three emission rules at once — `i1 false`, the *absence* of `nsw`/`nuw` (the
`-NEXT` text is exact), and the type-derived mask — and is mutant-validated against both an
`i1 true` doctoring and an `nsw` reintroduction.

**`…_reject_derived_compare.ll` now isolates Z5.** Its body carried **seven** instructions, so
Z6 rejected it independently and the fixture could not prove what its header claimed. Comparing
the **phi** instead of the latch value costs no instructions: the body stays at six, Z6 passes,
and Z5 is the sole ground — proven by a **one-token** accept↔decline flip.

### 3.3 Documentation (17 corrections)

The load-bearing ones, all measured false as written:

1. **Emission rule 1's justification** — `i1 true` does *not* decline the target cells (§1 L6).
2. **`llvm.dbg.value` "declines"** — LLVM 19 auto-upgrades it to a `#dbg_value` record at parse
   time, so it never reaches Z6 as an instruction and the loop **is claimed**. Sound (records
   carry no semantics; LLVM's salvage turns the erased `%sh` into `undef` and the counter phi
   into its RAUW'd value, verify-clean) — but **Z6 is debug-blind by construction** and must
   never be quoted as declining anything on debug-info grounds.
3. **"Z8 keeps the suite byte-stable"** (4 places) — a misattribution (§1 L7).
4. **"Z8 must read the SAME settled taint the rest of the pipeline reads"** — false. Z8 reads a
   **strictly smaller** set, because argument taint is minted later by `detectSpecializations`.
   The measured consequence is a real accept-set boundary, now recorded (§4).
5. **"Z9's same-width clause is the one place this is NARROWER than PRD §5"** — false four ways,
   and **one of them is a WIDENING** (`getLoopPredecessor` vs "a unique preheader"), which is the
   direction that can actually hurt. The header now lists every divergence in both directions.
6. **`noEscapingUse`'s non-Instruction branch** is unreachable dead code — a Constant cannot use
   an Instruction, metadata uses go through `ValueAsMetadata`, and a `BlockAddress` names a
   block. It is kept as free defence, but its claim to "answer PRD §7 item 3" is withdrawn.
7. **The f80 mask-shift fixture said "FIVE axes, FOUR independently fatal"** — measured **seven**
   failing clauses, and the set is now **bounded**, not merely enumerated: repairing all seven
   makes the pass claim the loop, so no eighth is hiding. The three that were missing matter —
   the "what is shifted" row had no fence letter at all (it is enforced by **Z8**, not Z5), and
   Z6 and Z9 went unmentioned on the fixture the PRD calls the single most important in the matrix.
8. **PRD §10 demanded an unsatisfiable assertion** ("each positive must show … `i1 false`") and
   filed a `not` fixture under "Positive". Both amended; the requirement is now met by the
   `IMMARG` mechanism.
9. **PRD §5.5's "the negatives assert *that* message"** — false for two, and the exceptions are
   the interesting ones (a different loop owner; and the one fixture where the recognizer *does*
   claim and a different owner then declines).

---

## 4. Residuals — non-blocking, no shipped defect

Each is an **over-decline** (safe under the Prime Directive) or a pre-existing issue this round
merely made visible. None blocks clearance.

1. **Callee-hosted idiom is never claimed.** Taint arriving only through a call argument is
   invisible to Z8, because `detectSpecializations` runs *after* this fixpoint and never
   re-triggers it. Measured: loud decline `cq specialization: callee contains tainted control
   flow under quantum lift` on the clone. Coverage-limiting, safe, now documented.
2. **A single-incoming LCSSA exit phi over the escaping counter declines.** `liftOneRegisterMergePhi`
   declines `N < 2` **by design** ("a degenerate <2 phi is not a mux"), and the ctlz claim is what
   makes that phi tainted. **Not a regression** — the same module declined at Q1 before this pass
   existed. The real cells escape it because their escapees feed a **6-incoming** merge phi.
   Note the counter-intuitive shape: a *multi*-incoming merge works and a *single*-incoming one
   does not. Filed as **bd `rjxd`** (P3, no customer today).
3. **Narrow negative literals are corrupted in the linked trace** — `cq_template_sub_i16_lh(i16 -9, …)`
   prints **65527**, and `i8 -9` prints **247**. The pass emits the declaration without
   `signext`/`zeroext` while the generated C definition takes `int16_t`/`int8_t`; adding
   `signext` fixes it. **i32 and i64 are clean**, so both real cells are unaffected; it
   reproduces with **no loop at all**, so it is pre-existing and ctlz-independent. ww4c only
   made it *reachable* in a routine way (the closed form's `(C0−1)` is characteristically
   negative — every real `ilogb` seed is) and *invisible* (i8/i16 have no e2e golden). Filed as
   **bd `etj3`** (P2) — it corrupts the **trace**, which Rule 2 makes the contract.
4. **The i8/i16/i64 accept surface has no e2e link coverage.** Only lit pins those widths, which
   is why the capture rewiring above matters most there.
5. **bd `ut09`** (PredMux W7 clause (e) / caller merge-phi arity) stands, unchanged.

---

## 4b. Verification run — reporting only what was executed (Rule 19)

| gate | why it applies | result |
|---|---|---|
| **#5 — an accept/decline predicate changed** | Z1(c) is a new fence clause | **run** |
| **#2 — pre-push** | code, fixtures, goldens' harness and docs all changed | **run** |
| #1 — Rule-13 core commit | `CtlzIdiomPrepass` is not on the Rule-13 core file list, but **Rule 13 applies on its merits** and this document is that discharge | n/a by list, satisfied in substance |
| #3 — harness change | none (`ir-pass/test` fixtures are lit-discovered; no `CMakeLists.txt` moved) | not tripped |
| #4 — template regeneration | none — **zero new frozen symbols**, no YAML edit | not tripped |

```
$ cmake --build build -j8 && ctest --test-dir build -j6 --output-on-failure
100% tests passed, 0 tests failed out of 257
Total Test time (real) = 286.47 sec        (257/257, ir-pass-lit 1100 fixtures)
```

Additionally, and separately measured:

* all **32** `lowering_ctlz_idiom*` lit entries green;
* all **four** ctlz-touching e2e slices green — `libm-real-ilogb`, `libm-real-ilogbf`,
  `intrinsic-ctlz`, `ctlz-idiom-loop` — with stage-2b free-pairing **strict** (no
  `--allow-unproven`);
* `free_pairing_check.py` **PASS, 0 violations, 0 unproven** on the lowered output of all six
  positive fixtures;
* **10/10 fixture mutants caught** after the capture rewiring (each `sed` verified non-no-op
  before the check, so a no-op could not read as "caught");
* the over-accept witness: **claimed, exit 0 before** the fix; **no claim, loud Q1 decline
  after**.

The full suite was run **after** every code and fixture change. The only edits made after it
started were Markdown (this file, the PRD, `README.md`, `mathh.md`), which is Rule 19's
docs-only row.

---

## 5. What this clearance does **not** establish

* **No simulation was run** (owner decision 2026-06-10). The sweeps verify **arithmetic** and
  the goldens verify **traces**; neither is a statevector check.
* **The i64 row is not exhaustively verified.** Proof plus boundary/randomized probes only.
* **`opt -verify` clean is not evidence** (Rule 2) and was never treated as such here.
* **Clearance covers the shipped accept shape.** Every §5.2 widening (stride ≠ 1, step ≠ −1,
  non-empty body, escaping shift register, escaping counter phi, mixed-width counter, i128/i80,
  nested/irreducible placement) is **additive surface owed its own Rule-12/13 round**. Each now
  has a decline fixture; none has a lowering.
* **The 4-for-4 record is the operative fact for whoever widens this next.** Two of those four
  hits — `y05j`'s `rwou` round and this one — landed *after* the increment was green and
  reviewed. Budget the adversarial round up front; do not hope for it.
