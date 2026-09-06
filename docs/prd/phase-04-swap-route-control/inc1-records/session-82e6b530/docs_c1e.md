# docs_c1e — fold review_c1e's items F-C1E-1..4 into branch `c1-round4` @ aa9d702 (session 82e6b530, 2026-09-06)

Agent: docs_c1e. Worktree `$SP1/wt/c1d` (branch `c1-round4`). NO code change licensed:
comments, docs, ONE additive lit fixture, record copies.

## Step 0 — orientation (2026-09-06)
Read BRIEF_common, BRIEF_docs_c1e, BRIEF_rebase_c1d, `$SP/progress/rebase_c1d.md`,
`$SP/progress/review_c1e.md` (verdict CLEAR-WITH-ITEMS, items F-C1E-1..4), CLAUDE.md (in context).
MEASURED state of the worktree before any edit:
* `git rev-parse HEAD` = **aa9d7028e5f2b688698d800ff560efab0144b165** (aa9d702)
* `git status --porcelain` EMPTY
* `git log --oneline main..HEAD | wc -l` = 17
* `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` = **EMPTY** (build current)
Next: step 1 = F-C1E-1 (the two comment corrections + the new discriminating lit fixture).

## Step 1a — F-C1E-1 item 2: the DISCRIMINATING lit fixture — DONE
New file `ir-pass/test/control_phase_kickback_mixed_value_merge_dtzb_head_preadd_inloop.ll` (218 lines),
derived from `clang -O1` on the lens's attack program `a22`
(`$SP/progress/review_c1e_work/a/a22_dtzb_head_out_preadd_rolled.c`), `@main` dropped, every assertion
read off the SUBJECT binary's own output (`$W/out/a22.subj.ll`).
⚠ MEASURED, and worth recording: `clang -O1` **FOLDS a22's diamond into a `select`**
(`%6 = select i1 %3, i32 %5, i32 %2`), so the merge is the 4.4 `SelectMergeEmit` — the same
controlled-copy merge Inc 2's `emitValueRegion` delegates to (Rule 14). The emitted shape is the
sibling's; the head is the dtzb-shaped `%h_op = cq_template_add_i32_hl(%h2, 3)`, OUT of place.
Twelve prefixes, ONE `%cq-opt` spawn:
CHECK / UCNT / **HCNT** / **CSRC** / PCNT / **QCNT** / ACNT / FCNT / XCNT / RYCNT / MDCNT / NOROUTE.
`CSRC` (the two controlled copies read DISTINCT rails under ONE flag into ONE out-rail) and `QCNT`
(the in-place `xor` budget, its own prefix because a positive COUNT after a NOT WINDOWS that NOT and
the `xorc` precedes the `addc` here) are new to the family; `HCNT` is the head-out-of-place pin.

**RED-GREEN, MEASURED** (`$W/rg.sh <fixture> <main|subj>`, prefix by prefix):
| binary | verdict |
|---|---|
| `main` **258d974** (`$SP/bin/main-258d974/`) | `OPT_RC=0`, **CHECK=1 FCNT=1 UCNT=1** (ACNT/CSRC/HCNT/MDCNT/NOROUTE/PCNT/QCNT/RYCNT/XCNT = 0) — **RED** |
| SUBJECT aa9d702 | all **12 prefixes 0** — **GREEN** |
The single IR difference between the two outputs on this module (`diff` of the `@slice` bodies) is
exactly two lines the subject GAINS: `cq_template_and_i32_hl_unc(%h_op3, %out, %4)` and
`cqrt_free(%h_op3)` — the per-activation which-path discharge. Counts, both binaries:
`and_i32_hl_unc` **1** (main **0**) · `cqrt_free` **3** (main **2**) · `cqrt_addc_i32` 1 ·
`cqrt_xorc_i32` 1 · `cqrt_rz_i1` 1 · `cqrt_x(i32` 4 · `cqrt_ry_` 2 · `!cq.branchphase` 1 ·
`cq_template_add_i32_hl` 1 · `cq_template_mul_i32_hl` 0 · `cqrt_cswap` 0 · `copy_i32_controlled` 2.

