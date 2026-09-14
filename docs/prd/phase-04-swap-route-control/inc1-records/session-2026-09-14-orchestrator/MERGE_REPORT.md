# MERGE-AND-GATE REPORT — session 2026-09-14, the ONE GROUP gate

> ⚠ **SUPERSEDED IN ITS VERDICT, NOT IN ITS MEASUREMENTS — READ §10 FIRST.** Everything below §1–§9 is
> the gate as it stood at first run and every number in it is still a fact about the binary
> `5c6f7490a81c7505…`, which **did not move** through the resolution. **§10 records the resolution pass
> and the GREEN re-run: 442/442.** The RED verdict below is kept verbatim because it is the record of
> what the group gate found; it is not the final state of the tree.

**VERDICT AT FIRST RUN: RED.** The combined gate fails. Three ctest entries fail out of 444, all reproduced
serially (contention excluded). Two of the three are **attributable to Track D alone** and reproduce
on Track D's OWN binary `4394b349`, so they are not a composition; the third is the twin matrix,
whose 41 moved cells are all attributed. **Do not squash on this tree as it stands** — §S1's rule is
that a red group gate is bisected, and it has been: the bisection is complete and per-track below.

Nothing was regenerated. No golden, no twin-matrix table, no quarantine row was touched.

---

## 1. The merge

Worktree `/Users/sorenwilkening/Desktop/CQ_merge`, branch `merge-gate-2026-09-14`, off `main` `28eac7d2`.

| # | track | bd | branch | tip | merge commit |
|---|---|---|---|---|---|
| 1 | T | `uq96` | `twin-matrix-bool` | `b360bc79` | `6d6cf118` — clean |
| 2 | U | `z9t1` | `undef-seed-zero` | `4e7ef89f` | `1ef4f4ac` — clean |
| 3 | F | `om35` | `f2-phi-descendant` | `5537b6c9` | `599c8e3b` — 1 conflict |
| 4 | P | `3qps`+`4aiu` | `mergephi-phase-leaf` | `ff3d210d` | `ab88d94f` — 1 conflict |
| 5 | W | `wx8g` | `inloop-bool-prep` | `85a94c9d` | `0abcbd49` — 1 conflict |
| 6 | D | `3d8q` | `stale-reader-fence` | `e509e418` | `c1ee7035` — clean |

**MERGED TIP `c1ee70350790381d9253e093222d383178e00bff`.** All six tips verified as ancestors.

**BINARIES (every gate line below is a fact about these):**
```
build/ir-pass/cq-opt       5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8
build/ir-pass/libCQPass.so 5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4
```
Built with `cmake --build build -j8` (whole tree; never `--target CQPass` alone). Exit 0. The only
compiler warnings are the three that already exist on `main` (`RegionTreeDetect.cpp` `OuterNeg`/
`InnerNeg`, `TaintPropagation.cpp` `PhiFns`/`M`) — verified against `main`'s sources. **No new warning.**

### 1a. Conflicts and how they were resolved

1. **`trackF/GATES.md` — add/add, DOCS ONLY.** Track F branched from `607b6fe4`, before `main`'s
   scaffolding commit `28eac7d2` created the SCOPING agent's `trackF/GATES.md` at the same path.
   Resolved by **UNION**, implementation table first, scoping table appended under a marked heading
   with a merge note. **No gate line was edited.**
2. **`tests/e2e/CMakeLists.txt` — content, TWICE (Track P, then Track W). ⚠ THIS IS THE FINDING THE
   BRIEF ASKED FOR.** The brief's premise — "append-only at disjoint anchors" — is **false**: Tracks
   U, P and W all appended at the *same* anchor, the tail immediately above the `get_property(...)`
   block that the file itself requires to stay LAST. Resolved by **UNION** in merge order (U, P, W),
   verified mechanically: **0 duplicate `add_test(NAME ...)`**, 434 registrations, and the
   `get_property`/`set_tests_properties` sweep is still the final statement. The resolution is
   semantically unambiguous, but the *anchor claim* should be corrected in the protocol: it is a tail
   anchor shared by every track that adds slices, so it will conflict on every multi-track merge.

---

## 2. Duplicate-body scan (L8) — PASS

`merge_gate_probes/dupscan_verdicts.py`, extended from Track F's committed `dupscan.py` so that it
reports the property that matters instead of only a count: for each duplicate-body group it reads
each member's **claimed verdict** off its RUN lines (`not %cq-opt` = DECLINE fixture, bare `%cq-opt` =
ACCEPT fixture) and flags groups that MIX them.

