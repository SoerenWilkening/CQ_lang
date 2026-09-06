# fix_c1d — the FOURTH C-1 round: retire the `hasOneUse` conjunct under the (1b) tripwire (bd 7yd0 / OQ-C2-1 / F-I2-1)

Agent `fix_c1d`. Worktree `$SP/wt/c1d`, branch `c1-round4`, base **a3c1513** (`main`, Inc 0+1 landed).
PRE-FIX = the MAIN CHECKOUT `/Users/sorenwilkening/Desktop/CQ_lang` @ a3c1513 (never edited, never rebuilt).
ORACLE  = `$SP0/wt/pre-3qlq` @ 52d7764.
INC2    = `$SP0/wt/inc2` @ 6ee3ea3 (READ-ONLY, another agent's worktree; used only to measure the
          Inc-2 value-merge spelling of the finding as a reproducer).

## Log
- 2026-09-06 step 0: read BRIEF_common, BRIEF_fix_c1d, fix_c1b.md, fix_c1c.md, review_c1c.md,
  clearance2.md, review_inc2_r2.md (F-I2-1 + OQ1). Worktree created at a3c1513 on `c1-round4`.
- step 0b: configured + built `$SP/wt/c1d/build` (background, `c1d_build1.log`) -> **BUILD_OK**.
- step 1 (HARNESS + REPRODUCTION). `$SP/progress/fix_c1d_work/{run.sh,cnt.sh,pairs.sh,rg.sh,allsweep.sh,p/,pop/,out/}`
  — 4 cases `main|fix|orac|inc2`. F-I2-1 REPRODUCED on the PRE-FIX `main` binary
  (`./run.sh p/q5sel_preadd_rolled.c main`): rolled **4 mints / 0 `_unc`, 44 lines** vs
  hand-unrolled **4/4, 52 lines** (`cnt.sh`, `cmp` DIVERGE 8 lines).
- step 2 (IMPLEMENT, commit `1cc0a6c`): ONE conjunct dropped in
  `LoopLowering.cpp::commitOutOfLoopInPlaceOps` — `if (!P || !P->hasOneUse()) return;` becomes
  `if (!P) return;`. The commit now asks exactly (1a) `isa<Constant>(Imm)` + M-C's own
  `classifyInPlaceReassignment`; the safety is the round-3 (1b) tripwire. ~55 lines of argument
  written at the site (the retired conjunct kept as HISTORY with BOTH measured directions).
- step 3 (MEASURED on my binary, rolled `and|lshr _hl` mints / `_hl_unc`, rolled-vs-unrolled `cmp`):
  | program | producer of `%out` | main (a3c1513) | MINE |
  |---|---|---|---|
  | `q5sel_preadd` | 4.4 SELECT merge (2 `cqrt_copy_i32_controlled`) | 4/0 44 vs 4/4 52 **DIVERGE** | **4/4 = 4/4, IDENT 52=52** |
  | `q4b_preadd` | Phase-4 VALUE-ARM ROUTE (`cqrt_copy_i32` into `%out`) | 4/0 57 vs 4/4 65 **DIVERGE** | **4/4 = 4/4, IDENT 65=65** |
  | `q7_k32` (K=32) | 4.4 select merge | 32 mints / **0** `_unc` | **32/32** (the leak was O(K)) |
  | `q5v_xor` (`m ^= 7`) | 4.4 select merge | 4/0 44 | **4/4 52** (twin UNFAITHFUL — `-O1` distributes `xor` over the bit test, documented `xorpre`/`r71` class) |
  | `q5v_none` (merge, NO preheader op) | control | IDENT 51=51 | IDENT 51=51 **unchanged** |
  | `q5ctl_theta_preadd` (theta root, WITH op) | control | IDENT 40=40 | IDENT 40=40 **unchanged** |
  | `o1_call_preadd` / `q5o_call` (6.5 arm) | — | DECLINE `value-arm swap-route under quantum control` | same DECLINE — the 6.5 spelling is UNREACHABLE with a preadd (`-O1` sinks the `+7` into the arm), so that row stays ANALYTIC |
