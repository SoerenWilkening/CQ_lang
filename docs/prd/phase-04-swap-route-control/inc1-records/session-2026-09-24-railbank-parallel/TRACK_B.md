# Track B — bd `xdu2.1`: bank reads under the bd `3d8q` stale-reader fence

Session 2026-09-24-railbank-parallel. Tree `d0720cb1` (`cq-opt`
`c6f61f80a5d524c6`, unchanged by every commit of this track: the track's source
edits are comments only, and the rebuilt binary is bit-identical).

## 0. Verdict

> ⚠ **SUPERSEDED IN PART by §6b (Rule-13 round 2, F-1, a P1).** The paragraph
> below was true of every shape it measured. It was NOT true of the capability:
> a parked rail relabelled by an in-place `xor` that the ROLLED in-loop collapse
> commits was a live silent miscompile on this tree and on main `e36d9df4`. It
> is fixed by `staleReadOfValue`'s bank-load hop (§6b). "Nothing in this track
> changed a verdict" is now false: 9 probe programs move ACCEPT→DECLINE, all of
> them over-accepts.

**The P1 is ALREADY CLOSED on this tree, and nothing in this track changed a
verdict.** The fix the bead names (seed the fence with the parked rail name via
the bank's store, position-aware walk) landed in `95949550` (session
2026-09-15) as `railBankParkedRails` + the hop in `recordStaleQuantumReaders`
(`OpcodeLowering.cpp`), with the red half
`railbank_reject_measure_after_nondiagonal_on_parked_rail.ll` and the
register-twin gate `e2e-railbank-register-twin-decline`. The bead was never
closed. This track re-measured it against the xdu2.4 surface (runtime-sized
banks, conditional stores), added the pins that surface was missing, and
corrected two source comments that had become false (L7). **Recommend closing
`xdu2.1`**; the orchestrator owns that call.

## 1. Re-measurement (before any edit)

Harness: `trackB_probes/gen_probes.py` writes the probes and
`trackB_probes/run_probes.py` runs each one through clang `-O1` → `cq-opt` →
link → run → stage 2b and pairs `*.bank.c` with `*.reg.c`. 78 probe files. The
table shows the bank verdict, the register-twin verdict where a twin exists, and
the wall that fired.

| probe | shape | bank | register twin |
|---|---|---|---|
| s01 | **the bead's program** (fixed `int b[3]`, park loop, Ry, measure loop) | DECLINE, 3d8q string | DECLINE, 3d8q |
| s02 | same on **runtime `int b[n]`** | DECLINE, 3d8q | DECLINE, 3d8q |
| s03 / s04 | park loop, Ry, **const-index** `cq_measure(b[1])` (fixed / runtime) | DECLINE `array mixes a rail cell access with an unrecognized one` (the carve) | DECLINE, 3d8q |
| s05 / s06 | **straight-line park** `b[0]=b[1]=b[2]=q` (fixed / runtime) | DECLINE `tainted value stored to memory` (not a bank) | DECLINE, 3d8q |
| s09 | **`cq_theta` arg-0** of the stale parked rail, const index | DECLINE, carve string | DECLINE, 3d8q |
| s10 | `cq_theta(b[i])` arg-0 in a loop, runtime | DECLINE `unsupported reader of a rail-bank cell` (D5) | — |
| s14 | Ry **inside** the measure loop (stale from trip 2) | DECLINE `muxed by a classical-condition phi` | DECLINE `rail record read past an in-place gate` |
| s15 / s16 | park the **loop-carried** q, rotate it in the same loop | DECLINE, mux phi | DECLINE, 3d8q |
| s17 | `_Bool` cells, stale | DECLINE `consumed by an unknown callee` | DECLINE, 3d8q |
| s18 | relabel **before** the park (runtime) | DECLINE, 3d8q | — (twin-gate `p05` is the fixed one) |
| s26 | runtime-trip in-place **xor loop** on the parked rail, then read | DECLINE, mux phi | DECLINE, in-place gate |
| s28 / s29 | Ry under a classical / **tainted** condition between park and read | DECLINE (carve `cells no iteration writes`) | DECLINE, 3d8q / `stale rail record read past a controlled Ry` |
| s30 | **two banks**: per-cell-theta bank + a stale invariant bank | DECLINE, 3d8q | — |
| s31 | relabel in a `noinline` callee | DECLINE `callee contains a quantum primitive` | same |
| c01–c09 | **conditional parks** of an invariant rail (`if (i&1) b[i]=q`, selects, PASS-H spelling with an invariant) | all DECLINE (store-to-memory, mux phi/select, initializer) | — |
| h01 / h02 / h03 / g03 | the **conditional-prep** (xdu2.4 / grover) shapes whose in-loop rail ALSO ESCAPES the loop and is relabelled after it | all DECLINE: `condition predates a non-diagonal gate`, `control flow under quantum control`, and (g03, unconditional) the 3d8q string | h01's twin DECLINEs |
| h06 | conditional-prep bank BESIDE a stale invariant bank | DECLINE, 3d8q | — |
| s07 | legitimate order (measure, then Ry) | ACCEPT, 7 lines | ACCEPT, **identical** |
| s11 / s12 / s21 / s22 | **dtzb** `q = q + 3` / `q ^= 5` / add loop after the park, cells read after | ACCEPT, `cq_template_add_i32_hl` **out of place** | ACCEPT — **TRACE-MISMATCH**, see §2 |
| s13 / s27 | the same with `q+3` **measured first** (order pinned by a use) | ACCEPT, out of place | ACCEPT, **identical** |
| s19 / s20 | runtime per-cell theta, ± an unrelated register rotated between the loops | ACCEPT, 13 / 9 lines | — |
| s25 | a `cq_phi` (diagonal) between park and read | ACCEPT | ACCEPT, identical |
| h04 / h05 | the xdu2.4 conditional preps (seed path / PASS H), controls | ACCEPT, 47 / 65 lines | — |
| x01 | `example/grover/main.c` as written (runtime `n`) | ACCEPT, STRICT 2b `3 verified, 0 violation(s)` | — |