```
fixtures: 1993
  comment=lstrip, blanks=KEPT      groups=7  CONTRADICTORY-VERDICT groups=0
  comment=lstrip, blanks=DROPPED   groups=9  CONTRADICTORY-VERDICT groups=0
  comment=col0,   blanks=KEPT      groups=6  CONTRADICTORY-VERDICT groups=0
  comment=col0,   blanks=DROPPED   groups=8  CONTRADICTORY-VERDICT groups=0
TOTAL CONTRADICTORY-VERDICT groups across all four normalisations: 0
```

* The four counts are **7/9/6/8 — identical to Track F's reconciliation at 1938 files**, at 1993 files
  with 69 fixtures added. No new duplicate body was introduced by the merge.
* All 8 groups are pre-existing pairs and every one is verdict-consistent (listed in
  `merge_gate_probes/dupscan_verdicts.log`).
* **No `git mv`'d fixture was resurrected.** All four deletions across the six branches are confirmed
  absent from the merged tree: `control_swap_reject_select_mergephi_tree_leaf.ll` (P),
  `control_inplace_ry_reject_rail_inloop.ll`, `control_inplace_ry_reject_stateprep_inloop_iterlocal.ll`,
  `control_inplace_ry_reject_inloop_iterlocal_base.ll` (W).

---

## 3. The full suite — **RED, 3/444**

```
ran: ctest --test-dir build -j6 --output-on-failure | 5c6f7490a81c7505
     99% tests passed, 3 tests failed out of 444.  Total Test time (real) = 497.00 sec
     FAILED: 318 e2e-loop-twin-matrix
             406 e2e-slice-control-select-bool-round2-window
             409 e2e-slice-control-select-cmp-round2-window
```
Load at start `3,69` (quiet); at end `6,67`. The two slice failures were **re-run at `-j1` and failed
identically in 1.82 s** — contention excluded.

### 3a. FAILURE 1 + 2 — the two `round2-window` e2e slices. **ATTRIBUTED: TRACK D ALONE.**

```
error: <unknown>:0:0: in function slice i32 ():
       cq opcode lowering: rotation/measure operand predates a non-diagonal gate
```
Both are multi-TU slices (`run_slice_multi.sh`). Reproduced the exact stage-1+`llvm-link` input and
ran it on every track binary:

