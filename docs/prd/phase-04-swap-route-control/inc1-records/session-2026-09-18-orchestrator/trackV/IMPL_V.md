# Track V — the NESTED-LOOP axis for `tools/loop_twin_matrix.py` (bd `test_C_libtooling-vsr6`)

Worktree `/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abab679cc6af1707e`,
branch `twinmatrix-nested-axis`, off `main` `cff8f7ac`. Files touched:
`tools/loop_twin_matrix.py`, `tools/loop_twin_matrix.expected.txt`,
`tools/loop_twin_matrix.quarantine.txt`, `tools/loop_twin_matrix_quarantine_test.py`, and records +
probes under `$SES/trackV/`. **No file under `ir-pass/`, `include/`, `runtime/` or `tests/` was
opened for writing.**

The worktree binary is BIT-IDENTICAL to the session ORACLE — measured, not assumed:

```
9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3  build/ir-pass/cq-opt
3e3dc35d471aae6b53067ffc374745f8cd9f148870a1879d971c8bdab831695d  build/ir-pass/libCQPass.so
```

both equal to `PROTOCOL.md`'s ORACLE block, so every measurement below is a fact about `9bd01598`
and every gate recorded at that hash elsewhere is CITED rather than re-run (§6).

---

## 0. The one-paragraph summary

The twin matrix has a **NESTED-LOOP axis** — 23 cells, `382` total — and it found **eight
rolled-vs-unrolled TRACE DIVERGENCES on `main`'s own compiler**, on the day it first existed. That is
the bead working exactly as filed: bd `emkg` was a P1 over-accept whose whole content is two loops
and it passed every gate in the tree, because no shipped fixture had the shape,
`free_pairing_check.py` is blind to TEMPLATE-minted rails by construction, and the one instrument
that CAN see a leaked template rail had 359 cells and not one second `for`. The eight are
quarantined as **classes D and E**, root-caused, and each class's attribution to the nesting was
**measured** rather than argued — class D reproduces on NEITHER of its three single-loop isolations
(so it NEEDS both loops), class E reproduces on BOTH of its two (so it does NOT). The `n1`/`n2`/`n3` column is `UNROLLED-ONLY` today with the
same diagnostic `$THIS/GATES.md` records for the committed probes, which is the row bd `emkg`'s fix
put there and the row a future widening moves. All **359 pre-existing cells are byte-unchanged**
(718 cell/surface pairs, **0 MOVED**, proven not asserted). The axis ships with two new boundary
controls, three new selftest guards and three new selftest cases — 52 → **58 cases, 0 failures**,
3 + 3 — and a mutant harness that made the whole thing fail on purpose **13 times out of 13,
0 MISSED**.

⚠ **§7 is the part to read: what the axis CANNOT witness.** It is written in L10's terms because the
bead was filed in them.

---

## 1. The axis

### 1.1 Why it had to exist, and why it is named `l2*`

`cells_of_matrix()` was a PREFIX × REGION × SUFFIX product over a **single** loop plus four
sub-grids, and the token `nest` inside it means a nested **CONTROL REGION** (`if (b && a == off)`),
never a nested loop. So none of its 359 cells could see a defect that needs two loops. bd
`test_C_libtooling-emkg` is exactly such a defect: conjunct (1) of
`declineDephasingUnmarkedLoopRails` read `L->blocks()`, which includes every strictly deeper
subloop's blocks, while conjunct (3) read `L`'s own — so a MARKED INNER loop set `Marked=true` and
`continue`d, and the OUTER loop's per-trip which-path rails leaked at a later non-diagonal gate. One
face of it **reproduced on the ORACLE**. It passed 2047 lit fixtures, the complete e2e layer, STRICT
stage 2b and 338 twin cells.

The cells are named `m_none_l2<region>_none_none_<inner>` and **not** `nest*`: `nest` is taken, it
means something else in this file, and a cell called `m_none_nest…` would be read as a
condition-tree cell by everyone who has read the rest of the module. `l2` = "a second loop". The
distinctness is asserted at import (`N_REGION` disjoint from `REGION`/`RY_REGION`/`B_REGION`/
`K_REGION`; `N_INNER` disjoint from `RGATE`/`BCARRY`/`K_READ`).

### 1.2 The geometry, and the one piece `_wrap` could not previously express

`_wrap` unrolls exactly ONE loop — the `for` it writes — and emits everything else verbatim on both
sides. For the CORE product that is all that is needed: **the inner loop is body text**, so it is
repeated `TRIPS` times on the twin and rolled on both sides, and the SUBJECT is the outer loop. No
`_wrap` change at all.