**No probe ACCEPTs where its register spelling DECLINEs, except s08 (§3).**
The hop reaches the runtime-sized bank (s02, s18) and the two-bank function
(s30, h06) with the 3d8q string; every other variant declines at an earlier
wall.

## 2. The dtzb axis — ⚠ "safe" WAS FALSE; see §6b

> ⚠ **CORRECTED 2026-09-24 (Rule-13 round 2, finding F-1, a P1).** This
> section originally claimed the in-place add/xor axis was safe for a parked
> rail. That was true only of the **M-C** minters (the straight-line and late
> conversions), which is all this section measured. The rolled in-loop
> **collapse** (`collapseRailPhisIn` → `markInPlaceRailOp`) is a different
> in-place minter with no G7(e) in front of it, and it accepted a stale bank
> read. `P1_bank.c`: `for(i) b[i]=q; for(k){ if(q>k) cq_phi(.3); q ^= 3; }
> for(i) cq_measure(b[i]);`. My probes s11–s13/s21/s22/s26/s27 did not reach it,
> because none of them put a tainted-condition region **and** an in-place op in
> the same loop (s26 declined at the mux-phi wall instead). What follows is
> kept as written and is correct **for the M-C minters only**. §6b has the fix
> and the full list of minters.


The fence walks for `cq_theta_` gates and not for an in-place `add`/`xor` (bd
`a3z7`'s vocabulary gap). So for a parked rail the only thing standing between
M-C's late in-place conversion (`inPlaceFenceHolds`) and a stale bank read is
that conversion's own refusal. Measured: it always refuses. The reason is
**G7 clause (e)**: the parking `store` is a plain-IR user of the parent, and
`priorUseIsSettled` returns false for any non-call user. (When the store comes
after the site, G6 refuses it instead.) Mutant M7, which lets (e) admit a
`StoreInst`, turns s13 into `cqrt_addc_i32(%h, 3)` followed by bank measures of
the relabelled rail: the unforgivable class. It is killed by the new
`railbank_stale_accept_parked_parent_add_stays_out_of_place.ll`, by matrix twin
22/23 and by twin-gate row `p10`.

`ArithLowering.cpp`'s retirement trigger claimed this "cannot" arise because
"D5 admits only a measurement … so there is no reader after the conversion".
**That was false**: a bank measure is exactly such a reader, and s13 is plain
`-O1` C. The comment is corrected at the source and now names G7(e) as the
refusal. It also restates the trigger: if G7(e) ever admits a store, this
absence and the vocabulary gap compose.

The s11/s12/s21/s22 TRACE-MISMATCH is not a compiler divergence. In the bank
spelling `clang -O1` sinks the out-of-place add below the measure loop, but not
in the register spelling. The two streams differ only in where one
`cq_template_add_i32_hl(h0,3)->h1` sits relative to measures of `h0`. That is a
computational-basis copy that commutes with them. These pairs were **not** added
to the twin-gate corpus (P2 would fail on `-O1` scheduling). `PAIRS.md` records
why, and s13/s27 are the order-pinned replacements.

## 3. A finding outside this bead: s08 (report, not fixed)

s08 is the runtime-sized legitimate order: park, then measure loop, then Ry,
then measure. **The bank ACCEPTS and the register spelling DECLINES** with
`cq uncompute: gate applied to handle after measurement` (FreePoint's
post-measure rule). Under the register-twin gate's P1 that is a VIOLATION.
However, the **fixed-size straight-line register twin s07 ACCEPTS the same
stream** (`ry(.5); measure×3; ry(.7); measure`). So the register side
disagrees with itself: the post-measure rule fires on a loop-carried measure
and not on a straight-line one. It is bd `yiid`'s boundary (`cq_measure` is not
a wire event) meeting FreePoint's policy, and it is not a stale read. The rail
is never freed (`0 cqrt_free site(s)`), so Rule 6 is not engaged. **Not added
to any corpus.** Adding it to the twin gate would turn a policy inconsistency
into a red gate, and pinning the bank accept would harden an unruled boundary.
It is owed a filing (suggest: under `yiid`).