| binary | `...select_bool_round2_window` | `...select_cmp_round2_window` |
|---|---|---|
| ORACLE `f7b65d8c` | ACCEPT | ACCEPT |
| U `a5773be1` · F `96fdd3a9` · P `283e3b33` · W `d47297cf` | ACCEPT | ACCEPT |
| **D `4394b349`** | **DECLINE (D's new string)** | **DECLINE** |
| MERGED `5c6f7490` | DECLINE | DECLINE |

**This is a single-track regression, not a composition**, and the PROTOCOL matrix is why no one saw
it: the implementer never runs `^e2e-`, and the merge gate is the only runner.

**It is very likely INTENDED and only half-landed.** Track D deliberately INVERTED the matching lit
fixture `control_swap_select_cmp_round2_window_accept.ll` from ACCEPT to DECLINE (its new header is
explicit: the module is the P1 stale-reader class, `b = cq_theta(x,.25); … b3 = cq_theta(x,.9);`, and
"this module ACCEPTED on the frozen session ORACLE"). **What it did not do is convert the two e2e
slices and their goldens of the same program.** So the goldens still assert the circuit the fence now
calls a miscompile. Owner/orchestrator decision required — either the goldens are records of the
defect and must be retired/converted with the fixture, or the fence over-declines. **I did not
regenerate them.**

### 3b. FAILURE 3 — `e2e-loop-twin-matrix`, 41 cells moved (338 cells, 295.63 s)

```
loop_twin_matrix [--phi-surface void]: 338 cells — 162 ACCEPT-IDENTICAL, 90 DECLINE, 86 other;
29 quarantined (pinned signatures), 2 boundary controls
    ACCEPT-IDENTICAL 161 · ACCEPT-IDENTICAL-WARN 1 · DECLINE-BOTH 53 · DECLINE-BOTH-DIFFERENT 37 ·
    TRACE-DIVERGENCE 29 · UNROLLED-ONLY 57
    control q_armoncond TRACE-DIVERGENCE · control q_noregion ACCEPT-IDENTICAL
FAILED (41)
```
**TRACE-DIVERGENCE stayed at 29 against 29 quarantined and both boundary controls held** — the safety
pins of the instrument are intact. The 41 movers, by class:

| n | transition | attributed |
|---|---|---|
| 17 | `UNROLLED-ONLY (rail record read past an in-place gate)` → `DECLINE-BOTH-DIFFERENT` (+ D's new string) | **D** |
| 14 | `UNROLLED-ONLY (control flow inside a loop body)` → **ACCEPT-IDENTICAL** | **W** |
| 8 | `DECLINE-BOTH-DIFFERENT (loop body ∥ state prep merged…)` → `DECLINE-BOTH (state prep merged…)` | **W** |
| 1 | `UNROLLED-ONLY (condition predates a non-diagonal gate)` → **ACCEPT-IDENTICAL** — `m_none_ddilry_none_none_binv` | **W** ⚠ see 3c |
| 1 | **`ACCEPT-IDENTICAL` → `DECLINE-BOTH`** (D's new string) — `m_none_pbitd_none_premark_rypost` | **D** |

### 3c. Against Track W's recorded predictions (`trackT/IMPL_T.md` §8, and the same table in `loop_twin_matrix.py`)

| prediction | measured | held? |
|---|---|---|
| the **eight** named loop-message rows → `ACCEPT-IDENTICAL` | **5 of the 8 flipped**: `bilry_binv`, `nbilry_binv`, `bilprep_binv`, `dilry_binv`, `bil2_binv`. **3 did NOT**: `m_none_bilry_none_none_bcar`, `m_none_nbilry_none_none_bcar`, `m_none_bilprep_none_none_bcar` — still `UNROLLED-ONLY / control flow inside a loop body` | **PARTIAL** — an over-decline survives on the `il*` × `bcar` (loop-carried) combination |
| (not predicted) | **9 further cells flipped**, all `*bry*` — the bare-`_Bool` Ry axis from Track T's FIRST pass (`c12a2afe`), which the prediction table (written for the second pass's ten `il*` cells) never covered. Coherent with `wx8g`'s capability | n/a — a **gap in the prediction**, not a defect |
| `m_none_ddilry_none_none_binv` → **UNMOVED** ("it dies at gate 2c before the loop clause… if it flips, the cause is not clause (c) and **must be found**") | ⚠ **IT FLIPPED**, `UNROLLED-ONLY` → `ACCEPT-IDENTICAL`. **FOUND, as instructed** — see below | **FAILED** |
| `m_none_dilesc_none_none_binv` → **UNMOVED** ("a move there means clause (c3) is gone") | **UNMOVED.** Not in the 41 | **HELD** — the safety pin of the increment is intact |

**`m_none_ddilry_none_none_binv`, found.** The cell's two C sources were dumped from the instrument
(`merge_gate_probes/dump_cell.py`, written to `ddilry_rolled.c` / `ddilry_flat.c`) and run on every
binary:

```
ORACLE f7b65d8c   rolled DECLINE(condition predates a non-diagonal gate) · flat ACCEPT
U · F · P · D     rolled DECLINE(same)                                   · flat ACCEPT
W  d47297cf       rolled ACCEPT                                          · flat ACCEPT
W  40edde36       rolled ACCEPT   <-- ALREADY IN TRACK W'S ROUND-2-CLEARED BINARY
MERGED 5c6f7490   rolled ACCEPT                                          · flat ACCEPT
```
**Attributed: Track W alone, and it is in the CLEARED code, not in the three post-clearance edits.**
The resulting circuit is not internally inconsistent — rolled and flat traces are **byte-identical
(28 lines each)** and STRICT stage 2b is clean on both — so what moved is a *gate-2c* decline the
instrument had pinned as untouchable, on a shape (`a = cq_theta(a, 0.9)` after the loop, a
non-diagonal gate on the CONDITION's own wire) whose flat spelling already accepted on the ORACLE.
**It needs a ruling, not a regeneration**: either 2c's rolled-side refusal was an over-decline that
`wx8g` legitimately removed, or the flat side is a pre-existing over-accept now extended to the
rolled form.

### 3d. Track W's post-clearance binary move — **the orchestrator's judgement is VERIFIED BY MEASUREMENT**

The brief flagged that Track W's binary moved `40edde36` → `d47297cf` after its round-2 clearance, by
three edits accepted as "decline-direction or diagnostic-only", with "your full suite and sweep are
the verification of that judgement". I built `40edde36` (`git worktree ../CQ_wbisect` at `1dee47e2`;
the rebuilt hash reproduced `40edde36678c7dd4…` exactly) and swept **2385 modules** — the whole
fixture corpus + every Track W probe + all 290 corpus movers — on both:

```
ran: 40edde36 vs d47297cf over 2385 modules | VERDICT DIFFS 0 | STDERR DIFFS 1
     the one stderr diff: trackW/review_r1_probes/c3_rotate_after.c
       40edde36  error: <unknown>:0:0: … control flow under quantum control
       d47297cf  error: …/c3_rotate_after.c:10:42: … control flow under quantum control
```
**0 verdict changes, 1 GAINED source location.** The three edits are diagnostic-only in effect, as
judged. (This also means `ddilry` and `d4_noRailRegion` below are in the cleared code.)

---

## 4. `cq-opt-equivalence-full` — GREEN

```
ran: cmake --build build --target cq-opt-equivalence-full | 5c6f7490a81c7505
     cq_opt_equivalence: compared 1993 fixtures, 0 mismatch(es)   (2 min 53 s)
```
Owed by U, F, D and W. Discharged.

---

## 5. The corpus sweep — **COMPLETE** (the session's sweep debt, repaid)

`merge_gate_probes/sweep_one.sh`, `-P6`, **4194 rows in 6 min 45 s, run to completion** (not closed by
a tail argument). Corpus = `ir-pass/test/*.ll` (1993) + every `probes`/`review_*_probes`/`fix_*_probes`
dir of this session's six tracks (including Track D's live `review_r3_probes`) + the 2026-09-11,
2026-09-13 and `session-{9pum,b6ap,f2-i1,l4x4,boi6,r903}` dirs. Output:
`merge_gate_probes/corpus_5c6f7490a81c7505.txt`. 1 `CLANGERR`, identical on both binaries
(`session-2026-09-11/review_integration_probes/U0_uncommented.c`) — the same one Track U reported.

Each row also byte-compares the **full stderr** of the two binaries, which closes PROTOCOL S3's blind
spot (the `cq_measure_<sfx>` family renders as an empty tag under the shared regex, so a
decline→decline string change inside it is invisible to the tag).

### 5a. Movers, attributed **per track by MEASUREMENT** (not by string)

290 verdict movers. Every one was re-run on the ORACLE, on each of the five single-track binaries
(Track T has no pass source; its binary IS the ORACLE) and on the merged binary
(`merge_gate_probes/attrib_one.sh`; full table `corpus_attribution_5c6f7490.txt`):

| attributed to | movers | character |
|---|---|---|
| **D** | **107** | 104 `ACCEPT → DECLINE` on D's new string + 3 decline→decline. **All decline-direction.** 12 of these are shipped `ir-pass/test` fixtures — and **all 12 were converted by Track D in this merge and now carry a `RUN: not` line**, which is why lit is green. The two unconverted casualties are the e2e slices in §3a |
| **U** | **70** | 16 F1→ACCEPT, 13 `undef/poison literal reaches two emitted gate operands`→ACCEPT, **38 `ACCEPT→ACCEPT` with a CHANGED lowered IR** (spot-verified: the diff is exactly `cqrt_alloc_i1(i1 undef)` → `cqrt_alloc_i1(i1 false)` — the ruling, working), 3 other |
| **P** | **47** | 14 `branch phase on a bare i1 condition`→ACCEPT, 7 → `condition predates`, 3 → `condition measured before`, the rest `control flow`→ACCEPT |
| **W** | **40** | 38 `control flow inside a loop body`→ACCEPT, 1 D→D, **1 `ACCEPT → DECLINE`** — see 5c |
| **F** | **18** | F2 (`state prep seed is proven equal to the condition register`)→ACCEPT |
| **COMPOSITION** | **8** | see 5b |
| **unattributable** | **0** | — |

### 5b. The 8 composition movers — **two are NEW and unreviewed**

* **4 × `trackD/review_r{1,2}_probes/…/r12_owner_grover.{c,ll}` — F × U, benign.** Track F alone makes
  it accept; Track U alone still declines; the merged md5 differs from F's by exactly one line,
  `cqrt_alloc_i1(i1 undef)` → `cqrt_alloc_i1(i1 false)`. The composed result is strictly **more**
  correct than F's alone (F's stream materialises an `undef` at the allocation, which is the very
  defect `z9t1` closes).
