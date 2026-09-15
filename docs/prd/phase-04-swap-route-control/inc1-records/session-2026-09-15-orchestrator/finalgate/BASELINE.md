# BASELINE — the Rule-12 regeneration of the 15 moved twin-matrix cells

Completes `GATE.md` §4 / `ATTRIBUTION.md` **F-1**, the one item that stood between
`verify-integration` and `main`. Worktree `/Users/sorenwilkening/Desktop/CQ_VERIFY`, branch
`verify-integration`. **Every line below is `ran:` unless marked `cited:`.** Nothing was rebuilt; the
binary hash is the gate's SUBJECT, before and after every measurement.

| label | `cq-opt` sha256 | `libCQPass.so` sha256 |
|---|---|---|
| **SUBJECT** (this regeneration) | `9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3` | `3e3dc35d471aae6b53067ffc374745f8cd9f148870a1879d971c8bdab831695d` |
| **ORACLE** `main` `74eabd2c` (read-only) | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` |

`ran:` both hashes re-verified at open and at close of this work; `include/CQ.h` and
`runtime/cq_runtime.h` are byte-identical between the two worktrees, so the ORACLE binary is a valid
reference for the SUBJECT's own generated sources. **Nothing was relinked under a measurement and no
process was killed by pattern.** Box load at every run: 1.8–6.7.

---

## 1. WHAT WAS DONE

```
ran: python3 tools/loop_twin_matrix.py --clang /usr/local/opt/llvm@19/bin/clang \
       --opt   <CQ_VERIFY>/build/ir-pass/cq-opt \
       --plugin <CQ_VERIFY>/build/ir-pass/libCQPass.so \
       --include <CQ_VERIFY>/include \
       --runtime <CQ_VERIFY>/build/runtime/libcq_runtime.a \
       --templates <CQ_VERIFY>/build/runtime/libcq_templates.a \
       --phi-surface void --jobs 6 --regenerate
     -> exit 0, 3:22.63 wall
        regenerated tools/loop_twin_matrix.expected.txt (330 cells; 29 quarantined and omitted)
            preserved 461 header line(s) of loop_twin_matrix.expected.txt byte-for-byte
