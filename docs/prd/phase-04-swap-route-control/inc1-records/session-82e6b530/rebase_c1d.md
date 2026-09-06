# rebase_c1d — progress (session 82e6b530, 2026-09-06)

Task: rebase branch `c1-round4` (bd 7yd0, C-1 round 4) @ 59f6a95 onto `main` (b99b853 / code 258d974),
re-run its gates, fold in lens items F-C1D-2/3/4, re-measure `q4b`, prepare the landing.

Worktree: $SP1/wt/c1d (branch c1-round4). Progress appended after every step.

## Step 0 — orientation (2026-09-06)
Read BRIEF_common, BRIEF_rebase_c1d, CLAUDE.md, `c1-round4/fix_c1d.md` (298 lines), `c1-round4/review_c1d.md` (335 lines).
MEASURED state before the rebase:
* `main` = **b99b853** (docs-only on top of code **258d974**); worktree `$SP1/wt/c1d` = branch `c1-round4` @ **59f6a95**,
  `git status --porcelain` EMPTY, `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` EMPTY (build current).
* `git log --oneline a3c1513..c1-round4` = **10 commits**.
* Overlap `git diff --name-only a3c1513 c1-round4` ∩ `… a3c1513 main` = **exactly 5 files**, as the brief predicted:
  `CLAUDE.md`, `ROADMAP.md`, `retire-swap-route-PRD.md`, `tests/e2e/CMakeLists.txt`,
  `…/session-adc5590a/briefs/BRIEF_fix_c1d.md`.
* `git diff --name-only a3c1513 main -- ir-pass/src/LoopLowering.cpp tools/loop_twin_matrix.{py,expected.txt} …INC1_NOTES.md`
  is EMPTY → the three must-not-conflict files are untouched by main. `a3c1513..main` = 109 files;
  the code half is `ArithLowering.cpp EmitInverse.cpp SelectClassify.cpp SwapRouteEmit.cpp SwitchValueEmit.cpp`
  + 3 headers (Inc 2).

## Step 1 — the rebase (`git rebase main` in `$SP1/wt/c1d`) — DONE, commit `f920e09`

