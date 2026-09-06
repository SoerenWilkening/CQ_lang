# fix_c1b — the SECOND C-1 fix round (F-C1-1, F-C1-2) on 3qlq Inc 1

Agent: fix_c1b. Worktree `$SP/wt/fix-c1`, branch `3qlq-inc1-fix-c1`, base ba01d8d.
PRE-FIX  = main checkout /Users/sorenwilkening/Desktop/CQ_lang @ 542d588 (never rebuilt).
FIX-1    = the round-1 binary, SAVED at $SP/progress/fix_c1b_work/{cq-opt.fix1,libCQPass.so.fix1}
           sha256 cq-opt.fix1 = 223674f13fe0675b6e01f0024a9ea2a8893acb5b6615b3e666f085ca02a1eed3
ORACLE   = $SP0/wt/pre-3qlq @ 52d7764.

## Log
- 2026-09-06 step 0: read BRIEF_common, BRIEF_fix_c1b, BRIEF_fix_c1, progress/fix_c1.md,
  progress/review_c1.md IN FULL. Worktree clean at ba01d8d; `find ir-pass/src ir-pass/include
  ir-pass/tools -newer build/ir-pass/cq-opt` EMPTY (build current).
  SAVED the FIX-1 binary pair (sha above) BEFORE touching any source.