Sub-grids N2 and N4 need the opposite: a loop that **encloses** the subject and stays rolled on both
sides. `preloop`/`postloop` sit outside the repetition but on ONE side of it each, so spelling an
enclosure with them would mean putting an unmatched `{` in a slot documented as "a line" — a trick,
not a mechanism. So `_wrap` gained one parameter, `enclose=(open, close)`, defaulting to `None`,
emitted identically on both spellings, with `open` placed BEFORE the `index` path's `int i = 0;` so
the counter re-initialises on every enclosing trip exactly as the subject `for` does. Sub-grid N3
(the sibling) needed **nothing**: `preloop` is already documented as "before the loop, outside the
repetition on both sides", which is precisely what a faithful sibling wants (Rule 14 — ask the slot
that already owns the position).

The geometry is **asserted per cell**, not trusted: the twin loses the subject `for`, repeats every
`for` inside the body `TRIPS` times, and emits every enclosing/sibling `for` once, i.e.
`nu == nr - 1 + body_fors * (TRIPS - 1)`. ⚠ **The obvious spelling `nu == nr - 1` is WRONG** and was
measured wrong on all 19 core cells before it was corrected — the inner loop is body text, so the
twin carries two of it. Writing the weaker sentence down first would have made the guard red against
a correct axis, which is the other way an instrument lies.

### 1.3 The three axes, and the one place the bead's wording was ambiguous

| axis | values | seed |
|---|---|---|
| INNER (the `<rgate>` slot) | `l2im` fully iteration-local, hence MARKED — the emkg silencer · `l2iu` reads the OUTER register, hence unmarked — the control · `l2ic` marked only by clause (ii-c) | `n1` / `n2` / `n3`'s inners |
| OUTER-OWN-RAIL (the region token) | `l2n` none · `l2b` the per-trip TEMPLATE bit rail `(a >> (i+1)) & 1` · `l2c` the `icmp` USED AS DATA `a > (i+1)` | `n1`–`n3`'s outer rail; `r3`'s |
| POST-LOOP INTERFERENCE (the trailing `d`) | absent · `a = cq_theta(a, 0.9)` after the nest | `n1`–`n3` |