## 4. Source-mutation matrix

Harness: `trackB_probes/mutate.py`. It applies each mutant as one exact
replacement (it asserts exactly one match), rebuilds `CQPass`+`cq-opt` at
`-j3`, runs ONLY the owned tests, then restores with `git checkout -- <file>`.
The owned tests are: lit `railbank_stale|stale_reader|reader_predates`, the
matrix runner on `railbank_stale_matrix.c`, and the twin gate. **KILLED means a
failing owned test.** An OVER-DECLINE that the twin gate only prints does not
count. The raw log is `trackB_probes/mutate.log` (first run, M1–M9). M0 and M6
were re-run after matrix row 32 was added. After every run the binary was
restored to `c6f61f80a5d524c6`.

| mutant | what it breaks | result | detected by |
|---|---|---|---|
| **M0 null** | a comment | **0 detections** — lit 21/21, matrix 29 (then 30) cases 0 failures, twin rc 0 | — (control) |
| M1 | the hop ignored (seed = the load) | **KILLED** | 4 new reject fixtures; matrix rows 1, 2, 10, 12, 13, 16; twin `p01`/`p05`/`p08`/`p09` |
| M2 | constants admitted as seeds | MISSED | no subject: no accepting bank stores a constant (the zero initializer is a `memset`; PASS G's `false` is a phi incoming, not a store) |
| M3 | round-2 delta keyed on `Rec` only | MISSED | no constructible subject (the source says so: a `%out` rail reaches a bank store only through in-loop tainted control, which declines earlier) |
| M4 | self-exemption granted after a hop | MISSED | no subject: only a `cq_measure` can hop (D5 refuses a `cq_theta` arg-0 bank read, s10), and a measure is never a `cq_theta_` reader |
| M5 | the hop does not follow the GEP tree | **KILLED** | same set as M1 |
| M6 | no storage-cast peel (`_Bool` seed = the `zext`) | **KILLED** (re-run) | matrix row 32 (bool per-cell capability over-declines). The first run only showed the twin gate PRINTING a `p03` over-decline, which does not fail it, so row 32 was added to catch it |
| M7 | G7(e) admits a `StoreInst` (M-C converts the parked parent in place) | **KILLED** | `railbank_stale_accept_parked_parent_add_stays_out_of_place.ll`; matrix twin 22/23; twin gate `p10` (rc 1) |
| M8 | backward closure: every non-constant phi/select incoming of a seed added as a seed | MISSED | no subject. It is the closure the old retirement trigger said was "owed", and it moved nothing, including the two shipped conditional-bank shapes (rows 30/31). Recorded at the source as "free on what was measured and pinned by nothing"; **not shipped** (Rule 12 (c)) |
| M9 | the reader policy bit flipped to `RequireEmitDominance=true` | **KILLED** | `lowering_stale_reader_exclusive_arms_accept.ll` only (a pre-existing fixture inside the owned filter). No bank row moves, as the hop comment predicts ("the hop moves the SEED and nothing else") |

**Denominator: 9 non-null mutants, 5 KILLED, 4 MISSED (M2, M3, M4, M8), each
with a stated no-subject reason.** No new conjunct was added, so none of these
is a new-code mutant. They mutate the existing hop plus the one M-C clause the
corrected comment now cites.

## 5. What changed

* `ir-pass/test/railbank_stale_reject_{runtime_bank_measure_after_ry,runtime_stale_before_park,second_bank_invariant,condprep_beside_invariant_park}.ll`
  — declines, each with the 3d8q string verbatim and the `not` inversion.
* `ir-pass/test/railbank_stale_accept_{parked_parent_add_stays_out_of_place,runtime_percell_sibling_rotated}.ll`
  — accepts with IR `CHECK`s, one prefix per count, and pure negatives.
* `tests/e2e/railbank_stale_matrix.c` + `.cases.json` — 30 rows (17 declines,
  13 accepts, 4 linked byte-compared twins), registered as
  `e2e-railbank-stale-matrix`, one line at the end of `tests/e2e/CMakeLists.txt`.
* `tools/railbank_twin_pairs/p09`–`p12` + `PAIRS.md` rows.
* Comments only in `ir-pass/src/ArithLowering.cpp` (the G7(e) correction) and
  `ir-pass/src/OpcodeLowering.cpp` (the conditional-store trigger fired; the
  re-derivation). `CODE_MAP.md` regenerated (line numbers only).

Red-green: the fence predates this track, so the red half of every new decline
fixture is shown by mutant M1/M5 (the hop disabled), not by an older binary.

## 6. Owned test results (as run, final binary `c6f61f80a5d524c6`)

* `lit ir-pass/test --filter 'railbank_stale|stale_reader|reader_predates'`: 21 (22 after §6a)
  discovered, 21 (22) passed.
* `ctest -R '^e2e-railbank-register-twin-(decline|selftest)$|^e2e-railbank-stale-matrix$'`:
  3/3 passed. Twin gate: `12 pair(s) checked, 0 VIOLATION(s), 0
  TRACE-MISMATCH(es), 0 over-decline(s)`. Matrix: `30 case(s): 13 accept, 17
  decline; 4 twin(s); 0 failure(s)`.

## 6a. Rule-13 round 1 P3 items (after merge `33f8bcdb`), fixed on top of `a153a259`

* **Item 2: the rolled-loop in-place relabel path.** `tryCaseA`'s CLOSURE
  (`LoopLowering.cpp`) refuses any non-rail user of a rail member. The bank
  store (or its storage cast) is such a user, so a parked `q` never becomes a
  rolled in-place rail. Neither `staleRailRecordRead` (it groups per root mint,
  and a bank load has none) nor the memory hop (its vocabulary is `cq_theta_`
  only) asks this question. A RETIREMENT TRIGGER is now written at that clause.
  The review's probe `e1_bank` is **matrix row 33**, a decline measured at the
  mux-phi wall. It is distinct from row 11 (a runtime-trip xor loop), because
  e1's trip count is fixed at 3 with unrolling disabled.
* **Item 3: the `ArithLowering.cpp` overstatement.** The claim "every bank rail
  has its store as a user" is replaced: the non-call user is the `store` on an
  `int` bank, or the storage `CastInst` on a `_Bool`/widening bank. The trigger
  now reads "admits a `StoreInst` OR a storage `CastInst`".
* **Item 4: accept rows 28–32 pinned only the verdict.** Now:
  * **28, 29, 31, 32** are **byte-compared twins** (matrix twins 28/40, 29/41,
    31/42, 32/43), linked and run. 31/42 drops the one identity line
    `cqrt_ry_i32(h0, 0x0p+0)`, the same convention as dynamic-matrix twin 14/17.
  * **30** (the seed-path conditional prep) **cannot be a byte twin**. Its flat
    twin emits the same gates, but the rolled form mints the prep rail before
    the `icmp sgt` flag and the flat form mints it after. A fresh `|0⟩` alloc
    commutes with that compare, so the circuits are equal, but the handle
    numbering permutes (checked by `diff`; this is the only difference). It is
    pinned instead by the new lit fixture
    `railbank_stale_accept_runtime_condprep_gate_order.ll`, which fixes the
    per-trip order alloc → flag → controlled Ry(flag, seed) → strip → free, the
    data select reading the seed rail, and the store. It also pins that each
    bank measure reads a cell load, and that the seed is never freed.
  * Controls:
    * `trackB_probes/twinctl.py` pairs rolled row 30 with the wrong twin, and
      the runner reports `TWIN 30/41` failing (rc 1).
    * `trackB_probes/fixctl.py` runs 4 IR mutants against the new fixture: a
      different module, control/target swapped, alloc after flag, and a seed
      `cqrt_free`. **All 4 are caught**, and the unmutated module passes every
      prefix.
  * Stage 2b is not re-run per row by the matrix runner. The row-30 and row-31
    accepts measured STRICT `0 violation(s)` by hand (§1).

## 6b. Rule-13 round 2 finding F-1 (P1): the collapse path, and the fix

**The defect (pre-existing on main `e36d9df4`, re-measured on this branch
before the fix, `cq-opt` `c6f61f80a5d524c6`).** Reviewer probes `P1_bank.c`,
`P1_bank_ry.c`, `P1_bank_fixed.c` and `r_qx{33,3n,k3,kn}_bank.c`, plus my
`t3_fixed_const_trip`, all ACCEPT with STRICT 2b clean. `P1_bank` emits
`ry(h0); [flag; rz_i1; strip; free; cqrt_xorc_i32(h0,3)] ×3; measure(h0) ×4`,
so the bank measures observe `q^3` where the source says `q`. Every register
twin DECLINES with `cq loop lowering: rail record read past an in-place gate on
the same rail`. Probe corpus: `trackB_probes/collect2.py` (34 files, 11 pairs).

**Mechanism.**
1. The reader fence's memory hop (`railBankParkedRails`) runs before
   `lowerLoops`. It walks for `cq_theta_` gates, and the in-place `xor` does not
   exist as a gate until the collapse commits it.
2. The collapse's own fence, `staleRailRecordRead` → `staleReadOfValue`,
   enumerates the parked value's SSA users. It finds the bank STORE, which comes
   before the loop, so no gate lies between the def and that "read". It never
   sees the cell LOADS.

**Fix (Rule 14: no second spelling).**
* `RailBankPromote`: the bank address-tree walk is now ONE function,
  `forEachBankCellMemop`, used by both directions. On top of it sits
  `railBankCellReadsOf(V, Loads)`: the forward hop read backwards. "V is parked"
  is decided by the same `bankStoreRailValue` relation (a direct store, or a
  store of the storage cast), and every cell load of every such bank is
  returned.
* `LoopLowering::staleReadOfValue`: before the SSA-user loop, each such load is
  asked `railGateBetween(Def, Load, Gates, Refreshes)`. That is the same walk
  and the same refresh bit an SSA read gets. The load's single user (the
  measure) is named for the diagnostic, which is the string the register twin
  gets. This only adds read points, so it can only add declines. It sits at
  both call sites (`tryCaseA` and the round-2 collapse), because both call
  `staleRailRecordRead`.