* **1 × `trackF/review_r1_probes/p9_undef_seed.ll` — this is X1.** Known, reviewed (F-F1-3).
* ⚠ **3 × `trackP/review_r1_probes/r19_phi_and_prepcond.{c,s1.ll}` and
  `session-2026-09-13/trackM/probes/m28.c` — a genuine F × P composition that NO track's gate could
  see and no review has cleared.** Under F alone each declines `control flow` (leaf grammar); under
  P alone each declines at F2; **together they ACCEPT.** Both are "a condition TREE whose leaves are
  preps' merge φs" (`if (b1 && b0) cq_phi(0.3)` and `if (b1 && b0) a -= 3;`). Measured on the merged
  binary: STRICT stage 2b clean (`r19` 3 mints / 1 free verified; `m28` 8 mints / 2 frees verified),
  streams well-formed — `h0`/`h1` read only as Toffoli controls, ancillas bracketed and returned to
  `|0⟩` before their free. **Sound as far as this gate can see, but it is a new accept the group
  created and the tracks' Rule-13 rounds did not examine.** Traces are in this report's probe dir.

### 5c. The one ACCEPT→DECLINE outside Track D: `trackW/review_r1_probes/d4_noRailRegion.c`

ORACLE ACCEPT → MERGED `control flow inside a loop body`. Attributed to **Track W**, and present
already at `40edde36` (the cleared binary). Context that makes it probably intended: Track W's own
round-1 review measured this exact program as a rolled-vs-unrolled **TRACE DIVERGENCE (28 vs 34
lines)** that reproduced on the ORACLE. Declining it is the safe direction. Filing it as an
over-decline candidate with that note rather than as a defect.