- step 4 (RED-GREEN, `rg.sh`, per prefix): `control_phase_kickback_mixed_merge_out_rail_preadd_inloop.ll`
  main `OPT_RC=0 CHECK=1 FCNT=1 UCNT=1` (ACNT/MDCNT/NOROUTE/PCNT/XCNT=0) — **RED**;
  mine all 8 prefixes 0 — **GREEN**.
- step 5 (TWIN MATRIX, sub-grid **F4**): `tools/loop_twin_matrix.py` gains a `PREHEAD` slot
  (`_wrap(prehead=)`, defaulted) + one new PREFIX key `addpresel` (PRELOOP `a = a + 7;`,
  PREHEAD `int mb=0,mc=0; mb=cq_theta(..); mc=cq_theta(..); a = (a>5)?mb:mc;`) and **2 cells**
  `m_addpresel_pbit{,d}_none_none_rypost`. `BASE_PREFIX` untouched, so the 120-cell product
  cannot see the key. **PROVEN BYTE-UNCHANGED, not asserted**: `dump_sources.py` over both
  surfaces, **0 of 1144 pre-existing rows missing or changed**, 8 new (2 cells x 2 surfaces x
  2 spellings). Sizes asserted 12 -> **14** (F), total 286 -> **288**.
  PRE-FIX DISPOSITION MEASURED BY HAND on both binaries:
  `m_addpresel_pbit_...` main rolled 2/0 (35) vs unrolled 2/2 (39) **DIVERGE(4)**; MINE **IDENT 39=39**.
  `m_addpresel_pbitd_...` main 2/0 (36) vs 2/2 (40) **DIVERGE(4)**; MINE **IDENT 40=40**.
- step 6 (E2E): `slice_control_phase_perbit_loop_merge_preadd{,_unrolled}.c` + goldens by the
  FULL pipeline on my binary, STRICT 2b **`0 violation(s), 0 unproven`** on both;
  **BYTE-IDENTICAL 52 = 52** (was 44 vs 52 on `main`). `cmp` gate
  `e2e-phase-perbit-loop-merge-preadd-twin-identical`. `ctest -N` **348 -> 351** total,
  `^e2e-` 338 -> **341**, `^e2e-slice-` 308 -> **310**. `ctest -j6 -R merge-preadd` **3/3 passed**.
  Commits `1cc0a6c` (code + lit fixture), `2c26ec6` (e2e + matrix).
- step 7 (INJECTION MATRIX over the new accept, `inj.py` re-pointed at my worktree): 1 fixture x 16
  mutations -> **`clean` PASS, 0 MISSED, 0 DIRTY** — every one of the 15 injections caught
  (`knownbad` CHECK/ACNT/MDCNT · `rz_f80|f16|i16`/`a_cswap`/`b_rzctl`/`extra_cswap`/`d_surviving_phi`
  NOROUTE · `extra_free` FCNT · `extra_x`/`h_unpaired_x` XCNT · `c_rz_after_free` ACNT,MDCNT ·
  `e_drop_free` CHECK,FCNT · `f_negated` CHECK,ACNT,MDCNT · `g_drop_mark` CHECK,MDCNT).
- step 8 (`ctest -R ir-pass-lit` on my build) -> **Passed, 77.71 s, 0 failed** (`c1d_lit_A.log`);
  `ls ir-pass/test/*.ll | wc -l` -> **1674** (1673 + the one new accept).