* Why here and not by widening the reader hop's vocabulary: at the reader
  fence's slot the in-place op is not yet committed (`taint.InPlaceRailOps` is
  filled by the collapse), so widening it would ask a prediction. This fence
  asks at the site that is about to commit, with the op already in `Gates`
  (`collectRailGates` counts it). That is L1's cure: "ask at the site".

**Every in-place minter for a parked rail, and what refuses each (L2/L3):**

| minter | site | what refuses a parked parent / a later bank read | evidence |
|---|---|---|---|
| M-C straight-line (`classifyInPlaceReassignment` → `inPlaceFenceHolds`) | `ArithLowering.cpp` | G6/G7(e): the park `store` or storage cast is a non-call user of the parent; G5 refuses in-loop sites | mutant M7 (round 1): killed |
| M-C late conversion (`lateReassignShape` → `inPlaceFenceHolds`) | `ArithLowering.cpp` | same G6/G7(e) | M7 |
| `commitOutOfLoopInPlaceOps` | `LoopLowering.cpp` | calls `classifyInPlaceReassignment`, so the same G6/G7(e) | argued (same function), not separately mutated |
| `tryCaseA` Case A | `LoopLowering.cpp` | its CLOSURE refuses the store as a non-rail user, **and** `staleRailRecordRead` (now with the bank-load hop) | `e1_bank` matrix row 33; comment corrected |
| rolled collapse `collapseRailPhisIn` | `LoopLowering.cpp` | **only** `staleRailRecordRead`; before this fix, nothing | **F-1**; now matrix rows 34–37, fixtures `railbank_stale_reject_inloop_xor_*`, twin rows p13–p15 |
| 7.4 break (`emitBreakForward`) | `LoopLowering.cpp` | (E15): the rail mint may be read only by the rail phi and the escape phi, so the park store is refused | **`f1_break_bank` ALONE** declines `early break body is not a provable rolled single-rail loop` (its twin too); the gate that fires was read, not mutated. ⚠ **Corrected by round 3 (F-R3-2):** the reviewer's `c4_break.c` does NOT go through this minter. `-O1` merged its break into the loop's single exit, so it lowered through the rolled collapse and declines at `staleRailRecordRead`. The E15 claim rests on `f1_break_bank` only |

