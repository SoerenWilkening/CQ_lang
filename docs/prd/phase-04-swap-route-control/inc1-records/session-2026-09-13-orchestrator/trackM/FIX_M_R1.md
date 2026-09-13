# FIX — Track M, round 1 (`review_M_r1.md` CLEAR-WITH-ITEMS → `FIX_BRIEF_M_R1.md`)

Session 2026-09-13. Worktree `/Users/sorenwilkening/Desktop/CQ_mphi`, branch `mphi-rail-leaf`. Protocol row
"fix". **Nothing committed, nothing pushed.** Binary `ae216b3727f5b1ec` → **`0d3105d0eb9d476a`** (one
functional change; the comment-only edits after it re-hashed identically, verified). Gates in `GATES.md`;
artifacts in `probes/impl/` and `fix_M_r1_probes/`.

| finding | grade | disposition |
|---|---|---|
| **F-M1** | OVER-DECLINE + DOC | **FIXED** — `ControlRegion::PrepRegionIdx` + ONE precedence edge; both false comments rewritten; `r03` ACCEPTS |
| **F-M6** | DOC (unpinned accept) | **PINNED** — fixture + K-independence + injection row + 2 slices + a mutant-validated twin gate |
| **F-M3** | OVER-DECLINE | **NOT FIXED, by instruction** — pinned as a DECLINE with a `3d8q` retirement trigger |
| **F-M5** | pre-existing leak | recorded (§7 of `IMPL_M.md`, reproducers named below) |
| **F-M7** | DOC (nit) | retirement trigger added at `declineRegion` |

---

## 1. F-M1 — the emission-order edge

### 1.1 What was wrong

`SelectMergeEmit.cpp` justified H-1's re-read with *"that region is emitted FIRST (plan index is push order
is block order)"* and closed with *"The φ-still-present-at-emit-time branch has NO SUBJECT today"*. **Both
false**, and the reviewer measured it on ordinary `-O1` C: `lowerControlRegions` Kahn-sorts the bd `hcrg`
precedence graph, in which a `SelectRegion` is **inert** (all four block fields null ⇒ it aliases nothing,
nothing aliases it, `Pending == 0`). A following `PhaseKickback` whose `Pred` IS the prep's `MergeBB` takes
the sanctioned `sequentialChainAlias` edge `Precedes[kickback] = {prep}`, scheduling the **prep last** —
after the select, whose condition re-read then found the φ still live and fired the loud H-1 backstop.

### 1.2 The fix — a RECORD and ONE edge, by calling, never re-deriving

| site | what |
|---|---|
| `ir-pass/include/ControlPlan.h:507` | new `unsigned PrepRegionIdx = kNoParent;` + its rationale |
| `ir-pass/src/SelectClassify.cpp:551` | `preppedRailPhiRegion` → **`preppedRailPhiRegionIdx`** (returns the index) |
| `ir-pass/src/SelectClassify.cpp:994-998` | rung 0 captures the index |
| `ir-pass/src/SelectClassify.cpp:1294-1299` | the accept carries it: `R.PrepRegionIdx = PrepIdx;` |
| `ir-pass/src/SwapRouteEmit.cpp:2598-2637` | **the ONE edge**, plus its bound re-check |

```cpp
for (size_t i = 0; i < N; ++i) {
  if (Regions[i].Kind != ControlRegion::SelectRegion) continue;
  const unsigned P = Regions[i].PrepRegionIdx;
  if (P == ControlRegion::kNoParent) continue;      // compare/rail cond: no rewrite, no edge
  if (P >= N || P == i) { declineRegion(Regions[i]); return; }   // Rule 1, never a third path
  Precedes[P].push_back(i);
  ++Pending[i];
}
```

**Rule 14 is the shape of the fix, not a footnote.** The emitter knows nothing about `InPlaceRotation` arms:
`classifySelectRegion` ran the ladder, committed the index, and this loop only transcribes it. An index (not
a pointer) for exactly the reason `ParentIdx` gives one line above — the list is a `SmallVector` that
reallocates — and indices are stable because `plan.Regions` is only ever `push_back`'d (`grep` confirms: no
erase, no sort, no resize anywhere in `ir-pass/src`).