- step 9 (MUTATION VALIDATION, one half at a time, on my own `git archive HEAD` dbgtree copy,
  3 build+check cycles; `mutate.py`/`mutrun.sh`, table over 10 fixtures):
  | mutant | what goes RED | result |
  |---|---|---|
  | **M1** restore `P->hasOneUse()` | the new merge-out-rail accept | **RED** (CHECK/FCNT/UCNT) and **NOTHING else moves** — the one conjunct is exactly this capability |
  | **M2** delete the (1b) tripwire re-ask | `control_phase_kickback_reject_preloop_commit_stale.ll` | **RED** (OPT_RC=0 CHECK=1) and NOTHING else moves — round 3's net is still load-bearing after the widening |
  | RESTORE | — | all 10 fixtures GREEN on every prefix |
  ⭐ AND M2 IS THE SAFETY ARGUMENT MADE INTO A MEASUREMENT: on the M2 binary (my widened commit,
  tripwire deleted) all NINE F-C1C-1-class programs ACCEPT and `y1` reproduces the FIX-2 wrong
  unitary verbatim — `cqrt_addc_i32` in place, measures **`h0`, `h1`, `h0`**, 39 lines — while my
  binary DECLINES every one. So the net that stops that class is the TRIPWIRE, not `hasOneUse`
  (which is TRUE for `y1`: its `P = %q2` really does have one use).
- step 10 (⭐ **THE §3.11 INPUT-STABILITY TABLE'S `P` ROW, RE-DONE WITH PROGRAMS — what did
  `hasOneUse` guard that G6/G7 does not? MEASURED ANSWER: NOTHING.** An env-free instrumented
  DBG build of my own `git archive HEAD` copy printing `P`'s use list and the fence verdict at
  every candidate; `mutate.py DBG`):
  | program | `P`'s users besides the op | `hasOneUse` | M-C fence G6/G7 | disposition on MY binary |
  |---|---|---|---|---|
  | `r2_preadd_inv` | none | **true** | in place | COMMITTED (unchanged from `main`) |
  | `q5sel_preadd_rolled` | **2 x `cqrt_copy_i32_controlled`** — prior WRITERS, G7 arm (c) | false | in place | **COMMITTED — the new capability** |
  | `q4b_preadd_rolled` | **1 x `cqrt_copy_i32`** (Phase-4 value-arm route) | false | in place | **COMMITTED** |
  | `x2_preadd_keep` | `cq_measure(%2)` — a later READER | false | **REFUSES** | REFUSED, byte-unchanged (the leak control) |
  | `c2_m11d_two_loops_no_preadd` | a still-UNLOWERED tainted `and i32` in loop 1 — G7 arm (e) | false | **REFUSES** | REFUSED, byte-unchanged |
  So `hasOneUse` conflated "P has another user" with "P has a LATER READER"; G6/G7 separate them,
  and every one of the three verdicts above is the one M-C reaches on its own.
  ⚠ **AND THAT LAST ROW IS A CORRECTION TO clearance2's OQ-C2-1** — see the OWNER QUESTION below.
- step 11 (DOCS, commit `d0da4ef`): notes **§3.14** (the finding, who found it and that it was a
  round on ANOTHER increment, the re-done `P` row with programs, the fix, the M1/M2 mutation
  table, what it buys, the pinning) + **the §2 ⭐ table's `commitOutOfLoopInPlaceOps` row** and
  **§3.13's OQ-C2-1 bullet** (the attribution correction) · **PRD §0 E2** (the fourth round,
  and the `hasOneUse` line LEAVES the residual list while `m11d` stays, re-attributed) +
  **E10** (a new step 3b; the count SEVEN/FIVE -> **EIGHT/SIX**; §3.1–§3.12 -> §3.1–§3.14) +
  the §0 header's OQ-C2-1 mention · **CLAUDE.md**'s C-1 bullet (the fourth-round paragraph,
  the count line "SEVEN INSTANCES ACROSS FIVE" -> **"EIGHT ACROSS SIX"**, the OQ-C2-1 sentence
  corrected in place).
