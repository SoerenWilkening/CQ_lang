# fix_c1c — the THIRD C-1 round: NARROW round 2 (F-C1B-1, F-C1B-2, F-C1B-5)

Agent: fix_c1c. Worktree `$SP/wt/fix-c1`, branch `3qlq-inc1-fix-c1`, base 638334c.
Scope: NARROWING ONLY. No new accept anywhere.

## Log
- 2026-09-06 — step 0: saved the round-2 binary pair to `$SP/progress/fix_c1c_work/{cq-opt.fix2,libCQPass.so.fix2}`
  (`cp -f` from `$SP/wt/fix-c1/build/ir-pass/`). Worktree clean at 638334c.
- step 1: read BRIEF_fix_c1b, progress/fix_c1b.md, progress/review_c1b.md IN FULL, notes §2 ⭐ table
  + §3.10, and the code (`LoopLowering.cpp` `commitOutOfLoopInPlaceOps` / `invariantRegisterRoots{,Impl}`
  / the two `ClaimedRailRoots` writers, `ArithLowering.cpp` `classifyInPlaceReassignment` /
  `inPlaceFenceHolds` G4/G5/G6/G7, `OpcodeLowering.cpp:236-350`, `TaintPropagation.h:370/:418/:457`).
- step 2: HARNESS `$SP/progress/fix_c1c_work/{run.sh,p/,out/}` — review_c1b's harness with a FIFTH case
  `fix2` (the SAVED round-2 pair). 263 reproducers in `p/` (review_c1b's set is a superset of all three
  earlier rounds' — verified by `cmp` over fix_c1_work/review_c1_work/fix_c1b_work: only `ctl_good.c`
  differs). CONTROLLED: `ctl_good` ACCEPT 4 lines on subj/fix1/fix2/orac; `ctl_bad` DECLINE
  `cq rotation lowering: unsupported quantum-derived rotation angle` on all four.
- step 3 (F-C1B-1 REPRODUCED INDEPENDENTLY on FIX-2, `./run.sh p/<z>.c <bin> p/tu_extf.c`;
  `railInImmSlot` = `grep -cE 'call void @cqrt_(addc|xorc)_i32\(i32 %[A-Za-z0-9_.]+, i32 %' s2.ll`):

  | program | 542d588 | FIX-1 | FIX-2 |
  |---|---|---|---|
  | z23_preadd_r2derived_imm  | 47 lines, railInImmSlot=0 | 47, 0 | **51, 1 — `cqrt_addc_i32(h7, 6)`** |
  | z26_preadd_r2derived_add1 | 47, 0 | 47, 0 | **51, 1 — `cqrt_addc_i32(h6, 7)`** (operands swapped) |
  | z27_prexor_r2derived      | 47, 0 | 47, 0 | **51, 1 — `cqrt_xorc_i32(h7, 6)`** |
  | z29_preadd_r2derived_and  | 47, 0 | 47, 0 | **51, 1 — `cqrt_addc_i32(h7, 6)`** |

  All four `opt` exit 0 and STRICT 2b `0 violation(s)` on FIX-2 (`2b=0` in every status line).
  `z32_claim_across_loops_nomeas` DECLINES `cq uncompute: tainted handle live range crosses a loop
  backedge` on ALL THREE binaries — so F-C1B-2 has NO trace-level pin and its discriminator has to be
  the marking itself (instrumented build) plus mutation.