### 5d. **Diagnostic LOCATIONS — CLEAN** (`merge_gate_probes/locscan_one.sh`)

Every row that declines on either binary (2060 modules) had its diagnostic's location field compared:

```
ran: diagnostic-location scan, 2060 decline rows | 5c6f7490a81c7505
     LOST locations (real file:line:col -> <unknown>:0:0)        0
     GAINED locations (<unknown>:0:0 -> real file:line:col)      21
     new declines with NO location, from a .c source            0
     new declines with NO location, from hand-written .ll       42  (those modules carry no !dbg at all)
```
**Zero `!dbg` lost.** The 21 gains are Track W's `declAnchor` located-anchor fallback. Separately, 41
rows have the SAME first diagnostic string but a different full stderr; inspected — every one is
either a gained location or the decline moving to a LATER function because the first one now lowers
(e.g. `b1_twofn.c` `f_pass:10` → `f_fail:22`). None is a regression.

---

## 6. X1–X5, each with its measured verdict

| # | verdict | measurement |
|---|---|---|
| **X1** | ✅ **HELD, and stronger than predicted** | `p9_undef_seed.ll`: ORACLE **DECLINE at F1** → MERGED **ACCEPT**. And the byte-for-byte claim is confirmed: the lowered IR of `p9` on the merged binary is **identical** (modulo `ModuleID`/`source_filename`) to that of `control_inplace_ry_stateprep_phidesc_collider_accept.ll`. **Undef spelling of every Track-F customer also run**: `cascade_two_bools`, `cascade_three_bools`, `vd`, `w2`, each in base and undef spelling — on the merged binary the undef spelling gives the **same verdict as its `= 0` twin in all four**, and for the three that accept the **runtime traces are BYTE-IDENTICAL** (29/29, 35/35, 45/45 lines) with STRICT 2b clean on all six. `w2` stays a `control flow` decline in both spellings (the pre-existing wall) |
| **X2** | ✅ **HELD** | The F2 family re-asked with BOTH changes present: all **39** F2-naming fixtures mutated so every `@cq_theta_*` SEED operand is `undef` (`x2_mutate.py`), run on both binaries. **0 ACCEPT on the merged binary.** 4 movers, all DECLINE→DECLINE, every one moving from F1 (`seed does not match the merge incoming`) to a *later, more specific* fence (F2 ×3, `state prep merged with a quantum register` ×1) — i.e. Track U removes the trivial F1 mismatch and lets the real fence answer. **No accept was manufactured by the composition** |
| **X3** | ✅ **HELD** | `r7_mbeta_base_offcone.ll` and `r12_mbeta_ifelse_rechain.ll` both stay **DECLINE (F2)** on the merged binary. The M-β RAUW did not manufacture a φ-descendancy |
| **X4** | ✅ **HELD** | `r5_round2_phidesc.ll` ORACLE DECLINE(F2) → MERGED **ACCEPT**; control `r5c_round2_nonphidesc.ll` **DECLINE(F2) on both**. F2's conjunct really is asked over the post-emission graph |
| **X5** | ⚠ **THE TRIGGER FIRED — the fixtures held, but the SHAPE IS NOW REACHABLE** | See below |

### X5 in full

**The two named fixtures did not move.** `control_inplace_ry_reject_stateprep_backedge_phidesc_collider.ll`
and `…_nonphidesc_collider.ll` both DECLINE at F2 on the merged binary, with a **byte-identical
`CQ_CTRL_DBG` anchor** to the ORACLE (`decline [state prep seed is proven equal to the condition
register] at: %c = icmp eq i32 %q, 7`), and `lit --filter backedge` is 4/4 green.