**It cannot create a cycle, structurally rather than empirically:** this is the ONLY way a `SelectRegion`
acquires an edge and every such edge points **into** it. A node with no outgoing edges cannot lie on a cycle,
so the Kahn backstop keeps exactly the population it had. The out-of-range arm is unreachable today and
declines LOUDLY rather than silently skipping (a silent skip would restore the over-decline with no
diagnostic anywhere).

### 1.3 `r03`, and its ORDER argument

`ran:` **ACCEPT, 33 trace lines**, STRICT 2b `8 mints / 6 left allocated, 3 free: 3 verified, 0 violation(s),
0 unproven`. The source is the flagship plus `if (a == 2) { cq_phi(0.3); }`.

```
 1- 2  alloc_i1→h0; ry_i1(h0,½)                     b0's rail
 3-13  the a-mux  (`if (b0==1) a -= 3`)             → h2, ancilla h1 freed at |0>
14-16  alloc_i1→h5; ry_i1(h5,½); ry_i1_controlled(h0,h5,−½)    the b1 prep (anti-control)
17-26  add_i32_hl(h2,−3)→h6; alloc_i1→h7; cnot(h5,h7); alloc_i32(0)→h8;
       copy_c(h7,h6,h8); x(h7); copy_c(h7,h2,h8); x(h7); cnot(h5,h7); free(h7)      THE SELECT → h8
27-30  icmp_eq_i32_hl(h8,2)→h9; rz_i1(h9,0.3); icmp_eq_i32_hl_unc(h9,h8,2); free(h9)   THE KICKBACK
31-33  measure h0, h5, h8
```

**The trace is in SOURCE ORDER, and that is not a property of the schedule.** Every emitter inserts
**positionally** — the kickback before its own `Pred`'s terminator, the select's stream immediately before
the select instruction — so the trace follows IR POSITION, not emission order. The scheduler's only job is
to make the prep's M-β run before the select's re-read. **The correctness check that matters here is line 27:
the kickback mints its flag from `h8`, the SELECT'S OUT RAIL** — `a` at that point in the source IS the
select's value. The one inversion (the a-mux at 3–13 before the `b1` prep at 14–16) is the flagship's own and
commutes: block-diagonal in `h0`'s basis, disjoint targets. `h0` and `h5` are read only as controls; all four
`cqrt_x` are on ancillas; all three `cqrt_free` are proven-`|0⟩` (two copy ancillas + the kickback's stripped
flag).

### 1.4 The H-1 backstop is now UNREACHABLE, kept, and pinned by counterfactual

No hand IR can exercise it any more: rung 0 sets `PrepRegionIdx` for every φ it admits, so an admitted φ
select always carries its edge. **It is kept** — it is the "a seventh emitter forgot the edge" tripwire, and
its correctness does not depend on being reachable (CLAUDE.md L3: the sentence "no subject today" is exactly
what gets a backstop deleted for symmetry, which is why this increment's version of that sentence is now a
warning instead).

`ran:` the counterfactual, binary `253a80e6d9d45f16` (one statement disabled, nothing else, reverted after):

```
r03_order_third_region  ACCEPT 33  ->  exit=1  cq controlled lowering: control flow     (the H-1 backstop)
r18_third_is_select     ACCEPT 40  ->  ACCEPT 40     (inert third construct — unaffected)
r17_owner_file          ACCEPT 29  ->  ACCEPT 29     (no third region — unaffected)
```

So the edge is precisely what fixes `r03` and changes nothing else.

### 1.5 The two comments, rewritten

`SelectMergeEmit.cpp` now states (a) that "the prep is emitted first" is **not free** — it is an obligation
carried by `PrepRegionIdx` and discharged by the edge, with `r03` named as the measured reproducer of what
happens without it; and (b) that the φ-still-present branch **had** a subject, is unreachable again only
because another file keeps an obligation, and must not be deleted.

---

## 2. F-M6 — the in-loop select on an outside prep's φ, now pinned

`r22_inloop_select_outside_prep.c`: a 4.4 select **inside** a bounded loop whose condition is the merge φ of
a prep **outside** it. ORACLE DECLINE `control flow`; SUBJECT **ACCEPT 43** (rolled).

