# Track B — bd `xdu2.1`: bank reads under the bd `3d8q` stale-reader fence

Session 2026-09-24-railbank-parallel. Tree `d0720cb1` (`cq-opt`
`c6f61f80a5d524c6`, unchanged by every commit of this track: the track's source
edits are comments only, and the rebuilt binary is bit-identical).

## 0. Verdict

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

## 2. The dtzb axis — safe, and for a reason no comment stated

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

* `lit ir-pass/test --filter 'railbank_stale|stale_reader|reader_predates'`: 21
  discovered, 21 passed.
* `ctest -R '^e2e-railbank-register-twin-(decline|selftest)$|^e2e-railbank-stale-matrix$'`:
  3/3 passed. Twin gate: `12 pair(s) checked, 0 VIOLATION(s), 0
  TRACE-MISMATCH(es), 0 over-decline(s)`. Matrix: `30 case(s): 13 accept, 17
  decline; 4 twin(s); 0 failure(s)`.

## 7. NOT tested here (belongs to the merge gate)

The full `ir-pass-lit`, including the pre-existing
`railbank_reject_measure_after_nondiagonal_on_parked_rail.ll` and every
`railbank_accept_*.ll`, which this track's filter does not match. Also not run:
every `e2e-slice-railbank-*`, `e2e-railbank-dynamic-admission-matrix`, the
corpus A/B, cq-opt-equivalence and the loop-twin matrix. No verdict-affecting
source changed (the binary hash is identical), so none of them should move.
That is an inference, not a measurement. Also not attacked: multi-function
modules beyond s31 (bd `1yeu`), `-g` builds, and bool/`i8` conditional banks.
M8's "free" is measured only over the owned tests.