**But the retirement trigger's premise is now FALSE, and this is the loud part.**
`ArmClassify.cpp`'s trigger (3a) says `wx8g` "is the ONLY reason the back-edge-φ shape is unreachable
rather than merely narrowed", and instructs: *"The day `wx8g` lands, the back-edge fixture pair is the
tripwire: re-derive this skip against the shapes `wx8g` admits, and do not assume the φ case is the
only cyclic one."* `wx8g` landed in this merge. Three probes built from the shape Track W now admits
(`merge_gate_probes/x5{a,b,c}_*.c`):

```
                                        ORACLE                              MERGED
x5a_inloop_prep_backedge_carry    D: control flow inside a loop body   D: state prep merged with a
                                                                          quantum register (F1)
x5b_inloop_prep_guard_collider    D: control flow inside a loop body   ACCEPT  (2b clean, 9 lines)
x5c_inloop_ry_backedge_carry      D: control flow inside a loop body   ACCEPT  (2b clean, 8 lines)
```
The fence that made the shape unreachable is gone. `x5a` — an in-loop bare-`_Bool` state prep whose
loop-header φ takes the region's merge-φ descendant **on its back edge**, i.e. exactly the available
collider the dominance skip was narrowed for — now **reaches the state-prep fences** and declines at
**F1**, with a source-located `!dbg`. Safe direction, and nothing I could construct over-accepts. But
the argument text in `ArmClassify.cpp` is now **stale**, the skip is **live rather than vacuous**, and
the re-derivation the comment demands is **OWED**. This is the one composition the session created by
design and did not measure; it is measured now.

---

## 7. Re-measured counts for the closing pass (merged tree, `5c6f7490a81c7505`)

| metric | 2026-09-13 close (`59ac5b7`) | **merged 2026-09-14** |
|---|---|---|
| `ctest --test-dir build -N` | 420 | **444** |
| `^e2e-` | 410 | **434** |
| `^e2e-slice-` | 365 | **383** |
| `twin-identical` | 34 | **40** |
| `ls ir-pass/test/*.ll \| wc -l` | 1928 | **1993** |
| `ls tests/e2e/*.expected.log \| wc -l` | 367 | **385** |
| twin cells (`grep -c '^m_' expected` + `grep -c '^cell ' quarantine`) | 259+29 = 288 | **309+29 = 338** |
| `cq-opt-equivalence-full` | 1928/0 | **1993/0** |

⚠ These are measured on a tree whose full suite is RED. If §3a is resolved by converting the two
slices, `^e2e-slice-` and the golden count move; re-measure after the fix.

---

## 8. What the orchestrator must decide, and what a partial re-run costs

1. **§3a — the two `round2-window` e2e slices (Track D).** Ruling needed: retire/convert the slices
   and goldens with the fixture Track D already inverted, or treat the fence as over-declining.
   Re-run after the fix: `ctest -R '^(e2e-slice-control-select-bool-round2-window|e2e-slice-control-select-cmp-round2-window)$'`
   (1.8 s) — plus a full suite only if pass source changes.
2. **§3b/3c — the twin matrix.** 40 of the 41 movers are intended-direction and attributed. A
   deliberate `--regenerate` is owed **after** a ruling on `m_none_ddilry_none_none_binv` and on the
   three `il* × bcar` cells that did NOT flip. **I did not regenerate.** Re-run after: `ctest -R '^e2e-loop-twin-matrix$'` (~296 s).
3. **§5b — the F × P composition (`r19_phi_and_prepcond`, `m28`).** A new accept no track reviewed.
   Sound at 2b + trace; wants a Rule-13 opinion on the composition, not on either track alone.
4. **§6/X5 — `ArmClassify.cpp` retirement trigger (3a).** Its premise is now false. The comment must
   be re-derived and a bd issue filed; the shape is reachable and declines at F1 today.
5. **§5c — `d4_noRailRegion.c`** (Track W, ACCEPT→DECLINE, safe direction, pre-existing trace
   divergence) — file as an over-decline candidate.
6. **§1a — the protocol claim** that `tests/e2e/CMakeLists.txt` merges at "disjoint anchors" is false
   and should be corrected.

Everything else in the group is green: the build, the duplicate scan, equivalence, the corpus sweep's
attribution (0 unattributable), the diagnostic-location scan (0 lost `!dbg`), and X1–X4.

**No stale citation was found.** In particular the VOID Track-D binary `6480de5f` is referenced
nowhere in anything this gate consumed.

## 9. Housekeeping

* Bisect worktree `/Users/sorenwilkening/Desktop/CQ_wbisect` (detached at `1dee47e2`, binary
  `40edde36678c7dd4…`) was created for §3d and can be removed; it was never written to.
* Merge worktree `/Users/sorenwilkening/Desktop/CQ_merge` is left in place at `c1ee7035` for the
  orchestrator. **Not squashed, not pushed**, per the brief.
* All evidence is under `$SES/merge_gate_probes/`.