**Why it is admitted while `m30` is not**, stated in every artifact because the two look alike: `m30` is the
LOOP-CARRIED shape — its φ is a loop header phi, the tainted value crosses iterations, and the LOOP LAYER
declines it before detection runs (`loop-carried tainted value crosses iterations`, re-measured identical on
both binaries as `r21`). Here the φ is defined OUTSIDE the loop and is loop-INVARIANT, so nothing crosses the
back edge and the ordinary flat ladder applies. `SCOPE_M.md` §4's "a φ in a loop — OUT, pinned by `m30`"
covers the carried cell only.

**What was added:**

* `ir-pass/test/control_swap_accept_select_mergephi_inloop_outside_prep.ll` — with the **K-independence
  measurement in the header**: `ran:` the lowered IR is **78 lines / 19 gate calls at K=3 AND at K=1000**
  (`clang -O1`, no `-g`) ⇒ ROLLED. A regression that unrolled would multiply every count prefix by the trip
  count. ⚠ This fixture deliberately carries **no** `= phi` negative — a rolled loop's induction phis are
  exactly what a correct lowering must leave standing, and asserting the sibling flat accepts' negative here
  would demand an unroll. The header says so.
* an **injection row**, including an 8th mutation written for this cell: *a gate HOISTED OUT of the loop
  body* (the per-trip ancilla mint moved to the entry, so one ancilla is shared across trips — the second
  trip would then copy into a rail the first left dirty). Caught.
* `tests/e2e/slice_control_cascade_select_in_loop_outside_prep.c` (**43** lines) and its hand-unrolled twin
  `..._unrolled_twin.c` (**43** lines), with `e2e-cascade-select-in-loop-twin-identical` (`compare_files`).
  **`ran:` the two traces are BYTE-IDENTICAL.** The gate is mutant-validated: swapping the two
  `copy_i32_controlled` in trip 2 reddens it. It is an INTERNAL-CONSISTENCY gate (both halves need this
  increment) and is labelled as such — and it is the **only** instrument for this cell, because the loop twin
  matrix has no `_Bool` axis.

---

## 3. F-M3 — NOT fixed, pinned as a decline with a `3d8q` retirement trigger

`control_swap_reject_select_mergephi_inplace_arm.ll` (= `r01_inplace_arm_bool.c`). RED on the ORACLE for the
wrong reason (`control flow` — the grammar), GREEN here for the right one (`condition predates a
non-diagonal gate` — rung (iii)).

The header states plainly that **the circuit is valid and the compiler refuses it anyway** (an over-decline
is a defect, not a margin), that the refusal comes from the SEED SET rather than the physics
(`condProvenance(φ)` drags the PRE-rotation name into `RailProv`), and — the load-bearing part — that
**narrowing that seed first would convert this over-decline into an OVER-ACCEPT of the bd `3d8q`
in-place-arm class**, because the same cone is currently the only thing refusing a φ whose pre-rotation name
has sibling readers. The correct sequence is written into the file: land the `3d8q` fence → re-derive the
seed → flip this fixture. **For the orchestrator to file.**

---

## 4. F-M5 / F-M7 — records

* **F-M5.** The bd `3d8q` reproducers are `probes/impl/p3d8q_sibling.c` (φ spelling) and
  `review_M_r1_probes/r15_p3d8q_sibling.c`, with the control `probes/impl/p3d8q_sibling_rail.c` — which
  **ACCEPTS ON THE FROZEN ORACLE** (30 lines, 2b clean), so the hole is pre-existing and this increment adds
  customers to it. Already in `IMPL_M.md` §7.2; both file names are now named there for the bead.
* **F-M7.** Retirement trigger added at `SwapRouteEmit.cpp`'s `declineRegion`: it reads the raw
  `A.Condition`, safe today only because every region it can be called with is block-carrying (a
  `SelectRegion` is skipped by the alias pre-flight and, since F-M1, is always scheduled because its only
  edges are incoming), and block-carrying regions never have a merge-φ condition. The trigger names the
  `fg9k` value-arm-on-a-φ as the increment that would break it, and the fix (re-read from the live
  instruction).

---

## 5. A defect found while fixing — 5 VACUOUS negatives, and the instrument that now catches them

⚠ **The injection matrix caught something the review did not, and it is the same class as the `NOT: phi`
bug.** Re-running it over the new fixtures, `x-on-user-register` reddened `XCNT` but **not `NOX`** on the
in-loop fixture. Cause: `NOX`/`NOFREE` name their handles by hand, and I had copied the flagship's names
(`%h4`, `%out`, `%h_op`) into modules that do not define them. **A `-NOT` naming a handle the module never
defines is VACUOUS — it passes for the wrong reason.**