```

The invocation is the committed `ctest` one (`tests/e2e/CMakeLists.txt:4457`) plus `--regenerate`,
with `CQ_LD` exported to the same wrapper the ctest sweep supplies. The tool has no per-row
regeneration mode — `--regenerate` rewrites the whole generated body from the run — so the two
obligations the brief sets (header survival, and *only* the 15 moving) are discharged by proof
below, not by scope.

⚠ **`--regenerate` exiting 0 is itself load-bearing and is not just "it wrote the file".** Its
refusal set (`loop_twin_matrix.py`, the `if cfg.regenerate:` block) is *hard failures not blessed by
the quarantine* **+** *quarantine failures* **+** *boundary-control failures*, and a refusal writes
nothing. So exit 0 states, before a single row was written: no un-quarantined `TRACE-DIVERGENCE`, no
`VACUOUS-ACCEPT` (the bd `rpkr` non-vacuity floor), **all 29 quarantined signatures still pinned**,
and **both boundary controls as pinned**.

---

## 2. THE bd `gfsk` HEADER PROTECTION — IT HELD, AND THIS IS THE FIRST REAL CUSTOMER

Track I closed bd `gfsk` this session with an end-of-header marker, byte-for-byte preservation in
both write modes, a refusal on an unmarked file, and a post-write read-back. Nothing had exercised it
on a real regeneration. It has now.

`ran:` header split with the tool's own `split_header()` (Rule 14 — the predicate is *called*, not
re-spelled), before and after the write:

| file | marker | header bytes PRE → POST | sha256 PRE | sha256 POST | byte-identical |
|---|---|---|---|---|---|
| `tools/loop_twin_matrix.expected.txt` | present | 31195 → 31195 (461 lines) | `9d8a1ce1…fc18dc` | `9d8a1ce1…fc18dc` | **YES** |
| `tools/loop_twin_matrix.quarantine.txt` | present | 11794 → 11794 (177 lines) | `6b6337a4…44dc8a` | `6b6337a4…44dc8a` | **YES** |

`ran:` whole-file sha256 of the quarantine, PRE `212355f72f29f628af2a0f718792a924ebad2d99d3941045e06c02592549e92f`
→ POST **identical**, and `diff` against the pre-run copy is empty: **the quarantine file was not
written at all**, which is correct — `--regenerate` owns only the expected table.

`ran:` whole-file sha256 of the expected table `840bd317…9779f0` → `29358b24…a2326`; the delta is 15
generated rows and nothing else (§4).

**The 54-line prose-deletion failure mode (bd `gfsk`) did not recur, and the mechanism that stopped
it is now witnessed rather than only mutation-tested.** The tool also *reported* what it preserved
("preserved 461 header line(s) … byte-for-byte"), which is the half of the contract that makes a
silent deletion inexpressible.

---

## 3. THE 15 CELLS — ONE WRITTEN REASON EACH (Rule 12)

Evidence for every row: `probes/baseline/bank_evidence.{py,txt}` (all **21** bank cells, both sides,
**both binaries**, with exit code, diagnostic, full trace and `counts()`), `probes/baseline/full_stderr.txt`
(full stderr with `!dbg`, both binaries), `probes/baseline/accept_stream_witness.{py,txt}` and
`probes/baseline/table_row_diff.txt`. The reasons are read off measured streams, never inferred from
the verdict string.

Two facts hold for **all fifteen** and are stated once rather than fifteen times:

* **Every mover is a `k*` BANK cell** — Track I's axis (bd `rpkr`), 21 cells, added this session on a
  binary bit-identical to the ORACLE. **Nothing outside the axis moved** (§4).
* **Every one pinned `cq taint escape: tainted value stored to memory`**, which is precisely the wall
  Track B's rail bank (bd `xdu2` W1 second half) retires for a *carved* bank. The axis was built to
  red exactly here, its own source says so, and the red is the trigger firing — not a defect.

### 3a. THE CAPABILITY ARRIVING — 2 cells, and the shared stream is checked against an INDEPENDENT compiler

⚠ `ACCEPT-IDENTICAL` cannot see a cell whose two halves agree because BOTH are wrong (CLAUDE.md's
`m_none_pbitd_none_premark_rypost`). So for these two the reason is **not** "the halves match".

**1. `m_none_kprep_none_none_kflat` — `UNROLLED-ONLY` → `ACCEPT-IDENTICAL`.** The design target:
`_Bool k[2] = {0}` written once per trip by `k[i] = cq_theta(k[i], 0.5)`, read back at constant
subscripts. `ran:` the SUBJECT's **rolled** trace is 9 lines and is **byte-identical to the trace the
ORACLE emits for the unrolled twin** — a compiler that contains no rail bank at all, lowering the
SROA-scalarised cascade. That is witness **W-B** stated against an independent reference, so the
shared-wrongness hole is closed *for anything bank-specific*: the stream the new capability produces
is the stream the old compiler already produced for the equivalent program. Read for content, the
stream is right and says three separate things:

```
cqrt_alloc_i32(0) -> h0 ; cqrt_ry_i32(h0, 0x1p-1)     <- `a`
cqrt_alloc_i1(0)  -> h1 ; cqrt_ry_i1(h1, 0x1p-1)      <- k[0], fresh rail, from its zero seed
cqrt_alloc_i1(0)  -> h2 ; cqrt_ry_i1(h2, 0x1p-1)      <- k[1], a SECOND fresh rail
cqrt_measure_i32(h0) ; cqrt_measure_i1(h1) ; cqrt_measure_i1(h2)
```

  (i) the two cells are **two distinct mints**, so the promoter did not alias one bank cell onto
  another; (ii) each is rotated **once from its zero seed**, not twice on one handle, which is the
  cross-trip-forward defect `IMPL_I.md` §3.3 names as the only thing the `kloop` shape could see —
  answered here in the safe direction by the stream itself; (iii) every mint is measured and none is
  freed, which is Rule 6 exactly (the measurement owns the handle; `Ry(θ)|0⟩ ≠ |0⟩`, so nothing may
  be freed). `counts(_unc, free, mints) = (0, 0, 3)`, 3 measures — the bd `rpkr` **non-vacuity floor**
  for this cell is `(3, 3)` and is **met exactly**, so no user measurement vanished into
  `MeasureLowering`'s classical split. Stage 2b ran STRICT on both sides inside the matrix.
  ⚠ What this does **not** close: a defect in the *scalar cascade* lowering itself would be shared by
  the reference (`IMPL_I.md` §4.1), and `kflat`'s twin is **not a bank program** (§4.8 there).

**2. `m_none_k2b_none_none_kflat` — `UNROLLED-ONLY` → `ACCEPT-IDENTICAL`.** The K5 grouping-key probe:
two banks `k` and `m` in one body, at **different angles** (0.5 and 0.25). `ran:` same result — the
SUBJECT's rolled trace is 15 lines and **byte-identical to the ORACLE's scalarised twin**. The
content answers the open question the cell exists for (`staleRailRecordRead` groups per ROOT MINT and
a bank rail has no root mint): **five distinct mints, two disjoint rail sets, no cross-bank merge**,
`k` rails at `0x1p-1` and `m` rails at `0x1p-2`, and the measure order is the `return` expression's
order `k[0], k[1], m[0], m[1]`. Floor `(5, 5)`, measured `(5 measures, 5 mints)` — **met exactly**.

### 3b. F-3 — the new `ROLLED-ONLY` class, 3 cells, pinned as an OVER-DECLINE (see §5 for the trigger)

These three are the `kloop` read shape: the write loop is rolled on one side and hand-unrolled on the
other, while the *read* loop stays rolled on both. **The rolled side compiles; the hand-unrolled twin
declines.** Direction: the decline is on the twin, so no accepted circuit is created by the movement;
the new accept is on the rolled side and is checked below.

`ran:` **the mechanism, read in source and then confirmed by the twin's own `!dbg`.**
`QramLowering.cpp:1264-1268` opens the carve with `Loop *L = LI.getLoopFor(SI->getParent()); if (!L)
return RailBankCarve::NotBank;` — *"a bank cell is written once per TRIP; a straight-line tainted
array store is not a bank and keeps its generic decline"*. The unrolled twin's stores are
straight-line (`m_none_kprep_none_none_kloop.unrolled.c:8` and `:10`), and the twin's diagnostic is
`…stored to memory` at exactly `:8:10`. ⚠ **The asymmetry needs TWO conditions, not one, and the gate's
write of it names only the first.** The `kflat` twins are unaffected **because SROA scalarises the
array away** (constant subscripts) before any fence sees a store; the `kloop` twins keep a rolled read
over a *dynamic* subscript, so the array survives SROA and the straight-line stores are real. That is
why one capability shows as `ACCEPT-IDENTICAL` at `kflat` and `ROLLED-ONLY` at `kloop`.

**3. `m_none_kprep_none_none_kloop` — `DECLINE-BOTH` → `ROLLED-ONLY`.**
**4. `m_none_k2b_none_none_kloop` — `DECLINE-BOTH` → `ROLLED-ONLY`.**
**5. `m_none_kiprep_none_none_kloop` — `DECLINE-BOTH` → `ROLLED-ONLY`.**

Why the *accepting* rolled stream is right, given that the cell's own twin cannot witness it
(`probes/baseline/accept_stream_witness.py`, exit 0, `checked 5 comparison(s), 0 unexpected`):

* `ran:` **Q2** — for cells 3 and 4 the rolled **gate** stream is *identical* to the `kflat` sibling's
  rolled gate stream, which §3a pinned against the ORACLE; the `cqrt_measure_` **multiset** is equal
  and only the measure **ORDER** differs, exactly as the two sources differ (`kloop` reads the bank in
  a loop *before* `return cq_measure(a)`; `kflat` reads it inside the `return`). So these two inherit
  §3a's oracle-backed witness for everything except a measurement permutation the source itself
  writes.
* `ran:` **Q2b** — cell 5 is the K2 `int`-cell WIDTH control and has no accepting `kflat` sibling, so
  its reference is cell 3 modulo the width token: a blind `_i1( → _i32(` rewrite of the `_Bool`
  stream reproduces the `int` stream **exactly**, 9 lines each. That is the discriminator K2 exists
  for, answered in the informative direction — *the bank works and the `[N x i1] → [N x i32]` type
  rewrite is not what makes it work*, since an `int` bank needs no rewrite and emits the same shape.
* `ran:` floors, **by hand**, because the instrument does not ask them here (§5): cell 3 `(3 measures,
  3 mints)` vs floor `(3,3)`; cell 4 `(5,5)` vs `(5,5)`; cell 5 `(3,3)` vs `(3,3)`. **All met.**
* Every mint is measured, none is freed — Rule 6 as in §3a. Stage 2b STRICT, both sides, inside the
  matrix.

### 3c. STILL A DECLINE, AT A LATER WALL — 10 cells

None of these creates an accept. In each, the rolled side stops at a **different, already-shipped**
fence now that the store wall no longer stops it first; the pin records the fence that actually
decides. Where the cell has an accepting *unrolled* half, `ran:` **that half's trace is byte-identical
on ORACLE and SUBJECT**, so the accepting side did not move at all and only the refusing side's owner
changed.

**6. `m_none_kread_none_none_kflat` — `UNROLLED-ONLY`, string → `cq controlled lowering: control flow
inside a loop body under quantum control` @ `:9:23`.** This is the axis's **headline** cell and the
new string is the *right answer to the question it asks*. `SCOPE_L1a` §4.4 (D) names the silent
failure: a bank load used as a branch condition (`if (k[i]) a = cq_theta(a, 0.25);`) is untainted
without promotion, so `hasTaintedCondBranch` never fires and **the arm runs as classical code over a
quantum register**. The new diagnostic is a *`… under quantum control`* string, which is emitted only
for a **tainted** condition — so the measurement proves the promoted bank load **carries taint to the
branch**, and the region is then refused because in-loop tainted control flow is out of scope. The
unrolled half corroborates it from the other side: its trace (identical on both binaries, 11 lines)
contains `cqrt_ry_i32_controlled(h1, h0, 0x1p-2)` — a *controlled* rotation, i.e. the flat spelling
also reads `k[i]` as a quantum control. Safe direction, and a positive result for D5.

**7. `m_none_kread_none_none_kloop` — `DECLINE-BOTH` → `DECLINE-BOTH-DIFFERENT`** (rolled: the same
in-loop-quantum-control string @ `:9:23`; unrolled: still `…stored to memory` @ `:8:10`). Same reason
as 6 for the rolled half; the unrolled half is unchanged and is the F-3 shape (§3b) — it never
carves, so it never reaches the control question.

**8. `m_none_karith_none_none_kflat` — `UNROLLED-ONLY`, string → `cq loop lowering: loop-carried
tainted value crosses iterations`.** D5's second complement: `a = a + (int) k[i];`. The new fence is
the shipped 7.3 cross-iteration decline, and — as in 6 — **its firing is itself the proof that the
bank load is tainted**: `a` is only a *loop-carried tainted* value if the load propagates taint into
it. The unrolled half's trace is byte-identical on both binaries (19 lines) and treats the load as a
real rail: `cq_template_zext_i1_to_i32` + `cq_template_add_i32`, with a full `_unc`/`cqrt_free`
pairing `(3, 3, 7)`. So both spellings agree about the *semantics* of the load; only the rolled
accumulation is out of scope.

**9. `m_none_karith_none_none_kloop` — `DECLINE-BOTH` → `DECLINE-BOTH-DIFFERENT`.** Rolled: the same
cross-iteration string; unrolled: still `…stored to memory` (F-3 shape). Reason as 8.

**10. `m_none_kcond_none_none_kflat` — `DECLINE-BOTH-DIFFERENT` → `DECLINE-BOTH-DIFFERENT`**, the
rolled string moving to `cq controlled lowering: condition predates a non-diagonal gate under quantum
control` @ `:8:13`. The body is `if (a > 5) k[i] = cq_theta(k[i], 0.5);` — the cascade's arm, and the
`MergePhiPeel` P10 `armWritesMemory` obstacle. With the store carved, the arm becomes a genuine
tainted-condition region and is refused by **gate 2c**, the fence CLAUDE.md calls *"the live fence in
front of almost everything"*: `a` is rotated by `cq_theta(a, 0.5)` before the condition reads it.
That is the correct owner for this shape. The unrolled half is unchanged (`control flow under quantum
control` @ `:8:9`) on both binaries.

**11. `m_none_kcond_none_none_kloop` — `DECLINE-BOTH` → `DECLINE-BOTH-DIFFERENT`.** Rolled → 2c as in
10; unrolled still `…stored to memory` (F-3 shape).

**12. `m_none_kicond_none_none_kloop` — `DECLINE-BOTH` → `DECLINE-BOTH-DIFFERENT`.** The `int`-cell
twin of 11; identical reason, identical strings. ⚠ Its `kflat` sibling `m_none_kicond_none_none_kflat`
**did not move** (it declines at the carve's own `cq rail bank: array mixes a rail cell access with an
unrecognized one` on both binaries) — which is the axis discriminating the carve's classifier from the
control fence, and is why only one of the two `kicond` cells is in this list.

**13. `m_ry_kprep_none_none_kflat` — `UNROLLED-ONLY`, string → `cq taint escape: tainted value muxed
by a classical-condition phi`.**
**14. `m_none_kprep_ry_none_kflat` — same transition.**
**15. `m_add_kprep_none_none_kflat` — same transition.**

The K3 a-gate STAR: the design-target bank plus an in-place gate on the **disjoint** register `a`
(`a = cq_theta(a, 0.25)` as PREFIX, `a = cq_theta(a, -0.5)` as SUFFIX, `a = a + off` as PREFIX). All
three stay `UNROLLED-ONLY` — still a decline, no circuit emitted — and `ran:` all three unrolled
halves are **byte-identical on ORACLE and SUBJECT** (11 lines each), so the accepting side is
untouched. The rolled side now walks past the retired store wall and is refused by
`declineClassicalMuxes` on the loop-carried `a` phi. The verdict is correct as a *pin* (the string is
the fence that decides, character-for-character) — but see **F-B1** in §5: this is a composition
over-decline and must be filed, not blessed.

---

## 4. ONLY THE 15 MOVED — THE OTHER 344 ROWS AND EVERY QUARANTINE SIGNATURE ARE UNMOVED

`ran:` `probes/baseline/table_row_diff.txt`, a row-by-row comparison of the pre-run copy of
`tools/loop_twin_matrix.expected.txt` against the regenerated file:

```
rows PRE=330 POST=330  added=0 removed=0
MOVED=15  UNCHANGED=315  every mover is a BANK (k-region) cell: True
```

`ran:` a mechanical cross-check against the gate's own recorded failure list
(`finalgate/matrix_15_cells.txt`): for all 15, **PRE == the gate's `expected:` and POST == the gate's
`got:`, character-for-character**, and the moved *set* equals the gate's set exactly. No cell moved
that the gate did not see move, and no cell the gate saw move failed to move.

`ran:` the quarantine file is **byte-unchanged** (identical sha256, empty `diff`), 29 `cell ` blocks
before and after; `315 + 29 = 344` rows unmoved, `330 + 29 = 359` cells total, unchanged.

`ran:` the two boundary controls and all 29 signatures are asserted **twice** — once by
`--regenerate`'s refusal set (§1) and once by the plain re-run (§6): *"all 29 quarantined cells
diverge with their pinned signature … both boundary controls as pinned"*.

---

## 5. WHAT MUST NOT BE READ AS A STEADY STATE

### F-3 — the three `ROLLED-ONLY` rows are an OVER-DECLINE. **L8 RETIREMENT TRIGGER.**

Per the owner's ruling of 2026-09-11 — *"our end-goal is to not decline any code that will lead to a
valid quantum circuit"*, an over-decline is **a defect to remove, not a free safety margin** — these
three rows record a defect that is currently pinned, not a design. `ran:` reproduced from plain C by
the gate (`finalgate/probes/rolledonly/ro_{rolled,unrolled}.c`), so it is not a matrix artefact.
**Reported to the orchestrator for filing as a defect** (§7).

The rows become **wrong**, and must be **re-derived from scratch rather than merely re-blessed**, the
day any of these is true:

* **(a)** `QramLowering.cpp`'s carve precondition `Loop *L = LI.getLoopFor(SI->getParent()); if (!L)
  return RailBankCarve::NotBank;` is relaxed, widened, or moved. The twin then carves, the cells
  should go `ACCEPT-IDENTICAL`, and the rolled-vs-unrolled witness they currently lack is restored.
  ⚠ Relaxing it is **not free**: that conjunct's own comment names
  `ir-pass/test/control_classical_call_arm_reject_localarray_store.ll` as the shipped fixture that
  depends on a straight-line tainted array store keeping its generic decline.
* **(b)** the `kloop` read shape stops defeating SROA on the twin. The asymmetry needs **both** the
  loop precondition **and** a read that keeps the array alive in the twin; if `-O1` ever scalarises a
  dynamic-subscript read loop, the twin lowers and the row moves for a reason that has nothing to do
  with (a).
* **(c)** the rows' pinned twin string `cq taint escape: tainted value stored to memory` changes. It
  is the *twin's* diagnostic, pinned character-for-character; a different string means a different
  fence owns the twin and the whole F-3 reading has to be re-derived.

⚠ **AND THE STANDING COST, WHICH IS LARGER THAN `GATE.md` F-3 RECORDED.** For these three cells the
matrix's usual claim (rolled == unrolled, byte-identical) is unavailable because one side does not
compile — the gate says that. **What it does not say is that the bd `rpkr` NON-VACUITY FLOOR is also
not evaluated on them.** `verdict()` asks the floor only inside the `rolled.exit == 0 and
unrolled.exit == 0` branch; a `ROLLED-ONLY` cell never enters it. So on these three the instrument
checks **neither** trace identity **nor** the floor. The floor quantities were therefore measured **by
hand** for this regeneration (§3b: `(3,3)`, `(5,5)`, `(3,3)`, all met) — *the instrument does not
check them and will not red if they later fall.* The capability's witness of record for those
programs is elsewhere: the two `kflat` `ACCEPT-IDENTICAL` cells above and the shipped green
`e2e-railbank-flat-twin-identical` (ctest #455).

### F-B1 — a NEW composition over-decline the K3 star pins, measured here for the first time

`ran:` each half of the K3 star lowers **alone** on the SUBJECT:

```
bank alone   : m_none_kprep_none_none_kflat rolled   -> exit 0, ACCEPT-IDENTICAL (§3a)
a-gate alone : probes/baseline/k3_composition/nobank_{ry,add,rypost}.c
               -> exit 0, NO diagnostic, all three
together     : m_{ry_kprep, none_kprep_ry, add_kprep}_…_kflat rolled
               -> exit 1, cq taint escape: tainted value muxed by a classical-condition phi
```

`a` and the bank are **disjoint objects**, and the two features compose to a decline neither has on
its own. That is the owner's 2026-09-11 class exactly. The pinned rows are correct as pins — the
string is the fence that decides — and the rows must not be read as "the combination is unsupported
by design". **Filed to the orchestrator** (§7); its retirement trigger is the same as any
over-decline's: the row moves to `ACCEPT-IDENTICAL` the day the composition lowers, and that is a
deliberate regeneration with a reason, not a surprise.

### The K-DEPENDENCE caveat these 15 reasons inherit (`IMPL_I.md` §4.6)

Every reason above is measured at **`TRIPS = 2`** and bank size 2 (8 for `kover`, which did not move).
A bank defect that needs three or more trips, or a bank whose cells are written in a non-monotone
order, is **invisible to all 15 of these rows**. ⚠ This is the direct analogue of bd `uq96`'s
second-pass lesson (every `B_ARM` declaring its second register outside the loop): *an instrument is
only ever blind in the shape nobody has pointed it at yet.* If the bank's defects live at K ≥ 3, this
axis needs a second pass and nothing in this regeneration hints at it.

### What this regeneration is NOT evidence about (`IMPL_I.md` §4, carried, not paraphrased away)

1. **A wrong unitary both halves share.** Closed here only for *bank-specific* defects, and only on
   the two `kflat` cells, by the ORACLE comparison — a defect in the scalar cascade lowering is shared
   by the reference.
2. **The unitary at all** (Rule 2). No simulator, and none is coming.
3. **Rail identity at a free** — that is stage 2b, which is blind to template-minted rails, so for a
   *template* rail freed dirty **neither instrument is a witness**. The pair is not a partition.
   (Immaterial to the five accepting bank sides here: they free nothing.)
4. **Cross-function defects** (bd `1yeu`): one function per module, this axis included.
5. **The D5 allow-list's semantics — only its disposition.** Rows 6–9 say the bank load reaches the
   branch/arithmetic **as taint**; they do not say an accepted circuit for those shapes would be right.

---

## 6. THE RE-RUN

```
ran: shasum -a 256 build/ir-pass/cq-opt  -> 9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3  (before)
ran: ctest --test-dir build -R '^e2e-loop-twin-matrix$' --output-on-failure
       1/1 Test #318: e2e-loop-twin-matrix ....  Passed  171.18 sec
       100% tests passed, 0 tests failed out of 1
ran: shasum -a 256 build/ir-pass/cq-opt  -> 9bd01598…a13b3  (after, UNCHANGED — nothing was relinked)
```

`ran:` the run's own attestation, taken from `build/Testing/Temporary/LastTest.log` rather than by a
second run (PROTOCOL non-redundancy) — `probes/baseline/ctest_rerun_output.txt`:

```
loop_twin_matrix [--phi-surface void]: 359 cells — 164 ACCEPT-IDENTICAL, 99 DECLINE, 96 other;
                                       29 quarantined (pinned signatures), 2 boundary controls
    ACCEPT-IDENTICAL 163 · ACCEPT-IDENTICAL-WARN 1 · DECLINE-BOTH 55 · DECLINE-BOTH-DIFFERENT 44
    ROLLED-ONLY 3 · TRACE-DIVERGENCE 29 · UNROLLED-ONLY 64
    control q_armoncond  TRACE-DIVERGENCE      control q_noregion  ACCEPT-IDENTICAL
all cells match loop_twin_matrix.expected.txt; all 29 quarantined cells diverge with their pinned
signature (loop_twin_matrix.quarantine.txt); both boundary controls as pinned for the `void` surface
```

The class tally **reconciles exactly** with `GATE.md` §4's SUBJECT figures (`163 AI · 1 WARN · 55 ·
44 · 3 ROLLED-ONLY · 29 · 64`), so the regenerated table pins the run the gate measured and not a
different one.

**Nothing else was re-run.** The full suite (456/457), `cq-opt-equivalence-full` (2082/0) and the
corpus sweep (6165 rows / 356 movers / 0 unattributable) are `cited:` from `GATE.md` on this same
binary; re-running them would be a third measurement, which PROTOCOL forbids.

---

## 7. FOR THE ORCHESTRATOR — file these, do not let them read as settled

1. **F-3 (`GATE.md`, sharpened here): FILE AS A DEFECT.** The rolled bank compiles where its
   hand-unrolled twin declines; 3 cells; an over-decline under the owner's 2026-09-11 ruling. Trigger
   and the *two* preconditions behind it are in §5. ⚠ Add the part the gate did not have: those three
   cells lose the **non-vacuity floor** as well as the twin identity, so the instrument checks nothing
   about their accepted streams.
2. **F-B1: FILE AS A DEFECT (new, measured here).** The bank composes with an in-place gate on a
   **disjoint** register to a decline that neither has alone — 3 cells, reproduced from plain C
   (`probes/baseline/k3_composition/`).
3. **A diagnostic-quality observation, measured and PRE-EXISTING — do not file it against this merge.**
   5 of the 15 rows now decline through fences that emit **no `!dbg`** (`<unknown>:0:0`): the three K3
   star cells (`classical-condition phi`) and the two `karith` cells (`crosses iterations`). `ran:` both
   fences are `diagnose(<PHINode>, …)` (`TaintPropagation.cpp:1620`, `LoopLowering.cpp:2143/2595`), and
   `ran:` **the ORACLE emits `<unknown>:0:0` for both strings on plain `-g -O1` C programs that contain
   no bank at all** (`probes/baseline/dbgloc/`, three programs, two strings). So the location loss is a
   property of diagnosing a `-O1` phi, not something this merge dropped. It is still real: a lost
   source location is invisible to every other gate in the tree.
4. **Still owed and untouched by this file:** `ATTRIBUTION.md` §OWED 1–4 — the Rule-13 opinion on
   E2 × D5, ROUTING R6 (a reviewer whose subject is the *composition*), the loopfix conversions, and
   ROUTING R12's ruled-but-unbuilt owner ruling E6 option (D). **A regeneration is a Rule-12 act; it
   discharges no Rule-13 opinion.**

## 8. INSTRUMENT HYGIENE — both probes written for this file were attacked

CLAUDE.md L10: *an instrument's failure mode is to report a pass, so the only instrument worth citing
is one that has been made to fail on purpose.*

* `bank_evidence.py` refuses (`exit 2`) when its cell selection is empty — the `checked 0` hole.
* `accept_stream_witness.py`: `ran:` real configuration → `checked 5 comparison(s), 0 unexpected`,
  **exit 0**; `ran:` self-attack (SUBJECT pointed at the ORACLE binary, so the rolled sides decline and
  their traces are empty) → `checked 5 comparison(s), 5 unexpected`, **exit 1**.
  ⚠ **The first spelling of that self-attack found a vacuity hole in my own probe and it is recorded
  rather than quietly fixed:** with both traces empty, `gates("") == gates("")` is `True`, so Q2 and
  Q2b reported **three passes on nothing** while only Q1 failed. A non-vacuity guard was added and the
  self-attack now fails all five. That is the same shape as the `empty-module-accepts-vacuity-trap`
  memory, arriving in a brand-new instrument on its first day.