---

# 10. RESOLUTION PASS — coordinator dispositions 1–5. **FINAL VERDICT: GREEN, 442/442.**

⚠ **THE BINARY DID NOT MOVE.** The resolution touched `tests/e2e/` (two slices unregistered, two
goldens deleted), added one `ir-pass/test` fixture, and edited `tools/loop_twin_matrix.py` (a Python
instrument). Rebuilt and re-hashed: `cq-opt 5c6f7490a81c75057fe73abcd…` and
`libCQPass.so 5276f7ab7416b36b3ceeb8…` — **BIT-IDENTICAL** to the gated build. So §5 (corpus),
§5d (locations), §4 (equivalence) and §6 (X1–X5) are **`cited:`**, not stale, and every hash key above
is still the hash on disk.

## 10.1 Disposition 1 — the two e2e slices: CONVERTED (Track D's ruling, completed)

The e2e layer has **no decline shape**, and this slice's own registration block said so already:
*"`run_slice*.sh` runs under `set -euo pipefail` and byte-diffs a golden, so a program whose `opt`
exits non-zero cannot be a passing slice at all (there is no WILL_FAIL and no decline runner in this
file)."* The existing precedent is `slice_control_switch_phase.c` (2026-09-05): **keep the `.c`
unregistered with the record in its header, DELETE the golden, leave a `REMOVED` block at the anchor.**
That shape was followed exactly — nothing invented.

* Both `.c` files and both `_lib.c` files **kept**, each with a full conversion header: what the
  program was, why it now declines (`b = cq_theta(x,.25); …merge…; b3 = cq_theta(x,.9)` — two sibling
  rotations on one register, `docs/frontend.md` §3.2), the measured diagnostic, an explicit statement
  that **no golden was regenerated and none could be**, and an **L8 RETIREMENT TRIGGER** naming the
  owner ruling by date and requiring a *freshly derived* golden if the chained spelling is ever made to
  lower. The original headers are kept **verbatim** underneath.
* Both goldens **DELETED** (not rewritten). Both `add_test` blocks replaced by `⚠ REMOVED 2026-09-14`
  comment blocks that keep the original registration prose verbatim with **every directive neutered**
  (`# --- (was) …`).
* ⚠ **A COVERAGE HOLE WAS FOUND AND CLOSED IN THE PROCESS.** The **cmp** program was already pinned:
  Track D's inverted `control_swap_select_cmp_round2_window_accept.ll` is — verified here —
  **byte-identical** to the cmp slice's linked stage-1 module. The **bool (rail-leaf)** program was
  pinned **NOWHERE ELSE AT ALL**; `control_swap_select_rail_round2_window_accept.ll` does not exist.
  Unregistering it alone would have dropped the decline entirely. So the bool program's **verbatim
  linked stage-1 module** is now committed as
  `ir-pass/test/control_swap_reject_select_rail_round2_window.ll` — the shape the CMakeLists prose
  prescribes twice — with the diagnostic mirrored character-for-character and the original e2e header
  kept verbatim and neutered. **Validated NON-VACUOUS by binary mutation**: FileCheck does not match on
  the ORACLE `f7b65d8c` (where `opt` exits 0) and matches on `5c6f7490` (exit 1).
* Net: converting these two slices cost **zero coverage**.

## 10.2 Disposition 2 — the twin matrix: adjudicated, then regenerated deliberately

**`MERGE_TWIN_ADJUDICATION.md` was written BEFORE `--regenerate` ran** and carries the per-GROUP table
with, for each group, the cause, the direction and the unitary-level reason:

| group | n | cause | direction |
|---|---|---|---|
| G1 | 18 | **D**, the stale-reader ruling — every cell carries a `mark = a;` whose name the wire then moves past, so `cq_measure(mark)` measured the ROTATED register while naming the pre-rotation state | DECLINE |
| G2 | 5 | **W**, clause (c), the iteration-local rolled rail | ACCEPT |
| G3 | 9 | **W**, the in-loop bare-`_Bool` controlled-Ry ARM (`*bry*`) — a **gap in the prediction**, which covered only the second pass's `il*` cells | ACCEPT |
| G4 | 8 | **W**, the same retirement on the PREP branch — the loop stops being the discriminator, the prep's own F1 fence answers; no circuit either way | DECLINE→DECLINE |
| G5 | 1 | **W**, `m_none_ddilry_none_none_binv` — see below | ACCEPT |
| G6 | (3, not in the 41) | the surviving `il*`×`bcar` over-decline — **filed** | — |