- step 12 (MATRIX regenerate on my build): `regenerated tools/loop_twin_matrix.expected.txt
  (259 cells; 29 quarantined and omitted)`, rc=0. Against the committed table: `comm -23` over
  the `^m_` rows **EMPTY** (all **257** pre-existing rows byte-unchanged), non-row/header diff
  EMPTY, `quarantine.txt` **BYTE-UNCHANGED** (29 cells), **2 NEW rows**:
  `m_addpresel_pbit_none_none_rypost ACCEPT-IDENTICAL` and
  `m_addpresel_pbitd_none_none_rypost ACCEPT-IDENTICAL-WARN  cq rotation lowering: non-diagonal
  gate over a live derived record`. ⚠ That WARN is the FIRST `ACCEPT-IDENTICAL-WARN` row in the
  table (the verdict existed in the tool and had no customer); MEASURED, it is emitted on **all
  four** of {main,fix} x {rolled,unrolled}, so it is a property of the shape (a post-loop
  diffusion on a merged register whose `mb`/`mc` sources are live derived records) and NOT of
  this change. `opt` exits 0 in all four. Commit `bd22a7f` (matrix table).
- step 13 (E2E GATES, `ctest -j6 -R 'e2e-loop-twin-matrix|quarantine-selftest|free-pairing-selftest|twin-identical|perbit|onward-perbit|merge-preadd'`)
  -> **35/35 passed, 229.35 s**, including `e2e-loop-twin-matrix` (**Passed, 229.18 s**, now 288
  cells), `e2e-loop-twin-quarantine-selftest`, `e2e-free-pairing-selftest`, all 21
  `*-twin-identical` gates (the 20 pre-existing + the new merge-preadd one) and both new slices.