`cd build && lit ir-pass/test --filter 'control_phase_kickback_mixed_value_merge'` → **2/2 PASS**,
0.67 s, of **1691** discovered.

INJECTION MATRIX over the new fixture (`$W/inj.py`, the rebase agent's tool unmodified, 17 columns):
**`clean` PASS, 0 MISSED, 0 DIRTY** — every mutation caught by a named prefix
(`extra_ry`→RYCNT, `extra_free`→FCNT, `extra_x`→XCNT, `e_drop_free`→CHECK,FCNT,
`g_drop_mark`→CHECK,MDCNT, `h_unpaired_x`→CHECK,XCNT, the six route mutations→NOROUTE,
`c_rz_after_free`→ACNT,MDCNT, `f_negated`→CHECK,ACNT,MDCNT, `knownbad`→CHECK,ACNT,MDCNT).
Full 45-accept matrix launched in the background (`$SP/progress/docs_c1e_inj_full.tsv`).
Next: step 1b = the two in-source comment corrections (F-C1E-1 item 1).

## Step 1b — F-C1E-1 item 1: the two in-source citations CORRECTED (COMMENTS ONLY) — commit `5f3bb01`
* `ir-pass/src/LoopLowering.cpp`, the "MEASURED rather than argued" paragraph at
  `commitOutOfLoopInPlaceOps`: now a three-bullet list saying WHICH fixture measures WHAT —
  (i) the G6/G7 NET is pinned by `control_swap_value_ifelse_head_out_of_place.ll` (RED on the lens's
  G6/G7-disabled mutant, its two copies collapsing onto one register); (ii) the q4b fixture's `HCNT`
  pins the head-out-of-place PROPERTY and NOT the net, because `-O1` reassociates `(p+3)*5` and G2's
  SHAPE half refuses a `mul` whatever the pair answers — it and its e2e pair are GREEN on that mutant;
  (iii) the NEW `..._dtzb_head_preadd_inloop.ll` is the one that discriminates on the commit path.
* `ir-pass/src/ArithLowering.cpp`, the CONSUMER-2 comment's ⚠ paragraph: same correction, stated as
  "cite the right fixture for the right claim", naming the lens finding.
MEASURED comments-only: `git diff -- ir-pass/src | grep -E '^\+[^+]' | grep -vE '^\+\s*//'` EMPTY and
the same for removed lines (`^-[^-]` filtered) EMPTY. `--stat`: ArithLowering +20/-4, LoopLowering +42/-8.

## Step 1c — the FULL injection matrix (45 accepts × 17 mutations) — 0 MISSED / 0 DIRTY
`grep -L 'RUN: not' ir-pass/test/control_phase_kickback_*.ll` = **45** files (44 + the new one).
`python3 $W/inj.py accepts.txt` → `$SP/progress/docs_c1e_inj_full.tsv`:
**0 MISSED · 0 DIRTY · `clean` PASS on all 45**; `extra_ry` caught by **RYCNT on 27** and **CHECK on 18**
(the rebase agent measured 26/18 over 44 — the +1 is the new fixture's own RYCNT).

## Step 2 — F-C1E-2: the six leak spellings, RE-MEASURED by me (not transcribed)
Harness `$W/run.sh <file.c> <main|subj>` (the lens's, re-pointed at my work dir): stage 1 → 2 → 2b
STRICT → 3 → 4. Counting `cq_template_{and,lshr}_i32_hl` mints / `_hl_unc` discharges in the TRACE.
| program | shape | `main` 258d974 rolled | subject rolled | unrolled twin | rolled trace main vs subj |
|---|---|---|---|---|---|
| `a1` | dtzb head `p+3` read by the loop | 4/0, 44 | 4/0, 44 | 4/4, 52 | **byte-IDENTICAL** |
| `a2` | preadd on the value arm's SOURCE `p` | 4/0, 45 | 4/0, 45 | 4/4, 53 | **byte-IDENTICAL** |
| `a3` | preadd on the arm's CHAIN-FINAL | 4/0, 45 | 4/0, 45 | 4/4, 53 | **byte-IDENTICAL** |
| `a9` | pre-op value measured later (the `x2_preadd_keep` control — a CORRECT G6 refusal) | 4/0, 45 | 4/0, 45 | 4/4, 53 | **byte-IDENTICAL** |
| `a11` | 4.4 select, dtzb head read by the loop | 4/0, 44 | 4/0, 44 | 4/4, 52 | **byte-IDENTICAL** |
| `a4` | merge `%out` feeding TWO loops (`+7` then `+5`) | 8/0, 73 | 8/0, 73 | 8/8, 91 | **byte-IDENTICAL** |
| `a17` | the same with `^5` between the loops | 8/0, 73 | **8/4, 81** | **DECLINES** `cq controlled lowering: condition predates a non-diagonal gate under quantum control` on BOTH binaries | main != subj (round 4 STRICTLY IMPROVES it: the first loop now discharges) |
| `a16` | `a2` + a post-loop diffusion `t = cq_theta(t,.11)` | **DECLINES** `cq controlled lowering: control flow under quantum control` | same decline | same decline | — |
⚠ **ONE REFINEMENT TO THE LENS'S OWN SENTENCE.** F-C1E-2 groups "`a4`/`a17` (merge `%out` feeding TWO
loops — 8/0 on main, 8/4 on the subject: loop 1 now discharges)". MEASURED separately: that is **a17
only**. `a4` is 8/0 on BOTH binaries with byte-identical rolled traces; the two differ by ONE token
(`p = p + 5` vs `p = p ^ 5`), and `a17`'s unrolled twin DECLINES on both binaries so it has no
byte-identity witness at all. Recorded as measured rather than as quoted.
STRICT stage 2b is `0` (clean) on every accepting run above — the class is structurally invisible to it.
Next: the record edits (reproducer copies + notes §3.15 + PRD E2).

## Step 3 — the record edits — commits `3521223`, `43a3a90`, `65acb8e`
* **F-C1E-2 reproducers**: 16 files (8 rolled/unrolled pairs) copied verbatim from the lens's battery
  into `docs/prd/phase-04-swap-route-control/inc1-records/c1-round4/` as
  `c1e_a{1,2,3,4,9,11,16,17}_*.c`, with a new README section carrying the RE-MEASURED table, the
  mechanism (G7 arm (e) / G6), the "why it is a leak and not a wrong unitary" (`a16` declines
  loudly; STRICT 2b is structurally blind), the a4/a17 refinement and the F-C1E-3 unfaithful-twin
  paragraph. (`ls …/c1-round4/c1e_*.c | wc -l` = **16**.)
* **notes §3.15** gains `#### The independent lens ON THE REBASED TREE (review_c1e …)` — the
  disposition table for F-C1E-1..4, the "which fixture measures WHAT" subsection, the re-measured
  leak table, the unfaithful-twin sentence and the grep correction.
* **PRD §0 E2** residual list gains the class as its own ⚠ paragraph after (i)/(ii) — deliberately
  NOT folded into "the other two are UNCHANGED", which would have made that sentence false.
* **F-C1E-4**: the sentence corrected in `inc1-records/session-82e6b530/rebase_c1d.md`.
  RE-MEASURED by me: `grep -rn 'session-adc5590a/fix_c1d.md' --include='*.md' .` → **7 hits** (the
  lens measured 5; my own §3.15 paragraph added 2), **all prose**, and
  `ls …/session-adc5590a/fix_c1d.md` → `No such file or directory`. The claim the grep was reaching
  for is true and is now stated directly instead of by a self-invalidating command.
Next: step 4 = the record copies + README/NEXT_SESSION_PROMPT/session-adc5590a README updates.

## Step 4 — the session record + the two status files — commits `c9f1fe9`, `dfe44ca`
* Copied into `docs/prd/phase-04-swap-route-control/inc1-records/session-82e6b530/`:
  `review_c1e.md`, `investigate_eqpx.md`, and `briefs/BRIEF_{review_c1e,investigate_eqpx,docs_c1e}.md`.
  Its `README.md` now names FOUR agents and carries a line per file, including a paragraph saying
  what `investigate_eqpx.md` is and that **nothing in it is applied on this branch** (it is the
  PRE-EXISTING bd `test_C_libtooling-eqpx`, reproducing on the pre-3qlq ORACLE).
* `session-adc5590a/README.md`'s round-4 section and `NEXT_SESSION_PROMPT.md`'s state block each gain
  the second lens: **CLEAR-WITH-ITEMS on the REBASED tree (aa9d702), items F-C1E-1..4 all APPLIED**,
  and the **full `ctest` 367/367** (0 failed, 385.89 s — READ from `$SP/progress/orch_full_ctest_c1e.log`,
  the ORCHESTRATOR's run; I did not run the full suite).

## Step 5 — rebuild + gates + counts — commit `370517f`
Rebuild BOTH targets: `cmake --build build -j8` → `BUILD_RC=0`, `Built target CQPass` **and**
`Built target cq-opt`; `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` → **EMPTY**.
| command (in `$SP1/wt/c1d`) | result |
|---|---|
| `cd build && lit -v ir-pass/test --filter 'control_phase_kickback_mixed_value_merge'` | **2/2 PASS**, 1.55 s, of **1691** discovered |
| `python3 $W/inj.py accepts_new.txt` re-run on the REBUILT binary | `clean` PASS, **0 MISSED / 0 DIRTY**, and `diff` against the pre-rebuild run **IDENTICAL** — the comment edits moved no behaviour |
| `ls ir-pass/test/*.ll \| wc -l` | **1691** (was 1690) |
| `ctest --test-dir build -N \| tail -1` | **367** (UNCHANGED — `ir-pass-lit` is ONE entry and no slice was added) |
| `ctest -N -R '^e2e-'` / `-R '^e2e-slice-'` | **357** / **321** (UNCHANGED) |
| `ls tests/e2e/*.expected.log \| wc -l` | **323** (UNCHANGED) |
Count lines updated BY COMMAND, not by arithmetic: `CLAUDE.md` ×2 (the round-4 rebase paragraph and
the `ir-pass-lit` line) and notes §3.15's "Pinned" bullet. `ROADMAP.md` carries no fixture count that
moved (`grep -n '1690\|1687' ROADMAP.md` → one line, an Inc-1-era Rz census over 1687 outputs, which
is a HISTORICAL measurement and is left alone).
NOT touched, deliberately: the three OTHER live citations of the q4b fixture
(PRD §0 lines ~271 / ~403, `RETIRE_SWAP_ROUTE_INC2_NOTES.md` §5) — each says the fixture PINS the
`q4b` leak row, which is TRUE and is not the claim F-C1E-1 corrected.

## Step 6 — the gates, final
| command | result |
|---|---|
| `ctest --test-dir build -R ir-pass-lit --output-on-failure` | **Passed, 33.45 s, 0 failed** (`$SP/progress/docs_c1e_lit.log`, `CTEST_RC=0`) |
| `cd build && lit -s ir-pass/test` | **1691 discovered · 1690 Passed · 1 Expectedly Failed · 0 unexpected failures**, 34.88 s — the 1 XFAIL is the standing `lowering_invert_add_i32.ll` (Phase-7 tracker) |
| `cd build && lit -v ir-pass/test --filter 'control_phase_kickback_mixed_value_merge'` | **2/2 PASS**, 1.55 s |
NOT run, deliberately (BRIEF_common): the full `ctest` (the orchestrator's gate — its run on
`aa9d702` is `$SP/progress/orch_full_ctest_c1e.log`, 367/367), `e2e-loop-twin-matrix` (no cell can
move: this branch adds one lit fixture and edits comments; the rebase agent's run on the same tree
was Passed / no cell moved), `cq-opt-equivalence-full`, `frontend-lit`, the runtime entries.
⚠ Following the rebase agent's recorded lesson, `lit --filter` was never run concurrently with
`ctest -R ir-pass-lit` in this build tree.

## FOR THE BD UPDATE
> **`3qlq.13` — add to the subject list:** a **preheader in-place op whose PARENT has a second
> *unlowered tainted* user** keeps the O(K) which-path leak, because `classifyInPlaceReassignment`
> correctly refuses M-C there (G7 arm (e), or G6 when the merge's controlled copies are emitted
> after the pre-op) so the C-1 commit never marks it. **SEVEN measured plain-C spellings**
> (`review_c1e` finding **F-C1E-2**, re-measured by `docs_c1e`), **PRE-EXISTING and byte-identical
> to `main` 258d974 on six of them** — `a1` a dtzb head read by the loop 4/0 (44) vs twin 4/4 (52),
> `a2` the preadd on the value arm's SOURCE `p` 4/0 (45), `a3` the preadd on the CHAIN-FINAL,
> `a9` the pre-op value measured later (a CORRECT G6 refusal), `a11` the same over a 4.4 select,
> `a4` a merge `%out` feeding TWO loops 8/0 (73) vs 8/8 (91) — while on the seventh, `a17`, round 4
> STRICTLY IMPROVES it (8/0 → 8/4, the first loop discharges). It is a LEAK and not a wrong unitary:
> the diffusion variant `a16` DECLINES loudly (`cq controlled lowering: control flow under quantum
> control`) on every binary, and STRICT stage 2b reports `0 violation(s), 0 unproven` throughout
> because a TEMPLATE-minted rail has no `cqrt_alloc` to count. This is **OQ-C1D-1's class one shape
> over**, DISCLOSED not fixed. Reproducers `docs/prd/phase-04-swap-route-control/inc1-records/
> c1-round4/c1e_a{1,2,3,4,9,11,16,17}_*.c`; narrative notes **§3.15**; residual line PRD §0 **E2**.

---

# HAND-BACK

## 1 — what shipped (branch `c1-round4`, on `main` b99b853)

| commit | contents |
|---|---|
| `d9eba90` | **F-C1E-1 item 2** — the discriminating lit accept `ir-pass/test/control_phase_kickback_mixed_value_merge_dtzb_head_preadd_inloop.ll` (218 lines, 12 prefixes, one `%cq-opt` spawn; `CSRC` and `QCNT` new to the family) |
| `5f3bb01` | **F-C1E-1 item 1** — the two in-source citations corrected in `LoopLowering.cpp` and `ArithLowering.cpp`, **COMMENTS ONLY** |
| `3521223` | **F-C1E-2 / F-C1E-3** — 16 reproducer files `inc1-records/c1-round4/c1e_a*.c` + the re-measured README table |
| `43a3a90` | **F-C1E-1..4** — notes **§3.15**'s new "the independent lens ON THE REBASED TREE" subsection, and PRD §0 **E2**'s residual line |
| `65acb8e` | **F-C1E-4** — the rebase record's self-invalidated "0 hits" grep, corrected in place (and in notes §3.15) |
| `c9f1fe9` | the session record: `review_c1e.md`, `investigate_eqpx.md`, three briefs, README rewritten for four agents |
| `dfe44ca` | `session-adc5590a/README.md` round-4 section + `NEXT_SESSION_PROMPT.md` state block: second lens CLEAR-WITH-ITEMS, full suite 367/367 at aa9d702 |
| `370517f` | counts re-measured by command (lit 1690 → **1691**; ctest/e2e/slice/golden counts UNCHANGED) |

**NO CODE CHANGE.** `git diff main HEAD -- ir-pass/src` filtered for non-comment lines is UNCHANGED
from what the rebase left: exactly the round's own `if (!P || !P->hasOneUse()) return;` →
`if (!P) return;` in `LoopLowering.cpp`, and **0** in `ArithLowering.cpp`.
`git diff --stat main HEAD -- runtime tools/opcode_table.yaml include` **EMPTY** (owner D3).

## 2 — what is left
* The orchestrator still owes: the **full `ctest -j6`** re-run on this tree, the **squash onto
  `main`**, the push, `bd close 7yd0`, the `3qlq.13` subject-list line above, and a `bd remember`.
* Untouched and still open: OQ-C1D-1/2/3, bd `eqpx` (P1, PRE-EXISTING — its READ-ONLY investigation
  is recorded but nothing from it is applied here), and everything on the epic's standing list.
* Branch committed, **NOT pushed**. No bd issue touched. The main checkout was never edited, rebuilt
  or `git`-mutated; every `main` figure came from the FROZEN binary `$SP/bin/main-258d974/`.