### Conflict table (MEASURED, `$W/rebase{1,2,3}.log`)
| commit being applied | file | conflict | resolution |
|---|---|---|---|
| `1cc0a6c` fix + fixture | — | none | clean |
| `2c26ec6` e2e + matrix | `tests/e2e/CMakeLists.txt` | **auto-merged** | BOTH blocks kept (verified: 29 `control_value_` lines incl. the 4 `e2e-value-*-twin-identical` gates, AND the merge-preadd pair + gate at 4823/4831/4939) |
| `d0da4ef` notes/PRD/CLAUDE | `CLAUDE.md`, PRD | **auto-merged** | clean |
| `bd22a7f` matrix table | — | none | clean |
| `09bc5f1` counts | **`CLAUDE.md` × 2 hunks** | CONTENT | took **HEAD (main's Inc-2 text)** on both — they are the ctest/lit COUNT paragraphs, which step 5 re-measures on the rebased tree; also reverted a stray extra `)` the branch side had added to close a sentence that no longer exists (`**310** goldens)).` → `goldens).`) |
| `7fb38e1` third class | **`CLAUDE.md` × 2 hunks** | CONTENT | same class, took **HEAD** on both |
| `66c2945` closure table | — | none | clean |
| `fd0c5e8` session record | `…/briefs/BRIEF_fix_c1d.md` (add/add) | **none — the two copies are byte-identical** (`git diff main HEAD -- …/BRIEF_fix_c1d.md` EMPTY) | kept |
| `59f6a95` addendum | — | none | clean |

**`ir-pass/src/LoopLowering.cpp`, `tools/loop_twin_matrix.{py,expected.txt}` and
`RETIRE_SWAP_ROUTE_INC1_NOTES.md` did NOT conflict**, as the brief required.

### Duplicate record file
`diff …/session-adc5590a/fix_c1d.md …/session-adc5590a/c1-round4/fix_c1d.md` → **no output, both 298
lines, IDENTICAL** (both carry the build-currency addendum). `git rm`'d the branch's copy; the ONE
cross-reference (`RETIRE_SWAP_ROUTE_INC1_NOTES.md:1976`) now points at `…/c1-round4/fix_c1d.md` and
names the lens beside it.
⚠ **CORRECTED by the lens on this tree (`review_c1e` F-C1E-4, applied by `docs_c1e`).** This line
said `grep -rn 'session-adc5590a/fix_c1d.md' --include='*.md' .` → **0 hits**. It is not 0 and
cannot be: the lens measured **5** and, after §3.15 gained the paragraph recording this very
finding, `docs_c1e` re-measured **7** — every one of them PROSE (the notes' §3.15 text,
`BRIEF_rebase_c1d.md`, and lines of this record itself, including the sentence that asserted 0).
What the grep was reaching for is TRUE and is now stated directly: the file is gone
(`ls …/session-adc5590a/fix_c1d.md` → No such file or directory) and **no live cross-reference
points at the missing path** — the one that did, `RETIRE_SWAP_ROUTE_INC1_NOTES.md:1976`, was
re-pointed at `…/c1-round4/fix_c1d.md` in this same commit. A `.md` file cannot assert its own
absence from a `--include='*.md'` grep.

### Reproducer duplication (kept, cross-referenced)
`inc2-records/` carries 14 of the same basenames; `diff -q` on `q4b_preadd_{rolled,unrolled}.c`,
`q5sel_preadd_rolled.c`, `q7_k32_rolled.c` → **IDENTICAL**. Both kept, with a new
`## REBASE onto the landed Increment 2` section in `inc1-records/c1-round4/README.md` saying so
and flagging that every `main` column in that table was measured against **a3c1513**, not 258d974.

### Post-rebase shape (MEASURED)
* `git log --oneline main..HEAD` → **10 commits** (none became empty).
* `git diff main HEAD --stat -- ir-pass/src ir-pass/include` → **ONLY `ir-pass/src/LoopLowering.cpp`**, +60/−12.
* `git diff main HEAD --name-status` → 3 M docs + 1 M code + 2 M tools/tests + 23 A reproducers + 2 A lit + 4 A e2e.
Next: step 2 (rebuild + gates).

## Step 2 — rebuild + the round's own gates on the REBASED binary — ALL GREEN

Rebuild: `cmake --build build -j8` (background, `$SP/progress/rebase_c1d_build1.log`) → `BUILD_RC=0`,
BOTH targets (`Built target CQPass`, `Built target cq-opt`).
`find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` → **EMPTY**.

| # | gate | command | result |
|---|---|---|---|
| 1 | the two round-4 accepts + the round-3 tripwire decline | `lit -v ir-pass/test --filter 'control_phase_kickback_mixed_merge_out_rail_preadd_inloop\|..._preheader_addc_after_region_inloop\|control_phase_kickback_reject_preloop_commit_stale'` | **3/3 PASS**, 1.43 s, of **1689** discovered |
| 2 | whole lit corpus | `ctest -R ir-pass-lit --output-on-failure` (`rebase_c1d_lit_B.log`) | **Passed, 50.47 s, 0 failed** (run A had ONE false red — see below) |
| 3 | the gate group incl. all 4 Inc-2 value twin gates + all 9 Inc-2 value slices (F-C1D-2's "re-run on the rebased tree") | `ctest -j6 -R 'twin-identical\|quarantine-selftest\|free-pairing-selftest\|perbit\|onward-perbit\|merge-preadd\|e2e-slice-control-value'` | **48/48 passed** (`e2e-value-{diamond,ifelse,mixedops,polarity}-twin-identical` all Passed; both merge-preadd slices + their `cmp` gate Passed) |
| 4 | F-C1D-2's named fixture + family | `lit --filter 'control_swap_value_ifelse_head_out_of_place'` → **1/1 PASS**; `lit --filter 'control_swap_value'` → **19/19 PASS** |
| 5 | twin matrix, **no cell may move** | `ctest -R e2e-loop-twin-matrix` (background, `rebase_c1d_matrix.log`) | **Passed, 292.00 s, 0 failed** — NO cell moved. Committed table: `grep -c '^m_' tools/loop_twin_matrix.expected.txt` = **259**, `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt` = **29** → 288 cells |

`ls ir-pass/test/*.ll | wc -l` → **1689** (main's 1687 + round 4's 2).

⚠ **RECORDED, NOT PAPERED OVER — run A of `ir-pass-lit` reported ONE red and it was MINE, not the
tree's.** `rebase_c1d_lit_A.log`: `FAIL: control_phase_kickback_mixed_merge_out_rail_preadd_inloop.ll`
with `FileCheck error: '<stdin>' is empty.` I had launched that ctest in the background and then ran
`lit --filter` on the SAME fixture in the foreground; two lit processes share one `%t.cqd0.ll`, so
one truncated the other's file. The same fixture passed standalone before and after, and the serial
re-run (run B, nothing else running) is **Passed, 0 failed**. This is CLAUDE.md's own rule —
"contention causes false FAILURES, never false passes; re-run any -j failure serially BEFORE calling
it a regression" — and the lesson for the next agent is narrower: **never run `lit --filter`
concurrently with `ctest -R ir-pass-lit` in the same build tree.**

## Step 3 (measurement half) — `q4b` RE-MEASURED on the rebased binary — **rolled == unrolled, BYTE-IDENTICAL**

Sources: `docs/prd/phase-04-swap-route-control/inc1-records/c1-round4/q4b_preadd_{rolled,unrolled}.c`
(copied to `$W/p/`). Harness `$W/run.sh` = the session-2 `review_c1d_work/run.sh` re-pointed
(stage 1 → 2 → 2b STRICT → 3 → 4). Counting convention: `cq_template_{and,lshr}_i32_hl` mints /
`_hl_unc` discharges (`$W/cnt.sh`).

| binary | rolled | unrolled | `cmp` |
|---|---|---|---|
| **`main` 258d974** (Inc 2 landed, the leak LIVE) | **4/0, 52 lines** | 4/4, 60 | **DIVERGE, 8 lines** |
| **MINE (rebased `c1-round4`)** | **4/4, 60 lines** | 4/4, 60 | **IDENTICAL** |
| ORACLE 52d7764 (`$SP0/wt/pre-3qlq`) | **S1FAIL — the program is UNEXPRESSIBLE there** | S1FAIL | — |

⭐ **MINE's rolled trace is byte-identical to `main`'s own UNROLLED twin** (`cmp -s` → identical), and
the only difference from `main`'s rolled trace is the four missing pairs
`cq_template_and_i32_hl_unc(h{6,8,10,12}, h5, …)` + `cqrt_free(h{6,8,10,12})` — i.e. exactly the four
leaked which-path ancillas, one per activation. STRICT 2b on MINE's rolled:
`6 rail mint(s) of which 6 left allocated, 8 cqrt_free site(s): 8 verified, **0 violation(s), 0 unproven**`
— the leak is invisible to it, as the epic records (a template-minted rail has no `cqrt_alloc` to count).

**The ORACLE row, stated honestly.** The committed `.c` uses the SHIPPED register-free
`cq_phi(double)`, which does not exist at 52d7764: stage 1 fails with `too few arguments provided to
function-like macro invocation`. Transliterating to the oracle's register form (`p=cq_phi(p,0.7)`) is
a DIFFERENT program and I record it as such: the **ROLLED** spelling DECLINES there
(`cq taint escape: tainted value muxed by a classical-condition phi`), the UNROLLED spelling accepts
at 4/4, 65 lines and emits **4 `cqrt_cswap` + 4 `cqrt_rz_i32_controlled`** — the routed, TENSORED
per-qubit Rz that PRD §1 shows is the identity on the marked branch. So the oracle has no
rolled/unrolled pair for this shape at all, and its unrolled member is the defect the epic retired.

**The two structural facts the brief asked me to confirm in the trace** (`out/q4b_preadd_rolled.fix.trace`):
* the Inc-2 chain HEAD is **OUT of place** — `cq_template_mul_i32_hl(h1, 5) -> h2` on a FRESH rail,
  because `p` (`h1`) is read by the merge (`cqrt_copy_i32_controlled(h4, h1, h5)`, the ¬flag arm).
  ⚠ The brief predicted `cq_template_add_i32_hl` for the head; MEASURED it is a `mul`, because
  `clang -O1` reassociates `(p+3)*5` to `p*5 + 15` — `grep -c 'cq_template_add_i32_hl('` = **0**,
  `grep -c 'cq_template_mul_i32_hl('` = **2**. The PROPERTY the brief names (head out of place, on a
  fresh rail, commit did not reach it) holds; the opcode does not.
* exactly **ONE** in-place `cqrt_addc_i32` on the merge OUT-rail: `cqrt_addc_i32(h5, 7)`. (The trace
  has 4 `cqrt_addc_i32` lines in all; the other three — `(h2,15)`, `(h2,-15)`, `(h3,7)` — are the
  HOISTED chain's own interior in-place ops and its uncompute, on `h2`/`h3`, not on `p` and not on `%out`.)

## Step 3 (pinning half) — commit `9681da5`

**lit ACCEPT `ir-pass/test/control_phase_kickback_mixed_value_merge_preadd_inloop.ll`** (206 lines),
derived from `clang -O1` on `inc1-records/c1-round4/q4b_preadd_rolled.c` with `@main` dropped, every
assertion read off MY binary's own output. Ten prefixes, one `%cq-opt` spawn:
CHECK / UCNT / **HCNT** / PCNT / ACNT / FCNT / XCNT / **RYCNT** / MDCNT / NOROUTE (whole-file pure-negative).

Red-green per prefix (`$W/rg.sh`, three binaries):
| binary | verdict |
|---|---|
| `main` **258d974** (`$SP/bin/main-258d974/`) | `OPT_RC=0 **CHECK=1 FCNT=1 UCNT=1**` (ACNT/HCNT/MDCNT/NOROUTE/PCNT/RYCNT/XCNT = 0) — **RED** |
| MINE (rebased) | all **10 prefixes 0** — **GREEN** |
| `c1dpre` = the PRE-rebase round-4 binary 59f6a95 (a3c1513 + the fix, no Inc 2) | `CHECK=1 HCNT=1 NOROUTE=1 PCNT=1 XCNT=1` — red, because there the value arm still ROUTES (`cqrt_cswap`). Not a defect: it is the discriminator that this fixture is specific to the Inc-2 mechanism |

Counts asserted, all MEASURED on the pass output (`call`-sites only, declares excluded):
`cq_template_and_i32_hl_unc` **1** (main: **0**) · `cqrt_free` **4** (main: **3**) · `cqrt_addc_i32` **4** ·
`cqrt_rz_i1` **1** · `cqrt_x(i32` **4** · `cqrt_ry_` **2** · `!cq.branchphase` **1** ·
`cq_template_mul_i32_hl` **2** · `cq_template_add_i32_hl` **0** · `cqrt_cswap` **0**.

**The F-C1D-2 pin is the `HCNT` prefix** — the lens asked for it and could not pin it:
`%[[P2]] = cqrt_alloc_i32(7)` → `cqrt_ry_i32(%[[P2]], 0.25)` → `cq_template_mul_i32_hl(%[[P2]], 5)`
(the head, OUT of place onto a fresh rail), then whole-file `HCNT-NOT: cqrt_addc_i32(i32 %[[P2]],`
and `HCNT-NOT: cqrt_xorc_i32(i32 %[[P2]],` — `p`'s own rail is never mutated in place, because the
¬flag arm of the merge reads it. That is G6/G7 (Inc 2's "CONSUMER 2"), the sole net there now.

**e2e pair** `tests/e2e/slice_control_phase_perbit_loop_value_merge_preadd{,_unrolled}.c` + goldens
generated by the FULL pipeline on my binary:
| | rolled | unrolled | `cmp` |
|---|---|---|---|
| `main` 258d974 | 4/0, **52** | 4/4, 60 | DIVERGE 8 |
| MINE | 4/4, **60** | 4/4, 60 | **IDENTICAL** |
STRICT 2b on both: `0 violation(s), 0 unproven`. The two goldens are byte-identical (60 = 60) and the
rolled golden is byte-identical to the q4b reproducer's trace. Registered next to the merge-preadd
block: 2 slices + the `cmp` gate `e2e-phase-perbit-loop-value-merge-preadd-twin-identical`.
`cmake -S . -B build` rc=0; `ctest -j6 -R 'value-merge-preadd'` → **3/3 passed, 2.32 s**.

## Step 4 — the lens items F-C1D-2 / F-C1D-3 / F-C1D-4 (commits `dbeff1f`, `<F-C1D-4>`)

### F-C1D-2 — the in-source argument (COMMENTS ONLY)
MEASURED that the two edits are comment-only: `git diff -- ir-pass/src/{Arith,Loop}Lowering.cpp`
adds **0 non-comment lines** and removes **0 lines** (`grep -vcE '^\+\s*//'` over the added lines,
and `grep -cE '^-[^-]'` = 0).
* `LoopLowering.cpp`, at `commitOutOfLoopInPlaceOps`' argument: **why the commit cannot reach an
  Inc-2 chain head**, in two independent halves, each read off the code —
  **(A) DIRECTION**: the walk is `peelInPlaceStep`, which returns an OPERAND (a rotation gate's
  arg 0, or `inPlaceValueRailOperand`'s tainted side), so it walks BACKWARD; a chain head is a
  USER of the arm's input `Q`, forward of it, and on the arm's side of the merge.
  **(B) THE PEEL STOPS AT THE `cqrt_alloc`**: the merge candidate reaches this path from
  `collapseFlattenedLoopRails` (`CQLoweringPass.cpp:393`), AFTER `lowerControlRegions` (`:376`)
  has emitted `%out = cqrt_alloc_<W>(0)` and RAUW'd the merge to it, and `peelInPlaceStep`'s FIRST
  clause returns null for a `CallInst` not in `GateCalls`. So the peel visits exactly
  {the preheader op, `%out`} and stops.
* `ArithLowering.cpp`'s CONSUMER-2 comment gains one cross-reference sentence naming the
  retirement, the backward-peel reason and the new fixture. **No code change there.**
* PINNED by the new fixture's `HCNT` prefix (step 3).

### F-C1D-3 — three refinements to notes §3.14's 8h7d.5 closure table, each VERIFIED first
1. **fan-out row**: "arithmetically unchanged" is complete only because a committed op can never
   have been `OutOfPlace` — `railValueConsumerDisposition` returns `OutOfPlace` **exactly** when
   `blockCanRepeat(BO->getParent())` (`LoopLowering.cpp:212-213`, the one such return), and
   `inPlaceFenceHolds`' G5 refuses precisely that (`ArithLowering.cpp:646-648`). Without G5 the
   widening WOULD add an `InPlaceUser` and could mint a new `kMsgRailFanout` decline.
2. **`WireWalk` row**: its stated reason ("the stage runs before `lowerLoops`") is **FALSE** for
   `declineLiftedStaleRecordOps` — `CQLoweringPass.cpp:522` (and `:848` in the second entry
   point), both AFTER the commit at `:363`/`:393`. The row survives because
   `grep -n 'InPlaceRailOps\|PreLoopCommittedInPlaceOps' ir-pass/src/WireWalk.cpp ir-pass/include/WireWalk.h`
   returns **exactly one line, `WireWalk.cpp:457`, and it is PROSE** — no code read at all.
3. **the row the table lacked — the F-3 question**: `staleRailRecordRead`'s **SKIP** set is the
   CHAIN, built with `peelInPlaceStep(V, GateCalls, taint)` at the default `AsLowered=false`
   (`LoopLowering.cpp:2539`, `:2546`) — the SHAPE reading — so the widening grows the GATE set and
   the RECORD set (both decline-ward) and **cannot shrink the skip set**.
   Peel census RE-MEASURED (`grep -rn 'peelInPlaceStep(\|peelInPlaceBase(' ir-pass/src ir-pass/include`):
   **24 hits, 4 prose, 2 decl/defn = 18 code call sites**, of which **2 pass `AsLowered=true`**
   (`LoopLowering.cpp:3214` clause (ii)'s peel, and `:3412-3413` `markIfRailLocal::onRail` — the
   latter wraps over two lines, which is why a one-line `grep -c` reports 1). The lens's `:3176`
   and `:3374` are the same two sites before my +38-line comment (3176+38 = 3214; 3374+38 = 3412).

### F-C1D-4 — the injection matrix gains an `extra_ry` row
`$W/inj.py` (a copy of the session-2 tool, re-pointed — the REPO path is unchanged because this
worktree IS the one it named) gains mutation `extra_ry`: insert
`call void @cqrt_ry_i32(i32 <rail>, double 5.000000e-01)` immediately AFTER the last `cqrt_free`,
`<rail>` = arg-0 of the first `and`/`lshr` `_hl` template call, falling back to the first
`cqrt_alloc_*` result. Accept set = `grep -L 'RUN: not' ir-pass/test/control_phase_kickback_*.ll`
= **44 files** (of 62 in the family).

| run | result |
|---|---|
| FIRST (`rebase_c1d_inj1.log`), 44 × 17 | `extra_ry` **25 MISSED**, 0 DIRTY; every one of the 16 pre-existing mutations **0 MISSED / 0 DIRTY**; `clean` PASS on all 44 |
| after adding a `RYCNT` prefix to those 25 | `lit --filter 'control_phase_kickback'` → **62/62 PASS** |
| SECOND (`rebase_c1d_inj2.log`), 44 × 17 | ⭐ **0 MISSED / 0 DIRTY on every column**; `clean` PASS on all 44. `extra_ry` is caught by **RYCNT on 26** fixtures and by **CHECK on 18** |

Each of the 25 gains ONE extra `%filecheck … --check-prefix=RYCNT < %t.cqd0.ll` RUN line against
the EXISTING `%t.cqd0.ll` (no second `%cq-opt` spawn) plus its own `RYCNT-COUNT-n` / `RYCNT-NOT`
block, `n` read from the pass output (measured 1–4 per fixture). **RYCNT is its own prefix and is
never folded into NOROUTE** — a `COUNT` inside NOROUTE windows every `NOT` after it (the
Inc-3/Inc-4 recurrence the brief warns about). No decline fixture was touched.

## Step 5 — docs (status flips + counts BY COMMAND) and the record — commit `cc0399b`

### Status flips — every "in flight" / "NOT landed" sentence about bd `7yd0`
Using the precedent wording verbatim: **LANDED on `main` 2026-09-06 as ONE squash commit** (hash
filled by the orchestrator: the squash of branch `c1-round4`, whose tip is recorded in the landing
commit message; `git log main -1` shows the hash).
* PRD `retire-swap-route-PRD.md`: §0 **E2**'s round-4 paragraph, **E10** item 3b, **E11**'s
  "WHERE THE FIX LIVES: not here", **E12**'s `7yd0` bullet, and the §7 header line.
* `RETIRE_SWAP_ROUTE_INC2_NOTES.md`: §5's `7yd0` paragraph and the **F-I2-1** disposition row.
* `ROADMAP.md`: the Inc-2 block's F-I2-1 sentence and the C-1 fourth-round paragraph.
* `CLAUDE.md`: the C-1 bullet's round-4 paragraph (with the ⚠ that every `main` figure in it is
  against **a3c1513**, plus the 258d974 re-measurement and the F-C1D-2/3/4 dispositions).
* `inc1-records/session-adc5590a/README.md`'s round-4 section and
  `NEXT_SESSION_PROMPT.md`'s state line (the latter marked HISTORY for its step 1 and left AS
  WRITTEN so the hand-off can be diffed against what happened).

### Notes — new **§3.15** "The round-4 REBASE onto the landed Increment 2"
The rebase + conflict table, the `q4b` measurement on three binaries, the F-C1D-1/2/3/4
dispositions, and the `extra_ry` injection table.

### Counts, MEASURED on the rebased build (never by arithmetic)
| command | main 258d974 | rebased |
|---|---|---|
| `ls ir-pass/test/*.ll \| wc -l` | 1687 | **1690** |
| `ctest --test-dir build -N \| tail -1` | 361 | **367** |
| `ctest -N -R '^e2e-'` | 351 | **357** |
| `ctest -N -R '^e2e-slice-'` | 317 | **321** |
| `ctest -N -R 'twin-identical'` | 24 | **26** |
| `ls tests/e2e/*.expected.log \| wc -l` | 319 | **323** |
| `grep -c '^m_' tools/loop_twin_matrix.expected.txt` | 259 | **259 (UNCHANGED)** |
| `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt` | 29 | **29 (UNCHANGED)** |
| non-`i1` `cqrt_rz` across the goldens | 0 | **0**, now across 323 |
| goldens containing `cqrt_cswap` | 1 of 319 | **1 of 323** (`slice_control_abort`) |
(main's figures read from `git show main:…` / `git ls-tree -r main` — the main checkout was never
built, rebuilt or mutated this session.)

### Record
`inc1-records/session-82e6b530/{README.md, briefs/BRIEF_common.md, briefs/BRIEF_rebase_c1d.md}`;
this progress file is copied there as `rebase_c1d.md` at the end. The c1-round4 reproducer README
gains a `## REBASE onto the landed Increment 2` section (its `main` columns are against **a3c1513**,
the `inc2-records/` duplication cross-referenced) and the `q4b` re-measurement table.

---

# HAND-BACK

**`q4b` VERDICT: rolled == unrolled, BYTE-IDENTICAL, 4/4 = 4/4 at 60 = 60 on the rebased binary
(and byte-identical to `main` 258d974's OWN unrolled twin), against 4 mints / 0 `_unc` at 52 lines
vs 4/4 at 60 — `cmp` DIVERGE 8 — on `main` 258d974. NO FINDING: nothing moved that should not
have, and no twin-matrix cell moved.**

## 1 — what shipped (branch `c1-round4`, on `main` b99b853)

Round 4's own **ten** commits, rebased unchanged, plus the **five** below, plus the record commits
that carry this very file (which is why no hash is quoted for the tip: it moves each time this
file is corrected — `git log --oneline main..HEAD | wc -l` and `git rev-parse HEAD` on the handed-
off branch are authoritative, and the hand-back message reports both as measured at hand-off):

| commit | contents |
|---|---|
| `f920e09` | the rebase resolution: two `CLAUDE.md` count-hunk conflicts → main's Inc-2 text (+ a stray `)` reverted), the duplicate `session-adc5590a/fix_c1d.md` `git rm`'d and its cross-reference re-pointed, the moved baseline + the `inc2-records/` duplication recorded in the reproducer README |
| `9681da5` | ⭐ `q4b` PINNED: lit accept `control_phase_kickback_mixed_value_merge_preadd_inloop.ll` (10 prefixes) + e2e pair `slice_control_phase_perbit_loop_value_merge_preadd{,_unrolled}.c` + goldens + the `cmp` gate `e2e-phase-perbit-loop-value-merge-preadd-twin-identical` |
| `dbeff1f` | **F-C1D-2** (the in-source "the commit cannot reach an Inc-2 chain head" argument + the `ArithLowering` cross-reference — COMMENTS ONLY) and **F-C1D-3** (three verified refinements to notes §3.14's 8h7d.5 closure table) |
| `8fbbcd0` | **F-C1D-4**: the injection matrix's `extra_ry` row + a `RYCNT` prefix on 25 kickback accepts |
| `cc0399b` | status flips (round 4 landing), notes **§3.15**, counts re-measured by command, `inc1-records/session-82e6b530/` |

**CODE — still ONE non-comment change on the whole branch.** `git diff main HEAD -- ir-pass/src`
= `LoopLowering.cpp` (+110/−12) and `ArithLowering.cpp` (+10/−0); filtering comments,
**ArithLowering has 0 non-comment changed lines** and LoopLowering has exactly the round's own
conjunct: `if (!P || !P->hasOneUse()) return;` → `if (!P) return;`.
`git diff --stat main HEAD -- runtime tools/opcode_table.yaml include` is **EMPTY** (owner D3).

## 2 — what I ran (every command, every result)

| # | gate | result |
|---|---|---|
| 1 | `git rebase main` | 10 commits replayed, **2 hand-resolved `CLAUDE.md` hunks** (both count paragraphs), everything else auto-merged; `LoopLowering.cpp`, `tools/loop_twin_matrix.*` and `RETIRE_SWAP_ROUTE_INC1_NOTES.md` **did not conflict**; `git log --oneline main..HEAD` = 10 (none empty) |
| 2 | `cmake --build build -j8` (BOTH targets) | `BUILD_RC=0`; `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` **EMPTY**, re-checked after every later edit |
| 3 | the 2 round-4 accepts + the round-3 tripwire decline | `lit --filter …` **3/3 PASS**, 1.43 s |
| 4 | `ctest -R ir-pass-lit` | **Passed, 50.47 s, 0 failed** (run B, serial) — see the OWNER-QUESTION-adjacent note below about run A |
| 5 | `ctest -j6 -R 'twin-identical\|quarantine-selftest\|free-pairing-selftest\|perbit\|onward-perbit\|merge-preadd\|e2e-slice-control-value'` | **48/48 passed** — incl. all four `e2e-value-*-twin-identical` gates and all nine Inc-2 value slices (F-C1D-2's "re-run on the rebased tree") |
| 6 | `lit --filter 'control_swap_value_ifelse_head_out_of_place'` / `'control_swap_value'` | **1/1** and **19/19 PASS** |
| 7 | `ctest -R e2e-loop-twin-matrix` | **Passed, 292.00 s, 0 failed — NO cell moved** (259 expected rows + 29 quarantined = 288, both files byte-unchanged) |
| 8 | ⭐ `q4b` on three binaries (full pipeline, STRICT 2b) | `main` 258d974 **4/0, 52** vs 4/4, 60 (DIVERGE 8) · rebased **4/4, 60 == 4/4, 60 IDENTICAL** · oracle 52d7764 **unexpressible** (stage 1 fails on the register-free `cq_phi`; its register-form transliteration declines rolled and routes unrolled with 4 `cqrt_cswap` + 4 `cqrt_rz_i32_controlled`) |
| 9 | red-green on the new fixture, 3 binaries × 10 prefixes | `main` 258d974 `CHECK=1 FCNT=1 UCNT=1` **RED** · rebased **all 10 zero** · pre-rebase 59f6a95 `CHECK/HCNT/NOROUTE/PCNT/XCNT` red (it still routes — the discriminator) |
| 10 | `ctest -j6 -R 'value-merge-preadd'` | **3/3 passed, 2.32 s** |
| 11 | injection matrix, 44 accepts × 17 mutations, twice | first: `extra_ry` **25 MISSED**, everything else 0/0 · after the `RYCNT` prefixes: ⭐ **0 MISSED / 0 DIRTY everywhere**, `clean` PASS on all 44 |
| 12 | `lit --filter 'control_phase_kickback'` | **62/62 PASS** |
| 13 | `ctest -R ir-pass-lit` (final, after the RYCNT edits) | **Passed, 53.62 s, 0 failed**, 1690 fixtures |
| 14 | final sanity `ctest -j6 -R 'twin-identical\|merge-preadd\|quarantine-selftest\|free-pairing-selftest'` | **32/32 passed** |
| **NOT run** (deliberately, per BRIEF_common) | the full `ctest` (the orchestrator's gate), `cq-opt-equivalence-full`, `frontend-lit`, the runtime entries, the whole-population sweep (round 4's own 485/615-program sweeps stand; nothing on this branch changes a decline predicate) | |

## 3 — findings that are NOT mine to decide

**None that is a wrong unitary, a moved cell, or a contradiction of a PRD §2 decision.** Three
things a reader should know, none of them blocking:

### RECORD ITEM — one `ir-pass-lit` red was SELF-INFLICTED, and it is recorded rather than hidden
Run A reported `FAIL: control_phase_kickback_mixed_merge_out_rail_preadd_inloop.ll` with
`FileCheck error: '<stdin>' is empty.` I had a background `ctest -R ir-pass-lit` and a foreground
`lit --filter` on the SAME fixture running at once; two lit processes share one `%t.cqd0.ll`.
The serial re-run is green, and the fixture passed standalone before and after. CLAUDE.md's rule
covers it ("contention causes false FAILURES, never false passes; re-run serially before calling
it a regression"); the narrower lesson for the next agent is **never run `lit --filter`
concurrently with `ctest -R ir-pass-lit` in the same build tree.**

### RECORD ITEM — the brief's predicted chain-head opcode is a `mul`, not an `add`
The brief expected `cq_template_add_i32_hl` for the hoisted chain head. MEASURED,
`clang -O1` reassociates `(p+3)*5` into `p*5 + 15`, so the head is `cq_template_mul_i32_hl` and
`cq_template_add_i32_hl` count is **0**. The PROPERTY the brief names — head OUT of place on a
fresh rail, the commit did not reach it — holds and is what `HCNT` pins. Likewise the brief's
"`cqrt_addc_i32` count == 1": the module has **4**, of which exactly ONE is on the merge `%out`
(the subject) and three are the hoisted chain's own interior ops on `%h_op`/`%h_op3`. Both are
asserted as measured, in `CHECK` (the `%out` one, by capture) and `PCNT` (the total).

### RECORD ITEM — the peel census is 18 code call sites, not the lens's 20
`grep -rn 'peelInPlaceStep(\|peelInPlaceBase(' ir-pass/src ir-pass/include` → **24 hits**, of
which **4 are prose** and **2 are the declaration and the definition** ⇒ **18 code call sites**,
**2** of them at `AsLowered=true`. The lens's *ratio* ("only 2") reproduces exactly; its
denominator does not, so §3.14 now carries the census with the command that produced it.

## 4 — what is left

* The orchestrator still owes: the **full `ctest -j6`** on this tree, the **squash onto `main`**
  (the docs already read "LANDED … hash filled by the orchestrator", the precedent wording),
  the push, `bd close 7yd0` and a `bd remember`.
* **An independent Rule-13 lens on THIS tree is worth budgeting** even though the code delta is
  unchanged from the already-cleared round 4: the count on this one function is eight findings
  over six adversarial rounds, two of them introduced by a fix, and this rebase adds a NEW
  customer class to the fixed path (the Inc-2 controlled-copy merge) plus 25 edited fixtures.
* Untouched and still open: OQ-C1D-1 (`m11d` is refused by G7 arm (e), not by `hasOneUse`),
  OQ-C1D-2 (the one-line revert if the owner prefers to keep the conjunct), OQ-C1D-3 (`q7_k32`
  and `q5v_xor` have no faithful twin), and everything on the epic's standing list.
* Branch committed, **NOT pushed**. No bd issue closed or edited. The main checkout was never
  edited, rebuilt, or `git`-mutated.

---
### Hand-off state (measured at hand-off)
* branch `c1-round4`, `git log --oneline main..HEAD | wc -l` = **17** (`main` = b99b853).
  ⚠ The TIP HASH is deliberately not written here: this file is committed ON that branch, so
  quoting its own tip is self-referential and goes stale on the next amend — `git rev-parse
  c1-round4` is the answer, and the agent's final message reports it as measured at hand-off.
  `git status --porcelain` EMPTY; `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt`
  EMPTY. NOT pushed. The main checkout is untouched at b99b853 and was never built this session.