- step 1: HARNESS `$SP/progress/fix_c1b_work/{run.sh,cnt.sh,pair.sh}` (4 cases subj|fix1|fix|orac;
  `fix1` = the SAVED round-1 pair + the main checkout's runtime/include/tools). 191 lens
  reproducers copied to `p/`.
- step 2 (BOTH FINDINGS REPRODUCED INDEPENDENTLY, rolled `and|lshr _hl` mints / `_hl_unc`):
    r2  preheader `q=q+7`  subj 3/0|3/3 DIVERGE(6) · fix1 3/0|3/3 DIVERGE(6)
    r33 onward-only        subj 3/0|3/3 DIVERGE(6) · fix1 3/0|3/3 DIVERGE(6)
    r35 onward+diffusion   subj 3/0|3/3 DIVERGE(6) · fix1 3/0|3/3 DIVERGE(6)
    r40 onward + r1-region rolled 3/0 on both; its unrolled twin DECLINES
        `cq controlled lowering: control flow under quantum control` on both (OQ-C1-3 class).
- step 3 (THE BRIEF'S "MEASURE FIRST" PROBES, new `p/x*.c`):
  * (a) `x1_preadd_noR.c` — the SAME program WITHOUT `r` (pure-invariant, the `NotClaimed`
    path): **3/0 vs 3/3 DIVERGE(6) on 542d588 AND on FIX-1**, while the pre-3qlq ORACLE on
    the old-surface twin (`x1o`/`x1ou`) is **3/3 IDENT**.
    => F-C1-1 is a **PRE-EXISTING F-L5-1-era hole**, not round 1's. The notes must say so.
  * (b) `x2_preadd_keep.c` (`int keep=q; q=q+7; … cq_measure(keep)`): M-C goes **OUT OF
    PLACE** — the fix1 trace has `cq_template_add_i32_hl(h0, 7) -> h2`, NOT `cqrt_addc_i32`
    — 3/0 vs 3/3 on both binaries. This is the Q-R1-1 template-rail class and the extension
    must REFUSE it (leak-control, byte-identical to FIX-1).
  * `x3_deadgate_body.c` (an in-body `int t=cq_theta(r,.1);` whose result is DEAD — no phi,
    no claim): ACCEPTS and leaks 3/0 on both binaries today. Must STAY a leak after the fix.
  MEASURED in-place-ness: `r2`/`x1` traces carry `cqrt_addc_i32(h0, 7)`.
- step 4 (IMPLEMENT, commit 2f8db78 on `3qlq-inc1-fix-c1`). BOTH findings are
  CAPABILITIES, not declines. Files: `LoopLowering.cpp`, `LoopPlan.h`,
  `TaintPropagation.{h,cpp}`, `SwapRouteEmit.cpp`, `CQLoweringPass.cpp`.
  * **F-C1-1** — new `commitOutOfLoopInPlaceOps` (LoopLowering.cpp, anon ns): walks
    each candidate's CLAIM-time chain and, for a dtzb `add`/`xor` OUTSIDE `L`, asks
    the ONE owner of that decision — `ArithLowering::classifyInPlaceReassignment`
    (Rule 14) — plus a STABILITY conjunct `P->hasOneUse()`; on success records the op
    in `taint.InPlaceRailOps`, which COMMITS both readers (`OpcodeLowering:263/:350`
    route it in-place; M-C's G5 refuses a marked site). `invariantRegisterRoots` is
    split into an `...Impl` + a wrapper that ROLLS BACK every marking on failure, so
    a module the extension does not serve is byte-identical. `wd`/`DT`/`LI` threaded
    through `collapseFlattenedLoopRails` from both call sites.
  * **F-C1-2(2a)** — new `taint.ClaimedRailRoots`, written at BOTH Case-A collapse
    sites (`tryCaseA` ACCEPT, `collapseRailPhisIn` step (4)); clause (0) reads the
    UNION with the caller's local `CarriedRoots`. NOT `tryBreak` (its rails belong
    to `lowerBreakReversePlay`).
  * **F-C1-2(2b)** — `taint.InLoopFlattenedPreds` becomes a `DenseMap<BB,unsigned>`
    COUNT (`++` at the two `SwapRouteEmit` sites); the round-2 delta is the count
    having MOVED, not membership.
- step 4b (⭐ THE 8h7d.5 LESSON CAUGHT INSIDE THIS EDIT, measured with an
  env-gated instrumented build then stripped): widening the clause-(0) SKIP alone
  left `IRR TRUE roots=1` with NOTHING marked — `markIfRailLocal`'s "accumulating
  loop-invariant tainted input" clause needs the CLAIMED rail in `Roots` to answer
  `onRail`. Clause (0) now skips the candidate **INTO** `RootsOut`. Two sets over
  one closure; widening one and not the other is F-1/F-3 verbatim.
- step 5 (MEASURED on my binary, rolled `and|lshr _hl` / `_hl_unc`, twin identity):
  | program | 542d588 | FIX-1 | MINE |
  |---|---|---|---|
  | r2 preheader `q=q+7`      | 3/0 DIVERGE(6) | 3/0 DIVERGE(6) | **3/3 IDENT** |
  | r71 preheader `q^=9`      | 3/0 DIVERGE(6) | 3/0 DIVERGE(6) | **3/3 IDENT** |
  | x1 same, NO carried `r`   | 3/0 DIVERGE(6) | 3/0 DIVERGE(6) | **3/3 IDENT** |
  | r33 onward-only           | 3/0 DIVERGE(6) | 3/0 DIVERGE(6) | **3/3 IDENT** |
  | r35 onward + diffusion    | 3/0 DIVERGE(6) | 3/0 DIVERGE(6) | **3/3 IDENT** |
  | r40 onward + r1 region    | 3/0 (no twin)  | 3/0 (no twin)  | **3/3** (twin DECLINES on all 3) |
  | x2 `keep` pre-op value    | 3/0 | 3/0 | **3/0 BYTE-UNCHANGED** (leak control) |
  | x3 dead in-body gate      | 3/0 | 3/0 | **3/0 BYTE-UNCHANGED** (leak control) |
- step 6 (POPULATION, 124 programs = the lens's 60 + its 56 `r*` + my 8 `x*`,
  `sweep.sh`/`poplist.txt`, byte-diff of EVERY rolled trace FIX-1 vs mine):
  **95 BYTE-UNCHANGED, 6 MOVED, and the 6 are exactly the F-C1-1/F-C1-2 population**
  (r2, r71, x1, r33, r35, r40 — all 3/0 -> 3/3). NO other status, decline string or
  trace moved. Q-R1-1 controls `n9`/`d2`/`d3`/`n4`/`r5`/`n10`: all BYTE-UNCHANGED,
  all still 3/0. **STRICT stage 2b: 101 of 101 accepts `0 violation(s), 0 unproven`.**
- step 7 (RED-GREEN, Rule 12; each fixture run BY HAND on all three binaries with
  `rg.sh` = `cq-opt` + `FileCheck` per prefix. rc per prefix, 0=pass):
  | fixture | 542d588 | FIX-1 | MINE |
  |---|---|---|---|
  | `control_phase_kickback_mixed_preheader_addc_inloop.ll` (ACCEPT) | CHECK=1 FCNT=1 **UCNT=1** | same **RED** | all 8 prefixes 0 **GREEN** |
  | `control_phase_kickback_mixed_onward_inloop.ll` (ACCEPT) | CHECK=1 FCNT=1 **UCNT=1** | same **RED** | all 7 prefixes 0 **GREEN** |
  | `control_phase_kickback_mixed_onward_r1open_inloop.ll` (ACCEPT) | CHECK=1 FCNT=1 **UCNT=1** | same **RED** | all 6 prefixes 0 **GREEN** |
  | `..._mixed_preheader_add_outofplace_leak_control.ll` (ACCEPT-AND-LEAKS) | all 0 | all 0 | all 0 — the widening did NOT reach it |
  | `..._mixed_onward_deadgate_leak_control.ll` (ACCEPT-AND-LEAKS) | all 0 | all 0 | all 0 — ditto |
  In every accept the ⭐ discriminator is `UCNT` (the `and_i32_hl_unc` count), which
  was ZERO on both earlier binaries.
- step 8: `ctest -R ir-pass-lit` on my build -> **Passed, 33.35 s, 0 failed**
  (`fix_c1b_lit_A.log`).
- step 9 (E2E): 4 new slices + 4 goldens + 2 `cmp` twin gates.
  `slice_control_phase_perbit_loop_mixed_preadd{,_unrolled}.c` (single TU) and
  `slice_control_phase_onward_perbit_loop_mixed{,_unrolled}.c` + `onward_perbit_mixed_lib.c`
  (two TUs, `run_slice_multi.sh`). Goldens by the FULL pipeline on my binary,
  STRICT 2b (`0 violation(s), 0 unproven` on both rolled slices).
  BYTE-IDENTITY MEASURED: preadd 38 = 38 (was 32 vs 38), onward 47 = 47 (was 41 vs 47).
  ⚠ The r40 shape (round-1 region + onward region in ONE loop) gets NO e2e twin:
  its hand-unrolled form DECLINES `cq controlled lowering: control flow under
  quantum control` on all three binaries (OQ-C1-3 / bd 3qlq.9), so the LIFO
  per-trip pairing is asserted in the lit fixture instead — stated in its header.
  `ctest -j6 -R 'perbit|onward-perbit|twin-identical|quarantine-selftest'` ->
  **30/30 passed, 4.21 s** (incl. every pre-existing `*-twin-identical` gate and
  `e2e-loop-twin-quarantine-selftest`).
  COUNTS re-measured by `ctest -N`: total **342 -> 348**, `^e2e-` **332 -> 338**,
  `^e2e-slice-` **302 -> 308**.
- step 10 (MUTATION VALIDATION, five cycles, one half at a time, each a full
  rebuild; `fix_c1b_work/mutate.py`, log `fix_c1b_mutate.log`; the RED/GREEN read
  is the per-prefix FileCheck rc on MY build):
    M1 `commitOutOfLoopInPlaceOps` returns immediately   -> preadd accept **RED** (CHECK/FCNT/UCNT)
    M2 mark on SHAPE alone (drop the M-C fence + hasOneUse)
                                                        -> the OUT-OF-PLACE LEAK CONTROL **RED**
       (CHECK/PCNT/FCNT/UCNT — the mutant really does convert `x2`'s add to
       `cqrt_addc` and discharge the rails, i.e. the control catches a would-be
       WRONG UNITARY, not just a missing feature)
    M3 clause (0) drops the `ClaimedRailRoots` union     -> onward accept **RED**
    M4 skip WITHOUT inserting into `RootsOut`            -> onward accept **RED**
    M5 the round-2 delta reverts to MEMBERSHIP           -> r1open accept **RED**
    RESTORED -> all four fixtures GREEN on every prefix.
  All five halves are load-bearing; none is decoration.
- step 11 (TWIN MATRIX, F-C1-7). `tools/loop_twin_matrix.py` gains a PRE-LOOP slot
  (`_wrap(preloop=)` + `PRELOOP`, both defaulted) and sub-grid **F3**. The 120-cell
  product now iterates an explicit `BASE_PREFIX` so a new `PREFIX` key cannot
  silently multiply the long-pole gate. **PROVEN BYTE-UNCHANGED, not asserted**:
  `dump_sources.py` hashes every generated source of every cell on both surfaces,
  before and after — **0 of 1136 rows missing or changed**, 16 new (4 cells x 2
  surfaces x 2 spellings).
  PRE-FIX DISPOSITION of the 4 new cells, MEASURED BY HAND on all three binaries:
    `m_addpre_pbit_none_none_rypost`  subj 2/0|2/2 DIVERGE(4) · FIX-1 same · MINE **IDENT**
    `m_addpre_pbitd_none_none_rypost` subj 2/0|2/2 DIVERGE(4) · FIX-1 same · MINE **IDENT**
    `m_xorpre_pbit_none_none_rypost`  subj 2/0|2/2 DIVERGE(32) · FIX-1 same · MINE 2/2|2/2 **DIVERGE(36)**
    `m_xorpre_pbitd_none_none_rypost` subj 2/0|2/2 DIVERGE(34) · FIX-1 same · MINE 2/2|2/2 **DIVERGE(38)**
  ⚠ THE TWO `xorpre` CELLS ARE AN **UNFAITHFUL TWIN**, INVESTIGATED NOT
  QUARANTINED (Rule 11 — I read the two stage-1 modules). `-O1` rewrites
  `((a^9)>>i)&1` to `and %a, 2` / `and %a, 4` for every bit where the mask is 0,
  because `xor` DISTRIBUTES over a bit test — so the FLAT side acquires uses of the
  PRE-xor register that the ROLLED side structurally cannot have (its shift amount
  is a loop variable). The pre-op value therefore has a later read on the flat side
  only, M-C correctly goes OUT of place there (`cq_template_xor_i32_hl(h0,9)->h2`,
  and the flat side even MEASURES `h2`), and the two SOURCES are not the same
  program after `-O1`. `add` does not distribute over a bit test, which is why
  `addpre` is faithful. The same artefact makes the PLAIN-C `q ^= 9` pair
  (`r71`/`r71u`) an unfaithful twin too: its ROLLED trace still moves 3/0 -> 3/3
  (the fix working) but its twin CANNOT witness that. `xorpre` is therefore DROPPED
  from the sub-grid with the measurement recorded in the code — the `addpost`
  precedent from round 1, and what the quarantine file's own header requires.
- step 12 (MATRIX, re-run after dropping `xorpre`): `--regenerate` on my build ->
  `regenerated tools/loop_twin_matrix.expected.txt (257 cells; 29 quarantined and
  omitted)`, rc=0. Against the committed table: `comm -23` over the `^m_` rows
  **EMPTY** (all **255** pre-existing rows byte-unchanged), non-row/header diff
  EMPTY, quarantine file byte-unchanged (29 cells, three classes), **2 NEW rows**
  both `ACCEPT-IDENTICAL`. `ctest -j6 -R 'e2e-loop-twin-matrix|e2e-loop-twin-quarantine-selftest'`
  -> **2/2 passed**, matrix **176.31 s** at 286 cells.
  ⚠ The FIRST `--regenerate` (with `xorpre` still in) **REFUSED TO WRITE** and named
  both `xorpre` cells as TRACE-DIVERGENCE with `cqrt_xorc_i32(h0, 9)` vs
  `cq_template_xor_i32_hl(h0, 9) -> h2` as the first differing line — the instrument
  working as its docstring predicts, and the measurement that drove the drop.
- step 13 (INJECTION MATRIX, `fix_c1_work/inj.py` re-pointed): 5 fixtures x 16
  mutations = 80 cells. FIRST RUN found **2 MISSED** (`extra_x` on the two fixtures
  with no `XCNT` prefix — `..._onward_r1open_inloop.ll` and
  `..._onward_deadgate_leak_control.ll`, both 4 `cqrt_x` measured on the module).
  Added the prefix to both; RE-RUN **0 MISSED / 0 DIRTY**, `clean` PASS on all five
  (`inj_c1b2.tsv`). Red-green on the two hardened files re-verified: still RED on
  542d588/FIX-1 for the accept, still GREEN on all three for the control.
- step 14 (F-C1-3, the `short` leak control): `p/r5_short_inv.c` — the C-1 accept's
  source with `int` -> `short` and NOTHING else — makes `-O1` hoist
  `sext i16 %q to i32` into the preheader, so the body's condition reads
  `cq_template_sext_i16_to_i32(%h)`. 3/0 vs 3/3 on all three binaries, rolled trace
  BYTE-UNCHANGED subj == FIX-1 == mine. Pinned as
  `control_phase_kickback_mixed_short_sext_leak_control.ll` (accept-and-leaks,
  0 MISSED / 0 DIRTY). PRD §0 E2 and notes §3.10 gained the disclosure: **no cast
  appears in the program at all — the user wrote a TYPE.**
- step 15 (DOCS): notes **§3.10** (both findings, root causes, fixes, the 8h7d.5
  table for `InPlaceRailOps` / `ClaimedRailRoots` / `InLoopFlattenedPreds`, the
  matrix axis and its `xorpre` exclusion, the mutation table, three owner
  questions) + the **F-C1-4 correction in place** (§3.5's `d2`/`n4` rows were `0/0`
  and are **3/0 | 3/3**: the conditions are `i64`, so an `and_i32_hl`-pinned grep
  read zero; dispositions unchanged and re-confirmed) + the `n8` rows in §3.5/§3.7
  marked as NOT generalising + the §2 once-only-stage table row rewritten
  ("FIXED TWICE"). PRD §0 **E2** ("five things, not three"). **CLAUDE.md**: the C-1
  bullet gains the fourth/fifth instance and the count line goes "THREE INSTANCES
  ACROSS THREE ROUNDS" -> "FIVE ACROSS FOUR". **ROADMAP**: the branch-status block
  and the matrix paragraph.
- step 16 (FINAL GATES on my build, all re-measured by command):
    `ctest -R ir-pass-lit` -> **Passed, 33.67 s**; `lit -q ir-pass/test` ->
    **1666 discovered** · `ctest -j6 -R 'twin-identical|quarantine-selftest|free-pairing-selftest|^e2e-slice-control-phase-{perbit,onward-perbit}'`
    -> **31/31 passed, 4.49 s** · `ctest -j6 -R 'e2e-loop-twin-matrix|...quarantine-selftest'`
    -> **2/2, 176.35 s**.
    COUNTS: `ctest -N` **348** total / **338** `^e2e-` / **308** `^e2e-slice-`;
    `ls ir-pass/test/*.ll | wc -l` **1666**; `grep -c '^m_' …expected.txt` **257**;
    `grep -c '^cell ' …quarantine.txt` **29**.
- step 17: two `bd remember` entries
  (`commit-the-preheader-inplace-op-not-a-second-spelling`,
  `claimed-rail-roots-come-from-the-tree`). No bd issue closed or edited.

---

## HAND-BACK

### 1 — what shipped (branch `3qlq-inc1-fix-c1`, 5 commits on top of ba01d8d)

**OPTION (a), THE CAPABILITY, FOR BOTH FINDINGS.** Neither is a decline. Rolled
`cq_template_and_i32_hl` / `_hl_unc` on my binary, against a hand-unrolled twin:
**r2 3/3 (twin 3/3, IDENTICAL) · r35 3/3 (twin 3/3, IDENTICAL) · r40 3/3 (its twin
DECLINES on every binary in the epic — OQ-C1-3 class, so it has no twin witness at
any layer and the lit fixture carries a structural per-trip pairing assertion
instead)**. On 542d588 and on the round-1 fix all three were **3/0**.

| commit | contents |
|---|---|
| `2f8db78` | the two fixes (F-C1-1 commit+rollback; F-C1-2 `ClaimedRailRoots` + the COUNT delta) |
| `b0e18bc` | the five red-green fixtures |
| `da30f9b` | 4 e2e slices + 4 goldens + 2 `cmp` twin gates |
| `d8319bc` | twin-matrix sub-grid F3, the measured `xorpre` exclusion, notes §3.10 + the F-C1-4 corrections |
| `f5cf578` | injection-matrix hardening (XCNT ×2), PRD E2, CLAUDE.md, ROADMAP, re-measured counts |
| `638334c` | the F-C1-3 `short`/`sext` leak control |

CODE — `LoopLowering.cpp`, `LoopPlan.h`, `TaintPropagation.{h,cpp}`,
`SwapRouteEmit.cpp`, `CQLoweringPass.cpp`. No new `cqrt_*`/`cq_template_*` symbol,
no new diagnostic, no change to `markIfRailLocal`, `Uncomputation`, `FreePoint`,
`ArithLowering` or `runtime/`.
* **F-C1-1**: `commitOutOfLoopInPlaceOps` asks
  `ArithLowering::classifyInPlaceReassignment` (the ONE spelling, Rule 14) plus a
  `P->hasOneUse()` STABILITY conjunct, and records the op in
  `taint.InPlaceRailOps` — a COMMITMENT both readers honour.
  `invariantRegisterRoots` splits into an `...Impl` + a wrapper that ROLLS BACK
  every marking on failure.
* **F-C1-2(2a)**: new `taint.ClaimedRailRoots`, written at BOTH Case-A collapse
  sites, read by clause (0) in UNION with the local set — and the candidate is
  skipped **INTO** `RootsOut` (the 8h7d.5 lesson, caught inside this edit).
* **F-C1-2(2b)**: `taint.InLoopFlattenedPreds` becomes a per-block COUNT; the
  round-2 delta is the count having MOVED.

LIT (6 new files, corpus 1660 -> **1666**): 3 ACCEPTS
(`control_phase_kickback_mixed_preheader_addc_inloop.ll`, `..._mixed_onward_inloop.ll`,
`..._mixed_onward_r1open_inloop.ll`) + 3 ACCEPT-AND-LEAKS controls
(`..._mixed_preheader_add_outofplace_leak_control.ll`,
`..._mixed_onward_deadgate_leak_control.ll`, `..._mixed_short_sext_leak_control.ll`).

E2E (4 slices + 1 lib TU + 4 goldens + 2 `cmp` gates; `ctest -N` 342 -> **348**,
`^e2e-` 332 -> **338**, `^e2e-slice-` 304 -> **308**):
`slice_control_phase_perbit_loop_mixed_preadd{,_unrolled}.c` and
`slice_control_phase_onward_perbit_loop_mixed{,_unrolled}.c` +
`onward_perbit_mixed_lib.c` (two TUs, `run_slice_multi.sh`), gated by
`e2e-phase-perbit-loop-mixed-preadd-twin-identical` (38 = 38, was 32 vs 38) and
`e2e-phase-onward-perbit-loop-mixed-twin-identical` (47 = 47, was 41 vs 47).

INSTRUMENT: `tools/loop_twin_matrix.py` gains a PRE-LOOP slot and sub-grid **F3**
(2 cells, 284 -> **286**); `expected.txt` 255 -> **257** rows, every pre-existing
row byte-unchanged, quarantine byte-unchanged, all **1136** pre-existing generated
sources hash-identical (twice).

DOCS: notes **§3.10** + the §3.5/§3.7/§2 corrections; PRD **§0 E2**; CLAUDE.md's
C-1 bullet and three count lines; ROADMAP's branch-status block and matrix
paragraph.

### 2 — what I ran

| gate | result |
|---|---|
| red-green per fixture, 3 binaries, by hand | 3 accepts **RED** on 542d588 AND on FIX-1 (CHECK/FCNT/**UCNT**), **GREEN** on mine; 3 leak controls **GREEN on all three** |
| `ctest -R ir-pass-lit` (mine) | **Passed**, 32.8 s then 33.7 s; `lit -q` **1666 discovered** |
| population, FIX-1 vs mine, 124 programs | **95 rolled traces BYTE-UNCHANGED, 6 MOVED**, and the 6 are exactly r2 / r71 / x1 / r33 / r35 / r40 (3/0 -> 3/3). No other status, decline string or trace moved |
| Q-R1-1 controls (`n9`,`d2`,`d3`,`n4`,`r5`,`n10`) | all **BYTE-UNCHANGED**, all still 3/0 |
| STRICT stage 2b | **101 of 101** accepts `0 violation(s), 0 unproven` |
| mutation validation, one half at a time | **M1..M5 all RED**, RESTORED GREEN (6 build+check cycles) |
| injection matrix | 6 fixtures × 16 mutations; first run **2 MISSED**, after hardening **0 MISSED / 0 DIRTY** |
| twin matrix | `--regenerate` REFUSED once (the `xorpre` finding), then rc=0 at 286 cells; `e2e-loop-twin-matrix` **Passed 176.31 s**, quarantine selftest **Passed** |
| e2e gates | `ctest -j6 -R 'perbit\|onward-perbit\|twin-identical\|quarantine-selftest'` **30/30, 4.21 s**; final 31-entry run incl. `free-pairing-selftest` **31/31, 4.49 s** |
| **NOT run** | the full `ctest` (the orchestrator's gate); `cq-opt-equivalence-full`; the `--phi-surface register` matrix (its header guard refuses against the shipped `CQ.h`) |

### 3 — findings that are NOT mine to decide

See notes §3.10 for the full text of **OQ-C1-4** (the `r40` shape is a shipped
accept with no twin witness at any layer, because its flat spelling declines on
every binary — is the flat decline the thing to fix, or is a structural pairing
assertion the accepted witness for this family?), **OQ-C1-5** (`hasOneUse` is a
STRUCTURAL fence standing in for a temporal one; the alternative is a
re-verification in `lowerOps` with one more set and one more diagnostic — which
does the owner want?) and **OQ-C1-6** (`ClaimedRailRoots` is written by two of the
THREE rail-collapse sites; `tryBreak` is excluded on purpose and no reproducer
combines a break loop with an invariant per-bit register).

Not an owner question but worth the orchestrator's eye: the plain-C `q ^= 9`
preheader pair (`r71`/`r71u`) is an **unfaithful twin** for the same measured
`-O1` reason as the matrix's `xorpre` cells — its rolled trace moves 3/0 -> 3/3
(the fix working) and NOTHING can witness it, because `xor` distributes over a bit
test and the flat spelling becomes a different program. Recorded in notes §3.10
and in the matrix source; deliberately not quarantined.

### 4 — what is left

* Nothing in F-C1-1 / F-C1-2 / F-C1-3 / F-C1-4 / F-C1-7 scope. F-C1-5 and F-C1-6
  were CLEAR in the lens report and needed no action.
* The orchestrator still owes: the full `ctest -j6`, and the re-clearance.
* Branch committed, NOT pushed. No bd issue closed or edited (two `bd remember`
  entries added).