**Measured after the fix (`cq-opt` `427492b12c4162e2`).**
* All 7 reviewer bank probes, plus `t3`, DECLINE with the twin's exact string.
  `P1_legit`, `t4_legit_fixed` and `t5_legit_ry` still ACCEPT.
* A/B of the pre-fix binary against the new one (`trackB_probes/ab.py`) over
  every `ir-pass/test/*railbank*.ll` and every accepted-probe stage-1 module
  (133 modules, including `example/grover/main.c`, `h04`/`h05`, all accept
  controls):
  * The null control (base vs base) runs first: **0 movers of 133**.
  * The A/B: **8 movers of 133**, all ACCEPT→DECLINE, and all are the intended
    F-1 shapes. **0 stream moves on any accept.**
* Red-green (`trackB_probes/redcheck.py`, `trackB_probes/mutate2.log`):
  * On the pre-fix binary the 3 new reject fixtures FAIL (rc 0) and the legit
    fixture PASSES.
  * The matrix run against the pre-fix binary fails exactly rows 34–37.
  * After the fix, all pass.

**Round-2 mutation matrix** (`trackB_probes/mutate.py`, owned tests only, the
null mutant first; the final full run is `trackB_probes/mutate3.log` on the
binary with hash `427492b12c4162e2`, restored after every mutant).