- step 4 (IMPLEMENT, all three halves; build rc=0, only the 4 PRE-EXISTING `-Wunused-*` warnings):
  * **(1a)** `commitOutOfLoopInPlaceOps` (LoopLowering.cpp) now requires `isa<Constant>(Imm)` BEFORE
    asking `classifyInPlaceReassignment`. The argument is written at the site and CHECKED, not assumed:
    `IOSinkLowering.cpp:295` already enumerates every `taint.Tainted.insert(` site as a
    `CallInst`/`Instruction`/(clone-local) `Argument` — never a `Constant`; RE-MEASURED at this HEAD
    (`grep -rn 'Tainted\.insert(' ir-pass/src` → **35** sites, the file's own "30" being older).
  * **(1b)** new `taint.PreLoopCommittedInPlaceOps` (TaintPropagation.h) — the SUBSET of
    `InPlaceRailOps` this path PREDICTED, written and rolled back in lockstep. `lowerOps` Phase 1
    re-asks `classifyInPlaceReassignment` for exactly those ops under the FINAL `DominatorTree`/
    `LoopInfo` and FINAL taint, and on a changed answer fires
    `cq loop lowering: pre-loop in-place op no longer provable at lowering` and enqueues nothing.
    The re-ask suppresses ONE clause — G5's `InPlaceRailOps` self-test — through a new defaulted
    `IgnoreSelfMarking` parameter threaded `classifyInPlaceReassignment` → `inPlaceFenceHolds`
    (ONE fence body, Rule 14; no second spelling).
  * **F-C1B-2** `taint.ClaimedRailRoots` becomes
    `DenseSet<pair<const Value *, const BasicBlock *>>` keyed on `(root, the CLAIMING loop's header)`;
    both writers pass `L->getHeader()`, clause (0) asks `{Root, L->getHeader()}`.
- step 5 (THE FOUR REPRODUCERS ON MY BINARY, `./run.sh p/<z>.c fix p/tu_extf.c`):
  z23 / z26 / z27 / z29 all **47 lines, railInImmSlot=0**, emitting
  `cq_template_{add,xor}_i32(h7, h6) -> h8` — and every one **BYTE-IDENTICAL to FIX-1's trace**
  (`cmp -s`), hence to 542d588's. The `cqrt_addc_i32(h7, 6)` gate is gone.

## ⭐ F-C1C-1 — a SECOND CONFIRMED SILENT MISCOMPILE in round 2's commit, found by BUILDING the tripwire's customer (2026-09-06)

The brief predicted the (1b) tripwire would be "unreachable from plain C for the immediate half".
It is reachable from plain C for the **G6/G7 half**, and the program that reaches it is a
CONFIRMED MISCOMPILE on FIX-2 that round 2's own argument says cannot exist.

```c
/* p/y1_preadd_chained_prerecord.c — plain C, clang -O1, single TU */
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int q2=cq_theta(q,0.3);            /* SAME wire, a SECOND SSA name for it */
  int a = q2 + 7;                    /* P = %q2, which really does have ONE use */
  for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  return cq_measure(q)+cq_measure(r)+cq_measure(a); }   /* a LATER read of the PRE-op name */
```

MEASURED (`./run.sh p/y1_preadd_chained_prerecord.c <bin>`):

| binary | emitted | measures | disposition |
|---|---|---|---|
| 542d588 | `cq_template_add_i32_hl(h0, 7) -> h2` (OUT of place) | `h0`, `h1`, **`h2`** | 33 lines, correct |
| FIX-1 | identical, 33 lines | `h0`, `h1`, **`h2`** | correct |
| **FIX-2 (638334c)** | **`cqrt_addc_i32(h0, 7)`** (IN place) | `h0`, `h1`, **`h0`** | **39 lines, WRONG — `q` and `a` collapse onto ONE register**, `opt` exit 0, STRICT 2b `0 violation(s)` |
| MINE | — | — | **DECLINE `cq loop lowering: pre-loop in-place op no longer provable at lowering`** |

ROOT CAUSE, and it is the 8h7d.5 lesson a FIFTH time. `commitOutOfLoopInPlaceOps`' stability
conjunct is `P->hasOneUse()`, and its written argument is *"no later stage invents a read of a
value that has none"*. That is true of the **SSA VALUE** and FALSE of the **WIRE**:
`lowerRotations` RAUWs EVERY member of a theta chain onto the ONE `cqrt_alloc` handle, so at
`lowerOps` the parent `P` is `%h`, whose user set is the UNION of `%q`'s and `%q2`'s. `hasOneUse`
was asked of `%q2`; the read that made the in-place choice wrong is a use of `%q`. M-C's own
G6/G7 refuse it correctly at `lowerOps` — which is exactly why 542d588 is right — and round 2's
commit pre-empted that refusal from a program point where the read was invisible.

A SILENT FALLBACK TO OUT-OF-PLACE WOULD NOT BE SOUND HERE: the commit is what licensed
`markIfRailLocal` to mark the loop body, and that permission (in `taint.IterationLocalBlocks`)
already stands — the body would be marked on the premise that it reads the ROOT rail while it
would in fact read a fresh `cq_template_add_i32_hl` template rail (the Q-R1-1 class). Lowering
nothing and exiting non-zero is the only disposition that keeps the two consistent, which is
the (1b) design the brief specified.

COST, stated plainly: this is a NEW LOUD DECLINE for a program 542d588 accepted-and-leaked. It
is the Prime-Directive direction and it is this round's only disposition change outside the
F-C1B-1 population.
- step 5b (F-C1C-1's BOUNDING PROBES, `p/y2`,`p/y3`):
  * `y2_preadd_chained_nopreread.c` — y1 with the pre-op name NOT read afterwards: ACCEPT,
    3 mints / 3 `_unc`, 38 lines on FIX-2 **and on mine, BYTE-IDENTICAL** (`cmp -s`). The
    tripwire does NOT over-fire; the F-C1-1 capability is intact through a CHAINED root.
  * `y3_preadd_chained_prerecord_unrolled.c` — the HAND-UNROLLED twin of y1: on ALL FOUR
    binaries (542d588 / FIX-1 / FIX-2 / mine) it emits `cq_template_add_i32_hl(h0, 7) -> h2`
    and measures `h0`,`h1`,**`h2`** — 39 lines, 3/3. So on FIX-2 the ROLLED and UNROLLED
    spellings of ONE source compute DIFFERENT VALUES, with the unrolled one matching 542d588.
    That is the epic's own byte-identity twin witness, and it grades F-C1C-1 CONFIRMED.
- step 6 (POPULATION, FIX-2 vs MINE — the WHOLE `p/` corpus, 262 programs = round 1 §3.5 +
  review_c1's 60 + fix_c1b's + review_c1b's 51 + my 3 `y*`; `allsweep.sh` then `popdiff.sh`,
  which compares the STATUS (binary token deleted) AND byte-compares the trace):
  **UNCHANGED = 256, MOVED = 6**, and the six are EXACTLY the allowed set:
  | program | FIX-2 | MINE |
  |---|---|---|
  | z23 / z26 / z27 / z29 | 51 lines, rail in the immediate slot | **47 lines, byte-identical to FIX-1/542d588** |
  | z21_preadd_volatile_imm | 3 mints / 3 `_unc`, 38 lines | **3/0, 32 lines, BYTE-IDENTICAL to 542d588 AND FIX-1** (the disclosed (1a) cost) |
  | y1_preadd_chained_prerecord | 39 lines, WRONG (F-C1C-1) | **LOUD DECLINE** |
  No other status, decline string or trace moved. (`out/*.status`, `moved.txt`.)
- step 6b (the F-C1B-2 CUSTOMER PINS — must not be lost to the per-loop key; rolled
  `and|lshr _hl` mints/`_unc` and rolled-vs-unrolled byte identity, FIX-2 vs MINE):
  r33 3/3 IDENT | 3/3 IDENT · r35 3/3 IDENT | 3/3 IDENT · r40 3/3 (twin declines on every
  binary, OQ-C1-3) | same · z9 3/3 IDENT | same · z10 3/3 IDENT | same · r2 3/3 IDENT | same ·
  x1 3/3 IDENT | same · d1 3/3 IDENT | same · r71 3/3, twin DIVERGE(54) on both (the
  disclosed unfaithful twin). **Zero customers lost.**

## ⭐ F-C1B-2 HAS AN OBSERVABLE PLAIN-C PIN AFTER ALL — `p/w3_claim_across_loops_measured_gate.c`

The lens graded F-C1B-2 LATENT because all four spellings it built decline at a later fence.
A fifth does not:

```c
int ext_f(int a);                                   /* second TU: return a + 100; */
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  for(int i=0;i<3;i++){ r=cq_theta(r,0.1); }        /* LOOP A — claims r (tryCaseA)       */
  int y=5; if (q>5) y=ext_f(7);                     /* 6.5 arm -> %out, tainted at ROUND 2 */
  int acc=0;
  for(int i=0;i<3;i++){ if((y>>i)&1) cq_phi(0.25);  /* LOOP B — an ONWARD per-bit region   */
                        int s=cq_theta(r,0.2); acc+=cq_measure(s); }   /* an in-place gate on r */
  return cq_measure(y)+acc; }
```

MEASURED (rolled `and|lshr _hl` mints / `_hl_unc`):

| binary | w3 |
|---|---|
| 542d588 | 3 / **0**, 45 lines |
| FIX-1 | 3 / **0**, 45 lines, BYTE-IDENTICAL to 542d588 |
| **FIX-2** | **3 / 3, 51 lines** — loop B MARKED on loop A's claim |
| MINE | 3 / **0**, 45 lines, **BYTE-IDENTICAL to 542d588 AND FIX-1** |

So the per-loop key is not a new over-decline: it REVERTS a widening round 2 introduced by
accident. The hand-unrolled twin declines on all four binaries
(`cq loop lowering: loop-carried rail has multiple in-place consumers`, the Rule-8 fan-out
guard), so there is no twin witness either way — which is why the lens's LATENT grade was
right about the UNITARY and wrong about the OBSERVABILITY.
CONTROL `p/w4_claim_across_loops_two_invariants.c` (the same module with loop B's in-body gate
on `r` REMOVED): 3/3, 46 lines, BYTE-IDENTICAL on all four binaries — the key refuses nothing
that was legitimately claimed.

### the instrumented ground truth (my own `git archive HEAD` copy under `$W/dbgtree`, built once)
```
z32  MINE  claimedTOTAL=1 claimedHERE=0 -> IRR FALSE   -> no marking
w3   MINE  claimedTOTAL=1 claimedHERE=0 -> IRR FALSE   -> no marking
z32  FIX-2 claimed=1                    -> IRR TRUE    -> markIfRailLocal MARKED 1 blocks
w3   FIX-2 claimed=1                    -> IRR TRUE    -> markIfRailLocal MARKED 1 blocks
```
### the HEADER-STABILITY question the brief asks, ANSWERED BY MEASUREMENT (not argued)
```
r33  MINE  claimedHERE=1  (claim written by tryCaseA at ROUND 1, read at ROUND 2 —
                           i.e. ACROSS the whole round-2 control fixpoint and flatten)
r40  MINE  claimedHERE=1 at BOTH offers (writer = collapseRailPhisIn step (4))
```
The loop-header pointer survives the round-2 flatten for BOTH writers, and every shipped
customer (r33/r35/r40/z9/z10/r2/x1/d1) keeps its 3/3. And the failure mode if it ever did not
is bounded in the SAFE direction: a claim that fails to match makes clause (0) JUDGE the
candidate, clause (iii) refuse it, and the module keep today's leak — never an over-accept.
- step 7 (FIXTURES, 7 new files, corpus 1666 -> 1673 — `ls ir-pass/test/*.ll | wc -l`):
  | file | kind | 542d588 | FIX-1 | FIX-2 | MINE |
  |---|---|---|---|---|---|
  | `control_phase_kickback_mixed_preheader_r2derived_imm_outofplace.ll` | ACCEPT (z23) | all 0 | all 0 | **CHECK=1 PCNT=1 UCNT=1 NOROUTE=1** | all 0 |
  | `control_phase_kickback_mixed_preheader_r2derived_commuted_outofplace.ll` | ACCEPT (z26) | all 0 | all 0 | **CHECK=1 PCNT=1 NOROUTE=1** | all 0 |
  | `control_phase_kickback_mixed_preheader_volatile_imm_leak_control.ll` | ACCEPT-AND-LEAKS (z21) | all 0 | all 0 | **CHECK=1 PCNT=1 UCNT=1** | all 0 |
  | `control_phase_kickback_reject_preloop_commit_stale.ll` | **DECLINE** (y1) | optrc=0 **RED** | optrc=0 **RED** | optrc=0 **RED** | optrc=1 CHECK=0 **GREEN** |
  | `control_phase_kickback_mixed_preheader_chained_root_inloop.ll` | ACCEPT control (y2) | **CHECK=1 FCNT=1 UCNT=1** | same **RED** | all 0 | all 0 |
  | `control_phase_kickback_mixed_claim_across_loops_leak_control.ll` | ACCEPT-AND-LEAKS (w3) | all 0 | all 0 | **CHECK=1 UCNT=1** | all 0 |
  | `control_phase_kickback_mixed_claim_across_loops_accept_control.ll` | ACCEPT control (w4) | all 0 | all 0 | all 0 | all 0 |
  Read the shape of that table: this round's four NARROWING fixtures are RED **on FIX-2 ONLY**
  (they assert 542d588's and FIX-1's stream), the DECLINE fixture is RED on all three earlier
  binaries, and the two CONTROLS are the discriminators — `..._chained_root_inloop` is RED on
  the two PRE-round-2 binaries, so it pins the round-2 CAPABILITY that (1b) must not blanket
  away, and `..._claim_across_loops_accept_control` is green everywhere, so the per-loop key
  cannot be a blanket refusal. Measured per prefix with `rg.sh` (FileCheck rc per prefix).
- step 8 (INJECTION MATRIX over the 6 new accepts, `fix_c1_work/inj.py`, 6 × 16 mutations = 96
  cells): FIRST RUN **6 MISSED** rows (`extra_free`/`extra_x`/`e_drop_free`/`h_unpaired_x`/
  `c_rz_after_free`, and on the commuted fixture the whole `rz_*` family). Added the missing
  `FCNT`/`XCNT`/`ACNT`/`MDCNT`/`UCNT` prefixes and the two `cqrt_rz_<W>` NOROUTE negatives;
  RE-RUN **0 MISSED / 0 DIRTY**, `clean` PASS on all six (`inj_c1c3.tsv`). Red-green re-verified
  after the hardening — unchanged (table in step 7).
- step 9 (`ctest -R ir-pass-lit` on my build) → **Passed, 32.98 s, 0 failed**
  (`fix_c1c_lit_A.log`). ⚠ that run predates the step-8 hardening; re-run at the end.
- step 10 (MUTATION VALIDATION, one half at a time, on my OWN `git archive HEAD` DBG copy;
  4 build+check cycles, `mutate.py`/`mutrun.sh`, log `fix_c1c_mutate.log`):
  | mutant | what goes RED | result |
  |---|---|---|
  | RESTORE | — | all 7 fixtures GREEN on every prefix |
  | **M1** drop `isa<Constant>(Imm)` (1a) | the two r2derived accepts **and** the volatile leak control | **RED** — and the two r2derived files fail with `OPT_RC=1 :: cq loop lowering: pre-loop in-place op no longer provable at lowering`, i.e. **(1b) CATCHES (1a)'s DEFECT AS A LOUD DECLINE**. The two nets are independent, and with only one of them the CONFIRMED MISCOMPILE becomes a refusal rather than a wrong circuit |
  | **M2** never re-ask at `lowerOps` (1b) | `..._reject_preloop_commit_stale.ll` | **RED** (optrc=0, CHECK=1) and NOTHING else moves |
  | **M3** revert the per-loop `ClaimedRailRoots` key | `..._claim_across_loops_leak_control.ll` | **RED** (CHECK/FCNT/UCNT) and NOTHING else moves |
  | RESTORE | — | all 7 GREEN again |
  All three halves are load-bearing; none is decoration.
- step 11 (E2E, `ctest -j6 -R 'twin-identical|quarantine-selftest|free-pairing-selftest|perbit|onward-perbit|e2e-slice-control-phase|e2e-slice-loop'`)
  → **49/49 passed, 11.06 s**, including every pre-existing `*-twin-identical` gate,
  `e2e-loop-twin-quarantine-selftest`, `e2e-free-pairing-selftest`,
  `e2e-phase-perbit-loop-mixed-preadd-twin-identical` and
  `e2e-phase-onward-perbit-loop-mixed-twin-identical`. No golden regenerated.
- step 12 (STRICT stage 2b on my binary, every accepting lowered output of the population):
  **193 outputs — 191 `0 violation(s), 0 unproven`, 2 `0 violation(s), 4 unproven`, 0
  violations.** The two are `f0_break_plain` / `f3_break_global_phase_before`, the dtzb
  whole-loop reverse-play family that ships with `--allow-unproven`, and their checker output
  is BYTE-IDENTICAL on FIX-2. The six new fixtures' lowered modules are each
  `0 violation(s), 0 unproven`.
- step 13 (TWIN MATRIX, background): `ctest -j6 -R 'e2e-loop-twin-matrix|e2e-loop-twin-quarantine-selftest'`
  → **2/2 passed**, matrix **181.66 s**. NO cell moved (the gate compares against the committed
  `expected.txt` + quarantine); 257 expected rows + 29 quarantined = 286 cells, both files
  untouched by this round.
- step 14 (DOCS): notes **§3.11** (F-C1B-1 with its four-program table and the commuted
  wrong-rail spelling; F-C1C-1 with its twin witness; F-C1B-2 with the w3/w4 pin and the
  measured header stability; the **full 8h7d.5 input-stability table** for every input of
  `classifyInPlaceReassignment` the commit evaluates; the mutation table; the fixture list;
  F-C1B-5's three corrections; OQ-C1-7/8/9) · **§2's ⭐ table gains the
  `commitOutOfLoopInPlaceOps` ROW** and its closing paragraph goes "two defects" → **four** ·
  **PRD §0 E2** (the round-3 pair, and the TWO new residuals: the volatile-immediate leak and
  the chained-wire decline) · **CLAUDE.md**'s C-1 bullet ("FIVE INSTANCES ACROSS FOUR ROUNDS"
  → **"SEVEN ACROSS FIVE"**, with both new findings spelled out) and its lit count line
  (1666 → **1673**, with the seven files and their red-green shape) · **ROADMAP**'s C-1 block
  and matrix paragraph. F-C1B-5's slips 1 and 2 corrected in place with the reason; slip 3
  (the round-2 hand-back's "16 new / 4 cells") corrected in notes §3.11 rather than by editing
  another agent's session file.
- step 15 (FINAL GATES on my build): `ctest -R ir-pass-lit` → **Passed, 32.43 s, 0 failed**;
  `lit -q ir-pass/test` → **1673 discovered**; `ctest -j6 -R 'twin-identical|quarantine-selftest|free-pairing-selftest|perbit|onward-perbit'`
  → **31/31 passed, 4.76 s**. COUNTS by command: `ls ir-pass/test/*.ll | wc -l` **1673** ·
  `ctest -N` **348** total / **338** `^e2e-` / **308** `^e2e-slice-` (UNCHANGED — this round
  adds no e2e entry) · `grep -c '^m_' tools/loop_twin_matrix.expected.txt` **257** ·
  `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt` **29**.
- step 16: two `bd remember` entries (`commit-time-prediction-must-be-reverified`,
  `claimed-rail-roots-are-per-loop`). No bd issue closed or edited.
- step 17: committed the twelve plain-C reproducers + `tu_extf.c` + a four-binary disposition
  README under `docs/prd/phase-04-swap-route-control/inc1-records/c1-round3/`, following the
  `clearance_c1/` precedent, so a re-clearance can re-derive every number without the
  scratchpad. Commit `dec2019`.

---

## HAND-BACK

**The four F-C1B-1 reproducers on my binary emit `cq_template_add_i32(h7, h6) -> h8`
(`cq_template_xor_i32` for `z27`) — the correct out-of-place Q+Q op, with the `y*3` rail
`_unc`'d and freed — 47 trace lines each, BYTE-IDENTICAL to FIX-1's and to 542d588's; the
round-2 binary emitted `cqrt_addc_i32(h7, 6)` / `cqrt_xorc_i32(h7, 6)` / `cqrt_addc_i32(h6, 7)`
at 51 lines. `z32` is now UNMARKED: `claimedTOTAL=1 claimedHERE=0 → IRR FALSE → nothing
marked`, where the round-2 binary printed `claimed=1 → IRR TRUE → markIfRailLocal MARKED 1
blocks`.**

### 1 — what shipped (branch `3qlq-inc1-fix-c1`, 5 commits on top of 638334c)

| commit | contents |
|---|---|
| `6a3e5d9` | the three fixes — (1a), (1b), the per-loop `ClaimedRailRoots` key |
| `eaac8ce` | 7 red-green fixtures |
| `da11a06` | injection-matrix hardening (0 MISSED / 0 DIRTY) |
| `402b086` | notes §3.11 + the §2 ⭐ row, PRD §0 E2, CLAUDE.md, ROADMAP, the F-C1B-5 slips |
| `dec2019` | the 12 committed reproducers + their four-binary README |

CODE — `LoopLowering.cpp`, `OpcodeLowering.cpp`, `ArithLowering.cpp`, `ArithLowering.h`,
`TaintPropagation.h`. NO new `cqrt_*`/`cq_template_*` symbol, no `runtime/` or
`opcode_table.yaml` change, no change to `markIfRailLocal`, `Uncomputation`, `FreePoint`,
`ChainWalk` or `EmitInverse`.
* **F-C1B-1 (1a)** — `commitOutOfLoopInPlaceOps` requires `isa<Constant>(Imm)`. Monotone: a
  `Constant` is in none of the 35 measured `taint.Tainted.insert(` sites, so its G2 answer
  cannot move between `:393` and `:536`.
* **F-C1B-1 (1b)** — new `taint.PreLoopCommittedInPlaceOps` (the subset this path PREDICTED,
  written and rolled back in lockstep); `lowerOps` Phase 1 re-asks the ONE fence under the
  final `DominatorTree`/`LoopInfo` and final taint and declines
  `cq loop lowering: pre-loop in-place op no longer provable at lowering`. Exactly one clause
  suppressed, through a defaulted `IgnoreSelfMarking` threaded
  `classifyInPlaceReassignment` → `inPlaceFenceHolds` (one fence body, Rule 14).
* **F-C1B-2** — `taint.ClaimedRailRoots` becomes
  `DenseSet<pair<const Value *, const BasicBlock *>>`, keyed on the CLAIMING loop's header.

LIT (7 new, corpus 1666 → **1673**): 2 narrowing ACCEPTS
(`control_phase_kickback_mixed_preheader_r2derived_{imm,commuted}_outofplace.ll`), 2
ACCEPT-AND-LEAKS controls (`..._preheader_volatile_imm_leak_control.ll`,
`..._claim_across_loops_leak_control.ll`), 1 DECLINE
(`control_phase_kickback_reject_preloop_commit_stale.ll`) and 2 DISCRIMINATORS
(`..._preheader_chained_root_inloop.ll`, `..._claim_across_loops_accept_control.ll`).

E2E: **nothing added and nothing regenerated** — `ctest -N` stays 348 / 338 / 308. The twin
matrix is untouched (257 + 29 = 286) and green.

### 2 — what I ran

| gate | result |
|---|---|
| the four F-C1B-1 reproducers, 3 binaries | WRONG on FIX-2 (51 lines, rail in the immediate slot), correct on 542d588 / FIX-1 / mine, mine BYTE-IDENTICAL to FIX-1 |
| POPULATION, FIX-2 vs mine, 262 programs, status + byte-diff | **256 UNCHANGED, 6 MOVED** — the four reproducers, `z21` (the disclosed (1a) cost, back to 542d588's trace) and `y1` (the new loud decline). Nothing else |
| the F-C1B-2 customer pins (r33/r35/r40/z9/z10/r2/x1/d1) | all still 3/3, unchanged from FIX-2 |
| red-green per fixture, 4 binaries, by hand (`rg.sh`, rc per prefix) | 4 narrowing fixtures RED **on FIX-2 only**; the DECLINE RED on 542d588 + FIX-1 + FIX-2; `..._chained_root_inloop` RED on the two PRE-round-2 binaries; `..._claim_across_loops_accept_control` green everywhere |
| injection matrix, 6 accepts × 16 mutations | first run **6 MISSED**, after hardening **0 MISSED / 0 DIRTY**, `clean` PASS on all six |
| mutation validation, one half at a time (4 build+check cycles) | **M1/M2/M3 all RED** on exactly their own fixture, RESTORE green. M1 additionally shows (1b) catching (1a)'s defect as a LOUD DECLINE |
| instrumented ground truth (my own `git archive HEAD` DBG copy) | `z32`/`w3` `claimedHERE=0` → nothing marked (FIX-2: `claimed=1` → MARKED); `r33`/`r40` `claimedHERE=1` — the header pointer survives the round-2 flatten for BOTH writers |
| `ctest -R ir-pass-lit` | **Passed, 32.43 s, 0 failed**; `lit -q` **1673 discovered** |
| `ctest -j6 -R 'twin-identical\|quarantine-selftest\|free-pairing-selftest\|perbit\|onward-perbit'` | **31/31 passed, 4.76 s** |
| `ctest -j6 -R 'e2e-loop-twin-matrix\|...quarantine-selftest'` | **2/2 passed**, matrix 181.66 s, **no cell moved** |
| STRICT stage 2b, every accepting lowered output | **193 outputs: 191 `0 violation(s), 0 unproven`, 2 `0 violation(s), 4 unproven`** (the `--allow-unproven` break family, byte-identical checker output on FIX-2), **0 violations** |
| **NOT run** | the full `ctest` (the orchestrator's gate); `cq-opt-equivalence-full`; the `--phi-surface register` matrix |

### 3 — findings that are NOT mine to decide

**⭐ F-C1C-1 is a NEW CONFIRMED SILENT MISCOMPILE I found in the round-2 fix while building the
tripwire's customer.** It is fixed here (by the tripwire), but the owner should see it: the
round-2 `hasOneUse` conjunct is true of the SSA VALUE and false of the WIRE, and the program
`int q2=cq_theta(q,.3); int a=q2+7; for(…){ if((a>>i)&1) cq_phi(.2); r=cq_theta(r,.1); }
return cq_measure(q)+cq_measure(r)+cq_measure(a);` measured `h0`,`h1`,**`h0`** on FIX-2 where
542d588, FIX-1 and the hand-unrolled twin all give `h0`,`h1`,**`h2`**. Reproducer committed at
`docs/prd/.../inc1-records/c1-round3/y1_preadd_chained_prerecord.c`.

## OWNER QUESTION — OQ-C1-7 (notes §3.11)
The (1b) tripwire buys soundness with an over-decline: F-C1C-1's own program declined nowhere
before this round and declines now (`cq loop lowering: pre-loop in-place op no longer provable
at lowering`), where 542d588 accepted-and-leaked. The alternative is a COMMIT-TIME conjunct
over the whole WIRE's use closure, which restores the accept at the cost of a NEW predicate
that is itself a prediction — in the one function whose predictions have now failed twice.
Ship the decline (as here), or buy the shape back? Reproducer: `y1` above; its one-token
workaround `y2` compiles and discharges every rail.

## OWNER QUESTION — OQ-C1-8 (notes §3.11)
The `isa<Constant>(Imm)` fence costs `p/z21_preadd_volatile_imm.c` (a `volatile`-load
immediate), a NEW accept round 2 had introduced; it returns to the pre-round-2 leak,
byte-identical to 542d588. M-C itself still lowers that op in place at `lowerOps` — only the
PREDICTION of the answer is refused. Widening (1a) to "a `Constant` OR anything G4 already
proves stage-2b-classical" needs an argument that the widened class cannot gain taint at
round 2. Do we want it?

## OWNER QUESTION — OQ-C1-9 (notes §3.11)
Both findings of this round are the same shape: an emitter's decision PREDICTED by an earlier
stage. The structural alternative is to move the in-place question wholly to `lowerOps` and
have `lowerLoops` ask only a conservative "would M-C possibly fire?" that can only
over-decline. That is a re-plumbing of the Rule-13 core, not a review round's call.

*(Inherited and still open, unchanged by this round: OQ-C1-3/bd `3qlq.9` — the `r40` shape's
flat twin declines on every binary; OQ-C1-4/5/6 from round 2; Q-R1-1 — a hoisted
loop-invariant TEMPLATE rail read by the body's condition still leaks, and this round's own
`..._r2derived_imm_outofplace.ll` now pins that residual with an explicit `UCNT` block.)*

### 4 — what is left

* Nothing in F-C1B-1 / F-C1B-2 / F-C1B-5 / F-C1C-1 scope. F-C1B-3 and F-C1B-4 were CLEAR in
  the lens report and needed no action.
* The orchestrator still owes: the full `ctest -j6` and the re-clearance. **The re-clearance
  should budget a FOURTH round on `commitOutOfLoopInPlaceOps`** — the count on that one
  function is now 7 findings over 5 adversarial rounds, and two of the seven were introduced
  by a fix.
* Branch committed, NOT pushed. No bd issue closed or edited; two `bd remember` entries added
  (`commit-time-prediction-must-be-reverified`, `claimed-rail-roots-are-per-loop`).