A name-existence check (`probes/impl/vacuity.py`) found **5 such negatives across 3 fixtures** —
`cmp_cond_region`, `runtime_amux`, `two_selects` — two of them the **non-negotiable `NOX` on the SECOND user
register**. All corrected from the pass output; re-run: **56 named negatives across 10 accept fixtures, 0
VACUOUS**, and `NOX` now catches `x-on-user-register` in all 10. Each affected fixture carries a note saying
why the check exists.

**Final injection matrix: 11 accept fixtures × 8 mutations = 87 applied, 0 MISSED, 1 N/A**
(`rail-handle-in-imm-slot` has no shape in the in-loop module). The vacuity check immediately caught 2 more
in the `G6` fixture as it was written — the instrument earns its keep on its first day.

---

## 6. Corpus sweep and the four customers

**The four customers, re-measured on `0d3105d0eb9d476a`** — unchanged, and the owner's trace is byte-identical
to the committed golden:

| customer | lines | stage 2b |
|---|---|---|
| the owner's file | **29** | `8 mints / 6 left allocated, 2 free: 2 verified, 0 violation(s), 0 unproven` |
| `m16` (run-time `a`) | **31** | `3 free: 3 verified, 0 violation(s), 0 unproven` |
| `i2_cmpladder` | **21** | `2 free: 2 verified, 0 violation(s), 0 unproven` |
| `va` (the discriminator) | **19** | `1 free: 1 verified, 0 violation(s), 0 unproven` |

**`ran:` once after the fix, `0d3105d0eb9d476a` vs `fbbe0820ef4b176a`, now also covering
`trackM/review_M_r1_probes/`. 2723 rows: 2679 unchanged, 36 DECLINE→ACCEPT, 8 decline-string moves,
0 ACCEPT→DECLINE, 0 both-accept lowered-IR changes.**
Artifact `probes/impl/corpus_0d3105d0eb9d476a.txt`.

⚠ **md5s are NOT comparable ACROSS sweeps** and nearly cost me a false alarm: the corpus script lowers each
module from a fresh `mktemp` file, so `; ModuleID = …` differs per run and every accepting row's md5 moves.
The md5 is meaningful only WITHIN a row (ORACLE and SUBJECT read the SAME stage-1 file). The cross-sweep
delta below is therefore on VERDICT CLASS + DIAGNOSTIC STRING.

**Delta vs the round-1 sweep, over the 2696 shared rows: ONE mover.**

```
session-2026-09-11-orchestrator/review_integration_probes/G6_quantum_mux_values.c
    r1  (ae216b37)  DECLINE  cq controlled lowering: control flow
    fix (0d3105d0)  ACCEPT   26 lines, 2b `3 free: 3 verified, 0 violation(s), 0 unproven`
```

**That single row is the best evidence the fix is right, and it is not mine.** `G6` was written for the
2026-09-11 INTEGRATION review, for a different increment; the sweep found it. It is the SAME F-M1 order
shape as `r03` with a different third construct — a compare-guarded controlled state prep
(`if (a >= 3) b1 = cq_theta(b1,.5)`, on the select's own output) instead of a phase kickback — so it took the
same `sequentialChainAlias` edge, scheduled the first prep after the inert select, and hit the same H-1
backstop. Two constructs, one cause, one edge. Its select arm is also a QUANTUM register
(`if (b0 == 1) a = p;`), so the merge is a controlled basis copy out of a live rail that stays allocated and
is measured — Rule 8 has no subject (nothing freed by copy+uncompute, nothing moved). Pinned as
`control_swap_accept_select_mergephi_quantum_arm_then_prep.ll`; trace in
`probes/impl/G6_quantum_mux_values.subject.trace`.

The 8 decline-string moves are the three known families and nothing else: rung (ii) (`m05` + its fixture),
and rung (iii)'s wire string on the in-place-ARM/chained shapes (`p20` ×3 spellings, `r01`/`r16`, and their
two fixtures). All are DECLINE→a LATER, more specific fence.

**Counts after the fix:** fixtures **1913**, e2e goldens **361**, `ctest -N` **412**.
`ran: ctest -R ir-pass-lit` @ `0d3105d0eb9d476a` — **PASSED, 40.15 s, 1913 discovered / 1912 PASS / 1 XFAIL /
0 FAILED**.