| mutant | what it breaks | result | detected by / why missed |
|---|---|---|---|
| **N0 null** | a comment | **0 detections**: lit 27/27, matrix 42 cases 0 failures, twin rc 0 | control |
| N1 | the bank-load hop removed | **KILLED** | 4 `inloop_xor` reject fixtures; matrix rows 34–37 and 44; twin rows p13–p16 |
| N2 | `railBankCellReadsOf` ignores a storage-cast park | MISSED | **no subject reaches it**: every cast-parked shape I built declines earlier (`_Bool` cells: `tainted value consumed by an unknown callee`; `short` into `int b[n]`/`int b[3]`: `unsupported reader of a rail-bank cell`; `short b[n]`: `array element is not a reversible…`; probes t1, u2–u4). The conjunct follows the forward hop's `bankStoreRailValue` so the two directions agree (Rule 14), not because a program needs it today |
| N3 | the diagnostic names the load, not the measure | MISSED | location only: `!dbg`-free fixtures print `<unknown>:0:0` either way. Cosmetic, not a verdict |
| N4 | the bank read ignores the def-refresh cut (`false`) | MISSED | no subject: every parked value in reach is defined OUTSIDE the relabel loop, so the refresh bit is irrelevant. An in-loop park of a relabelled rail declines earlier (`muxed by a classical-condition phi`: s15/s16/c04/c05) |
| N5 | the bank read always cuts at the def (`true`) | MISSED | same reason as N4 |
| N6 | the shared address-tree walk does not follow GEPs | **KILLED** | the forward hop's fixtures too (11 lit reds): the one walk serves both directions, which is what Rule 14 asked for |
| N7 | only the FIRST cell load is asked | **KILLED** only after a new row was added | the first run missed it. The fix was fixture `…_read_before_and_after.ll`, matrix row 44 and twin p16: the bank is read before the xor loop (legit, first load) and after it (stale). **That program was a 4th live over-accept on the pre-fix binary** (it accepts there and declines now) |

**Denominator: 7 non-null mutants, 3 KILLED, 4 MISSED (N2–N5), each with a
stated reason.** N7 was first MISSED; the missing fixture it exposed was a real
over-accept.

⚠ **An instrument failure I caused and caught.** My first run of the new row
gave it matrix id 42, which collided with twin row 42. The JSON sidecar is a
dict, so it silently kept one entry. The **null-control mutant then reported
KILLED**, because the pure-comment mutant produced "failures". That is the null
control doing its job. The generator now asserts unique ids. The shared runner
`run_railbank_dynamic_matrix.py` still accepts a duplicate key silently (Python
`json` last-wins). I own the sidecar, not the runner, so this is reported rather
than fixed.

## 6c. Rule-13 round 3 finding F-R3-1 (P1): the park AFTER the in-place op, and the refresh cut

**The defect** (pre-existing on main, on preA/preD, and on my round-2 binary
`427492b12c4162e2`, all re-measured by me): `for(k){ if(q>k) cq_phi(.3); q ^= 3;
b[k] = q; } for(i) cq_measure(b[i]);`. The reviewer's
`a1`/`a3`/`b4`/`b5`/`b7`/`e1_fixed_const`/`e2_slice` all ACCEPT, and every bank
measure reads the FINAL wire. The hand-unrolled register twin `a1_reg_unrolled`
accepts with a correct out-of-place stream.

