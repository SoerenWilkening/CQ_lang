# fix_c1 — the C-1 FIX ROUND on 3qlq Inc 1 (clearance BLOCK)

Agent: fix_c1. Worktree `$SP/wt/fix-c1`, branch `3qlq-inc1-fix-c1` from 3qlq-inc1 (542d588).
PRE-FIX SUBJECT = main checkout /Users/sorenwilkening/Desktop/CQ_lang (542d588), never rebuilt.
ORACLE = $SP0/wt/pre-3qlq (52d7764).

## Log

- 2026-09-05 step 0: read BRIEF_common + BRIEF_fix_c1. Created worktree
  `$SP/wt/fix-c1` on branch `3qlq-inc1-fix-c1` at 542d588
  (`git worktree add`). Started background configure+build ->
  `$SP/progress/fix_c1_build.log`.

- step 1: build DONE (`BUILD_DONE_OK` in `fix_c1_build.log`). Harness copied to
  `$SP/progress/fix_c1_work/run.sh` with a 4th case `fix` -> `$SP/wt/fix-c1/build`.
  98 clearance reproducers copied to `.../p/`.
- step 2 (C-1 REPRODUCED on the PRE-FIX SUBJECT, main checkout 542d588):
    `./run.sh p/d1i_mixed_invariant_interf.c subj`  -> ACCEPT 2b=0 lines=31
    `./run.sh p/d1iu_..._unrolled.c subj`           -> ACCEPT 2b=0 lines=37
    `grep -c 'cq_template_and_i32_hl('`  rolled 3 / unrolled 3
    `grep -c 'cq_template_and_i32_hl_unc('` rolled **0** / unrolled **3**
    diff = exactly 3 inserted `_unc`+`cqrt_free` pairs. MATCHES clearance §2.2.
  ORACLE on the old-surface twin (`d1o`/`d1ou`, binary `orac` = 52d7764):
    both ACCEPT 37 lines, `diff` EMPTY (rolled == unrolled), `and_i32_hl_unc` 3.
    => C-1 is a REGRESSION against the pre-3qlq oracle. Confirmed independently.

- step 3 (RED, Rule 12): wrote
  `ir-pass/test/control_phase_kickback_mixed_invariant_carried_inloop.ll`
  (d1i's `clang -O1` module verbatim, `@main` dropped, `!llvm.loop` kept; 7 RUN
  lines over ONE `%t.cqd0.ll`; UCNT/ACNT/FCNT/XCNT/MDCNT count prefixes + a
  pure-negative whole-file NOROUTE; handle names DERIVED from the pass output).
  RAN on the PRE-FIX SUBJECT binary (542d588, main checkout):
    `cq-opt ... -S <fixture>` rc=0, then FileCheck per prefix:
      CHECK rc=1  UCNT rc=1  ACNT rc=0  FCNT rc=1  XCNT rc=0  MDCNT rc=0  NOROUTE rc=0
  => RED, and the ⭐ discriminator UCNT (`COUNT-1` of `and_i32_hl_unc`) is one of
  the three reds. GOOD.
- step 4 (IMPLEMENT, option (a) — the CAPABILITY): `ir-pass/src/LoopLowering.cpp`
    * `invariantRegisterRoots` gains `const SmallPtrSetImpl<Value*> *CarriedRoots`
      and a new clause (0): a candidate whose `peelInPlaceBase(V,…,AsLowered=true)`
      is already a carried root is SKIPPED, not judged (else clause (iii) sees the
      body's `r = cq_theta(r,.1)` on the RAUW'd `%r0` and refuses the whole
      extension). Header comment records C-1, the (I1) restatement, and that
      clause (i) is NOT vacuous post-collapse.
    * `collapseFlattenedLoopRails`, `Collapsed` branch: compute the invariant roots
      into a SEPARATE `SmallPtrSet Invariant`, union into `Roots` only on success
      (the out-set is filled incrementally and can return false half-filled), then
      call `markIfRailLocal` UNCHANGED.
    * `ir-pass/include/LoopPlan.h`: `collapseFlattenedLoopRails` header — "TWO ROOT
      SOURCES PER LOOP, NOT ONE".
  Rebuilt BOTH targets (`cmake --build build -j8`, `fix_c1_build3.log`,
  `BUILD_DONE_OK`). Only pre-existing warnings (RegionTreeDetect, TaintPropagation).