---

## §GATES — a copy of `GATES.md`

# Track M — gate ledger (`../PROTOCOL.md` §3.1)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`.
**A gate result is a fact about a BINARY, not about a moment.** Read this file before running any
gate; if the hash is unchanged and the gate is recorded, CITE the line instead of re-running it.

A cited line whose hash does not match the binary on disk is a FINDING.

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| per-probe pipeline (stages 1,2,2b,3,4) over `probes/` — 27 probes | `fbbe0820ef4b176a` (ORACLE, `e96f89c`) | 9 ACCEPT (`m03` 23, `m07` 23, `m09` 23, `m11` 28, `m12` 31, `m17` 28, `m18` 29, `m19` 28, `m26` 25 trace lines; every one STRICT stage 2b `0 violation(s), 0 unproven`) / 18 DECLINE with the anchors in `probes/README.md` | M-scope | 2026-09-13 12:4x |

**Not run by this agent, by protocol (the "scoping" column):** any build, `lit`, any `ctest` entry,
`cq-opt-equivalence`, the corpus sweep, the injection matrix, any twin matrix. The ORACLE hash was
verified by `probes/run.sh` before each sweep and matched `PROTOCOL.md`.
| per-probe pipeline (1,2,2b,3,4) over `probes/` + the session `probes/` — 32 modules | `fbbe0820ef4b176a` (impl worktree, UNMODIFIED — byte-identical to the ORACLE) | reproduces `probes/README.md` EXACTLY: 9 ACCEPT (m03 23, m07 23, m09 23, m11 28, m12 31, m17 28, m18 29, m19 28, m26 25; all STRICT 2b `0 violation(s), 0 unproven`) / 18 DECLINE with the recorded strings; va ACCEPT 19; vb/vc = m01; vd/ve as recorded | M-impl | 2026-09-13 14:1x |
| `lit --filter control_swap_accept_select_rail_after_prep` (the T1 pins, written BEFORE any pass edit) | `fbbe0820ef4b176a` | 2/2 PASS | M-impl | 2026-09-13 14:2x |
| per-probe pipeline over `probes/` + session `probes/` | `2fd12991d3e91d10` (SUBJECT: grammar + ladder + gate-2c seed + H-1 + H-7) | 11 DECLINE→ACCEPT (m01/m02/m04/m06/m10/m13/m15 + owner file + vb/vc + U1), 1 decline-string move (m05 → `condition measured before the control route`), 0 ACCEPT→DECLINE; **owner file ACCEPT 29 lines = the T1 prediction 29/29**, STRICT 2b `8 mints / 6 left allocated, 2 free: 2 verified, 0 violation(s), 0 unproven`; va unchanged ACCEPT 19 | M-impl | 2026-09-13 14:5x |
| H-1 counterfactual (`Cond = R.Condition` restored, ONE line, nothing else) | `4a8d52d4defc583d` (throwaway, reverted) | m01/m02/m04 ACCEPT→`control flow` exit 1, deterministic over 3 repeat runs ⇒ the emitter was walking the ERASED φ | M-impl | 2026-09-13 14:4x |
| H-6 discriminator on the FROZEN ORACLE (`m15u` = m15 in the rail-leaf spelling, `m15i` = compare spelling, `s04` = the shipped S†) | `fbbe0820ef4b176a` (ORACLE) | `m15u` **ACCEPT 29, 2b clean**; `s04` **ACCEPT 16, 2b clean**; `m15i` DECLINE `condition predates a non-diagonal gate` | M-impl | 2026-09-13 15:0x |
| H-9 control on the FROZEN ORACLE (`h9_ctl` = m17 + `cq_invert` brackets) | `fbbe0820ef4b176a` (ORACLE) | ACCEPT exit 0, STRICT 2b clean, then LINKFAIL `___cq_invert_begin`/`___cq_invert_end` ⇒ m13's new disposition is the PRE-EXISTING Phase-8 state | M-impl | 2026-09-13 15:0x |
| `lit --filter mergephi` (the 7 decline fixtures) | `2fd12991d3e91d10` | 7/7 PASS; `..._measure_before.ll` separately verified RED on the ORACLE `fbbe0820` for the OLD string | M-impl | 2026-09-13 15:1x |
| `ctest -R ir-pass-lit` (ONCE, at hand-off) | `2fd12991d3e91d10` | 1894 PASS / 1 XFAIL / **7 FAILED — ALL a worktree-PATH artefact, 0 regressions**: each carries a bare `NOROUTE-NOT: phi` that matches "phi" inside the module path `.../CQ_mphi/...`. Re-run from a path with no "phi": **7/7 PASS and 7/7 lowered IR byte-identical to the ORACLE**. Effective: 1901 PASS / 1 XFAIL / 0 regressions. Filed in IMPL_M.md §7.5 | M-impl | 2026-09-13 15:2x |
| corpus sweep ORACLE-vs-SUBJECT (ONCE, at hand-off) — `ir-pass/test/*.ll` + every `PROTOCOL.md` session probe dir | `2fd12991d3e91d10` vs `fbbe0820ef4b176a` | **2681 rows: 2668 unchanged, 11 DECLINE→ACCEPT (every one `control flow` at a select), 2 decline-string moves (m05 + its fixture → `condition measured before the control route`), 0 ACCEPT→DECLINE, 0 both-accept lowered-IR changes.** Artifact `probes/impl/corpus_2fd12991d3e91d10.txt` | M-impl | 2026-09-13 15:3x |