- step 14 (POPULATION, `main` vs mine, **485 programs** — the union of every `p/` of session
  adc5590a: fix_c1_work, review_c1_work, fix_c1b_work, review_c1b_work, fix_c1c_work,
  review_c1c_work, clearance2_work `p`+`p2`+`p3`, review_inc2_r2_work, plus my own; normalised
  STATUS **and** byte-diff of the trace, `popdiff.py`):
  **UNCHANGED = 477, MOVED = 8.** Every mover named:
  | program | main | mine |
  |---|---|---|
  | `q5sel_preadd_rolled` | 4/0, 44 | **4/4, 52** |
  | `q4b_preadd_rolled` | 4/0, 57 | **4/4, 65** |
  | `q7_k32_rolled` | 32/0, 240 | **32/32, 304** |
  | `q5v_xor` | 4/0, 44 | **4/4, 52** |
  | `m_addpresel_pbit{,d}_none_none_rypost_rolled` (the 2 new matrix cells) | 2/0 | **2/2** |
  | ⭐ `c2_m04_onward_then_preadd` | 3/0, 43 | **3/3, 49** — a THIRD class found by the sweep, not by the finding |
  | `c1c_a1_constexpr_imm` | — | LOWERED IR BYTE-IDENTICAL; only a `ptrtoint (@g_tab+12)` LOAD ADDRESS differs between two separately linked binaries (the artefact `review_c1c` recorded on the same probe) |
  **CLASS-FLIP CENSUS (run under bash, per review_c1c's own methodology note): `ACCEPT->ACCEPT
  332 · DECLINE->DECLINE 122 · LINKFAIL 2 · S1FAIL 29`. 0 ACCEPT->DECLINE, 0 DECLINE->ACCEPT,
  0 decline strings changed.** STRICT 2b over all **332** accepts: **330 `0 violation(s), 0
  unproven`, 2 `0 violation(s), 4 unproven`** (`f0_break_plain`, `f3_break_global_phase_before`
  — the `--allow-unproven` dtzb break family), **0 violations**.
- step 15 (the THIRD class, pinned): `p/g1_region_then_preadd_{rolled,unrolled}.c` — the
  single-TU distillation of `c2_m04`: `if (q>5) cq_phi(0.4); q = q + 7;` then D4's per-bit loop
  with a carried `r`. **`P` is a `cq_theta` ROOT MINT and there is NO MERGE IN THE PROGRAM**;
  its second use is the PRECEDING REGION'S OWN COMPARE, which by the commit's program point is
  `cq_template_icmp_sgt_i32_hl` with its `_unc` AND `cqrt_free` before the `add` — settled by
  G7 arm (d). main **3/0 (36) vs twin 3/3 (42), DIVERGE**; mine **3/3 = 3/3, IDENTICAL 42=42**.
  Fixture `control_phase_kickback_mixed_preheader_addc_after_region_inloop.ll`: main
  `OPT_RC=0 CHECK=1 FCNT=1 UCNT=1` **RED**, mine all 8 prefixes 0 **GREEN**.
  Injection matrix over BOTH new accepts (2 x 16): **`clean` PASS, 0 MISSED, 0 DIRTY**.
  Reproducers + a four-binary README committed at
  `docs/prd/phase-04-swap-route-control/inc1-records/c1-round4/` (23 files), the `c1-round3/`
  precedent. Commit `43ba404`; corpus 1674 -> **1675**.
- step 16 (THE 8h7d.5 QUESTION, asked of this widening and written into notes §3.14 as a table).
  Every reader of `taint.InPlaceRailOps` / `PreLoopCommittedInPlaceOps` (`grep -rn`), with the
  direction the widening moves it:
  * `OpcodeLowering:341/:428` — the op is emitted in place (**the subject**).
  * `inPlaceFenceHolds` G5 self-test — the commitment's single owner; unchanged.
  * the **Rule-8 FAN-OUT guard** (`:2187`, `:2617`, `> RailValueUse::OutOfPlace`) — `Unproven`
    and `InPlace` are BOTH `> OutOfPlace`, so the count is **arithmetically unchanged**.
  * `collectRailGates` (`:928`, `== InPlace`) — the gate set only GROWS, and its own comment
    says a MISSING gate is the over-accept: **strictly safer**.
  * `peelInPlaceStep(AsLowered=true)` — **exactly two call sites in the tree** (clause (ii)'s
    peel `:3176` and `markIfRailLocal`'s `onRail` `:3375`), the SAME spelling, which is the
    capability and is why they cannot disagree.
  * every other peel caller uses `AsLowered=false` (the SHAPE reading) — membership not consulted.
  * `WireWalk`/`declineStaleRecordOps` — runs BEFORE `lowerLoops`, the set is empty there.
  * the (1b) tripwire — more ops re-asked ⇒ more POSSIBLE loud declines; **0 measured**.
- step 17 (INC 2, read-only on `$SP0/wt/inc2` @ 6ee3ea3 — a REPRODUCER measurement only, no
  fixture, no slice): `q4b_preadd_{rolled,unrolled}` lowers there via the **Inc-2 value-arm
  CONTROLLED-COPY merge** (two `cqrt_copy_i32_controlled` into `%out`, then
  `cqrt_addc_i32(%out, 7)`) and STILL DIVERGES **4/0 (52 lines) vs 4/4 (60)**; `q5sel_preadd`
  diverges there too (44 vs 52). So Inc 2 adds a FOURTH producer of the rail and the same
  conjunct refuses it. That my fix serves it is ANALYTIC (the writers are the same `cqrt_copy`
  family, settled by G7 arm (c)) — it CANNOT be measured until the orchestrator rebases this
  branch onto the landed Inc 2.
- step 18 (SHAPE OF THE DIFF, `git diff --name-status main HEAD`): **30 A / 8 M**. ONE source
  file (`ir-pass/src/LoopLowering.cpp`, +60/-12, of which the only non-comment change is the
  4-line conjunct edit), **NO golden MODIFIED** (4 A), and `git diff --stat main HEAD -- runtime
  tools/opcode_table.yaml include` **EMPTY** (owner decision D3 — no new symbol).
- step 19 (FINAL GATES on my build, all re-measured by command):
  `ctest -R ir-pass-lit` -> **Passed, 41.02 s, 0 failed** (`c1d_lit_B.log`);
  `ctest -j6 -R 'quarantine-selftest|free-pairing-selftest|twin-identical|perbit|onward-perbit|merge-preadd'`
  -> **34/34 passed, 5.30 s**; `ctest -j6 -R 'e2e-loop-twin-matrix|…'` -> **35/35, 229.35 s**
  (matrix **Passed, 229.18 s**). COUNTS: `ls ir-pass/test/*.ll | wc -l` **1675** ·
  `ctest -N` **351** / `^e2e-` **341** / `^e2e-slice-` **310** / `twin-identical` **21** ·
  `grep -c '^m_' …expected.txt` **259** + `grep -c '^cell ' …quarantine.txt` **29** = **288** ·
  `ls tests/e2e/*.expected.log | wc -l` **312**.
  NOT RUN (deliberately, per BRIEF_common): the full `ctest` (the orchestrator's gate),
  `cq-opt-equivalence-full`, the `--phi-surface register` matrix (its header guard refuses
  against the shipped `CQ.h`), `frontend-lit`, the runtime entries.

---

## HAND-BACK

**The merge-out-rail family is rolled == unrolled BYTE-IDENTICALLY on my binary — `q5sel_preadd`
4/4 = 4/4 at 52 = 52 (was 4/0 / 44 vs 4/4 / 52 on `main`), `q4b_preadd` 65 = 65 (was 57 vs 65),
`q7_k32` 32/32 rolled (was 32/0) — and the F-C1C-1 family DECLINES on `main` AND on mine with
the same `cq loop lowering: pre-loop in-place op no longer provable at lowering` string:
`main` already declines all nine, so there is NO new decline anywhere. Measured over the whole
485-program C-1 population: 477 UNCHANGED / 8 MOVED, 0 ACCEPT→DECLINE, 0 DECLINE→ACCEPT, 0
decline strings changed.**

### 1 — what shipped (branch `c1-round4`, 8 commits on top of `main` a3c1513)

| commit | contents |
|---|---|
| `1cc0a6c` | the fix (ONE conjunct) + the merge-out-rail red-green fixture |
| `2c26ec6` | 2 e2e slices + 2 goldens + the `cmp` twin gate; twin-matrix sub-grid F4 |
| `d0da4ef` | notes §3.14, PRD §0 E2/E10, CLAUDE.md; OQ-C2-1's attribution corrected |
| `bd22a7f` | `loop_twin_matrix.expected.txt` regenerated (257 → 259) |
| `09bc5f1` | ROADMAP + CLAUDE.md counts re-measured by command |
| `43ba404` | the THIRD population class + its fixture + the committed reproducer set (`inc1-records/c1-round4/`, 23 files + README) |
| `7fb38e1` | notes/ROADMAP/CLAUDE.md: the third class, the 485-program sweep |
| `66c2945` | notes §3.14's 8h7d.5 closure table |

**CODE — ONE file, ONE non-comment change** (`ir-pass/src/LoopLowering.cpp`, +60/−12, of which
56 lines are the argument at the site):
`if (!P || !P->hasOneUse()) return;` → `if (!P) return;`.
No new `cqrt_*`/`cq_template_*` symbol; `git diff --stat main HEAD -- runtime
tools/opcode_table.yaml include` is **EMPTY** (owner decision D3). No golden MODIFIED.

**LIT** (corpus 1673 → **1675**): `control_phase_kickback_mixed_merge_out_rail_preadd_inloop.ll`
and `control_phase_kickback_mixed_preheader_addc_after_region_inloop.ll` — both ACCEPT, 8
prefixes, both `OPT_RC=0 CHECK=1 FCNT=1 UCNT=1` (**RED**) on `main` and all-zero here.

**E2E** (`ctest -N` 348 → **351**, `^e2e-` 338 → **341**, `^e2e-slice-` 308 → **310**, twin gates
20 → **21**): `slice_control_phase_perbit_loop_merge_preadd{,_unrolled}.c` + goldens (STRICT 2b
`0 violation(s), 0 unproven` on both) + `e2e-phase-perbit-loop-merge-preadd-twin-identical`
(**52 = 52**, was 44 vs 52).

**INSTRUMENT**: `tools/loop_twin_matrix.py` gains a `PREHEAD` slot and sub-grid **F4** (2 cells,
F 12 → 14, total 286 → **288**); `expected.txt` 257 → **259** rows, all 257 pre-existing rows
byte-unchanged, `quarantine.txt` byte-unchanged, all **1144** pre-existing generated sources
hash-identical across both surfaces.

**DOCS**: notes **§3.14** (+ the §2 ⭐ table row and §3.13's OQ-C2-1 bullet), PRD **§0 E2/E10**
and the §0 header, **CLAUDE.md** (the C-1 bullet, the count "SEVEN ACROSS FIVE" → **"EIGHT
ACROSS SIX"**, three count lines), **ROADMAP**.

### 2 — what I ran

| gate | result |
|---|---|
| red-green per fixture, 2 binaries, per prefix (`rg.sh`) | both accepts **RED on `main`** (CHECK/FCNT/UCNT), **GREEN** on mine |
| POPULATION, `main` vs mine, **485 programs**, status + trace byte-diff | **477 UNCHANGED, 8 MOVED**, every mover named; **0 class flips in either direction, 0 decline strings changed** |
| STRICT stage 2b, all 332 accepts | **330 `0 violation(s), 0 unproven` + 2 `0 violation(s), 4 unproven`** (the `--allow-unproven` break family), 0 violations |
| mutation validation, one half at a time (3 build+check cycles, 10-fixture table) | **M1** (restore `hasOneUse`) → the new accept RED, nothing else; **M2** (delete the (1b) tripwire) → the decline fixture RED, nothing else; RESTORE all green. **On M2 all NINE F-C1C-1 programs accept and `y1` measures `h0,h1,h0` again** |
| instrumented DBG build (`P`'s use list + fence verdict) | the §3.11 `P` row re-done with programs — `hasOneUse` guarded NOTHING G6/G7 does not |
| injection matrix, 2 accepts × 16 | **`clean` PASS, 0 MISSED, 0 DIRTY** on both |
| `ctest -R ir-pass-lit` | **Passed, 41.02 s, 0 failed**, 1675 fixtures |
| `ctest -j6 -R 'e2e-loop-twin-matrix\|quarantine-selftest\|free-pairing-selftest\|twin-identical\|perbit\|onward-perbit\|merge-preadd'` | **35/35 passed, 229.35 s** (matrix 229.18 s at 288 cells) |
| twin matrix `--regenerate` | rc=0, 259 cells; **0 of 257 pre-existing rows moved**, quarantine byte-unchanged, 1144 sources hash-identical |
| Inc 2 (`$SP0/wt/inc2`, READ-ONLY) | `q4b` lowers via the Inc-2 controlled-copy value merge and STILL DIVERGES 52 vs 60 there — a FOURTH producer, unfixed until the rebase |
| **NOT run** | the full `ctest`; `cq-opt-equivalence-full`; `frontend-lit`; the runtime entries; the `--phi-surface register` matrix |

### 3 — findings that are NOT mine to decide

## OWNER QUESTION — OQ-C1D-1 (notes §3.14): OQ-C2-1's `m11d` is NOT bought back, and the reason is a DIFFERENT clause
The re-clearance attributed `m11d`'s leak to `P->hasOneUse()`. MEASURED on an instrumented
build, its candidate is refused by `classifyInPlaceReassignment` ITSELF — G7 arm (e), because at
the commit's program point loop 1's `(q>>i)&1` is a still-UNLOWERED tainted `and i32` rather
than a settled producer. Its trace is byte-unchanged across this round (6/3 rolled vs 6/6
unrolled on BOTH binaries; the pre-3qlq oracle discharged all six). Widening arm (e) to admit an
opcode `lowerOps` will itself discharge is a NEW predicate in the one function whose predictions
have now failed three times — not a fix round's call. Reproducer committed at
`inc1-records/c1-round4/c2_m11d_two_loops_no_preadd.c`.

## OWNER QUESTION — OQ-C1D-2: OQ-C1-5 is ANSWERED by ACTING, and the revert is one line
The brief instructed the retirement; OQ-C1-5 had put the choice to the owner ("`hasOneUse` is a
structural fence standing in for a temporal one … which does the owner want?"). If the owner
prefers to keep it, restore `|| !P->hasOneUse()` at `LoopLowering.cpp:2964` and revert commits
`1cc0a6c`/`2c26ec6`/`43ba404`; the cost of keeping it is the three measured leak classes above.

## OWNER QUESTION — OQ-C1D-3: two of the six movers have NO faithful twin, so their fix is
witnessed by the ROLLED column alone. `q7_k32` (K=32) — the flat twin loses bit 31 to `-O1`'s
`ashr`/`icmp slt` fold (31/31 vs 32/32), so the **O(K)** claim rests on the rolled counts.
`q5v_xor` — the documented `xorpre`/`r71` class (`xor` distributes over a bit test, so the flat
side becomes a different program). Neither is quarantined, following round 2's `addpost`/`xorpre`
precedent; both are recorded with their measurements.

## RECORD ITEM — `review_inc2_r2`'s "6.5 classical-call arm" row is UNREACHABLE, not unfixed
It was filed ANALYTIC. MEASURED on both binaries: `int y=5; if (q>5) y=ext_f(7); int m=y+7;`
DECLINES `cq controlled lowering: value-arm swap-route under quantum control`, because with a
constant else-value `-O1` SINKS the `+7` INTO the arm and 6.5 never classifies it. The row
should read *unreachable at `clang -O1`*, not *analytic*. (`c2_m04_onward_then_preadd` IS a 6.5
program that moves — but its preadd is on the CONDITION register, which is the THIRD class, not
the merge one.)

## RECORD ITEM — Inc 2 adds a FOURTH producer and the fix for it is ANALYTIC until the rebase
`q4b` on `$SP0/wt/inc2` lowers via the Inc-2 controlled-copy value merge and diverges 52 vs 60
there. The same G7 arm (c) argument covers it (the writers are `cqrt_copy_i32_controlled`), but
it CANNOT be measured from this branch. Re-measure after the orchestrator's rebase.

### 4 — what is left

* Nothing in F-I2-1 / OQ-C2-1 scope that this round can settle.
* The orchestrator still owes: the full `ctest -j6`, the rebase onto the landed Inc 2 (and a
  re-measurement of `q4b` there), and an independent Rule-13 lens — **which should be budgeted**:
  the count on this one function is now **eight findings over six adversarial rounds**, and the
  eighth was found by a round that was reviewing a different increment, AFTER the code had landed.
* Branch committed, NOT pushed. No bd issue closed or edited.

---
### POST-HAND-BACK ADDENDUM (build currency, self-caught)
`find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` reported `LoopLowering.cpp`:
the ~56-line in-source ARGUMENT was written AFTER the build that every gate above ran on, so
that binary carried the behaviour but not the comment. REBUILT (`c1d_build3.log`, BOTH targets)
and RE-RAN: both new fixtures still GREEN on all 8 prefixes; `ctest -R ir-pass-lit`
**Passed, 33.58 s, 0 failed**; `ctest -j6 -R 'quarantine-selftest|free-pairing-selftest|
twin-identical|perbit|onward-perbit|merge-preadd'` **34/34 passed**. `find … -newer` now EMPTY.
Recorded rather than silently fixed: a stale binary is how this project measures FALSE GREEN.