- step 5 (GREEN): `./run.sh p/d1i_mixed_invariant_interf.c fix` -> ACCEPT 2b=0
  lines=**37**; `and_i32_hl` **3** / `and_i32_hl_unc` **3**.
  `diff` rolled(fix) vs unrolled(fix)  -> EMPTY (IDENTICAL).
  `diff` rolled(fix) vs unrolled(subj 542d588) -> EMPTY.
  `diff` rolled(fix) vs the COMMITTED clearance record
    `clearance_c1/d1iu_mixed_invariant_interf_unrolled.subj.trace` -> EMPTY.
  lit fixture on my build: PASS (0.56 s).

- step 6 (POPULATION, 3 binaries; `$SP/progress/fix_c1_work/{tab_subj,tab_fix,tab_new_subj,tab_new_fix}.tsv`,
  driver `sweep.sh`, byte-diffs by `diff out/<a>.<w>.trace out/<b>.<w>.trace`):

  | program | subj rolled/unrolled `and_unc` | fix rolled/unrolled | rolled==unrolled subj | fix | 2b |
  |---|---|---|---|---|---|
  | d1  mixed, no diffusion        | 0/3 | 3/3 | DIVERGES(6) | **IDENTICAL** | 0 viol |
  | d1i mixed + diffusion (C-1)    | 0/3 | 3/3 | DIVERGES(6) | **IDENTICAL** | 0 viol |
  | d1c carried `r^=9`             | 0/3 | 3/3 | DIVERGES(8) | DIVERGES(2)   | 0 viol |
  | d1k kickback on `r` too        | 0/3 | 3/3 | DIVERGES(6) | **IDENTICAL** | 0 viol |
  | d11 P3 tree w/ per-bit leaf    | 0/3 | 3/3 | DIVERGES(6) | **IDENTICAL** | 0 viol |
  | d1w K=32 (rolled only)         | 0/-  | 32/- | n/a        | 32 mints/32 unc | 0 viol |
  | d1d `q` DEAD                   | 0/-  | 3/-  | n/a        | root+rails left allocated, NOTHING freed dirty | 0 viol |
  | d1m direct compare on invariant| DECLINE `condition predates a non-diagonal gate` | same | — | UNCHANGED (drbq.12 LICM over-decline) | — |
  | d7  two invariant registers    | 6/6 | 6/6 | IDENTICAL | IDENTICAL (UNMOVED) | 0 viol |
  | d9  invariant root chain       | 3/3 | 3/3 | IDENTICAL | IDENTICAL (UNMOVED) | 0 viol |
  | d12 invariant cond measured    | 3/3 | 3/3 | IDENTICAL | IDENTICAL (UNMOVED) | 0 viol |
  | e5  P3 loop-carried leaf       | 0/0 | 0/0 | IDENTICAL | IDENTICAL (UNMOVED) | 0 viol |
  | d4  per-bit K=4 + diffusion    | 4/4 | 4/4 | IDENTICAL | IDENTICAL (UNMOVED) | 0 viol |
  | d5  per-bit K=32               | 32/31| 32/31| DIVERGES(21)| DIVERGES(21) UNMOVED (the documented `(q>>31)&1 -> icmp sgt` frontend canonicalisation) | 0 viol |
  | d6  sequential derived in-loop | 6/4 | 6/4 | DIVERGES(28)| DIVERGES(28) UNMOVED (clearance's unfaithful `d6u`) | 0 viol |
  | d10 trailing in-place `addc`   | 3/3 | 3/3 | IDENTICAL | IDENTICAL (UNMOVED) | 0 viol |
  | **d2 hoisted `sext` rail**     | 0/0 | 0/0 | DIVERGES(10)| DIVERGES(10) — rolled trace **BYTE-UNCHANGED subj==fix** (Q-R1-1 leak-control) | 0 viol |
  | **d3 hoisted Q+Q rail**        | 0/3 | 0/3 | DIVERGES(8) | DIVERGES(8)  — rolled trace **BYTE-UNCHANGED subj==fix** (Q-R1-1) | 0 viol |
  | b7  onward hoisted temp        | DECLINE `control flow` | same | — | UNCHANGED | — |

  NEW spellings written this round (`p/n*.c`):
  | n1 carried theta+`^9` chain    | 0/3 | 3/3 | DIVERGES(8) | MULTISET IDENTICAL, 2-line POSITION diff | 0 viol |
  | n2 TWO carried + one invariant | 0/3 | 3/3 | DIVERGES(6) | **IDENTICAL** | 0 viol |
  | n3 invariant MEASURED in body  | 0/3 | 3/3 | DIVERGES(6) | **IDENTICAL** | 0 viol |
  | **n4 per-bit on a SEXT of q**  | 0/0 | 0/0 | DIVERGES(10)| DIVERGES(10) — rolled trace **BYTE-UNCHANGED subj==fix** (leak-control) | 0 viol |
  | n5 K=1                         | 1/1 | 1/1 | IDENTICAL | IDENTICAL (UNMOVED) | 0 viol |
  | n6 carried gate BEFORE kick    | 0/3 | 3/3 | DIVERGES(6) | **IDENTICAL** | 0 viol |
  | n7 second kickback on carried  | 0/6 | 6/6 | DIVERGES(12)| **IDENTICAL** | 0 viol |
  | n8 mixed + ONWARD region       | 0/-  | 6/6 mints/uncs | flat twin DECLINES `control flow` on BOTH | structurally paired, LIFO, per trip | 0 viol |

  TWO residual byte divergences are UNFAITHFUL TWINS, measured, not compiler defects:
  * `d1c`: the unrolled source's THREE `r^=9` are FOLDED by `clang -O1` into ONE
    (`9^9^9 == 9`) — `grep -c '= xor i32'` on stage-1 IR: rolled 1, unrolled 1,
    but the unrolled's single xor stands for all three. Rolled emits 3 `cqrt_xorc`,
    unrolled 1. Same class as the clearance's `d6u`. This is why `n1` was written.
  * `n1`: MULTISET IDENTICAL (`diff <(sort …) <(sort …)` EMPTY); the only difference
    is the POSITION of one `cqrt_xorc_i32(h1,9)` relative to gates on the DISJOINT
    register `h0` — `-O1` sank the 2nd trip's xor past the 3rd `if` in the
    straight-line spelling. Commuting operations on disjoint wires; present
    identically on 542d588 (subj diverges by 8 = these 2 + C-1's 6).

- step 7: `ctest -R ir-pass-lit` on my build -> **Passed, 32.31 s** (`fix_c1_lit_A.log`).
  `lit -q ir-pass/test` -> **1657 discovered, EXIT=0** (`fix_c1_lit_B.log`); 1656 + my
  1 new fixture. No failures printed.

- step 8 (MUTATION VALIDATION, the fix_r2 pattern; `fix_c1_work/mutate.sh`,
  log `fix_c1_mutate.log`), one half at a time, each with a full rebuild:
    M1  disable the CarriedRoots SKIP (clause 0)  -> lit_rc=**1** (RED), d1i 31 lines, and_unc=**0**
    M2  disable the UNION on the Collapsed branch -> lit_rc=**1** (RED), d1i 31 lines, and_unc=**0**
    RESTORED                                       -> lit_rc=**0** (GREEN), d1i 37 lines, and_unc=**3**
  BOTH halves are load-bearing; neither is decoration.
- step 9 (three more fixtures, all verified on the PRE-FIX SUBJECT binary first):
  * `control_phase_kickback_mixed_hoisted_template_leak_control.ll` — the Q-R1-1
    LEAK CONTROL (new source `p/n9_mixed_hoisted_template_leak.c`: `int p=q*3;`
    hoisted, mixed with a carried `r`). ACCEPTS AND LEAKS: `UCNT-NOT` pins ZERO
    `and_i32_hl_unc`, `FCNT-COUNT-1` pins the single (flag) free. GREEN on
    542d588 (all 5 prefixes rc=0) AND on my build -> the widening did NOT reach it.
    MEASURED rolled/unrolled 3/0 vs 3/3 on both binaries.
  * `lowering_reject_break_phase_answer_kickback.ll` — THE B3 PIN (clearance §4(i)
    / §5.2), built from the COMMITTED `clearance_c1/f1_break_kick_before.subj.s1.ll`
    with `@main` dropped. `RUN: not … | FileCheck` mirrors
    `cq loop lowering: early break preserves a phase answer` character-for-character.
    MEASURED on 542d588: `opt` exit **1** with exactly that string; PASS on my build.
  * `lowering_break_global_phase_before_accept.ll` — its DISCRIMINATING CONTROL
    (`f3`, the bare `cq_phi(0.3)` before the same loop). ACCEPTS; `NOPHASE` pins
    the D2 deletion (no `@cqrt_rz_` anywhere). MEASURED: its trace is
    BYTE-IDENTICAL to the plain break loop's (`p/f0_break_plain.c`, 209 = 209,
    `diff` empty) — so B3 is a discriminator, not a wall. (Both are stage-2b
    `unproven`, exactly like the four shipped `slice_loop_break*` slices.)
  `lit --filter 'control_phase_kickback_mixed|lowering_reject_break_phase_answer|lowering_break_global_phase'`
  -> 5 of 1660 PASS (incl. the pre-existing `lowering_reject_break_phase_answer.ll`,
  left as is per the brief).

- step 10 (CLOSURE — the 8h7d.5 question, constraint 6). The closure I widened is
  "the Roots `markIfRailLocal` treats as THE REGISTER". GREP-ESTABLISHED FIRST:
  `Roots` is a LOCAL of `collapseFlattenedLoopRails`, passed only to
  `collapseRailPhisIn`, `invariantRegisterRoots` and `markIfRailLocal`
  (`grep -rn 'invariantRegisterRoots\|markIfRailLocal' ir-pass/src ir-pass/include`).
  Its ONE product that escapes this stage is `taint.IterationLocalBlocks`, a set
  of BLOCKS. So the closure has exactly one downstream carrier, and these are its
  consumers:

  | set / predicate | the answer | what MEASURES it |
  |---|---|---|
  | `markIfRailLocal`'s `onRail` / `AnyLocal` / escape exemption | Adding root `R` makes `onRail` true for in-loop values that PEEL to `R`. There are NONE: a `cq_theta`/`cq_phi` in `L` on `R`'s chain makes clause (iii) refuse the whole extension, and a dtzb `add`/`xor` in `L` is `OutOfPlace` under `AsLowered` (`railValueConsumerDisposition` -> `blockCanRepeat` is TRUE in a loop), so the peel stops at the BO and `onRail` is false. The only effect is that the operand clause no longer returns early for `R` itself. | probe `n10_mixed_body_temp_escapes.c` (a body temp `t = q & (1<<i)` that ESCAPES the loop): trace BYTE-UNCHANGED subj==fix, `and` 3 / `and_unc` 0 — the escape clause still refuses, leak stands. Mutations M1/M2 (both kill the marking). |
  | `Uncomputation`'s `IterationLocalBlocks` consumers — the §4/§2.9 MULTIPLICITY pair (a PREHEADER recovered gate with a body `At`) | An admitted Root is a `cqrt_alloc_<W>` producer (root mint, or a clause-(ii-b) control-owned out-rail), and `ChainWalk::isInteriorTerminalHandle` (I1) requires `isTemplateProducer` AND a `cq_template_`-prefixed callee — so no interior `At` can be placed for it. THE `Collapsed`-BRANCH HALF IS UNCHANGED BY THIS EDIT: that branch already called `markIfRailLocal` and already marked the body; the carried rail's preheader chain is `cq_theta` calls and marked `InPlaceRailOps`, none of them template producers. | `d1w` K=32: 32 mints / **32** uncs (a K-vs-1 pairing defect would show as 32 adjoints against 1); `d9` (a two-hop preheader root chain) UNMOVED; `d10`/`n1` (in-place `addc`/`xorc` on the carried rail) 1:1; `n8` (round-2 delta) 6/6 LIFO per trip. |
  | `FreePoint`'s `TermIterLocal` (terminal def block in `IterationLocalBlocks`) | An invariant ROOT is defined OUTSIDE `L`, so `TermIterLocal` is false for it and it keeps the ordinary Measured/Escaped path — exactly what the pre-existing header comment states. More loops are now marked, so more BODY-DEFINED terminals are in-body; that is the intended discharge. | STRICT stage 2b `0 violation(s)` on EVERY accepting reproducer in this round (~50); `d1d` (`q` DEAD): root and rails LEFT ALLOCATED, nothing freed dirty. |
  | `staleRailRecordRead` (`collapseRailPhisIn` step 2b) | It is asked ONLY of the COLLAPSED `ChainsByRoot`, never of the invariant root's chain — TRUE BEFORE THIS EDIT TOO (the `NotClaimed` path has the identical gap since F-L5-1). It is sound for a reason that must be STATED rather than inherited from the collapsed case: clause (iii) refuses an in-loop in-place gate on an invariant root and clause (i) refuses a header phi, so NOTHING in the body relabels it and the escape exemption has an EMPTY extension for those roots (row 1). The post-loop diffusion is a rail gate, but that is the pass-wide `declineStaleRecordOps` guard's business and is untouched. **⚠ If a future change ever admits an in-loop in-place gate on an invariant root, this emptiness ends AND step (2b)'s proof still would not cover it** — recorded as the fence, not as a comfort. | `n3` (the invariant register `cq_measure`d INSIDE the body ×3): rolled == unrolled BYTE-IDENTICAL; `d12` UNMOVED; `n11` (a post-loop record read) — see the OWNER QUESTION below. |
  | `ControlOwnedRails` | Read by clause (ii-b), unchanged — the union path reuses (ii-b) verbatim. | `n8` (the onward 6.5 `%out` rail) discharges 6/6. |
  | `railGateBetween` / `collectRailGates` | Neither reads `Roots`; both take CHAIN MEMBERS (`ChainsByRoot[...]`). GREP-verified. | n/a — no coupling to widen. |

- step 11 (E2E LAYER, the layer that can witness a moved golden):
  `ctest -j6 -R '^e2e-'` on my build -> **332/332 passed, 294.52 s**
  (`fix_c1_e2e_A.log`), INCLUDING `e2e-loop-twin-matrix` at its pre-axis 274 cells
  and `e2e-loop-twin-quarantine-selftest`. So the C-1 fix moved **no e2e golden
  and no matrix cell**.
- step 12 (TWIN MATRIX AXIS, clearance §4 (ii)): `tools/loop_twin_matrix.py` gains
  SUB-GRID F, **14 cells** (F1 = 4 regions x 3 `r`-carry gates; F2 = 2 record
  cells), 274 -> **288**. The regions are D4's per-bit idiom on a loop-INVARIANT
  `a` with the arm spelled `r = cq_phi(r, 0.2)` so BOTH surfaces are sensible
  (void -> the bare kickback; register -> the pre-3qlq oracle's `d1o` twin). Two
  new `_wrap` parameters, BOTH defaulted: `index` (binds `i` on the flat side —
  no existing cell reads the loop index) and `postloop` (the post-loop diffusion).
  **PROVEN BYTE-UNCHANGED, not asserted**: `dump_sources.py` hashes every
  generated source for every cell on both surfaces, before and after the edit —
  `comm -23 before after` is **EMPTY** over all **1104** pre-existing rows; 56 new
  rows appear (14 cells x 2 surfaces x 2 spellings). `cells_of_matrix`'s size
  assert and docstring updated (120/36/118/**14**, 288).

- step 13 (INJECTION MATRIX over the new accepts, fix_r2's `inj.py` re-pointed at my
  build): 3 fixtures x 16 mutations = 48 cells. FIRST RUN found **2 rows with MISSED
  cells** and that is the finding, not the pass:
    * `..._mixed_hoisted_template_leak_control.ll`: `extra_x` MISSED (no `cqrt_x`
      census) -> added an `XCNT-COUNT-2` / `XCNT-NOT` prefix.
    * `lowering_break_global_phase_before_accept.ll`: `extra_free`, `extra_x`,
      `extra_cswap` and `e_drop_free` ALL MISSED (it had only CHECK + a negative
      prefix) -> added FCNT (16 frees), XCNT (zero `cqrt_x`) and CCNT (2
      `cqrt_toffoli`, no `cqrt_cswap`), every count MEASURED on the module.
  RE-RUN: **0 MISSED, 0 DIRTY**, `clean` PASS on all three (`inj_c1b.tsv`).
  ⚠ Trap recorded: writing `NOPHASE:` inside fixture PROSE makes FileCheck read it as
  a directive — the first version of that fixture went red on its own comment.
- step 14 (TWIN MATRIX, first `--regenerate` on my build): the instrument **REFUSED TO
  WRITE** and reported 4 hard failures — every `addpost` cell of sub-grid F
  (`m_none_pbit*_none_none_addpost`). INVESTIGATED rather than quarantined:
    * on 542d588 those cells diverge by 6 lines (C-1's 4 missing `_unc`+`free` lines
      PLUS a 2-line `addc` position shift); MULTISET DIFFERS.
    * on my build the C-1 half is GONE and the ONLY difference left is the POSITION of
      one `cqrt_addc_i32(h1, 3)`; **MULTISET IDENTICAL**, same line count, same
      `_unc`/free/mint counts.
    * READ THE TWO STAGE-1 MODULES (Rule 11): the flat spelling keeps the volatile
      `load @off` in place and **SINKS `add nsw %7, %2` past the SECOND region**
      (block `%6` -> block `%11`), which a loop body cannot do across the back edge.
      The two SOURCES are not the same program after `-O1`.
  DISPOSITION: `addpost` DROPPED from `F_RGATE` with the measurement recorded in the
  code — quarantining a `-O1` scheduler artefact as a filed compiler defect is what
  the quarantine file's own header forbids, and the in-place-`add` carry shape is
  covered by the population table (`d1c`, `d10`, `n1`). Sub-grid F is **10 cells**,
  274 -> **284**. Byte-identity of the 1104 pre-existing generated sources RE-PROVEN
  after the drop (`comm -23` empty, 40 new rows).

- step 15 (MATRIX REGENERATED, 2nd run): `--regenerate` on my build ->
  `regenerated tools/loop_twin_matrix.expected.txt (255 cells; 29 quarantined and
  omitted)`, rc=0. DIFF against the committed table:
    * `comm -23 before after` over the `^m_` rows -> **EMPTY**: every one of the
      **245** pre-existing rows is BYTE-UNCHANGED. Non-row (header) diff EMPTY.
    * **10 NEW rows**: 9 `ACCEPT-IDENTICAL` and 1
      `UNROLLED-ONLY cq loop lowering: rail record read past an in-place gate on the
      same rail` (`m_none_pbitd_none_rpremark_rypost`) — a verdict **23 other shipped
      cells already carry**, i.e. an established over-decline class, not a new one.
    * PRE-FIX DISPOSITION of the new cells, measured by hand on 542d588 (4 sampled
      ACCEPT-IDENTICAL cells + the record pair): all four were **TRACE-DIVERGENCE(4)**
      on the subject and are IDENTICAL on the fix; the `rpremark` cell is
      UNROLLED-ONLY on BOTH. **So 9 of the 10 new cells would have been HARD FAILURES
      before the C-1 fix** — that is the axis's value, stated as a measurement.
    * The `register` table is deliberately NOT extended: `--phi-surface register`
      returns 2 at the header guard BEFORE `cells_of_matrix()` runs (the retired
      `cq_phi_<sfx>` family is gone from the tree), so the 10 cells are unreachable
      in that mode. Recorded in the code, not left as an omission.

- step 16 (FINAL GATES on my build, `fix_c1_final_gates.log`):
  `ctest -j6 -R 'e2e-loop-twin-matrix|e2e-loop-twin-quarantine-selftest|^e2e-slice-control-phase-perbit|^e2e-phase-perbit|ir-pass-lit'`
  -> **10/10 passed, 195.49 s**:
    `ir-pass-lit` Passed 40.08 s · `e2e-loop-twin-matrix` Passed **195.45 s**
    (284 cells) · `e2e-loop-twin-quarantine-selftest` Passed 0.57 s ·
    `e2e-slice-control-phase-perbit-loop{,-unrolled,-k32,-mixed,-mixed-unrolled}` ·
    `e2e-phase-perbit-loop-twin-identical` · `e2e-phase-perbit-loop-mixed-twin-identical`.
- step 17: `bd remember --key dispatch-precondition-excluded-invariant-roots-c1`
  (the C-1 root cause + the "are the two branches disjoint IN THE CUSTOMER SET?"
  lesson). No bd issue closed or edited.

---

## HAND-BACK

### 1 — what shipped (branch `3qlq-inc1-fix-c1`, 5 commits on top of 542d588)

**OPTION (a), THE CAPABILITY.** C-1 on my binary: **ROLLED 3 / 3** (`and_i32_hl` /
`and_i32_hl_unc`), **UNROLLED 3 / 3**, traces BYTE-IDENTICAL (37 = 37) and identical
to the committed clearance record
`clearance_c1/d1iu_mixed_invariant_interf_unrolled.subj.trace`. On 542d588 it was
rolled **3 / 0** vs unrolled 3 / 3.

| commit | contents |
|---|---|
| `dc740c9` | the fix + the red-green accept fixture |
| `e513663` | the Q-R1-1 mixed leak control, the B3 pin, the global-phase accept control |
| `9ac1ee6` | the mixed rolled/unrolled e2e pair + the `cmp` twin gate |
| `0921d25` | PRD ERRATA E2, notes §3, CLAUDE.md, matrix sub-grid F, 2 fixtures hardened |
| `3ec40c9` | sub-grid F's register-table note + the 10 cells' measured pre-fix dispositions |

CODE (`ir-pass/src/LoopLowering.cpp` +91/-, `ir-pass/include/LoopPlan.h` +19):
`invariantRegisterRoots` gains `const SmallPtrSetImpl<Value*> *CarriedRoots` and
clause (0) (skip a candidate the collapse already owns); the `Collapsed` branch of
`collapseFlattenedLoopRails` collects the invariant roots into a SEPARATE set and
unions on success only. No new `cqrt_*` / `cq_template_*` symbol, no new diagnostic,
no change to `markIfRailLocal`, `Uncomputation`, `FreePoint` or `runtime/`.

LIT (4 new files, corpus 1656 -> **1660**):
`control_phase_kickback_mixed_invariant_carried_inloop.ll` (ACCEPT, the C-1 pin),
`control_phase_kickback_mixed_hoisted_template_leak_control.ll` (ACCEPT-AND-LEAKS,
the Q-R1-1 discriminating control),
`lowering_reject_break_phase_answer_kickback.ll` (DECLINE, the B3 pin),
`lowering_break_global_phase_before_accept.ll` (ACCEPT, B3's discriminator).

E2E (2 slices + 2 goldens + 1 `cmp` gate; entries 329 -> **332** in `^e2e-`):
`slice_control_phase_perbit_loop_mixed{,_unrolled}.c` + goldens +
`e2e-phase-perbit-loop-mixed-twin-identical`.

INSTRUMENT: `tools/loop_twin_matrix.py` sub-grid **F**, 10 cells, 274 -> **284**;
`tools/loop_twin_matrix.expected.txt` 245 -> **255** rows, every pre-existing row
BYTE-UNCHANGED.

DOCS: PRD §0 **E2 rewritten** ("three things, not two"; C-1 named, fixed, witnessed;
the Q-R1-1 sentence now says "ANY loop-invariant TEMPLATE rail"); notes **§3** (the
verdict, root cause, fix, mutation table, population table, the 8h7d.5 closure table,
the matrix axis, the B3 fixture, 3 owner questions); CLAUDE.md's in-loop bullet gains
the third-instance sentence.

### 2 — what I ran

| gate | result |
|---|---|
| C-1 red-green | RED on 542d588 (CHECK/UCNT/FCNT rc=1), GREEN on mine |
| `ctest -R ir-pass-lit` (mine) | **Passed**, 32.3 s then 40.1 s |
| `lit -q ir-pass/test` (mine) | **1657 discovered, EXIT=0** (before the last 3 fixtures; 1660 at HEAD, ctest green) |
| `ctest -j6 -R '^e2e-'` (mine) | **332/332 passed, 294.5 s** — no golden moved, no matrix cell moved |
| final gate set (10 entries incl. the matrix + quarantine selftest) | **10/10, 195.5 s** |
| mutation validation, one half at a time | M1 RED · M2 RED · RESTORED GREEN (3 build+lit cycles) |
| injection matrix (fix_r2's `inj.py`, re-pointed) | 3 accepts × 16 mutations = 48 cells, **0 MISSED / 0 DIRTY** after hardening 2 fixtures that the FIRST run showed were blind |
| population, 3 binaries | 26 programs + 12 new spellings, table in §3.5 of the notes and in step 6 above; STRICT 2b `0 violation(s)` on every accept |
| matrix `--regenerate` | 1st run REFUSED to write (4 `addpost` hard failures — investigated, `-O1` sink, `addpost` dropped); 2nd run rc=0, 245 rows byte-unchanged + 10 new |
| generated-source byte-identity | all **1104** pre-existing rows unchanged (`comm -23` empty), twice |
| **NOT run** | the full `ctest` (the orchestrator's gate); `cq-opt-equivalence-full`; the `--phi-surface register` matrix (its header guard refuses against the shipped `CQ.h`) |

### 3 — findings that are NOT mine to decide

**OQ-C1-1 — a `Collapsed` loop with a SURVIVING tainted header phi.**
`collapseRailPhisIn` step (1) `continue`s in four places, so `Collapsed` does not imply
"no tainted header phi remains". The extension refuses such a loop at clause (i), and
`markIfRailLocal` refuses it again — today's leak, unchanged, Prime-Directive direction.
Should the mixed extension serve it too? No plain-C reproducer was constructed.

**OQ-C1-2 — an alias measured after a later gate on the same wire; PRE-EXISTING and
loop-independent.** `p/n12_flat_alias_measure_after_gate.c`:
`int q=cq_theta(u,.5); int mark=q; q=cq_theta(q,.9); return cq_measure(mark);` — no
loop — ACCEPTS and emits `ry(h0,.5); ry(h0,.9); measure(h0)`, i.e. the POST-gate
register measured where the source named the PRE-gate value. **MEASURED IDENTICAL on
the pre-3qlq ORACLE 52d7764, on 542d588 and on my build.** Flagged because the in-loop
spelling `p/n11_mixed_invariant_record_after_diffusion.c` is in this round's population
and a reader will otherwise mistake it for C-1 fallout (its only change across the fix
is the same three `_unc`+`free` pairs `d1i` gains — no reordering).

**OQ-C1-3 — the flat twin of a mixed loop with an ONWARD region declines.**
`p/n8_mixed_plus_onward_inloop.c` + `p/tu_extf.c`: the rolled form pairs 6/6 LIFO per
trip and is STRICT-2b clean on my build (6/0 on 542d588), but its hand-unrolled twin
declines `control flow under quantum control` on BOTH binaries — the clearance's own §5
item 5 (`b2u`/`b6u`). So that round-2-delta accept has no twin witness.

**NOT an owner question, but the orchestrator's docs pass owes it:** CLAUDE.md's ctest
counts move — `^e2e-` 329 -> 332, total 339 -> 342, `ir-pass-lit` corpus 1656 -> 1660,
`loop_twin_matrix.expected.txt` 245 -> 255 rows / 284 cells run. I edited ONE sentence
in CLAUDE.md per the brief and left the count sentences alone.

### 4 — what is left

* Nothing in the C-1 scope. The branch is committed, not pushed, and no bd issue was
  closed or edited (one `bd remember` added).
* The orchestrator still owes: the full `ctest -j6`, the wider CLAUDE.md/ROADMAP count
  pass, and the re-clearance.
* `d1c`'s and `n1`'s residual byte divergences are UNFAITHFUL TWINS (`-O1` folds
  `9^9^9` -> `9`; `-O1` sinks a straight-line `add` past a region), measured on both
  binaries and recorded in notes §3.6 — not compiler defects and deliberately NOT
  quarantined.