**Mechanism** (the reviewer's, confirmed by mutant N4): my round-2 bank hop
reused `Refreshes`. `Def` is the in-loop xor, `recordRefreshedByDef` is true,
and `railGateBetween` cuts every path that re-runs `Def`, so `xor → exit → load`
is gate-free. "Re-running Def refreshes the NAME" is true for SSA and false for
a CELL, because cell k keeps activation k's value. This is L2 exactly: the
refresh cut is the other set computed over the same closure. **My §4/§6b claims
that N4/N5 had "no subject", and that an in-loop park of a relabelled rail
"declines earlier (mux phi)", were FALSE.** They held only when the park
precedes the op (`a2`), which is all I built.

**Fix 1 (the collapse fence):** `staleReadOfValue`'s bank hop passes
`DefRefreshes=false`.

**Fix 2: the FORWARD hop has the same flaw, and it was reachable.** The reader
fence (`railBankParkedRails` → `findNonDiagonalWireGate`) grants through leg 2
(`recordBarrierCutsPath`) on the premise "executing the seed's def
re-establishes the record". For a cell that premise is false. New probes
(`trackB_probes/gen5.py`):
* v1: `if(r>k) cq_phi; q = cq_theta(q,.3); b[k] = q;`
* v2: `if(r>k) q = cq_theta(q,.3); b[k] = q;` (in-loop controlled Ry)
* v4: v1 plus an xor
* v7: `_Bool` condition, controlled Ry

All four ACCEPT on main and on round 2, with every cell reading the final wire.
`findNonDiagonalWireGate` now takes `SeedIsCellRead` (default `false`, so every
other caller is byte-unchanged). When it is true, only leg 1 may grant, and
`recordStaleQuantumReaders` passes `Hopped`.

**Isolation** (`trackB_probes/iso_forward.py`, three binaries built and then
restored):

| binary | v1 | v2 | v4 | v7 |
|---|---|---|---|---|
| collapse hop off, `SeedIsCellRead` off (the pre-fix forward hop) | ACCEPT | ACCEPT | ACCEPT | ACCEPT |
| collapse hop off, `SeedIsCellRead` on | ACCEPT | DECLINE (3d8q) | DECLINE | DECLINE |
| final | DECLINE | DECLINE | DECLINE | DECLINE |

**The v1 residual, stated rather than fenced.** In v1 the seed IS the
relabelling gate's own next dynamic instance (`%24 = cq_theta(%20)`,
`%20 = phi(%8, %24)`). The walker does not return the seed as its own staler,
so the forward hop alone misses it. It is the cell analogue of
`readerStalesItself`. It is caught by fix 1 (the collapse fence), because a
chained in-loop `cq_theta` parked into a bank is only lowerable through the
collapse:
* `tryCaseA`'s CLOSURE refuses the store user;
* the 7.4 break's (E15) refuses a non-phi mint reader;
* the iteration-local rolled rail is freshly minted each trip (v8/v9 decline).

**RETIREMENT TRIGGER** (also written into `WireWalk.h`'s `SeedIsCellRead`
note): the day a loop path other than the collapse admits an in-loop chained
`cq_theta` whose result is parked, give the forward hop a self-staling check.
I did not ship that check, because no owned test can pin it (Rule 12 (c)); the
same is true of `SeedIsCellRead` itself, see below.

**Measured.**
* **Red-green** (`trackB_probes/redcheck.py`):
  * The 3 new reject fixtures (`railbank_stale_reject_inloop_{xor,sub}_park_after_op.ll`,
    `…_add_park_after_op_slice.ll`) FAIL (rc 0) on `427492b1` and PASS on the
    final binary.
  * The new green `railbank_stale_accept_inloop_xor_park_outofplace.ll` passes
    on all three binaries.
  * Matrix rows 45–50 fail on `427492b1` and pass on the final binary.
  * Rows 51/52 are green controls: the parked `q^3` stays out of place (`w1`),
    and the same-trip read (`g2`) is forwarded by the promoter.
* **A/B**, `427492b1` vs final (`trackB_probes/ab.py`, log `ab3.log`), over
  every `*railbank*.ll` fixture plus every probe stage-1 module, including all
  48 reviewer round-3 programs and the accepted controls (`P1_legit`, `c1`,
  `f1`, `g2`, `g4`, `x01` grover main, `h04`/`h05`):
  * Null control first: **0 of 358**.
  * A/B: **31 movers, 15 unique programs, all ACCEPT→DECLINE**. They are the
    reviewer's 7, my `v1`/`v2`/`v4`/`v7`, `w2` (the in-place twin of `w1`), and
    the 3 new fixtures.
  * **0 stream moves on any accept.**