⚠ **The bead spells the middle axis "none / root mint / cmp-rail data" and the middle term is
ambiguous in the tree's own vocabulary.** "Root mint" is `railPhiRootMint`'s `cq_theta` allocation,
and **none of the three seed probes puts one in the outer body** — all three put the TEMPLATE bit
rail there. Both readings are covered rather than guessed between: the template-rail reading is
`l2b` (and it is the seeds' own), and the root-mint reading is **sub-grid N2**, whose enclosing loop
mints `w` per trip. Recorded as an ambiguity resolved by construction, not as a reading.

### 1.4 The four sub-grids, 23 cells

| sub-grid | cells | seed | what it points at |
|---|---|---|---|
| **N1** CORE | 18 | `n1`/`n2`/`n3`, `r3` | 3 outer-rail × 2 interference × 3 inner. The bead's own product |
| **N2** INVERTED | 2 | `r2_outer_marked_inner_rail` | the enclosing loop is the MARKED one and the SUBJECT is the inner — the emkg conjunct from the other side. `r2`'s header argues that direction is SOUND; a cell that pins a verdict an argument says is right is still a cell, because the argument is not the gate |
| **N3** SIBLING | 2 | `r5_sibling_loops_one_marked` | the marked loop is a PEER. **The control that says the defect was about CONTAINMENT** and not about "some marked block exists in this function" — without it every N1 verdict is equally explained by a function-wide marking bug |
| **N4** DEPTH-3 | 1 | `r1_triple_nest_mid_rail` | the subject in the MIDDLE of three. `r1` became a fixture because its rolled and unrolled TRACE LINE COUNTS AGREE (72 = 72) while the gate MULTISET does not — a shape a line-count comparison cannot see and a byte-diff can |

Sizes are ASSERTED in `cells_of_matrix()` (`120/36/118/14/50/21/23`), so an axis edit that silently
changes the cost of the suite's long pole stops the run.

**The cost, measured before it was committed** (this gate IS the suite's long pole, and
`CLAUDE.md`'s tools table says nothing goes into it without a named conjunct it is the witness for):
the 23 cells alone took **2 min 26 s wall / 145 s CPU at `--jobs 4` on a box at load ~45**
(`probes/nest_cells_only.py`). Scaled to the gate's own `--jobs 6`, that is of the order of half a
minute on a quiet box against its ~180–400 s band — the same order as bd `rpkr`'s 21 bank cells
(18.3 s measured at `--jobs 6`, load ~30). ⚠ Both figures are LOADED-box figures and are not
comparable with each other or with a quiet-box one; they are quoted with their load per Rule 19.

---

## 2. SEED FIDELITY — byte identity is NOT reached, and the committed probe is the tie-breaker

The brief asks the generator to produce the `n1`/`n2`/`n3` shapes EXACTLY and says, in the same
sentence, that if it cannot, *the committed probe is the tie-breaker and you say so*. **It cannot,
and here is the measurement rather than the adjective** (`probes/seed_fidelity.py`, normalising
whitespace, comments, the `#include` line and `main`'s spelling):

```
python3 probes/seed_fidelity.py --tools <worktree>/tools
    n1_nested_marked_inner        m_none_l2bd_none_none_l2im    13 normalised line(s) differ
    n2_nested_unmarked_inner      m_none_l2bd_none_none_l2iu    15
    n3_nested_iic_inner           m_none_l2bd_none_none_l2ic    15
    r1_triple_nest_mid_rail       m_none_l2d3d_none_none_l2im   20
    r2_outer_marked_inner_rail    m_none_l2invd_none_none_none  13
    r3_nested_cmp_rail_outer      m_none_l2cd_none_none_l2im    13
    r5_sibling_loops_one_marked   m_none_l2sibd_none_none_none  18
    a9_nested_loop                m_none_l2n_none_none_l2iu     13
    (+ the seven `_un` twins)                             seed_fidelity: 284 total
```

**Every one of those differences is a fixed property of `_wrap` that every one of the 382 cells
carries**, and they are enumerable:

1. the head is `int a = 0; … a = cq_theta(a, 0.5);` where the probes write `int y = cq_theta(5, 0.5);`
   — the same construct (a SOURCE theta on a classical constant seed) with a different seed VALUE and
   a different register name; it moves the `cqrt_alloc_i32` immediate and nothing structural;
2. the counter runs `0 .. TRIPS-1` where the probes run `1 .. 2`, so the subscripts are spelled
   `(a >> (i + 1)) & 1` and `a > (i + 1)` — **the same shifts 1 and 2**;
3. the tail is `return cq_measure(a) + s;` where the probes write `return s + cq_measure(y);`;
4. the twin binds `i` with `int i = 0; … i = i + 1;` where the probes hand-wrote the constants —
   which is `_wrap`'s documented `index` mechanism, and `-O1` constant-propagates it;
5. sub-grid N2's cell additionally carries the `a` register `r2` has no equivalent of (the head is
   fixed for every cell), which adds an `alloc`/`ry`/`measure` triple identically to both sides.

**The tie-breaker is therefore the committed probe, and the evidence that the generator produced the
right SHAPE is the VERDICT, not the text**: `m_none_l2bd_none_none_{l2im,l2iu,l2ic}` come out
`UNROLLED-ONLY` with the rolled diagnostic `cq loop lowering: rolled body leaks a rail entangled
with a rotated register` — character-for-character the disposition `$THIS/GATES.md` records for
`n1`/`n2`/`n3` on this same binary (*"rolled DECLINE ×3 (same string as s2); twins ACCEPT 42 / 34 /
48"*).

---

## 3. WHAT THE AXIS FOUND — eight divergences on `main`

`probes/nest_verdicts_9bd01598.tsv`, measured through the gate's own code path
(`probes/nest_cells_only.py` stubs `cells_of_matrix` to `nest_cells` and calls `main()`):

| cell | verdict |
|---|---|
| `m_none_l2n_none_none_l2im` · `…_l2iu` | ACCEPT-IDENTICAL |
| `m_none_l2nd_none_none_l2im` · `…_l2iu` | ACCEPT-IDENTICAL |
| `m_none_l2inv_none_none_none` · `m_none_l2invd_none_none_none` | ACCEPT-IDENTICAL |
| `m_none_l2sib_none_none_none` · `m_none_l2sibd_none_none_none` | ACCEPT-IDENTICAL |
| `m_none_l2bd_none_none_{l2im,l2iu,l2ic}` | **UNROLLED-ONLY** `cq loop lowering: rolled body leaks a rail entangled with a rotated register` |
| `m_none_l2cd_none_none_{l2im,l2iu,l2ic}` | **UNROLLED-ONLY**, same string |
| `m_none_l2d3d_none_none_l2im` | **UNROLLED-ONLY**, same string |
| `m_none_l2b_none_none_{l2im,l2iu,l2ic}` | **TRACE-DIVERGENCE** → quarantine |
| `m_none_l2c_none_none_{l2im,l2iu,l2ic}` | **TRACE-DIVERGENCE** → quarantine |
| `m_none_l2n_none_none_l2ic` · `m_none_l2nd_none_none_l2ic` | **TRACE-DIVERGENCE** → quarantine |

**8 ACCEPT-IDENTICAL, 7 UNROLLED-ONLY, 8 TRACE-DIVERGENCE** — counted mechanically
(`awk '{print $2}' probes/nest_verdicts_9bd01598.tsv | cut -f1 | sort | uniq -c`) and not read off
the table, because an eyeballed tally of exactly this kind was corrected by a cross-check once
already in this instrument's history (`$PREV/trackI/IMPL_I.md` §1.4, 8/9/4 read where 9/9/3 was
measured). Full traces and diffs: `probes/nest_divergences_9bd01598.txt`.

### 3.1 CLASS D — 6 cells, and it NEEDS BOTH LOOPS

The FLAT twin discharges the outer rail's intermediate every repetition
(`cq_template_lshr_i32_hl_unc(h1, h0, 1); cqrt_free(h1)`, or `cq_template_icmp_sgt_i32_hl_unc` for
the `l2c*` spelling); the ROLLED form emits neither, on any trip. Counts `(4, 4, N)` against
`(6, 6, N)` — two `_unc` and two `cqrt_free` missing, one per trip. **ROLLED IS THE DEFICIENT SIDE.**

⚠ **The attribution is MEASURED, with three isolations, all ACCEPT-IDENTICAL on the same binary**
(`probes/attribution_9bd01598.txt`):

| isolation | what it removes | verdict |
|---|---|---|
| `single_bitrail` | the inner loop entirely — one loop, the outer rail alone | ACCEPT-IDENTICAL 13 == 13 |
| `q_nestinlineplain` (a BOUNDARY CONTROL) | the inner `for`, keeping its gates inline; no interference | ACCEPT-IDENTICAL 35 == 35 |
| `q_nestinline` (a BOUNDARY CONTROL) | the same with the interference | ACCEPT-IDENTICAL |

⚠ **Provenance of those three rows, stated exactly.** `single_bitrail` and the 35 == 35 figure are
`probes/attribution.py`, built through `_wrap` with the same arguments `control_sources` passes.
`q_nestinline`'s ACCEPT-IDENTICAL was measured **through `control_sources`** by the nest-only driver,
which reported `BOUNDARY CONTROL has NO PINNED VERDICT … It was measured (ACCEPT-IDENTICAL)` — the
loop by which a pin is obtained honestly instead of guessed. `q_nestinlineplain`'s pin was written
from the identical-body `attribution.py` row and is **validated by the two full-matrix runs**, which
build both controls through `control_sources` and REFUSE TO WRITE (and red the gate) if either
verdict differs from its pin.

So the SUB-LOOP is necessary, and the two controls are what keep that sentence a measurement rather
than a reading — they run on every invocation, `--regenerate` included, and both write modes refuse
while a control has moved.

⚠ **It is the column the bd `emkg` fix does not reach.** Add the post-loop non-diagonal gate — the
`l2bd`/`l2cd` column, which is `n1`/`n2`/`n3` verbatim — and the compiler DECLINES on the rolled
side. Without it the same leak is silent. It is Rule-6 formally safe today (left allocated, never
freed dirty) and NOT a wrong unitary in these six programs, because nothing interferes with `a`
afterwards; the rails are still entangled which-path records of `a`'s bits, so this is the Rule-8
hazard **one line of C away**.

### 3.2 CLASS E — 2 cells, and it does NOT need the nesting

`clang -O1` hoists the loop-INVARIANT `cq_template_and_i32_hl(h0, 1)` rail (clause (ii-c)'s subject)
out of every loop that encloses it: on the ROLLED side that is BOTH loops, so it is minted ONCE; on
the FLAT side the outer loop is gone, so it is minted once per repetition. Counts `(4, 4, 14)`
against `(4, 4, 15)` — same discharge, ONE extra rail on the flat side. **NEITHER side is deficient
in discharge**; neither discharges it at all.

⚠ **Measured, and it is the opposite answer to class D's**: `inline_iic` (no loop around it) diverges
30 == 30 lines with IDENTICAL counts `(2, 2, 12)` — a pure POSITION divergence — and
`single_iic_loop` (one loop) diverges `(2, 2, 8)`/20 against `(1, 1, 7)`/17. **The nesting adds the
COUNT difference on top of a position difference that is there without it.** It is the
`x1`/`x8`/`x9` family and `CLAUDE.md`'s Q-R1-1 item arriving through a nest.

Two cells carry BOTH classes (`l2b`/`l2c × l2ic`); their `class` field says `D+E` and their digest
covers both.

### 3.3 The bd attribution, stated with its limit

All eight blocks name **bd `test_C_libtooling-s82e`** — an OPEN P1 whose own text is *"an in-loop
leak of entangled which-path rails … ROOT CAUSE: `markIfRailLocal`'s 'accumulating loop-invariant
tainted input' clause is a LEAK, NOT A DECLINE … THE WITNESS IS THE ROLLED-VS-HAND-UNROLLED TRACE
PAIR, which is the only instrument in the tree that sees it."* That is this class and this
instrument. ⚠ **But `s82e`'s own six-line reproducer has ONE loop**, and class D is measured NOT to
reproduce on any single-loop spelling — so the nesting-specific face is a **NEW POPULATION** of a
filed defect, and §8 asks for a bead of its own. A quarantine may not name an id that does not
exist, which is why the blocks point at the filed class and the request is here.

⚠ It was deliberately **not** attributed to bd `vsr6` itself: that bead closes with this landing, and
a quarantine pointing at a closed bead is a quarantine nobody will retire.

---

## 4. THE 359 PRE-EXISTING CELLS — 0 MOVED, proven

`probes/source_identity.py`, carried from `$PREV/trackI/probes/` with ONE change (`--tools <DIR>`, so
the BASELINE is read from `main`'s own `tools/` rather than from a copy taken before editing — which
removes the one way that discipline can go wrong):

```
python3 probes/source_identity.py --tools /Users/.../CQ_lang/tools --dump baseline.tsv
    dumped 718 cell/surface pair(s)
python3 probes/source_identity.py --tools <worktree>/tools --check baseline.tsv
    source_identity: 718 baseline pair(s), 764 in this run, 46 NEW, 0 MOVED
```

359 cells × 2 surfaces = 718, **0 MOVED**; 23 × 2 = 46 NEW. So any verdict change another track sees
on a pre-`vsr6` cell is theirs, not mine. The baseline is committed
(`probes/source_identity_baseline_main.tsv`).

---

## 5. THE L10 OBLIGATION — made to fail on purpose, 13 of 13

`CLAUDE.md` L10: *an instrument's failure mode is to report a PASS, so the only instrument worth
citing is one that has been made to fail on purpose.* `probes/mutants.py` edits a COPY of
`tools/loop_twin_matrix.py` (or, for M13, of the committed quarantine), runs the UNMODIFIED selftest
by the same command the ctest entry runs, and counts.

```
python3 probes/mutants.py <worktree>
    mutants: 13 applied, 13 CAUGHT, 0 MISSED, 0 NOT-APPLIED
```

| id | what it breaks | caught by |
|---|---|---|
| M1 | `nest_cells()` returns nothing | sub-grid size assert |
| M2 | sub-grid N4 dropped | sub-grid size assert |
| M3 | the inner loop INLINED — `l2im` stops being a loop | `< 2 for(` in the rolled source |
| M4 | the ENCLOSING loop dropped (N2) | same |
| M5 | the SIBLING loop dropped (N3) | same |
| M6 | the enclosure OPENS on the rolled side only | the subject-loop invariant |
| M7 | the axis not wired into `cells_of_matrix()` | "defined but NOT in cells_of_matrix()" |
| M8 | the interference column collapses onto its sibling | "generate the SAME source" |
| M9 | the enclosure CLOSES on the unrolled side only | same |
| M10 | `l2iu` given `l2im`'s body — the UNMARKED column becomes a copy of the MARKED one | the inner-axis mint/read discriminator |
| M11 | a boundary control loses its pin | "no pinned verdict … and not declared unmeasurable" |
| M12 | the axis renamed CONSISTENTLY | the interference-column check |
| M13 | a committed quarantine block names a cell the matrix does not produce | the quarantine-cell guard |

⚠ **The harness found two real holes in my own cases before it told the truth, and both are worth
more than the 13/13.**

* **M10 was MISSED.** Nothing in the file discriminated the three inner columns, so `l2iu` given
  `l2im`'s body was a silent duplicate — the axis would have had two marked columns and one fewer
  control, and every other check stayed green. Closed by asking the question the axis is ABOUT: the
  mint count and the outer-register read, per column (`l2im` 1 mint / no read, `l2iu` 0 mints / reads
  `a`, `l2ic` 1 mint / reads `a`), plus pairwise distinctness.
* **M11 was MISSED, for the reason the bank axis's own cases were once missed**: `install()`
  REPLACES `SURFACE_CONTROL_VERDICTS` with a stub in which every control is pinned, so a guard that
  read the module attribute was reading the stub. Closed by capturing the committed tables before any
  stubbing — the same `_REAL_CELL_NAME` discipline, one table over. (The stub itself is now DERIVED
  from `QUARANTINE_CONTROLS` rather than listed, so a new control cannot silently escape it, which is
  exactly what a hand-written two-entry dict did when `q_nestinline` arrived.)
* **M12 was caught by the WRONG GUARD**, which left `case_quarantined_cells_exist` unpinned — bd
  `e1gr`'s shape (two checks mutually redundant over the corpus, neither individually measured). M13
  exists for that reason and touches only the committed quarantine.
* An earlier spelling of the subject-loop invariant (`nu == nr - 1`) was **red against a correct
  axis** on all 19 core cells. A guard that fails on the truth is the other way an instrument lies;
  it is now derived from `GATE_ALL[rgate]` and `TRIPS`.

Selftest: **58 cases, 0 failures** (52 before this track — measured on both trees, not counted by
reading; the file's own docstring said 51 while it printed 52, and that is corrected).

---

## 6. GATES — see `GATES.md` for the hash-keyed lines

CITED, never re-run at `9bd01598` (PROTOCOL §6.1): `$THIS/GATES.md`'s `n1 / n2 / n3 nested (loopfix
probes) | 9bd01598 | rolled DECLINE ×3 (same string as s2); twins ACCEPT 42 / 34 / 48 | claude |
2026-09-17`, which is the disposition §2 checks the generated cells against.

RAN (each announced in `$SES/GATES_INFLIGHT.md` first, with no matching IN-FLIGHT line at this hash
when it started): the worktree build; `probes/nest_cells_only.py` (23 cells); `probes/attribution.py`;
`probes/nest_diverge_detail.py`; `probes/source_identity.py`; `probes/mutants.py`; the quarantine
selftest; ONE `loop_twin_matrix.py --regenerate` over all 382 cells; ONE
`ctest -R '^e2e-loop-twin-matrix$'`; ONE `ctest -R '^e2e-loop-twin-quarantine-selftest$'`.

NOT run, and not claimed: the full `ctest -j6`, `ir-pass-lit`, `^e2e-`, the equivalence sweep, any
corpus sweep. None of them can witness a `tools/`-only change whose compiler is byte-identical to
`main`'s, and the merge-and-gate agent owns them.

---

## 7. ⚠ WHAT THE AXIS CANNOT WITNESS — in L10's terms, because that is how the bead was filed

1. **A wrong unitary that both halves share.** The ORACLE is the twin, and for a CORE cell the twin
   is the same compiler on a flat spelling. A defect the rolled and flat paths SHARE is
   byte-identical on both and reports `ACCEPT-IDENTICAL`. That is
   `m_none_pbitd_none_premark_rypost`'s lesson — *a cell whose two halves agree because BOTH are
   wrong is precisely what `ACCEPT-IDENTICAL` cannot see; only a fence can.*
2. **The unitary at all** (Rule 2). There is no simulator and there will not be one.
3. **Rail identity at a free.** That is stage 2b — and stage 2b is blind to template-minted rails, so
   for a *template* rail freed dirty **neither instrument is a witness**. Do not read the pair as a
   partition.
4. **Cross-function defects** (bd `1yeu`): one function per module, this axis included.
5. **DEPTH BEYOND THREE, and BREADTH BEYOND ONE.** Every CORE cell has exactly one inner loop and
   `TRIPS = 2` at every level. A defect that needs a third sibling inside one body, four levels, or
   K ≥ 3 at any level is invisible here. ⚠ **This is the direct analogue of the bd `uq96`
   second-pass lesson** (every `B_ARM` declaring its second register outside the loop): if it turns
   out the nested defects live at depth 4 or at unequal trip counts, this axis will need a second
   pass and nothing here will have hinted at it.
6. **The inner loop is never the twin's subject except in sub-grid N2**, which has TWO cells and no
   inner-kind axis of its own. "Marked ancestor, rail in the inner loop" is measured at one point,
   not on a grid.
7. **Class E's position divergence is not attributed to a line of the pass.** §3.2 measures WHERE it
   appears and WHERE it does not; the owner (`markIfRailLocal`'s invariant-input clause) is read off
   bd `s82e`'s own root-cause text, not re-derived here.
8. **Nothing here is a fence.** Eight cells now pin eight divergences to their exact signature. That
   makes them un-drift-able; it does not make them fixed, and a quarantine is not a blessing.
9. **`nest_cells_only.py` is not the gate.** It stubs `cells_of_matrix`, so it can only ever say what
   the 23 new cells do; the committed table and the ctest entry are what pin them.

---

## 8. §bd — the exact text for the orchestrator to apply (I cannot write `bd` from a worktree)

```
bd update test_C_libtooling-vsr6 --append-notes "2026-09-17 Track V — LANDED, branch
twinmatrix-nested-axis. tools/loop_twin_matrix.py has a NESTED-LOOP axis: 23 cells
(m_none_l2*_none_none_*), 359 -> 382. Four sub-grids: N1 CORE 18 = 3 outer-own-rail
(none/bit-rail/icmp-as-data) x 2 post-loop interference x 3 inner (marked / unmarked /
(ii-c)-only), seeded from n1/n2/n3 and r3; N2 INVERTED 2 (r2, the enclosing loop marked
and the INNER one the subject — needed a new _wrap parameter `enclose`); N3 SIBLING 2
(r5, the containment control); N4 DEPTH-3 1 (r1, subject in the middle). All 359
pre-existing cells byte-unchanged (source_identity.py: 718 pairs, 0 MOVED). Two new
boundary controls (q_nestinline, q_nestinlineplain), both ACCEPT-IDENTICAL on void and
declared UNMEASURABLE on the retired register surface. Selftest 52 -> 58 cases, 0
failures; mutant harness 13 applied / 13 CAUGHT / 0 MISSED (two real holes found in my
own cases first — see IMPL_V §5). MEASURED ON THE ORACLE 9bd01598: 8 ACCEPT-IDENTICAL,
7 UNROLLED-ONLY, 8 TRACE-DIVERGENCE (counted by uniq -c, not read). The n1/n2/n3 column (l2bd x l2im/l2iu/l2ic) is
UNROLLED-ONLY with 'cq loop lowering: rolled body leaks a rail entangled with a rotated
register' — the row a widening moves. BYTE IDENTITY WITH THE COMMITTED PROBES WAS NOT
REACHED (seed_fidelity.py: 284 normalised differing lines over 15 comparisons, all of
them fixed _wrap properties every cell carries — the head's seed/register name, the
counter running 0..TRIPS-1 with (i+1) subscripts, the return term order, the twin's
bound counter); the committed probe is the tie-breaker, and the evidence the SHAPE is
right is that the verdict matches THIS/GATES.md's recorded n1/n2/n3 disposition
character-for-character. Records: SES/trackV/IMPL_V.md, GATES.md, probes/."

bd close test_C_libtooling-vsr6
```

**AND THE NEW FILING — this is the substantive one.** The axis found eight divergences on `main`'s
own compiler; six of them are a face of bd `s82e` that `s82e`'s own reproducer cannot reach:

```
bd create --type bug -p 1 --title "loop_twin_matrix class D: with an INNER loop present, the rolled OUTER loop never discharges its own per-trip template rail while the hand-unrolled twin does — needs BOTH loops, three single-loop isolations are identical" --description "
Found 2026-09-17 by the bd test_C_libtooling-vsr6 NESTED-LOOP axis of
tools/loop_twin_matrix.py, on the ORACLE 9bd01598 (main's pass source, unchanged).
6 cells: m_none_l2{b,c}_none_none_{l2im,l2iu,l2ic}.

SHAPE: an OUTER loop with its own per-trip rail off the loop-invariant register —
'(a >> (i+1)) & 1' for the l2b cells, the icmp-as-data 'a > (i+1)' for the l2c ones —
and an INNER loop left rolled. The FLAT twin discharges the outer rail's intermediate
every repetition (cq_template_lshr_i32_hl_unc(h1, h0, 1); cqrt_free(h1), resp.
cq_template_icmp_sgt_i32_hl_unc); the ROLLED form emits neither, on any trip.
Counts: rolled (4, 4, N) vs flat (6, 6, N) — two _unc and two cqrt_free missing.

IT NEEDS BOTH LOOPS, MEASURED, three isolations all ACCEPT-IDENTICAL on the same
binary: single_bitrail (one loop, the outer rail alone) 13 == 13; the boundary control
q_nestinlineplain (the same program with the inner loop written out FLAT, no
interference) 35 == 35; the boundary control q_nestinline (the same with the
interference). So bd s82e's own six-line one-loop reproducer cannot reach this face;
this is a NEW POPULATION of that filed class, not a new class.

IT IS THE COLUMN THE bd emkg FIX DOES NOT REACH: add the post-loop non-diagonal gate
(the l2bd/l2cd column = n1/n2/n3 verbatim) and the compiler DECLINES on the rolled side
('cq loop lowering: rolled body leaks a rail entangled with a rotated register').
Without it the same leak is silent.

GRADE: Rule-6 formally safe (left allocated, never freed dirty) and NOT a wrong unitary
in these six programs, because nothing interferes with 'a' afterwards. The rails are
entangled which-path records of 'a' bits, so it is the Rule-8 hazard one line of C
away, and free_pairing_check.py is blind to it by construction (TEMPLATE-minted, no
cqrt_alloc to count). DIRECTION: the ROLLED side is deficient.

OWNER: the leak side of markIfRailLocal / the per-activation discharge of an OUTER
loop's own chain when a sub-loop is present (bd s82e's root cause, reached through a
nest). Quarantined by pinned signature in tools/loop_twin_matrix.quarantine.txt as
CLASS D; retire the blocks and --regenerate when this closes.
Evidence: SES/trackV/probes/{nest_divergences,attribution}_9bd01598.txt, IMPL_V §3.1.
"

bd create --type bug -p 2 --title "loop_twin_matrix class E: the hoisted loop-invariant (ii-c) read is minted a DIFFERENT NUMBER OF TIMES rolled vs flat once two loops are present, and neither side discharges it" --description "
Found 2026-09-17 by the bd test_C_libtooling-vsr6 NESTED-LOOP axis, ORACLE 9bd01598.
2 cells: m_none_l2{n,nd}_none_none_l2ic (and it also rides on the two D+E cells).

SHAPE: the inner loop additionally measures the loop-INVARIANT 'a & 1' (clause (ii-c)'s
subject). clang -O1 hoists the cq_template_and_i32_hl(h0, 1) rail out of every enclosing
loop: ROLLED that is BOTH loops, so it is minted ONCE; FLAT the outer loop is gone, so
once per repetition. Counts (4, 4, 14) vs (4, 4, 15) — same discharge, one extra rail
flat. NEITHER side discharges it at all.

IT DOES NOT NEED THE NESTING, measured: inline_iic (no loop at all) diverges 30 == 30
with IDENTICAL counts (2, 2, 12) — a pure POSITION divergence — and single_iic_loop
(one loop) diverges (2, 2, 8)/20 vs (1, 1, 7)/17. The nesting adds the COUNT difference
on top of a position difference present without it. It is the x1/x8/x9 family and
CLAUDE.md's Q-R1-1 item arriving through a nest.

OWNER: markIfRailLocal's 'accumulating loop-invariant tainted input' clause is a silent
REFUSAL rather than a decline (bd s82e's root cause), so the hoisted rail is emitted and
never discharged on either side. DIRECTION: neither side is deficient in DISCHARGE; the
flat side simply leaks one more. Quarantined as CLASS E.
Evidence: SES/trackV/probes/{nest_divergences,attribution}_9bd01598.txt, IMPL_V §3.2.
"

bd update test_C_libtooling-s82e --append-notes "2026-09-17: the bd vsr6 NESTED-LOOP
axis adds 8 quarantined customers to this class (tools/loop_twin_matrix.quarantine.txt
classes D and E). SIX of them (class D) do NOT reproduce on any single-loop spelling —
three isolations measured ACCEPT-IDENTICAL on the same ORACLE 9bd01598 — so this bead's
own six-line one-loop reproducer cannot reach that face; filed separately. 'Pre-existing'
is true of the defect and FALSE of its population."
```

If the owner prefers the two new beads NOT to exist, the quarantine blocks stay pointed at `s82e`
and nothing else changes; the `bd` field is the only line that would move.

---

## 9. What I could NOT do

1. **I could not reach byte identity with the committed probes** (§2). The differences are
   enumerated and every one of them is a fixed `_wrap` property.
2. **I could not run the full `ctest -j6`, `ir-pass-lit`, `^e2e-` or any corpus sweep** — the
   PROTOCOL matrix gives those to the merge-and-gate agent, and none of them can witness a
   `tools/`-only change whose compiler is byte-identical to `main`'s.
3. **I could not measure the `register`-surface verdict of either new boundary control**: no
   register-surface `CQ.h` exists in the tree. They are declared in `CONTROL_UNMEASURED` and are
   built, compared and PRINTED there, never gated — with the reason written at the declaration,
   because asserting a verdict nobody has run is the failure L10 names.
4. **I did not root-cause class D or E in the pass source.** Both are attributed by MEASUREMENT
   (three isolations each) and by bd `s82e`'s own recorded root cause; no line of `LoopLowering.cpp`
   was read for this. The beads in §8 say so.
5. **I did not audit `tools/inplace_twin_matrix.py` or `tools/angle_select_twin_matrix.py`**, which
   share `_wrap`'s `phi_void_source` import but not `_wrap` itself, and which bd `gfsk` names as the
   same shape. Outside this bead.