The instructive one is G1's last cell, `m_none_pbitd_none_premark_rypost`: `ACCEPT-IDENTICAL` →
`DECLINE-BOTH`. **A cell whose two halves agreed because BOTH were wrong is precisely what
`ACCEPT-IDENTICAL` cannot see; only a fence can.**

**`m_none_ddilry_none_none_binv` — the corrected reason, recorded as instructed.** The prediction's
stated ground was *"its rolled side declines at gate 2c, not at the loop fence … so gate 2c refuses it
BEFORE the loop clause is ever reached."* **That ground is simply false, and the disproof was on the
row the whole time: if 2c were the operative refusal it would refuse the FLAT spelling too — and the
flat side ACCEPTED on the ORACLE, all along.** 2c never stopped the rolled side; the loop carve-out
did, and lifting the carve-out lifted it. This is **L7 in its exact shape — a wrong reason that reached
a right prediction**, hardening by repetition until something forced it to be checked. It is benign:
rolled and flat traces byte-identical at 28 lines, STRICT 2b clean on both. **No gate-2c ruling is
owed; the corrected sentence was**, and it is now in `EXPECTED_HEADER`.

**The regeneration, and its verification.** The now-historical PREDICTION block in `EXPECTED_HEADER`
was first rewritten **in place** into a MEASURED block (six numbered findings: the 5 that flipped, the
3 that did not with their isolation argument, the corrected `ddilry` reason, the 9 uncovered `*bry*`
cells with the lesson for the next early-regenerated axis, the escape pin that held, and D's 18). Then
`--regenerate`, then **mechanical** header-survival checks — Track T measured this instrument eating 54
lines of ruling prose once already:

```
EXPECTED_HEADER is a PREFIX of the written table: True
447 #-lines / 309 rows ; quarantine BYTE-UNTOUCHED at 29 cells
rows changed: 41 removed / 41 added — SET-IDENTICAL to the 41 adjudicated cells, 0 extra, 0 missing
```

## 10.3 Dispositions 3, 4, 5 — the records

* **3 — the `tests/e2e/CMakeLists.txt` anchor claim.** A measured **ERRATUM** is now in
  `PROTOCOL.md` §S1 beside the sentence it corrects (kept, so the correction has something to point
  at): the file is **not** append-only at disjoint anchors — it has ONE tail anchor above the
  mandatory-last `get_property` sweep, every slice-adding track appends there, and this merge hit two
  content conflicts in it. GROUP membership is unaffected. The erratum carries the three-command
  post-union check this gate ran, so it becomes standard: **0 duplicate `add_test` names, 434
  registrations, sweep still last** (432 after the two removals).
* **4 — X5.** `MERGE_FILINGS.md` §1, in the same words used to the coordinator: the two named fixtures
  **held**, and the back-edge shape **IS now reachable** — `ArmClassify.cpp` trigger (3a)'s premise is
  FALSE. The three probes are committed. **The re-derivation is recorded as OWED and deliberately not
  attempted.**
* **5 — the F × P compositions.** `MERGE_FILINGS.md` §2: `r19_phi_and_prepcond` and `m28` — a condition
  TREE whose leaves are preps' merge φs — accept only with both tracks present. Probes committed,
  traces and 2b figures recorded, and it is stated plainly that this is **cleared by MEASUREMENT and
  not by REVIEW**: Track F's Rule-13 rounds saw a binary on which these decline, and so did Track P's.

## 10.4 The GREEN re-run and the final counts

```
ran: ctest --test-dir build -j6 | 5c6f7490a81c7505
     100% tests passed, 0 tests failed out of 442.  Total Test time (real) = 448.60 sec
```

| metric | 2026-09-13 close (`59ac5b7`) | first run (RED) | **FINAL, GREEN** |
|---|---|---|---|
| `ctest -N` | 420 | 444 | **442** |
| `^e2e-` | 410 | 434 | **432** |
| `^e2e-slice-` | 365 | 383 | **381** |
| `twin-identical` | 34 | 40 | **40** |
| lit fixtures | 1928 | 1993 | **1994** |
| e2e goldens | 367 | 385 | **383** |
| twin cells | 259+29 = 288 | 309+29 = 338 | **309+29 = 338** |
| `cq-opt-equivalence-full` | 1928/0 | 1993/0 | **1993/0 (cited)** |

The −2 / −2 / −2 against the first run is the two converted slices and their deleted goldens; the +1 on
lit is the new rail-leaf decline fixture that now pins the bool program.

**Not squashed, not pushed.** Merge worktree `/Users/sorenwilkening/Desktop/CQ_merge` at
`merge-gate-2026-09-14`; bisect worktree `/Users/sorenwilkening/Desktop/CQ_wbisect`
(`1dee47e2` → `40edde36…`) left in place for the G5/§3d record and never written to.