* **Over-decline, filed rather than hidden:** `a1`/`w2` (twin row `p17`). The
  hand-unrolled register program is a valid circuit that emits out-of-place
  copies. The bank spelling now declines. Realizing it needs the collapse to
  keep a parked in-place op OUT of place (a copy-out), which is a lowering
  change, not a fence change. The twin gate prints this as `OVER-DECLINE`
  (counted, not failed).
* **Stream-level twin (the reviewer's suggestion), attempted and not
  byte-comparable.** `w1` (the out-of-place accept) against its hand-unrolled
  register twin: `-O1` folds the unrolled xors ACROSS iterations
  (`q^6^3 → q^5` template chains). The rolled form keeps one `xorc 6` per trip.
  Both are correct by hand, and the streams differ. So `w1`'s order is pinned
  by a lit fixture instead. (The IV-compare variant `g4` also differs, by an
  `i64` sext `-O1` introduces only in the rolled form.)

**Round-3 mutation matrix** (`trackB_probes/mutate.py`, log `mutate4.log` plus
`mutate5.log`; restored binary `7bbcdd9839f7de8f`):

⚠ **The first run's null control FIRED.** My harness counted twin-gate
`OVER-DECLINE` lines as failures, and `p17` is an over-decline by design. The
harness now counts only `VIOLATION`/`TRACE-MISMATCH`. N0, N2, N3, N8 and N9
were re-run under the fixed harness. The other mutants were killed by
lit/matrix failures, which do not depend on the fix.

| mutant | result |
|---|---|
| N0 null (re-run) | **0 detections** (lit 31/31, matrix 50/0, twin rc 0) |
| N1 hop removed | KILLED |
| N2 cast-user park ignored | MISSED — no subject (every cast-parked shape declines earlier) |
| N3 name the load | MISSED — location only |
| **N4 refresh cut reverted to `Refreshes`** (the round-2 code) | **KILLED**: 3 new lit fixtures, matrix rows 45–50 |
| N5 refresh cut forced `true` | **KILLED** (same) |
| N6 walker skips GEPs | KILLED |
| N7 first load only | KILLED |
| N8 `SeedIsCellRead` never set | MISSED — **shadowed**: every shape it catches is declined first by the collapse fence (fix 1) in the same pipeline; its effect is measured only by the isolation binaries above |
| N9 leg 2 kept for cell reads | MISSED — same shadowing |

**Denominator: 9 non-null mutants, 5 KILLED, 4 MISSED** (N2, N3, N8, N9), each
with a stated reason. N8 and N9 are defence in depth for the reader fence. They
are kept because they correct a false premise in a live fence and are
measured reachable in isolation. That is a judgement against my own round-1
rule (I did not ship M8 for being unpinnable). The difference is that M8 moved
nothing even in isolation, while N8 moves three programs.

## 7. NOT tested here (belongs to the merge gate)

**After §6b the verdict-affecting source DID change** (`LoopLowering.cpp`,
`RailBankPromote.{h,cpp}`; `cq-opt` `427492b12c4162e2`). The full `ir-pass-lit`,
every `e2e-slice-railbank-*`, `e2e-railbank-dynamic-admission-matrix`, the corpus
A/B, cq-opt-equivalence and the loop-twin matrix are therefore OWED at the merge
gate. What I ran instead:
* The hand A/B over every `*railbank*.ll` fixture plus 64 accepted-probe
  modules, with a null control (§6b).
* The owned tests.

The inference "only rail-bank modules can move" rests on this: the new code
runs only when `railBankCellReadsOf` finds a `!cq.railbank` store of the value.
That is argued from the code, not measured over the corpus. Also not attacked:
* a parked rail relabelled inside a NESTED loop;
* a bank read inside the relabel loop's own body after the relabel;
* multi-function modules (bd `1yeu`).

Original §7 follows.

The full `ir-pass-lit`, including the pre-existing
`railbank_reject_measure_after_nondiagonal_on_parked_rail.ll` and every
`railbank_accept_*.ll`, which this track's filter does not match. Also not run:
every `e2e-slice-railbank-*`, `e2e-railbank-dynamic-admission-matrix`, the
corpus A/B, cq-opt-equivalence and the loop-twin matrix. No verdict-affecting
source changed (the binary hash is identical), so none of them should move.
That is an inference, not a measurement. Also not attacked: multi-function
modules beyond s31 (bd `1yeu`), `-g` builds, and bool/`i8` conditional banks.
M8's "free" is measured only over the owned tests.