**NOT run by this agent, by protocol (the "implementation" column):** `ctest -R '^e2e-'`, the full `ctest`,
`cq-opt-equivalence`, any twin matrix, the duplicate-body fixture scan.
**NOT run because the H-6 STOP deferred the work that would be their subject:** the injection (mutation)
matrix and the three e2e slices — the ACCEPT fixtures and slices they run over were deliberately not written
(`IMPL_M.md` §7).

### After the orchestrator's H-6 = ADMIT ruling (2026-09-13 pm) — binary `ae216b3727f5b1ec`

The rung-0 predicate dropped its `RailLadderProven` conjunct (ruling item 2), so the binary moved
`2fd12991d3e91d10` → `ae216b3727f5b1ec`. Every row below is on the NEW binary; rows above it are facts about
the OLD one and stay as the record of how it got here.

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| item-2 measurement: the compare-guarded prep customer (`i2_cmpladder.c`, single-φ merge, no peel ⇒ F2/rb9x not reached) | `fbbe0820` ORACLE / `2fd12991` subject | BOTH `control flow`; the region is CLAIMED (exactly ONE diagnostic, at the select) and was refused by the `RailLadderProven` conjunct ALONE | M-impl | 2026-09-13 16:0x |
| item-2 after the change | `ae216b3727f5b1ec` | `i2_cmpladder` **ACCEPT 21 lines**, STRICT 2b `6 mints / 5 left allocated, 2 free: 2 verified, 0 violation(s), 0 unproven`; `i2_otherclass` (a claimed VALUE-class region) still DECLINES `control flow` on BOTH binaries | M-impl | 2026-09-13 16:1x |
| bd `3d8q` sibling probe (two SIBLING readers of the pre-rotation name) | `fbbe0820` ORACLE | `p3d8q_sibling_rail` (rail-leaf spelling) **ACCEPT 30 lines, 2b clean** ⇒ the hole is PRE-EXISTING; `p3d8q_sibling` (φ spelling) DECLINE `control flow` | M-impl | 2026-09-13 16:0x |
| bd `3d8q` sibling probe | `ae216b3727f5b1ec` | `p3d8q_sibling` **ACCEPT 31 lines** ⇒ Track M ADDS CUSTOMERS to bd `3d8q`; no fence built (ruling) | M-impl | 2026-09-13 16:1x |
| whole probe set re-run | `ae216b3727f5b1ec` | identical to `2fd12991` on every probe EXCEPT `m16` (run-time `a`), which moves DECLINE → **ACCEPT 31 lines**, 2b `3 free: 3 verified, 0 violation(s), 0 unproven` — the item-2 widening's own customer | M-impl | 2026-09-13 16:1x |
| `NOROUTE-NOT: phi` hygiene fix, 7 fixtures | `ae216b3727f5b1ec` | all 7 re-anchored to `{{= phi }}`; `lit --filter` GREEN **from the `CQ_mphi` worktree path**, where they previously failed; anchor re-validated against a module that DOES carry a surviving `phi` (it reddens) | M-impl | 2026-09-13 16:2x |
| `lit --filter` per new fixture (16 new: 8 accept, 8 decline) | `ae216b3727f5b1ec` | 16/16 PASS. Header scan for directive-looking prose before the first RUN line: 0 hits (one was found and fixed — a literal `CHECK:` inside a comment IS a directive) | M-impl | 2026-09-13 16:3x |
| **injection (mutation) matrix**, 8 accept fixtures × 7 mutations | `ae216b3727f5b1ec` | **56 applied, 0 MISSED, 0 N/A.** First pass was 43 applied / 1 MISSED / 13 N/A — the MISSED was a missing `RYCNT` prefix, the 13 N/A were the MUTATORS not tolerating `, !dbg !N`; both fixed and re-run. Artifact `probes/impl/injection_matrix_ae216b37.txt` | M-impl | 2026-09-13 16:4x |
| the 4 e2e slices, each `ctest -R '^e2e-slice-<name>$'` | `ae216b3727f5b1ec` | 4/4 PASS — `cascade-two-bools` **29**, `_base` **19**, `_uncond` **28**, `_int` **28** lines, every one STRICT stage 2b `0 violation(s), 0 unproven`. The 29 lines equal the T1 prediction 29/29 | M-impl | 2026-09-13 16:5x |
| the 2 new CMake gates + their MUTANT VALIDATION | `ae216b3727f5b1ec` | `base-prefix-identical` and `twin-identical` PASS; **5 mutations, 5 correct verdicts, and the two gates are COMPLEMENTARY** (prefix-half perturbation reddens only the prefix gate; select-half copy swap reddens only the twin gate; a truncated golden, an `h1`→`h10` alias attempt and a dropped line all redden loudly) | M-impl | 2026-09-13 16:5x |
| `ctest -R ir-pass-lit` (ONCE, at hand-off; pass source changed) | `ae216b3727f5b1ec` | **PASSED, 50.77 s. 1908 discovered / 1907 PASS / 1 XFAIL / 0 FAILED** — the 7 path-artefact failures are gone (fixed, not masked) | M-impl | 2026-09-13 17:0x |
| corpus sweep ORACLE-vs-SUBJECT (ONCE, at hand-off; hash changed) | `ae216b3727f5b1ec` vs `fbbe0820ef4b176a` | see IMPL_M.md §6 — artifact `probes/impl/corpus_ae216b3727f5b1ec.txt` | M-impl | 2026-09-13 17:1x |

**Counts after Track M** (measured, not quoted): `ls ir-pass/test/*.ll` **1908** (was 1893) ·
`ls tests/e2e/*.expected.log` **359** (was 355) · `ctest -N` **409** (was 403).

**STILL not run by this agent, by protocol:** `ctest -R '^e2e-'` as a whole, the full `ctest -j6`,
`cq-opt-equivalence` (⚠ **OWED at merge**: a decline string moved and analysis sites changed — see
`PROTOCOL.md`'s "iff a decline string / analysis site changed"), any twin matrix, the duplicate-body scan.

| new decline fixture `..._mergephi_chained_arm.ll` (= boi6 probe `p20`, the probe this increment is NAMED after) | `ae216b3727f5b1ec` / `fbbe0820` ORACLE | RED on the ORACLE (`control flow` — the leaf grammar pre-empts), GREEN here (`condition predates a non-diagonal gate` — rung (iii)/gate 2c). Added AFTER the corpus sweep, so its two verdicts were measured directly on both binaries rather than swept | M-impl | 2026-09-13 17:2x |
| rebuild after a COMMENT-ONLY edit to `SelectClassify.cpp` | `ae216b3727f5b1ec` | hash UNCHANGED — confirms the build is deterministic and that the corpus sweep's binary is the one on disk | M-impl | 2026-09-13 17:2x |

### Round-1 FIX (F-M1 / F-M3 / F-M6 / F-M5 / F-M7) — binary `0d3105d0eb9d476a`

`ControlRegion::PrepRegionIdx` + its ONE precedence edge moved the binary
`ae216b3727f5b1ec` → **`0d3105d0eb9d476a`**. Comment-only edits after that re-hashed identically (verified).

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| the 24 round-1 review probes, re-run | `0d3105d0eb9d476a` | **`r03` DECLINE → ACCEPT 33 lines**, STRICT 2b `8 mints / 6 left allocated, 3 free: 3 verified, 0 violation(s), 0 unproven`. **Every other probe identical to `review_M_r1.md`'s table** (r18 40, r05 43, r12 41, r13 31, r14 21, r15 31, r17 29, r22 43, r07 31, r08/r09 29; r01/r16 the wire string, r04 `control flow`, r21 the loop string, r02 `rotation angle`, r10/r11 the seed string, r19/r20 `control flow`) | M-fix | 2026-09-13 18:0x |
| **F-M1 counterfactual** (the edge disabled, one statement, nothing else) | `253a80e6d9d45f16` (throwaway, reverted) | `r03` ACCEPT → `control flow` exit 1 (the H-1 backstop), while `r18` (inert third construct) ACCEPT 40 and `r17` (owner file) ACCEPT 29 are UNAFFECTED ⇒ the edge is exactly what fixes `r03` and changes nothing else | M-fix | 2026-09-13 18:1x |
| the four customers, re-measured | `0d3105d0eb9d476a` | owner file **29** (trace byte-identical to the committed golden), `m16` **31**, `i2_cmpladder` **21**, `va` **19** — all STRICT 2b `0 violation(s), 0 unproven`; the 4 cascade e2e slices still PASS | M-fix | 2026-09-13 18:2x |
| **F-M6** K-independence (`clang -O1`, no `-g`) | `0d3105d0eb9d476a` | `r22` lowered IR **78 lines / 19 gate calls at K=3 AND at K=1000** ⇒ ROLLED, not unrolled | M-fix | 2026-09-13 18:2x |
| **F-M6** the rolled-vs-hand-unrolled twin | `0d3105d0eb9d476a` | both slices ACCEPT **43** lines, traces **BYTE-IDENTICAL** (`compare_files`); gate mutant-validated (copies swapped in trip 2 ⇒ REDDENS) | M-fix | 2026-09-13 18:3x |
| `lit --filter` per new/touched fixture (3 new: `_rail_then_kickback`, `_inloop_outside_prep`, `_inplace_arm`) | `0d3105d0eb9d476a` | 3/3 PASS; the two new DECLINE-side ones verified RED on the ORACLE `fbbe0820` for the OLD string | M-fix | 2026-09-13 18:3x |
| **VACUITY CHECK (new instrument)** over every accept's named pure negatives | `0d3105d0eb9d476a` | first run **5 VACUOUS across 3 fixtures** (a `NOX`/`NOFREE` naming a handle the module never defines — incl. the non-negotiable `NOX` on a SECOND user register); all fixed; re-run **56 named negatives across 10 fixtures, 0 VACUOUS**. Instrument `probes/impl/vacuity.py` | M-fix | 2026-09-13 18:4x |
| **injection matrix**, 10 accept fixtures × 8 mutations (an 8th added for F-M6: a gate HOISTED OUT of the loop body) | `0d3105d0eb9d476a` | **79 applied, 0 MISSED, 1 N/A** (`rail-handle-in-imm-slot` has no shape in the in-loop module). ⚠ It was the matrix that caught the vacuous `NOX`: `x-on-user-register` reddened `XCNT` but NOT `NOX` on two fixtures. After the fix `NOX` catches it in **all 10**. Artifact `probes/impl/injection_matrix_0d3105d0.txt` | M-fix | 2026-09-13 18:4x |
| `ctest -R ir-pass-lit` (ONCE, at hand-off) | `0d3105d0eb9d476a` | **PASSED, 39.26 s. 1912 discovered / 1911 PASS / 1 XFAIL / 0 FAILED** | M-fix | 2026-09-13 18:5x |
| corpus sweep ORACLE-vs-SUBJECT (ONCE after the fix; now also covering `trackM/review_M_r1_probes/`) | `0d3105d0eb9d476a` vs `fbbe0820ef4b176a` | see `FIX_M_R1.md` §6 — artifact `probes/impl/corpus_0d3105d0eb9d476a.txt` | M-fix | 2026-09-13 19:0x |

**Counts after the fix:** `ls ir-pass/test/*.ll` **1912** · `ls tests/e2e/*.expected.log` **361** ·
`ctest -N` **414**.

**STILL not run, by protocol (row "fix"):** `ctest -R '^e2e-'` as a whole, the full `ctest -j6`,
`cq-opt-equivalence` (⚠ **OWED at merge** — decline strings moved and analysis sites changed), any twin
matrix, the duplicate-body scan.

